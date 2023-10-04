//
//  ViewController.swift
//  iScreenshots
//
//  Created by Suresh Reddy on 30/09/23.
//

import UIKit
import Photos
// MARK: - View Controller Class

// This class represents the main view controller of the app.
final class ViewController: UIViewController, UITabBarDelegate, UIScrollViewDelegate {
    
    // MARK: - Properties
    
    // Lazy initialization of the bottom sliding bar view.
    lazy var bottomSlidingBar: ImageViewBottomAccessoryView = {
        let bar = ImageViewBottomAccessoryView.instanceFromNib()
        return bar
    }()
    
    // IBOutlet for the bottom tab bar.
    @IBOutlet weak var mBottomTabBar: UITabBar!
    
    // IBOutlet for the collection view.
    @IBOutlet weak var collectionView: UICollectionView!
    
    // View model for this view controller.
    private let viewModel = ViewModel()
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the tab bar delegate.
        mBottomTabBar.delegate = self
        
        // Add the bottom sliding bar view to the main view.
        view.addSubview(bottomSlidingBar)
        bottomSlidingBar.addConstraints(left: view.leftAnchor, bottom: mBottomTabBar.topAnchor, right: view.rightAnchor, topConstant: 44, heightConstant: 48)
        
        // Register the collection view cell.
        collectionView.register(UINib(nibName: ImageDetailCollectionCell.reuseIdentifier, bundle: nil), forCellWithReuseIdentifier: ImageDetailCollectionCell.reuseIdentifier)
        
        // Configure the collection view's layout.
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .horizontal
        config.contentInsetsReference = .none
        collectionView.collectionViewLayout = UICollectionViewCompositionalLayout(sectionProvider: { index, environment in
            return self.fullLayout(environment: environment)
        }, configuration: config)
        
        // Set up view model binding.
        addViewModelBinding()
        
        // Reload data and update UI elements.
        bottomSlidingBar.reloadData(viewModel: viewModel)
        navigationItem.title = viewModel.fetchNavigationDate()
        collectionView.reloadData()
        
        // Register for keyboard notifications.
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // MARK: - Keyboard Handling
    
