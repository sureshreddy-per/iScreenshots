//
//  ViewModel.swift
//  iScreenshots
//
//  Created by Suresh Reddy on 02/10/23.
//

import Foundation
import Photos
import UIKit
// MARK: - View Model Class

// This class represents the ViewModel for the main view controller.
final class ViewModel: NSObject, PHPhotoLibraryChangeObserver {
    
    // MARK: - Properties
    
    // A closure to notify the delegate of ViewModel-related events.
    var delegate: ((ViewModelDelegate) -> Void)?
        
    // An array containing all photos as PHAsset objects for easy access.
    var allPhotos: [PHAsset] = []
    
    // The currently selected index path in the collection view.
    var selectedIndexPath: IndexPath = IndexPath(row: 0, section: 0)
    
    // A flag indicating whether the "Info" option is selected.
    var isInfoSelected: Bool = false
    
    // An array of cell view models for populating the collection view.
    var cellModels = [ImageDetailCollectionCellViewModel]()
    
    var selectedImage: UIImage?
    
    lazy var cachingImageManager: PHCachingImageManager = {
        return PHCachingImageManager()
    }()

    // MARK: - Initialization
    
    override init() {
        super.init()
        // Check and request photo library permission if necessary.
        getPermissionIfNecessary { granted in
            guard granted else { return }
            DispatchQueue.global(qos: .userInitiated).async {
                self.fetchAssets()
            }
        }
        // Register as an observer for photo library changes.
        PHPhotoLibrary.shared().register(self)
    }
    
    deinit {
        // Unregister as an observer for photo library changes to prevent memory leaks.
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    // MARK: - Fetching Data
    
    // Fetch the formatted date for the currently selected photo.
    func fetchNavigationDate() -> String {
        if allPhotos.count > 0,
           selectedIndexPath.row < allPhotos.count,
           let lastModifiedDate = allPhotos[selectedIndexPath.row].creationDate {
            return formatDate(lastModifiedDate)
        } else {
            return "iScreenshots" // Default text when no photos are available.
        }
    }
    
    // Format a date as a string.
    private func formatDate(_ date: Date) -> String {
        let dayTimePeriodFormatter = DateFormatter()
        dayTimePeriodFormatter.locale = Locale(identifier: "en_IN")
        dayTimePeriodFormatter.dateFormat = "dd MMM YYYY hh:mm a"
        return dayTimePeriodFormatter.string(from: date)
    }
    
    // Request photo library permission if not already granted.
    func getPermissionIfNecessary(completionHandler: @escaping (Bool) -> Void) {
        guard PHPhotoLibrary.authorizationStatus() != .authorized else {
            completionHandler(true) // Permission already granted.
            return
        }
        PHPhotoLibrary.requestAuthorization { status in
            completionHandler(status == .authorized ? true : false) // Return true if permission is granted.
        }
    }
    
    // Fetch all photos from the photo library and populate the cell models.
    func fetchAssets() {
        
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.image.rawValue)
        
        allPhotosOptions.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
        let allPhotosResults = PHAsset.fetchAssets(with: allPhotosOptions)
        allPhotosResults.enumerateObjects { [weak self] asset, _, _ in
            self?.cellModels.append(ImageDetailCollectionCellViewModel(image: asset, isInfoSelected: self?.isInfoSelected ?? false, tags: []))
            self?.allPhotos.append(asset)
        }
        delegate?(.refresh) // Notify the delegate to refresh the view.
                
//        cachingImageManager.startCachingImages(for: allPhotos, targetSize: CGSize(width: 1000, height: 2000), contentMode: .aspectFill, options: nil)

    }
    
    // MARK: - Photo Library Change Observer
    
    // Handle changes in the photo library, such as additions or deletions of photos.
    func photoLibraryDidChange(_ changeInstance: PHChange) {
//            if let changeDetails = changeInstance.changeDetails(for: allPhotos) {
//                allPhotos = changeDetails.fetchResultAfterChanges
//            }
            self.delegate?(.refresh) // Notify the delegate to refresh the view.
    }
    
    // MARK: - Update Methods
    
    // Update the "isInfoNeedToShow" property for all cell models.
    func updateInfoSelected() {
        cellModels.forEach { $0.isInfoNeedToShow = self.isInfoSelected }
    }
    
    // Delete a photo from the cell models and the allPhotosArray.
    func delete(photo: PHAsset) {
        cellModels = cellModels.filter { photo != $0.imageData }
        allPhotos = allPhotos.filter { photo != $0 }
        if selectedIndexPath.row < cellModels.count {
            selectedIndexPath = IndexPath(row: selectedIndexPath.row, section: 0)
        } else {
            selectedIndexPath = IndexPath(row: selectedIndexPath.row - 1, section: 0)
        }
        self.delegate?(.refresh) // Notify the delegate to refresh the view.
    }
    
    func deletePhotoInGallery() {
        let asset = allPhotos[selectedIndexPath.row]
        // Attempt to delete the asset
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets([asset] as NSArray)
        }, completionHandler: { [weak self] (success, error) in
            if success {
                self?.delete(photo: asset)
                debugPrint("Photo deleted successfully.")
            } else {
                
                if let error = error {
                    print("Error deleting photo: \(error.localizedDescription)")
                } else {
                    print("Failed to delete photo.")
                }
            }
        })
    }
    
    // Update the tags for the currently selected cell model.
    func updateTagsFor(newTags: [String]) {
        guard selectedIndexPath.row < cellModels.count else {
            return
        }
        cellModels[selectedIndexPath.row].updateTags(newTags)
        self.delegate?(.refresh) // Notify the delegate to refresh the view.
    }
    
    // MARK: - Image Asset Fetching
    
    func fetchImageAsset(_ index: Int, completionHandler: ((UIImage?) -> Void)?) {
        let options = PHImageRequestOptions()
        options.version = .original
        options.isSynchronous = false
        PHImageManager.default().requestImageDataAndOrientation(for: allPhotos[index], options: nil) { data, _, _, _ in
            guard let data = data, let image = UIImage(data: data) else {
                completionHandler?(nil) // Asset is nil, return failure.
                return
            }
            completionHandler?(image)
        }
    }

}
