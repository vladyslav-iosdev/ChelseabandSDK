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

extension UIView {
    func dropShadow(color: UIColor, opacity: Float = 0.5, offSet: CGSize = .zero, radius: CGFloat = 1, scale: Bool = true, shouldRasterize: Bool = true) {
        layer.masksToBounds = false
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offSet
        layer.shadowRadius = radius

        layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
        layer.shouldRasterize = shouldRasterize
        layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int, alpha: CGFloat = 1.0) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        assert(alpha >= 0 && alpha <= 1.0, "Invalid alpha component")

        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: alpha)
    }

    convenience init(netHex: Int) {
        self.init(red: (netHex >> 16) & 0xff, green: (netHex >> 8) & 0xff, blue: netHex & 0xff)
    }

    convenience init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.scanLocation = 0

        var rgbValue: UInt64 = 0

        scanner.scanHexInt64(&rgbValue)

        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff

        self.init(
            red: CGFloat(r) / 0xff,
            green: CGFloat(g) / 0xff,
            blue: CGFloat(b) / 0xff, alpha: 1
        )
    }
}
