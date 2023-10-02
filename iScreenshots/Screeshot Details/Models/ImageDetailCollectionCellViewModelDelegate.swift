//
//  ImageDetailCollectionCellViewModelDelegate.swift
//  iScreenshots
//
//  Created by Suresh Reddy on 02/10/23.
//

import Foundation
// Enum that defines the possible delegate actions for the ImageDetailCollectionCellViewModel.
enum ImageDetailCollectionCellViewModelDelegate {
    // Indicates a need to refresh the associated view.
    case refresh
    
    // Indicates a need to update the image description in the view.
    case updateDescription
}

protocol ImageDetailCollectionCellDelegate: AnyObject {
    func editSelected(for viewModel: ImageDetailCollectionCellViewModel)
    func handleImageTap()
    func showDescription(text: String)
}
