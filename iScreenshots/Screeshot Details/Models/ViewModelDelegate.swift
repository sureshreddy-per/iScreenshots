//
//  ViewModelDelegate.swift
//  iScreenshots
//
//  Created by Suresh Reddy on 02/10/23.
//

import Foundation
// MARK: - ViewModel Delegate

// This enumeration defines delegate actions that can be triggered by the ViewModel.
enum ViewModelDelegate {
    // Action to request a data refresh, typically to update the view.
    case refresh
    
    // Action to scroll to a specific item in a collection view, identified by its index path.
    case scrollTo(indexPath: IndexPath)
}
