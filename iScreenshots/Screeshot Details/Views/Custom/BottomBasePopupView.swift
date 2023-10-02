//
//  BottomBasePopupView.swift
//  iScreenshots
//
//  Created by Suresh Reddy on 02/10/23.
//

import UIKit

// Base class for bottom-based popup views.
open class BottomBasePopupView: UIView {
    
    // Delegate to handle popup view close action.
    weak var delegate: BottomBasePopupViewDelegate?
    
    // Method to close the popup view.
    func closeSelectedFromController() { }
}
