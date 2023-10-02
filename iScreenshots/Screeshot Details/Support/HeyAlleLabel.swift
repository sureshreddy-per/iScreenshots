//
//  iScreenshotsLabel.swift
//  iScreenshots
//
//  Created by Suresh Reddy on 02/10/23.
//

import Foundation
import UIKit
open class iScreenshotsLabel: UILabel {

    // MARK: - Private Properties

    private lazy var layoutManager: NSLayoutManager = {
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(self.textContainer)
        return layoutManager
    }()

    private lazy var textContainer: NSTextContainer = {
        let textContainer = NSTextContainer()
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = self.numberOfLines
        textContainer.lineBreakMode = self.lineBreakMode
        textContainer.size = self.bounds.size
        return textContainer
    }()

    private lazy var textStorage: NSTextStorage = {
        let textStorage = NSTextStorage()
        textStorage.addLayoutManager(self.layoutManager)
        return textStorage
    }()

    internal lazy var rangesForDetectors: [DetectorType: [(NSRange, MessageTextCheckingType)]] = [:]
    
    private var isConfiguring: Bool = false

    // MARK: - Public Properties

    open weak var delegate: iScreenshotsLabelDelegate?

    open var enabledDetectors: [DetectorType] = [] {
        didSet {
            addGesture()
            setTextStorage(attributedText, shouldParse: true)
        }
    }

    open override var attributedText: NSAttributedString? {
        didSet {
            setTextStorage(attributedText, shouldParse: true)
        }
    }

    open override var text: String? {
        didSet {
            setTextStorage(attributedText, shouldParse: true)
        }
    }

    open override var font: UIFont! {
        didSet {
            setTextStorage(attributedText, shouldParse: false)
        }
    }
    
    private func addGesture(){
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        isUserInteractionEnabled = true
        addGestureRecognizer(tap)
    }
    
    @objc func handleTapGesture(_ gesture: UIGestureRecognizer) {
        guard gesture.state == .ended else { return }
        
        let touchLocation = gesture.location(in: self)
        if point(inside: self.convert(touchLocation, to: self), with: nil), handleGesture(self.convert(touchLocation, to: self)) {
        }
    }

    open override var textColor: UIColor! {
        didSet {
            setTextStorage(attributedText, shouldParse: false)
        }
    }

    open override var lineBreakMode: NSLineBreakMode {
        didSet {
            textContainer.lineBreakMode = lineBreakMode
            if !isConfiguring { setNeedsDisplay() }
        }
    }

    open override var numberOfLines: Int {
        didSet {
            textContainer.maximumNumberOfLines = numberOfLines
            if !isConfiguring { setNeedsDisplay() }
        }
    }

    open override var textAlignment: NSTextAlignment {
        didSet {
            setTextStorage(attributedText, shouldParse: false)
        }
    }

    open var textInsets: UIEdgeInsets = .zero {
        didSet {
            if !isConfiguring { setNeedsDisplay() }
        }
    }

