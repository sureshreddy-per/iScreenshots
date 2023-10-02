
import UIKit
import Photos

// MARK: - UIImageView Extension

// This extension provides convenience methods for loading images from PHAsset objects.
extension UIImageView {
    
    // Fetch and set an image from a PHAsset object with options.
    func fetchImageAsset(_ asset: PHAsset?, targetSize size: CGSize, contentMode: PHImageContentMode = .aspectFill, options: PHImageRequestOptions? = nil, completionHandler: ((Bool) -> Void)?) {
        // 1. Check if the PHAsset is valid.
        guard let asset = asset else {
            completionHandler?(false) // Asset is nil, return failure.
            return
        }
        
        // 2. Define a result handler to set the image when it's fetched.
        let resultHandler: (UIImage?, [AnyHashable: Any]?) -> Void = { image, info in
            self.image = image // Set the fetched image to the UIImageView.
            completionHandler?(true) // Notify completion with success.
        }
        
        // 3. Request the image from the PHAsset using PHImageManager.
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: size,
            contentMode: contentMode,
            options: options,
            resultHandler: resultHandler)
    }
}
