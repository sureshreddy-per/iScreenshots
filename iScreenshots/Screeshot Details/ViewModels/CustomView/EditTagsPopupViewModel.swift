//
//  EditTagsPopupViewModel.swift
//  iScreenshots
//
//  Created by Suresh Reddy on 02/10/23.
//

import Foundation
import UIKit

// MARK: - ViewModel for EditTagsPopupView

final class EditTagsPopupViewModel {
    
    // Arrays to store selected and available tags.
    var selectedTags: [String]
    var allOtherTags: [String]
    
    // View models for selected and available tag cells.
    var selectedCellModels = [ImageTagCollectionCellViewModel]()
    var availableCellModels = [ImageTagCollectionCellViewModel]()
    
    // Width of selected and available tags collections.
    var selectedTagsWidth: CGFloat = 0
    var availableTagsWidth: CGFloat = 0
    
    // Cell inset value.
    let cellInset: CGFloat = 8
    
    // Delegate for handling updates in the view model.
    var delegate : ((ViewModelDelegate)->())?
    
    // Height of a tag cell.
    private let tagCellHeight: CGFloat = 36
    
    // Width of the available screen.
    private var availableScreenWidth: CGFloat = 0

    // Initialize the view model with selected and available tags and the screen width.
    init(selectedTags: [String], allOtherTags: [String], screenWidth: CGFloat) {
        self.selectedTags = selectedTags
        self.allOtherTags = allOtherTags
        availableScreenWidth = screenWidth
        prepareCellModels()
    }
    
    // Prepare cell models for selected and available tags.
    private func prepareCellModels(){
        selectedCellModels.removeAll()
        var totalWidth: CGFloat = cellInset
        selectedTags.forEach{
            let model = ImageTagCollectionCellViewModel(tag: $0, tagMode: .edit)
            totalWidth += (model.size().width + cellInset)
            selectedCellModels.append(model)
        }
        selectedTagsWidth = totalWidth
        
        availableCellModels.removeAll()
        var availableTagsWidth: CGFloat = cellInset
        allOtherTags.forEach{
            let model = ImageTagCollectionCellViewModel(tag: $0, tagMode: .available)
            availableTagsWidth += (model.size().width + cellInset)
            availableCellModels.append(model)
        }
        self.availableTagsWidth = availableTagsWidth
        delegate?(.refresh)
    }
    
    // Remove a tag from the selected tags and move it to available tags.
    func removeItemFromSelected(tag: String){
        selectedCellModels = selectedCellModels.filter{ tag != $0.tag }
        availableCellModels.append(ImageTagCollectionCellViewModel(tag: tag, tagMode: .available))
        delegate?(.refresh)
    }
    
    // Add a tag to the selected tags and remove it from available tags.
    func addItemToSelected(tag: String){
        availableCellModels = availableCellModels.filter{ tag != $0.tag }
        selectedCellModels.append(ImageTagCollectionCellViewModel(tag: tag, tagMode: .edit))
        delegate?(.refresh)
    }

    // Calculate the height of the selected collection view.
    func getHeightOfSelectedCollection()->CGFloat{
        selectedTagsWidth = cellInset
        selectedCellModels.forEach { selectedTagsWidth += ($0.size().width + cellInset) }
        
        let availableWidth = availableScreenWidth - (tagCellHeight + 16)

        return (ceil(selectedTagsWidth / availableWidth) * tagCellHeight) + 16
    }
    
    // Define the layout for the tag cells.
    func gridLayout(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(60),
                                          heightDimension: .absolute(tagCellHeight))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = .init(top: 2, leading: 0, bottom: 2, trailing: 0)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .absolute(tagCellHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                         subitems: [item])
        group.interItemSpacing = .fixed(cellInset)
        let section = NSCollectionLayoutSection(group: group)
        return section
    }
    
    // Get an array of newly selected tags.
    func newSelectedTags()->[String]{
        selectedCellModels.map { $0.tag }
    }
}