    // Handle keyboard appearance by showing cancel and done buttons in the navigation bar.
    @objc func keyboardWillShow(_ notification: Notification) {
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(cancelNoteSelected))
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(addNoteSelected))
        navigationItem.rightBarButtonItem = doneButton
        navigationItem.leftBarButtonItem = cancelButton
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    // Handle keyboard dismissal by removing buttons from the navigation bar.
    @objc func keyboardWillHide(_ notification: Notification) {
        navigationItem.rightBarButtonItems = []
        navigationItem.leftBarButtonItems = []
    }
    
    // MARK: - Keyboard Actions
    
    // Handle the cancel button tap action.
    @objc func cancelNoteSelected() {
        dissmissKeyboard(isNoteNeedToSave: false)
    }
    
    // Handle the done button tap action.
    @objc func addNoteSelected() {
        dissmissKeyboard(isNoteNeedToSave: true)
    }
    
    // Dismiss the keyboard and update the note.
    private func dissmissKeyboard(isNoteNeedToSave: Bool) {
        guard let cell = collectionView.cellForItem(at: viewModel.selectedIndexPath) as? ImageDetailCollectionCell else { return }
        cell.updateNote(isNeedtoSave: isNoteNeedToSave)
        cell.noteTextField.resignFirstResponder()
        navigationController?.setNavigationBarHidden(viewModel.isInfoSelected, animated: true)
    }
    
    // MARK: - Collection View Layout
    
    // Configure the collection view layout for displaying items in full size.
    func fullLayout(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        return NSCollectionLayoutSection(group: group)
    }
    
    // MARK: - View Model Binding
    
    // Set up the view model binding by defining actions to handle updates.
    private func addViewModelBinding() {
        viewModel.delegate = { [weak self] action in
            switch action {
            case .refresh:
                DispatchQueue.main.async {
                    self?.collectionView.reloadData()
                    self?.bottomSlidingBar.reloadData(viewModel: self?.viewModel)
                }
            case .scrollTo(indexPath: let indexPath):
                self?.viewModel.selectedIndexPath = indexPath
                self?.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                self?.navigationItem.title = self?.viewModel.fetchNavigationDate()
            }
        }
    }
    
    // MARK: - Tab Bar Delegate
    
    // Handle tab bar item selection.
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let title = item.title, let option = TabOption(rawValue: title) else { return }
        switch option {
        case .share:
            showShareScreen()
        case .info:
            viewModel.isInfoSelected = !viewModel.isInfoSelected
            viewModel.updateInfoSelected()
            bottomSlidingBar.isHidden = viewModel.isInfoSelected
            navigationController?.setNavigationBarHidden(viewModel.isInfoSelected, animated: true)
            showInfoForSelected()
        case .delete:
            viewModel.deletePhotoInGallery()
        }
    }
    
    // MARK: - Scroll View Delegate
    
    // Handle the end of scroll to update the selected item and navigation title.
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        if let visibleIndexPath = collectionView.indexPathForItem(at: visiblePoint) {
            self.viewModel.selectedIndexPath = visibleIndexPath
            self.bottomSlidingBar.updateScrolledItem(at: visibleIndexPath)
            self.navigationItem.title = self.viewModel.fetchNavigationDate()
        }
    }
    // MARK: - Helper Methods
    
    // Show or hide the detailed information view for the selected item.
    func showInfoForSelected() {
        guard let cell = collectionView.cellForItem(at: viewModel.selectedIndexPath) as? ImageDetailCollectionCell else {
            return
        }
        cell.updateInfoBaseViewStatus(isHidden: !viewModel.isInfoSelected)
    }
    
    // Show the share screen for the selected image.
    private func showShareScreen() {
        guard let cell = collectionView.cellForItem(at: viewModel.selectedIndexPath) as? ImageDetailCollectionCell,
              let image = cell.mainImageView.image else {
            return
        }
        let shareController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(shareController, animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    // Return the number of items in the collection view.
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.cellModels.count
    }
    
    // Provide cells for the collection view.
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ImageDetailCollectionCell.reuseIdentifier,
            for: indexPath) as? ImageDetailCollectionCell else {
            fatalError("Unable to dequeue PhotoCollectionViewCell")
        }
        let model = viewModel.cellModels[indexPath.item]
        cell.delegate = self
        cell.configureUI(with: model)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        viewModel.cellModels[indexPath.item].fetchImage()
    }
}

// MARK: - ImageDetailCollectionCellDelegate

extension ViewController: ImageDetailCollectionCellDelegate {
    func showDescription(text: String) {
        let view = ExtendedDescriptionView(text: text)

        let controller = BasePopupViewController(view: view, height: view.height(), isMaxHeightNeed: true)
        controller.modalPresentationStyle = .overCurrentContext
        present(controller, animated: false)
    }
    
    func handleImageTap() {
        let newState = !mBottomTabBar.isHidden
        mBottomTabBar.isHidden = viewModel.isInfoSelected ? false : newState
        navigationController?.setNavigationBarHidden(viewModel.isInfoSelected ? true : newState, animated: true)
        bottomSlidingBar.isHidden = viewModel.isInfoSelected ? true : newState
        view.backgroundColor = newState ? .black : .white
    }
    
    // Handle the edit button selection for a cell.
    func editSelected(for viewModel: ImageDetailCollectionCellViewModel) {
        let view = EditTagsPopupView.instanceFromNib(selectedTags: viewModel.tags, allOtherTags: viewModel.allOtherTags)
        view.configureUI()
        view.onDoneAction { [weak self] view in
            self?.viewModel.updateTagsFor(newTags: view.viewModel.newSelectedTags())
            view.delegate?.closePopup()
        }
        let controller = BasePopupViewController(view: view, height: collectionView.frame.height / 2, isMaxHeightNeed: true)
        controller.modalPresentationStyle = .overCurrentContext
        present(controller, animated: false)
    }
}
