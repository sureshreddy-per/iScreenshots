//
//  EditTagsPopupView.swift
//  iScreenshots
//
//  Created by Suresh Reddy on 01/10/23.
//

import UIKit
// Type alias for a closure that takes an EditTagsPopupView as a parameter.
typealias EditTagsPopupViewAction = ((EditTagsPopupView) -> Void)

// A custom popup view for editing image tags.
final class EditTagsPopupView: BottomBasePopupView {

    // Outlets for UI elements in the popup.
    @IBOutlet weak var selectedCollectionView: UICollectionView!
    @IBOutlet weak var availableCollectionView: UICollectionView!
    @IBOutlet weak var topHorizontalView: UIView!
    @IBOutlet weak var selectedCollectionViewHeight: NSLayoutConstraint!

    // View model to populate and update popup data.
    var viewModel: EditTagsPopupViewModel!
    
    // Closure to execute when a user action is performed.
    private var onSelectAction: EditTagsPopupViewAction?

    // Create an instance of the EditTagsPopupView.
    class func instanceFromNib(selectedTags: [String], allOtherTags: [String]) -> EditTagsPopupView {
        let view = UINib(nibName: "EditTagsPopupView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! EditTagsPopupView
        view.viewModel = EditTagsPopupViewModel(selectedTags: selectedTags, allOtherTags: allOtherTags, screenWidth: view.selectedCollectionView.frame.width)
        return view
    }

    // MARK: - View Initialization

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    // Set up the UI elements and configure the collection views.
    private func setupUI() {
        selectedCollectionView.delegate = self
        selectedCollectionView.isScrollEnabled = false
        selectedCollectionView.backgroundColor = .clear
        selectedCollectionView.register(
            UINib(nibName: ImageTagCollectionCell.reuseIdentifier, bundle: nil),
            forCellWithReuseIdentifier: ImageTagCollectionCell.reuseIdentifier)
        
        selectedCollectionView.collectionViewLayout = UICollectionViewCompositionalLayout(sectionProvider: { index, environment in
            return self.viewModel.gridLayout(environment: environment)
        })
        selectedCollectionView.contentInset = UIEdgeInsets(top: 8,
                                                           left: 8,
                                                           bottom: -8,
                                                           right: -8)
        selectedCollectionView.layer.borderWidth = 1
        selectedCollectionView.layer.borderColor = UIColor.gray.cgColor
        selectedCollectionView.layer.cornerRadius = 8

        availableCollectionView.delegate = self
        availableCollectionView.isScrollEnabled = false
        availableCollectionView.backgroundColor = .clear
        availableCollectionView.register(
            UINib(nibName: ImageTagCollectionCell.reuseIdentifier, bundle: nil),
            forCellWithReuseIdentifier: ImageTagCollectionCell.reuseIdentifier)
        
        availableCollectionView.collectionViewLayout = UICollectionViewCompositionalLayout(sectionProvider: { index, environment in
            return self.viewModel.gridLayout(environment: environment)
        })
        
        topHorizontalView.layer.cornerRadius = topHorizontalView.frame.height / 2
    }
    
    // Add the view model binding to handle updates and configure the UI.
    private func addViewModelBinding(){
        viewModel.delegate = {
            [weak self] action in
            switch action {
            case .refresh:
                DispatchQueue.main.async {
                    self?.configureUI()
                    self?.availableCollectionView.reloadData()
                }
            case .scrollTo(indexPath: _): break
            }
        }
    }
    
    // Configure the UI elements and reload data for the collection views.
    func configureUI(){
        selectedCollectionView.dataSource = self
        availableCollectionView.dataSource = self
        
        addViewModelBinding()
        selectedCollectionView.reloadData()
        
        self.selectedCollectionViewHeight.constant = viewModel.getHeightOfSelectedCollection()
        self.setNeedsLayout()
    }
    
    // Define an action to be executed when the "Done" button is selected.
    @discardableResult
    public func onDoneAction(_ action: @escaping EditTagsPopupViewAction) -> Self {
        onSelectAction = action
        return self
    }
    
    // Handle the "Done" button action and execute the associated closure.
    @IBAction func doneSelected(_ sender: UIButton) {
        onSelectAction?(self)
    }
    
    // Calculate and return the height of the popup view.
    func height()->CGFloat { 300 }
}

// MARK: - UICollectionViewDataSource and UICollectionViewDelegate

extension EditTagsPopupView : UICollectionViewDataSource, UICollectionViewDelegate {
    
    // Returns the number of items in the collection view section.
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        
        if collectionView == selectedCollectionView {
            return viewModel.selectedCellModels.count
        } else {
            return viewModel.availableCellModels.count
        }
    }
    
    // Provides the collection view with cells to display in each item.
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == selectedCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageTagCollectionCell.reuseIdentifier, for: indexPath) as? ImageTagCollectionCell else { return UICollectionViewCell() }
            
            cell.configureUI(viewModel.selectedCellModels[indexPath.row])
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageTagCollectionCell.reuseIdentifier, for: indexPath) as? ImageTagCollectionCell else { return UICollectionViewCell() }
            
            cell.configureUI(viewModel.availableCellModels[indexPath.row])
            return cell
        }
    }
    
    // Handle the selection of items in the collection views and update the view model.
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        
        guard let cell = collectionView.cellForItem(at: indexPath) as? ImageTagCollectionCell, let tag = cell.viewModel?.tag else {
            return
        }
        if collectionView == selectedCollectionView {
            viewModel.removeItemFromSelected(tag: tag)
        } else {
            viewModel.addItemToSelected(tag: tag)
        }
    }
}