    open override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.width += textInsets.horizontal
        size.height += textInsets.vertical
        return size
    }
    
    internal var messageLabelFont: UIFont?

    private var attributesNeedUpdate = false

    public static var defaultAttributes: [NSAttributedString.Key: Any] = {
        return [
            NSAttributedString.Key.foregroundColor: UIColor.link
        ]
    }()

    open internal(set) var addressAttributes: [NSAttributedString.Key: Any] = defaultAttributes

    open internal(set) var dateAttributes: [NSAttributedString.Key: Any] = defaultAttributes

    open internal(set) var phoneNumberAttributes: [NSAttributedString.Key: Any] = defaultAttributes

    open internal(set) var urlAttributes: [NSAttributedString.Key: Any] = defaultAttributes
    
    open internal(set) var transitInformationAttributes: [NSAttributedString.Key: Any] = defaultAttributes
    
    open internal(set) var hashtagAttributes: [NSAttributedString.Key: Any] = defaultAttributes
    
    open internal(set) var mentionAttributes: [NSAttributedString.Key: Any] = defaultAttributes
    
    open internal(set) var stockAttributes: [NSAttributedString.Key: Any] = defaultAttributes

    open internal(set) var customAttributes: [NSRegularExpression: [NSAttributedString.Key: Any]] = [:]

    public func setAttributes(_ attributes: [NSAttributedString.Key: Any], detector: DetectorType) {
        switch detector {
        case .phoneNumber:
            phoneNumberAttributes = attributes
        case .address:
            addressAttributes = attributes
        case .date:
            dateAttributes = attributes
        case .url:
            urlAttributes = attributes
        case .custom(let regex):
            customAttributes[regex] = attributes
        }
        if isConfiguring {
            attributesNeedUpdate = true
        } else {
            updateAttributes(for: [detector])
        }
    }

    // MARK: - Initializers

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    // MARK: - Open Methods

    open override func drawText(in rect: CGRect) {

        let insetRect = rect.inset(by: textInsets)
        textContainer.size = CGSize(width: insetRect.width, height: rect.height)

        let origin = insetRect.origin
        let range = layoutManager.glyphRange(for: textContainer)

        layoutManager.drawBackground(forGlyphRange: range, at: origin)
        layoutManager.drawGlyphs(forGlyphRange: range, at: origin)
    }

    // MARK: - Public Methods
    
    public func configure(block: () -> Void) {
        isConfiguring = true
        block()
        if attributesNeedUpdate {
            updateAttributes(for: enabledDetectors)
        }
        attributesNeedUpdate = false
        isConfiguring = false
        setNeedsDisplay()
    }

    // MARK: - Private Methods

    private func setTextStorage(_ newText: NSAttributedString?, shouldParse: Bool) {

        guard let newText = newText, newText.length > 0 else {
            textStorage.setAttributedString(NSAttributedString())
            setNeedsDisplay()
            return
        }
        
        let style = paragraphStyle(for: newText)
        let range = NSRange(location: 0, length: newText.length)
        
        let mutableText = NSMutableAttributedString(attributedString: newText)
        mutableText.addAttribute(.paragraphStyle, value: style, range: range)
        
        if shouldParse {
            rangesForDetectors.removeAll()
            let results = parse(text: mutableText)
            setRangesForDetectors(in: results)
        }
        
        for (detector, rangeTuples) in rangesForDetectors {
            if enabledDetectors.contains(detector) {
                let attributes = detectorAttributes(for: detector)
                rangeTuples.forEach { (range, _) in
                    mutableText.addAttributes(attributes, range: range)
                }
            }
        }

        let modifiedText = NSAttributedString(attributedString: mutableText)
        textStorage.setAttributedString(modifiedText)

        if !isConfiguring { setNeedsDisplay() }

    }
    
    private func paragraphStyle(for text: NSAttributedString) -> NSParagraphStyle {
        guard text.length > 0 else { return NSParagraphStyle() }
        
        var range = NSRange(location: 0, length: text.length)
        let existingStyle = text.attribute(.paragraphStyle, at: 0, effectiveRange: &range) as? NSMutableParagraphStyle
        let style = existingStyle ?? NSMutableParagraphStyle()
        
        style.lineBreakMode = lineBreakMode
        style.alignment = textAlignment
        
        return style
    }

    private func updateAttributes(for detectors: [DetectorType]) {

        guard let attributedText = attributedText, attributedText.length > 0 else { return }
        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedText)

        for detector in detectors {
            guard let rangeTuples = rangesForDetectors[detector] else { continue }

            for (range, _)  in rangeTuples {
                // This will enable us to attribute it with our own styles, since `UILabel` does not provide link attribute overrides like `UITextView` does
                if detector.textCheckingType == .link {
                    mutableAttributedString.removeAttribute(NSAttributedString.Key.link, range: range)
                }

                let attributes = detectorAttributes(for: detector)
                mutableAttributedString.addAttributes(attributes, range: range)
            }

            let updatedString = NSAttributedString(attributedString: mutableAttributedString)
            textStorage.setAttributedString(updatedString)
        }
    }

    private func detectorAttributes(for detectorType: DetectorType) -> [NSAttributedString.Key: Any] {

        switch detectorType {
        case .address:
            return addressAttributes
        case .date:
            return dateAttributes
        case .phoneNumber:
            return phoneNumberAttributes
        case .url:
            return urlAttributes
        case .custom(let regex):
            return customAttributes[regex] ?? iScreenshotsLabel.defaultAttributes
        }

    }

    private func detectorAttributes(for checkingResultType: NSTextCheckingResult.CheckingType) -> [NSAttributedString.Key: Any] {
        switch checkingResultType {
        case .address:
            return addressAttributes
        case .date:
            return dateAttributes
        case .phoneNumber:
            return phoneNumberAttributes
        case .link:
            return urlAttributes
        case .transitInformation:
            return transitInformationAttributes
        default:
            fatalError("unrecognizedCheckingResult")
        }
    }
    
    private func setupView() {
        numberOfLines = 0
        lineBreakMode = .byWordWrapping
    }

    // MARK: - Parsing Text

    private func parse(text: NSAttributedString) -> [NSTextCheckingResult] {
        guard enabledDetectors.isEmpty == false else { return [] }
        let range = NSRange(location: 0, length: text.length)
        var matches : [NSTextCheckingResult] = [NSTextCheckingResult]()

        // Get matches of all .custom DetectorType and add it to matches array
        let regexs = enabledDetectors
            .filter { $0.isCustom }
            .map { parseForMatches(with: $0, in: text, for: range) }
            .joined()
        matches.append(contentsOf: regexs)

        // Get all Checking Types of detectors, except for .custom because they contain their own regex
        let detectorCheckingTypes = enabledDetectors
            .filter { !$0.isCustom }
            .reduce(0) { $0 | $1.textCheckingType.rawValue }
        if detectorCheckingTypes > 0, let detector = try? NSDataDetector(types: detectorCheckingTypes) {
            let detectorMatches = detector.matches(in: text.string, options: [], range: range)
            matches.append(contentsOf: detectorMatches)
        }

        guard enabledDetectors.contains(.url) else {
            return matches
        }

        // Enumerate NSAttributedString NSLinks and append ranges
        var results: [NSTextCheckingResult] = matches

        text.enumerateAttribute(NSAttributedString.Key.link, in: range, options: []) { value, range, _ in
            guard let url = value as? URL else { return }
            let result = NSTextCheckingResult.linkCheckingResult(range: range, url: url)
            results.append(result)
        }

        return results
    }

    private func parseForMatches(with detector: DetectorType, in text: NSAttributedString, for range: NSRange) -> [NSTextCheckingResult] {
        switch detector {
        case .custom(let regex):
            return regex.matches(in: text.string, options: [], range: range)
        default:
            fatalError("You must pass a .custom DetectorType")
        }
    }

    private func setRangesForDetectors(in checkingResults: [NSTextCheckingResult]) {

        guard checkingResults.isEmpty == false else { return }
        
        for result in checkingResults {

            switch result.resultType {
            case .address:
                var ranges = rangesForDetectors[.address] ?? []
                let tuple: (NSRange, MessageTextCheckingType) = (result.range, .addressComponents(result.addressComponents))
                ranges.append(tuple)
                rangesForDetectors.updateValue(ranges, forKey: .address)
            case .date:
                var ranges = rangesForDetectors[.date] ?? []
                let tuple: (NSRange, MessageTextCheckingType) = (result.range, .date(result.date))
                ranges.append(tuple)
                rangesForDetectors.updateValue(ranges, forKey: .date)
            case .phoneNumber:
                var ranges = rangesForDetectors[.phoneNumber] ?? []
                let tuple: (NSRange, MessageTextCheckingType) = (result.range, .phoneNumber(result.phoneNumber))
                ranges.append(tuple)
                rangesForDetectors.updateValue(ranges, forKey: .phoneNumber)
            case .link:
                var ranges = rangesForDetectors[.url] ?? []
                let tuple: (NSRange, MessageTextCheckingType) = (result.range, .link(result.url))
                ranges.append(tuple)
                rangesForDetectors.updateValue(ranges, forKey: .url)
            case .regularExpression:
                guard let text = text, let regex = result.regularExpression, let range = Range(result.range, in: text) else { return }
                let detector = DetectorType.custom(regex)
                var ranges = rangesForDetectors[detector] ?? []
                let tuple: (NSRange, MessageTextCheckingType) = (result.range, .custom(pattern: regex.pattern, match: String(text[range])))
                ranges.append(tuple)
                rangesForDetectors.updateValue(ranges, forKey: detector)
            default:
                fatalError("Received an unrecognized NSTextCheckingResult.CheckingType")
            }

        }

    }

    // MARK: - Gesture Handling

    private func stringIndex(at location: CGPoint) -> Int? {
        guard textStorage.length > 0 else { return nil }

        var location = location

        location.x -= textInsets.left
        location.y -= textInsets.top

        let index = layoutManager.glyphIndex(for: location, in: textContainer)

        let lineRect = layoutManager.lineFragmentUsedRect(forGlyphAt: index, effectiveRange: nil)

        var characterIndex: Int?

        if lineRect.contains(location) {
            characterIndex = layoutManager.characterIndexForGlyph(at: index)
        }

        return characterIndex ?? index
    }

    open func handleGesture(_ touchLocation: CGPoint) -> Bool {

        guard let index = stringIndex(at: touchLocation) else { return false }
              
        for (detectorType, ranges) in rangesForDetectors {
            for (range, value) in ranges {
                if range.contains(index) {
                    handleGesture(for: detectorType, value: value)
                    return true
                }
            }
        }
        return false
    }

    // swiftlint:disable cyclomatic_complexity
    private func handleGesture(for detectorType: DetectorType, value: MessageTextCheckingType) {
        
        switch value {
        case let .addressComponents(addressComponents):
            var transformedAddressComponents = [String: String]()
            guard let addressComponents = addressComponents else { return }
            addressComponents.forEach { (key, value) in
                transformedAddressComponents[key.rawValue] = value
            }
            handleAddress(transformedAddressComponents)
        case let .phoneNumber(phoneNumber):
            guard let phoneNumber = phoneNumber else { return }
            handlePhoneNumber(phoneNumber)
        case let .date(date):
            guard let date = date else { return }
            handleDate(date)
        case let .link(url):
            guard let url = url else { return }
            handleURL(url)
        case let .custom(pattern, match):
            guard let match = match else { return }
            handleCustom(pattern, match: match)
        }
    }
    // swiftlint:enable cyclomatic_complexity
    
    private func handleAddress(_ addressComponents: [String: String]) {
        delegate?.didSelectAddress(addressComponents)
    }
    
    private func handleDate(_ date: Date) {
        delegate?.didSelectDate(date)
    }
    
    private func handleURL(_ url: URL) {
        delegate?.didSelectURL(url)
    }
    
    private func handlePhoneNumber(_ phoneNumber: String) {
        delegate?.didSelectPhoneNumber(phoneNumber)
    }
    
    private func handleCustom(_ pattern: String, match: String) {
        delegate?.didSelectCustom(pattern, match: match)
    }

    func blur(_ blurRadius: Double = 2.5) {
        let blurredImage = getBlurryImage(blurRadius)
        let blurredImageView = UIImageView(image: blurredImage)
        blurredImageView.translatesAutoresizingMaskIntoConstraints = false
        blurredImageView.tag = 100
        blurredImageView.contentMode = .center
        blurredImageView.backgroundColor = .white
        addSubview(blurredImageView)
        NSLayoutConstraint.activate([
            blurredImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            blurredImageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    func unblur() {
        subviews.forEach { subview in
            if subview.tag == 100 {
                subview.removeFromSuperview()
            }
        }
    }

    private func getBlurryImage(_ blurRadius: Double = 2.5) -> UIImage? {
        UIGraphicsBeginImageContext(bounds.size)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        guard let image = UIGraphicsGetImageFromCurrentImageContext(),
            let blurFilter = CIFilter(name: "CIGaussianBlur") else {
            UIGraphicsEndImageContext()
            return nil
        }
        UIGraphicsEndImageContext()

        blurFilter.setDefaults()

        blurFilter.setValue(CIImage(image: image), forKey: kCIInputImageKey)
        blurFilter.setValue(blurRadius, forKey: kCIInputRadiusKey)

        var convertedImage: UIImage?
        let context = CIContext(options: nil)
        if let blurOutputImage = blurFilter.outputImage,
            let cgImage = context.createCGImage(blurOutputImage, from: blurOutputImage.extent) {
            convertedImage = UIImage(cgImage: cgImage)
        }

        return convertedImage
    }

}

internal enum MessageTextCheckingType {
    case addressComponents([NSTextCheckingKey: String]?)
    case date(Date?)
    case phoneNumber(String?)
    case link(URL?)
    case custom(pattern: String, match: String?)
}
extension String {
    func matches(_ regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
    }
}
public enum DetectorType: Hashable {

    case address
    case date
    case phoneNumber
    case url
    case custom(NSRegularExpression)

    // swiftlint:enable force_try

    internal var textCheckingType: NSTextCheckingResult.CheckingType {
        switch self {
        case .address: return .address
        case .date: return .date
        case .phoneNumber: return .phoneNumber
        case .url: return .link
        case .custom: return .regularExpression
        }
    }

    /// Simply check if the detector type is a .custom
    public var isCustom: Bool {
        switch self {
        case .custom: return true
        default: return false
        }
    }

    ///The hashValue of the `DetectorType` so we can conform to `Hashable` and be sorted.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(toInt())
    }

    /// Return an 'Int' value for each `DetectorType` type so `DetectorType` can conform to `Hashable`
    private func toInt() -> Int {
        switch self {
        case .address: return 0
        case .date: return 1
        case .phoneNumber: return 2
        case .url: return 3
        case .custom(let regex): return regex.hashValue
        }
    }

}
internal extension UIEdgeInsets {

    var vertical: CGFloat {
        return top + bottom
    }

    var horizontal: CGFloat {
        return left + right
    }

}
