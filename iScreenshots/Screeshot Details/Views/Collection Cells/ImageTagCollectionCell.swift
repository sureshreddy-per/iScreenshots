//
//  ImageTagCollectionCell.swift
//  iScreenshots
//
//  Created by Suresh Reddy on 01/10/23.
//

import UIKit

// A UICollectionViewCell subclass for displaying image tags with various modes.

final class ImageTagCollectionCell: UICollectionViewCell {

    // Outlets for UI elements in the cell.
    @IBOutlet weak var mTitle: UILabel!
    @IBOutlet weak var mBackgroundView: UIView!
    @IBOutlet weak var mRearButton: UIButton!

    // Reuse identifier for the cell.
    static let reuseIdentifier = "ImageTagCollectionCell"

    // View model to populate and update cell data.
    var viewModel: ImageTagCollectionCellViewModel?
    
    // MARK: - View Initialization

    // This method is called when the cell is loaded from a nib or storyboard.
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Set initial UI elements.
        mRearButton.setImage(UIImage(systemName: "plus"), for: .normal)
        mTitle.text = "Animal"
    }

    // MARK: - UI Configuration

    // This method configures the UI elements of the cell with the provided view model.
    func configureUI(_ viewModel: ImageTagCollectionCellViewModel) {
        self.viewModel = viewModel
        mTitle.text = viewModel.tag
        mRearButton.isHidden = false
        mBackgroundView.layer.cornerRadius = 4

        // Configure UI elements based on the tag mode.
        switch viewModel.tagMode {
        case .available:
            mRearButton.setImage(UIImage(systemName: "plus"), for: .normal)

        case .create:
            mRearButton.isHidden = true
            mBackgroundView.backgroundColor = .clear
            
        case .edit:
            mRearButton.setImage(UIImage(systemName: "xmark"), for: .normal)

        case .selected:
            mRearButton.isHidden = true
        }
    }
}
