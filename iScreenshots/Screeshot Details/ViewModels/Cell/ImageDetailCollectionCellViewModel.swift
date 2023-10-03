//
//  ImageDetailCollectionCellViewModel.swift
//  iScreenshots
//
//  Created by Suresh Reddy on 02/10/23.
//

import Photos
import UIKit
import Vision

final class ImageDetailCollectionCellViewModel {
    
    // MARK: - Properties
    
    var imageData: PHAsset
    var isInfoNeedToShow: Bool
    var tags: [String]
    var allOtherTags: [String] = []
    var imageDescription: String = "Text extraction from the image appears to be unsuccessful."
    var cellModels = [ImageTagCollectionCellViewModel]()
    var totalTagsWidth: CGFloat = 0
    let cellInset: CGFloat = 8
    var imageNote: String = ""
    let imagePredictor = ImagePredictor()
    var delegate: ((ImageDetailCollectionCellViewModelDelegate) -> Void)?
    private let totalTagsSupported: Int = 10
    private let totalSelectedTags: Int = 2
    
    // MARK: - Initialization
    
    init(image: PHAsset, isInfoSelected: Bool, tags: [String]) {
        self.imageData = image
        self.isInfoNeedToShow = isInfoSelected
        self.tags = tags
        
        // Fetch the image asset and perform OCR and image classification
        fetchImageAsset(image) { [weak self] image in
            guard let image = image else {
                self?.prepareCellModels()
                return
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                self?.performOCR(for: image)
                self?.classifyImage(image)
            }
        }
    }
    
    // MARK: - Tag Management
    
    func updateTags(_ newTags: [String]) {
        let unionOfTags = tags + allOtherTags + newTags
        self.tags = newTags
        
        allOtherTags = Array(Set(unionOfTags).subtracting(Set(newTags)))
        prepareCellModels()
    }
    
    func prepareCellModels() {
        cellModels.removeAll()
        var totalWidth: CGFloat = cellInset
        tags.forEach {
            let model = ImageTagCollectionCellViewModel(tag: $0, tagMode: .selected)
            totalWidth += (model.size().width + cellInset)
            cellModels.append(model)
        }
        totalTagsWidth = totalWidth
        delegate?(.refresh)
    }
    
    // MARK: - Image Classification
    
    func classifyImage(_ image: UIImage) {
        do {
            try self.imagePredictor.makePredictions(for: image, completionHandler: imagePredictionHandler)
        } catch {
            prepareCellModels()
            print("Vision was unable to make a prediction...\n\n\(error.localizedDescription)")
        }
    }
    
    private func imagePredictionHandler(_ predictions: [ImagePredictor.Prediction]?) {
        guard let predictions = predictions else {
            return
        }
        
        allOtherTags = predictions.prefix(totalTagsSupported).map { $0.classification }
        
        allOtherTags = allOtherTags.map {
            guard let firstWord = $0.split(separator: ",").first, !firstWord.isEmpty else {
                return $0
            }
            return String(firstWord)
        }
        let selectedTags = Array(allOtherTags.prefix(totalSelectedTags))
        allOtherTags = Array(allOtherTags.dropFirst(totalSelectedTags))
        updateTags(selectedTags)
    }
    
    // MARK: - Image Asset Fetching and OCR
    
    func fetchImageAsset(_ asset: PHAsset, completionHandler: ((UIImage?) -> Void)?) {
        let options = PHImageRequestOptions()
        options.version = .original
        options.isSynchronous = true
        PHImageManager.default().requestImageDataAndOrientation(for: asset, options: nil) { data, _, _, _ in
            guard let data = data, let image = UIImage(data: data) else {
                completionHandler?(nil) // Asset is nil, return failure.
                return
            }
            completionHandler?(image)
        }
    }
    
    func performOCR(for image: UIImage) {
        // Convert UIImage to CIImage
        guard let ciImage = CIImage(image: image) else {
            // Handle the case where the conversion fails
            return
        }
        
        // Create a request for text recognition
        let textRecognitionRequest = VNRecognizeTextRequest { [weak self] request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            var recognizedText = ""
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { continue }
                recognizedText += topCandidate.string + " "
            }
            
            // Update the description field with the recognized text
            guard !recognizedText.isEmpty else {
                return
            }
            self?.imageDescription = recognizedText
            self?.delegate?(.updateDescription)
        }
        
        // Perform text recognition
        let textRecognitionRequestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        do {
            try textRecognitionRequestHandler.perform([textRecognitionRequest])
        } catch {
            // Handle the error
            print("Error performing text recognition: \(error.localizedDescription)")
        }
    }
}
