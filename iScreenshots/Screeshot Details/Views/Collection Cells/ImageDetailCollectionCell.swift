//
//  ImageDetailCollectionCell.swift
//  iScreenshots
//
//  Created by Suresh Reddy on 30/09/23.
//

import UIKit
import Photos
import Vision

// A UICollectionViewCell subclass for displaying details of an image with associated tags and information.

final class ImageDetailCollectionCell: UICollectionViewCell {
    
    // Outlets for UI elements in the cell.
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var noteTextField: UITextField!
    @IBOutlet weak var collectionsTitle: UILabel!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var mCollectionView: UICollectionView!
    @IBOutlet weak var descriptionTitle: UILabel!
    @IBOutlet weak var descriptionValue: iScreenshotsLabel!
    @IBOutlet weak var mainVerticleStackView: UIStackView!
    @IBOutlet weak var infoBaseView: UIView!
    @IBOutlet weak var mCollectionViewHeight: NSLayoutConstraint!
    
    // Reuse identifier for the cell.
    static let reuseIdentifier = "ImageDetailCollectionCell"
    
    // Height of a tag cell in the collection view.
    private let tagCellHeight: CGFloat = 36
    
    // Delegate to handle cell interactions.
    weak var delegate: ImageDetailCollectionCellDelegate?
    
    // View model to populate and update cell data.
    var viewModel: ImageDetailCollectionCellViewModel?
    
    // MARK: - View Initialization
    
    // This method is called when the cell is loaded from a nib or storyboard.
    // It sets up the collection view, registers a custom cell, and configures its layout.
    override func awakeFromNib() {
        super.awakeFromNib()

        // Set the delegate for the collection view and disable scrolling.
        mCollectionView.delegate = self
        mCollectionView.isScrollEnabled = false
        mCollectionView.backgroundColor = .clear

        // Register the custom collection view cell using its reuse identifier.
        mCollectionView.register(UINib(nibName: ImageTagCollectionCell.reuseIdentifier, bundle: nil), forCellWithReuseIdentifier: ImageTagCollectionCell.reuseIdentifier)

        // Configure the collection view's layout using a compositional layout.
        mCollectionView.collectionViewLayout = UICollectionViewCompositionalLayout(sectionProvider: { index, environment in
            return self.gridLayout(environment: environment)
        })
        let readMore = try! NSRegularExpression(pattern: "Read more")
        let readLess = try! NSRegularExpression(pattern: "Read less")

        descriptionValue.enabledDetectors = [.custom(readMore), .custom(readLess)]
        descriptionValue.delegate = self
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        mainImageView.addGestureRecognizer(tap)
    }

    // MARK: - View Model Binding

    // This method sets up the view model binding by assigning the delegate and defining actions to handle updates.
    private func addViewModelBinding() {
        viewModel?.delegate = {
            [weak self] action in
            switch action {
            case .refresh:
                DispatchQueue.main.async {
                    self?.updateTagsCollectionView()
                }
            case .updateDescription:
                DispatchQueue.main.async {
                    self?.updateDescription()
                }
            }
        }
    }
    
    @objc func handleTapGesture(){
        delegate?.handleImageTap()
    }

    // MARK: - UI Configuration

    // This method configures the UI elements of the cell with the provided view model.
    func configureUI(with viewModel: ImageDetailCollectionCellViewModel) {
        self.viewModel = viewModel
        addViewModelBinding()
        noteTextField.text = viewModel.imageNote
        updateDescription()
        updateInfoBaseViewStatus(isHidden: !viewModel.isInfoNeedToShow)
        mainImageView.fetchImageAsset(viewModel.imageData, targetSize: mainImageView.bounds.size, completionHandler: nil)
        updateTagsCollectionView()
    }
    
    private func updateDescription(){
        if let imageDescription = viewModel?.imageDescription, imageDescription.count > 160 {
            descriptionValue.text =  imageDescription.prefix(150) + " Read more"
        } else {
            descriptionValue.text = viewModel?.imageDescription
        }
    }

    // This method updates the visibility of UI elements based on the provided isHidden flag.
    func updateInfoBaseViewStatus(isHidden: Bool) {
        self.mainImageView.contentMode = isHidden ? .scaleAspectFit : .scaleAspectFill
        self.infoBaseView.isHidden = isHidden
    }

    // MARK: - Tags Collection View

    // This method updates the tags collection view with data and adjusts its height.
    private func updateTagsCollectionView() {
        mCollectionView.dataSource = self
        mCollectionView.reloadData()
        let availableWidth = mCollectionView.frame.width - tagCellHeight
        self.mCollectionViewHeight.constant = ceil(viewModel!.totalTagsWidth / availableWidth) * tagCellHeight
        self.setNeedsLayout()
    }

    // MARK: - Collection View Layout

    // This method defines the layout for the tags collection view.
    func gridLayout(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(60),
                                              heightDimension: .absolute(tagCellHeight))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = .init(top: 2, leading: 0, bottom: 2, trailing: 0)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .absolute(tagCellHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                       subitems: [item])
        group.interItemSpacing = .fixed(viewModel!.cellInset)
        let section = NSCollectionLayoutSection(group: group)
        return section
    }

    // MARK: - Note Management

    // This method updates or retrieves the note text based on the isNeedtoSave flag.
    func updateNote(isNeedtoSave: Bool) {
        if isNeedtoSave {
            viewModel?.imageNote = noteTextField.text ?? viewModel?.imageNote ?? ""
        } else {
            noteTextField.text = viewModel?.imageNote
        }
    }

    // MARK: - User Interaction

    // This method is called when the "Edit" button is tapped. It notifies the delegate for further action.
    @IBAction func editSelected(_ sender: UIButton) {
        guard let viewModel = viewModel else {
            return
        }
        delegate?.editSelected(for: viewModel)
    }

    // MARK: - Reuse Preparation

    // This method prepares the cell for reuse by resetting UI elements and clearing the view model.
    override func prepareForReuse() {
        super.prepareForReuse()
        noteTextField.text = ""
        viewModel = nil
    }

}

// MARK: - UICollectionViewDataSource and UICollectionViewDelegate

extension ImageDetailCollectionCell: UICollectionViewDataSource, UICollectionViewDelegate {

    // Returns the number of items in the collection view section.
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.cellModels.count ?? 0
    }

    // Provides the collection view with cells to display in each item.
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Ensure the view model and cell models are valid, and dequeue a reusable cell.
        guard let viewModel = viewModel,
              viewModel.cellModels.count > indexPath.row,
              let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageTagCollectionCell.reuseIdentifier, for: indexPath) as? ImageTagCollectionCell else {
            return UICollectionViewCell() // Return an empty cell if conditions aren't met.
        }
        
        // Configure the cell with data from the view model's cell models.
        cell.configureUI(viewModel.cellModels[indexPath.row])
        return cell
    }
}
extension ImageDetailCollectionCell : iScreenshotsLabelDelegate {
    /// Triggered when a tap occurs on a custom regular expression
    ///
    /// - Parameters:
    ///   - pattern: the pattern of the regular expression
    ///   - match: part that match with the regular expression
    func didSelectCustom(_ pattern: String, match: String?){
        switch pattern {
        case "Read more":
            if let description = viewModel?.imageDescription, description.count > 800 {
                delegate?.showDescription(text: description)
            } else {
                descriptionValue.text = (viewModel?.imageDescription ?? "") + " Read less"
            }
            
        case "Read less":
            descriptionValue.text = (viewModel?.imageDescription.prefix(150) ?? "") + " Read more"

        default: break
        }
    }
}
