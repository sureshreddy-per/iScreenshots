//
//  ImageTagCollectionCellViewModel.swift
//  iScreenshots
//
//  Created by Suresh Reddy on 02/10/23.
//

import Foundation
import UIKit
// MARK: - ViewModel for ImageTagCollectionCell

// A view model class for `ImageTagCollectionCell`, containing tag data and mode.

final class ImageTagCollectionCellViewModel: NSObject {

    // The tag string.
    var tag: String
    
    // The mode of the tag (Available, Create, Edit, Selected).
    var tagMode: ImageTagMode
    
    // Initialize the view model with a tag and a tag mode.
    init(tag: String, tagMode: ImageTagMode) {
        self.tag = tag
        self.tagMode = tagMode
    }
    
    // Calculate and return the size of the cell based on the tag and mode.
    func size() -> CGSize {
        let itemSize = tag.size(withAttributes: [
            NSAttributedString.Key.font : UIFont.systemFont(ofSize: 15)
        ])
        
        var buttonWidth: CGFloat = 0
        if tagMode == .available || tagMode == .edit {
            buttonWidth = 20
        }
        
        return CGSize(width: itemSize.width + buttonWidth + 16, height: 32)
    }
}
