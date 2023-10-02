//
//  BottomSlideImageCollectionCellViewModel.swift
//  iScreenshots
//
//  Created by Suresh Reddy on 02/10/23.
//

import Foundation
import Photos
// MARK: - ViewModel for BottomSlideImageCollectionCell

// A view model class for `BottomSlideImageCollectionCell`, containing image data and selection status.

final class BottomSlideImageCollectionCellViewModel: NSObject {

    // The asset representing the image.
    let asset: PHAsset
    
    // A flag indicating whether the image is selected.
    var isSelected: Bool
    
    // Initialize the view model with an asset and an optional isSelected flag.
    init(asset: PHAsset, isSelected: Bool = false) {
        self.asset = asset
        self.isSelected = isSelected
    }
}
