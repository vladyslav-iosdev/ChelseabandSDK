
//
//  Array.swift
//  ChelseabandSDK_Example
//
//  Created by Vladyslav Shepitko on 03.12.2020.
//  Copyright © 2020 Sonerim. All rights reserved.
//

import UIKit

extension Array where Iterator.Element == UIView {
    public func asStackView(axis: NSLayoutConstraint.Axis = .horizontal, distribution: UIStackView.Distribution = .fill, spacing: CGFloat = 0, contentHuggingPriority: UILayoutPriority? = nil, perpendicularContentHuggingPriority: UILayoutPriority? = nil, alignment: UIStackView.Alignment = .fill) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: self)
        stackView.axis = axis
        stackView.distribution = distribution
        stackView.alignment = alignment
        stackView.spacing = spacing
        if let contentHuggingPriority = contentHuggingPriority {
            switch axis {
            case .horizontal:
                stackView.setContentHuggingPriority(contentHuggingPriority, for: .horizontal)
            case .vertical:
                stackView.setContentHuggingPriority(contentHuggingPriority, for: .vertical)
            @unknown default:
                stackView.setContentHuggingPriority(contentHuggingPriority, for: .vertical)
            }
        }
        if let perpendicularContentHuggingPriority = perpendicularContentHuggingPriority {
            switch axis {
            case .horizontal:
                stackView.setContentHuggingPriority(perpendicularContentHuggingPriority, for: .vertical)
            case .vertical:
                stackView.setContentHuggingPriority(perpendicularContentHuggingPriority, for: .horizontal)
            @unknown default:
                stackView.setContentHuggingPriority(perpendicularContentHuggingPriority, for: .horizontal)
            }
        }
        return stackView
    }
}
