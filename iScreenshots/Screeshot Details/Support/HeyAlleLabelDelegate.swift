//
//  iScreenshotsLabelDelegate.swift
//  iScreenshots
//
//  Created by Suresh Reddy on 02/10/23.
//

import Foundation
/// A protocol used to handle tap events on detected text.
public protocol iScreenshotsLabelDelegate: AnyObject {

    /// Triggered when a tap occurs on a detected address.
    ///
    /// - Parameters:
    ///   - addressComponents: The components of the selected address.
    func didSelectAddress(_ addressComponents: [String: String])

    /// Triggered when a tap occurs on a detected date.
    ///
    /// - Parameters:
    ///   - date: The selected date.
    func didSelectDate(_ date: Date)

    /// Triggered when a tap occurs on a detected phone number.
    ///
    /// - Parameters:
    ///   - phoneNumber: The selected phone number.
    func didSelectPhoneNumber(_ phoneNumber: String)

    /// Triggered when a tap occurs on a detected URL.
    ///
    /// - Parameters:
    ///   - url: The selected URL.
    func didSelectURL(_ url: URL)

    /// Triggered when a tap occurs on a custom regular expression
    ///
    /// - Parameters:
    ///   - pattern: the pattern of the regular expression
    ///   - match: part that match with the regular expression
    func didSelectCustom(_ pattern: String, match: String?)

}

public extension iScreenshotsLabelDelegate {

    func didSelectAddress(_ addressComponents: [String: String]) {}

    func didSelectDate(_ date: Date) {}

    func didSelectPhoneNumber(_ phoneNumber: String) {}

    func didSelectURL(_ url: URL) {}
    
    func didSelectCustom(_ pattern: String, match: String?) {}

}
