//
//  LoadingView.swift
//  ChelseabandSDK_Example
//
//  Created by Vladyslav Shepitko on 07.12.2020.
//  Copyright © 2020 Sonerim. All rights reserved.
//

import UIKit
import SnapKit
import ChelseabandSDK
import RxSwift
import RxCocoa

class LoadingView: UIView {

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .gray)
        view.hidesWhenStopped = true
        return view
    }()

    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.text = "Some status"
        label.font = .boldSystemFont(ofSize: 14)
        label.textColor = .black
        
        return label
    }()

    init() {
        super.init(frame: .zero)
        configureLayout()
    }

    var text: String? {
        get {
            return textLabel.text
        }
        set {
            textLabel.text = newValue
        }
    }

    var isAnimating: Bool {
        loadingIndicator.isAnimating
    }

    func startLoading() {
        loadingIndicator.startAnimating()
    }

    func stopLoading() {
        loadingIndicator.stopAnimating()
    }

    private func configureLayout() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 5

        stackView.addArrangedSubview(textLabel)
        stackView.addArrangedSubview(loadingIndicator)

        addSubview(stackView)
    }

    required init?(coder: NSCoder) {
        return nil
    }
} 
