//
//  DeviceConnectionView.swift
//  ChelseabandSDK_Example
//
//  Created by Vladyslav Shepitko on 14.12.2020.
//  Copyright © 2020 Sonerim. All rights reserved.
//

import UIKit
import SnapKit
import RxCocoa
import RxSwift

class DeviceConnectionView: UIView {

    private let connectionButton: UIButton = {
        let view = UIButton()
        return view
    }()

    private let bluetoothIconView: UIImageView = {
        let view = UIImageView()

        return view
    }()

    private let statusLabel: UILabel = {
        let view = UILabel()
        view.font = .systemFont(ofSize: 16, weight: .medium)

        return view
    }()

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .gray)
        view.hidesWhenStopped = true
        return view
    }()

    private lazy var onlineIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()

    private let disposeBag = DisposeBag()

    init() {
        super.init(frame: .zero)
        setupLayout()

        clipsToBounds = false
        backgroundColor = .white
    }

    required init?(coder: NSCoder) {
        nil
    }

    private func setupLayout() {
        addSubview(connectionButton)
        addSubview(bluetoothIconView)
        addSubview(statusLabel)

        connectionButton.snp.makeConstraints {
            $0.edges.equalTo(self)
            $0.height.equalTo(40)
        }

        bluetoothIconView.snp.makeConstraints {
            $0.leading.equalTo(connectionButton.snp.leading).offset(15)
            $0.centerY.equalTo(connectionButton.snp.centerY)
            $0.width.height.equalTo(25)
        }

        onlineIndicator.snp.makeConstraints {
            $0.width.height.equalTo(15)
        }

        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 5

        stackView.addArrangedSubview(onlineIndicator)
        stackView.addArrangedSubview(loadingIndicator)

        addSubview(stackView)

        stackView.snp.makeConstraints {
            $0.trailing.equalTo(connectionButton.snp.trailing).offset(-15)
            $0.centerY.equalTo(connectionButton.snp.centerY)
        }

        statusLabel.snp.makeConstraints {
            $0.leading.equalTo(bluetoothIconView.snp.trailing).offset(15)
            $0.centerY.equalTo(connectionButton.snp.centerY)
            $0.trailing.equalTo(stackView.snp.leading).offset(-15)
        }
    }

    func bind(viewModel: DeviceConnectionViewModel) -> Driver<Void> {
        let input: DeviceConnectionViewModel.Input = .init(connectionObservable: connectionButton.rx.tap.asObservable())
        let output = viewModel.transform(input: input)

        output.connectionIconObservable
            .drive(bluetoothIconView.rx.image)
            .disposed(by: disposeBag)

        output.connectionIconTintColorObservable
            .drive(onNext: { [weak self] color in
                self?.bluetoothIconView.tintColor = color
                self?.statusLabel.textColor = color
                self?.onlineIndicator.backgroundColor = color
            }).disposed(by: disposeBag)

        output.connectionStateTextObservable
            .drive(statusLabel.rx.text)
            .disposed(by: disposeBag)

        output.statusObservable.drive(onNext: { state in
            switch state {
            case .disconnected, .connected:
                self.onlineIndicator.isHidden = false

                self.loadingIndicator.isHidden = true
                self.loadingIndicator.stopAnimating()
            case .connecting, .scanning:
                self.onlineIndicator.isHidden = true

                self.loadingIndicator.isHidden = false
                self.loadingIndicator.startAnimating()
            }
        }).disposed(by: disposeBag)

        return output.connectionObservable
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        onlineIndicator.layer.cornerRadius = onlineIndicator.frame.height / 2
        dropShadow(color: .black, offSet: CGSize(width: 0.0, height: 0.5), radius: 2.5)
    }
}
