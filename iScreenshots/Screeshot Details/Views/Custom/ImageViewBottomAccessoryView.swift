//
//  ImageViewBottomAccessoryView.swift
//  iScreenshots
//
//  Created by Suresh Reddy on 30/09/23.
//

import UIKit

final class ImageViewBottomAccessoryView: UIView {
    
    // MARK: - Outlets and Properties
    
    @IBOutlet weak var mCollectionView: UICollectionView!
    var viewModel: ViewModel?
    
    // MARK: - Initialization
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupCollectionView()
    }
    
    // MARK: - CollectionView Setup
    
    private func setupCollectionView() {
        // Register the cell using its reuse identifier.
        mCollectionView.register(UINib(nibName: BottomSlideImageCollectionCell.reuseIdentifier, bundle: nil), forCellWithReuseIdentifier: BottomSlideImageCollectionCell.reuseIdentifier)
        
        // Configure the compositional layout for horizontal scrolling.
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .horizontal
        config.contentInsetsReference = .automatic
        
        mCollectionView.collectionViewLayout = UICollectionViewCompositionalLayout(sectionProvider: { index, environment in
            return self.miniHorizontalScrollLayout(environment: environment)
        }, configuration: config)
        
        // Set the delegate and data source for the collection view.
        mCollectionView.delegate = self
        mCollectionView.dataSource = self
    }
    
    // MARK: - CollectionView Layout
    
    private func miniHorizontalScrollLayout(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                              heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = .init(top: 0, leading: 1, bottom: 0, trailing: 1)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.1),
            heightDimension: .fractionalHeight(1))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        
        section.orthogonalScrollingBehavior = .none
        return section
    }
    
    // MARK: - View Creation
    
    class func instanceFromNib() -> ImageViewBottomAccessoryView {
        return UINib(nibName: "ImageViewBottomAccessoryView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! ImageViewBottomAccessoryView
    }
    
    // MARK: - Data Reload and Scrolling
    
    func reloadData(viewModel: ViewModel?) {
        self.viewModel = viewModel
        mCollectionView.reloadData()
    }
    
    func updateScrolledItem(at indexPath: IndexPath) {
        mCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
}

// MARK: - UICollectionViewDataSource and UICollectionViewDelegateFlowLayout

extension ImageViewBottomAccessoryView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.allPhotos.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let asset = viewModel?.allPhotos[indexPath.item], let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BottomSlideImageCollectionCell.reuseIdentifier, for: indexPath) as? BottomSlideImageCollectionCell else {
            fatalError("Unable to dequeue BottomSlideImageCollectionCell")
        }

        cell.configureUI(with: BottomSlideImageCollectionCellViewModel(asset: asset))
        
        // Configure the image cell here
        if let selectedIndex = viewModel?.selectedIndexPath {
            cell.updateSelectedConstraints(isSelected: selectedIndex == indexPath)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel?.delegate?(.scrollTo(indexPath: indexPath))
        updateScrolledItem(at: indexPath)
    }
}
