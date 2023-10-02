//
//  BottomSlideImageCollectionCell.swift
//  iScreenshots
//
//  Created by Suresh Reddy on 01/10/23.
//

import UIKit

// A UICollectionViewCell subclass for displaying images with optional selection indicators.

final class BottomSlideImageCollectionCell: UICollectionViewCell {

    // Outlets for UI elements in the cell.
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var leftConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightConstraint: NSLayoutConstraint!
    
    // View model to populate and update cell data.
    var viewModel: BottomSlideImageCollectionCellViewModel?
    
    // Reuse identifier for the cell.
    static let reuseIdentifier = "BottomSlideImageCollectionCell"

    // MARK: - View Initialization

    // This method is called when the cell is loaded from a nib or storyboard.
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    // MARK: - Reuse Preparation

    // This method prepares the cell for reuse by resetting UI elements and clearing the view model.
    override func prepareForReuse() {
        super.prepareForReuse()
        mainImageView.image = UIImage()
        leftConstraint.constant = 0
        rightConstraint.constant = 0
    }
    
    // MARK: - Constraint Update

    // This method updates the constraints for left and right indicators based on the isSelected flag.
    func updateSelectedConstraints(isSelected: Bool) {
        leftConstraint.constant = isSelected ? 8 : 0
        rightConstraint.constant = isSelected ? 8 : 0
    }

    // MARK: - UI Configuration

    // This method configures the UI elements of the cell with the provided view model.
    func configureUI(with viewModel: BottomSlideImageCollectionCellViewModel) {
        self.viewModel = viewModel
        mainImageView.fetchImageAsset(viewModel.asset, targetSize: mainImageView.bounds.size, completionHandler: nil)
        updateSelectedConstraints(isSelected: false)
    }
}

