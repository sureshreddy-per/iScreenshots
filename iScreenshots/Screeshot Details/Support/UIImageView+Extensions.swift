
import UIKit
import Photos

// MARK: - UIImageView Extension

// This extension provides convenience methods for loading images from PHAsset objects.
extension UIImageView {
    
    // Fetch and set an image from a PHAsset object with options.
    func fetchImageAsset(_ asset: PHAsset?, targetSize size: CGSize, contentMode: PHImageContentMode = .aspectFill, options: PHImageRequestOptions? = nil, completionHandler: ((Bool) -> Void)?) {
        // Check if the PHAsset is valid.
        guard let asset = asset else {
            completionHandler?(false) // Asset is nil, return failure.
            return
        }
                
        let options = PHImageRequestOptions()
        options.version = .original
        options.isSynchronous = true
        PHImageManager.default().requestImageDataAndOrientation(for: asset, options: nil) { data, _, _, _ in
            guard let data = data, let image = UIImage(data: data) else {
                completionHandler?(false) // Asset is nil, return failure.
                return
            }
            self.image = image
            completionHandler?(true) // Notify completion with success.
        }
    }
}
