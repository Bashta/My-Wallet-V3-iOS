//
//  Storyboardable.swift
//  Blockchain
//
//  Created by Alex McGregor on 8/14/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

import Foundation

public protocol Storyboardable: AnyObject {
    static var defaultStoryboardName: String { get }
}

public extension Storyboardable where Self: UIViewController {
    static var defaultStoryboardName: String {
        String(describing: self)
    }

    static func makeFromStoryboard() -> Self {
        let bundle = Bundle(for: self)
        let storyboard = UIStoryboard(name: defaultStoryboardName, bundle: bundle)

        guard let viewController = storyboard.instantiateInitialViewController() as? Self else {
            fatalError("Could not instantiate initial storyboard with name: \(defaultStoryboardName)")
        }

        return viewController
    }
}

extension UIViewController: Storyboardable { }
