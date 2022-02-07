//
//  ScrollingTabBarUtils.swift
//  ScrollingTabBarUtils
//
//  Created by Franklin Schrans on 24/12/2015.
//  Copyright © 2015 Franklin Schrans. All rights reserved.
//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Just contributors
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import UIKit

class ScrollingTabBarControllerDelegate: NSObject, UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, animationControllerForTransitionFrom fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ScrollingTransitionAnimator(tabBarController: tabBarController, lastIndex: tabBarController.selectedIndex)
    }
}

class ScrollingTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    weak var transitionContext: UIViewControllerContextTransitioning?
    var tabBarController: UITabBarController!
    var lastIndex = 0
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }
    
    init(tabBarController: UITabBarController, lastIndex: Int) {
        self.tabBarController = tabBarController
        self.lastIndex = lastIndex
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
        
        let containerView = transitionContext.containerView
        let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)
        let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)
        
        containerView.addSubview(toViewController!.view)
        
        var viewWidth = toViewController!.view.bounds.width
        
        if tabBarController.selectedIndex < lastIndex {
            viewWidth = -viewWidth
        }
        
        toViewController!.view.transform = CGAffineTransform(translationX: viewWidth, y: 0)
        
        UIView.animate(withDuration: self.transitionDuration(using: (self.transitionContext)), delay: 0.0, usingSpringWithDamping: 1.2, initialSpringVelocity: 2.5, options: UIView.AnimationOptions.overrideInheritedOptions, animations: {
            toViewController!.view.transform = CGAffineTransform.identity
            fromViewController!.view.transform = CGAffineTransform(translationX: -viewWidth, y: 0)
        }, completion: { _ in
            self.transitionContext?.completeTransition(!self.transitionContext!.transitionWasCancelled)
            fromViewController!.view.transform = CGAffineTransform.identity
        })
    }
}

// Taken from https://stackoverflow.com/questions/23121240/ios-uilabel-autoshrink-so-word-doesnt-truncate-to-two-lines/47469960#47469960
// Used to fix an issue with the beacon label where long words wrap in the middle of the word
extension UILabel {
    // Adjusts the font size to avoid wrapping long words
    func fitToAvoidWordWrapping() {
        guard adjustsFontSizeToFitWidth else {
            return // Adjust font only if width fit is needed
        }
        guard let words = text?.components(separatedBy: " ") else {
            return // Get array of words separated by spaces
        }
        
        // Need to find the largest word and its width in points
        var largestWord: NSString = ""
        var largestWordWidth: CGFloat = 0
        
        // Iterate over the words to find the largest one
        for word in words {
            // Get the width of the word given the actual font of the label
            let wordWidth = word.size(withAttributes: [.font: font]).width
            
            // Check if this word is the largest one
            if wordWidth > largestWordWidth {
                largestWordWidth = wordWidth
                largestWord = word as NSString
            }
        }
        
        // Reduce the label's font size until it fits
        while largestWordWidth > bounds.width && font.pointSize > 1 {
            // Reduce font and update largest word's width
            font = font.withSize(font.pointSize - 1)
            largestWordWidth = largestWord.size(withAttributes: [.font: font]).width
        }
    }
}

extension Notification.Name {
    static let didReceiveNotification = Notification.Name("didReceiveNotification")
    static let didUpdateSubscription = Notification.Name("didUpdateSubscription")
    static let completedLengthyDownload = Notification.Name("completedLengthyDownload")
}
