//
//  BasePopupViewController.swift
//  iScreenshots
//
//  Created by Suresh Reddy on 02/10/23.
//

import UIKit
// View controller for displaying a base popup.
final class BasePopupViewController: UIViewController {
    
    // Constants
    var defaultHeight: CGFloat = 300
    var dismissibleHeight: CGFloat = 200
    var maximumContainerHeight: CGFloat = UIScreen.main.bounds.height - 64
    
    // Current new height (initial is default height)
    var currentContainerHeight: CGFloat = 300
    
    // Content view within the popup.
    let contentView: BottomBasePopupView
    
    // Dynamic container constraints.
    var containerViewHeightConstraint: NSLayoutConstraint?
    var containerViewBottomConstraint: NSLayoutConstraint?
    
    // Maximum dimmed alpha value.
    let maxDimmedAlpha: CGFloat = 0.6
    
    // Dimmed view behind the popup.
    lazy var dimmedView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.alpha = maxDimmedAlpha
        return view
    }()
    
    // Container view to hold the content view.
    lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.addTopCurvedShadow()
        view.clipsToBounds = true
        return view
    }()
    
    // Initialize the popup view controller with a content view and optional parameters.
    init(view: BottomBasePopupView, height: CGFloat = 300, isMaxHeightNeed: Bool = false) {
        contentView = view
        defaultHeight = height
        dismissibleHeight = height - 60
        if !isMaxHeightNeed {
            maximumContainerHeight = height
        }
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overCurrentContext
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        contentView.delegate = self
        setupConstraints()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleClosePopupActionNotification))
        dimmedView.addGestureRecognizer(tapGesture)
        setupPanGesture()
    }
    
    // Handle tap gesture on the dimmed view to close the popup.
    @objc func handleClosePopupActionNotification() {
        contentView.closeSelectedFromController()
        animateDismissView(isCancel: false)
    }
    
    // Handle close action triggered by notification.
    @objc func handleCloseAction(notification: NSNotification) {
        if let isCancel = notification.userInfo?["isCancel"] as? Bool {
            animateDismissView(isCancel: isCancel)
        } else {
            animateDismissView(isCancel: false)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateShowDimmedView()
        animatePresentContainer()
    }
    
    // Set up the main view.
    private func setupView() {
        view.backgroundColor = .clear
    }
    
    // Set up constraints for dimmed view, container view, and content view.
    private func setupConstraints() {
        view.addSubview(dimmedView)
        view.addSubview(containerView)
        containerView.addSubview(contentView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        dimmedView.fillSuperview()
        contentView.fillSuperview()
        NSLayoutConstraint.activate([
            dimmedView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmedView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimmedView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmedView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
        containerViewHeightConstraint = containerView.heightAnchor.constraint(equalToConstant: defaultHeight)
        containerViewBottomConstraint = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: defaultHeight)
        
        containerViewHeightConstraint?.isActive = true
        containerViewBottomConstraint?.isActive = true
    }
    
    // Animate the presentation of the container view.
    func animatePresentContainer() {
        UIView.animate(withDuration: 0.3) {
            self.containerViewBottomConstraint?.constant = 0
            self.view.layoutIfNeeded()
        }
    }
    
    // Animate the dimmed view appearance.
    func animateShowDimmedView() {
        dimmedView.alpha = 0
        UIView.animate(withDuration: 0.4) {
            self.dimmedView.alpha = self.maxDimmedAlpha
        }
    }
    
    // Animate the dismissal of the popup view.
    func animateDismissView(isCancel: Bool) {
        dimmedView.alpha = maxDimmedAlpha
        UIView.animate(withDuration: 0.4) {
            self.dimmedView.alpha = 0
        } completion: { _ in
            self.dismiss(animated: false)
        }
        
        UIView.animate(withDuration: 0.3) {
            self.containerViewBottomConstraint?.constant = self.defaultHeight
            self.view.layoutIfNeeded()
        }
    }
    
    // Set up pan gesture for handling user interactions.
    func setupPanGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture(gesture:)))
        panGesture.delaysTouchesBegan = false
        panGesture.delaysTouchesEnded = false
        view.addGestureRecognizer(panGesture)
    }
    
    // Handle pan gesture for dragging the popup view.
    @objc func handlePanGesture(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let isDraggingDown = translation.y > 0
        let newHeight = currentContainerHeight - translation.y
        
        switch gesture.state {
        case .changed:
            if newHeight < maximumContainerHeight {
                containerViewHeightConstraint?.constant = newHeight
                view.layoutIfNeeded()
            }
        case .ended:
            if newHeight < dismissibleHeight {
                animateDismissView(isCancel: false)
            }
            else if newHeight < defaultHeight {
                animateContainerHeight(defaultHeight)
            }
            else if newHeight < maximumContainerHeight && isDraggingDown {
                animateContainerHeight(defaultHeight)
            }
            else if newHeight > defaultHeight && !isDraggingDown {
                animateContainerHeight(maximumContainerHeight)
            }
        default:
            break
        }
    }
    
    // Animate the container view height change.
    func animateContainerHeight(_ height: CGFloat) {
        UIView.animate(withDuration: 0.4) {
            self.containerViewHeightConstraint?.constant = height
            self.view.layoutIfNeeded()
        }
        currentContainerHeight = height
    }
}

// Extend BasePopupViewController to conform to BottomBasePopupViewDelegate.
extension BasePopupViewController: BottomBasePopupViewDelegate {
    
    // Close the popup view when the close action is triggered.
    func closePopup() {
        animateDismissView(isCancel: true)
    }
}

