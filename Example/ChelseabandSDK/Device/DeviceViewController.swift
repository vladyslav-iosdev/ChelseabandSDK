//
//  DeviceViewController.swift
//  ChelseabandSDK_Example
//
//  Created by Vladyslav Shepitko on 25.11.2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import ChelseabandSDK

class DeviceViewController: UIViewController {

    private let deviceView = DeviceView()

    var connectButtonObservable: Observable<Void> {
        return deviceView.connectButton.rx.tap.asObservable()
    }

    var sendNewButtonObservable: Observable<Void> {
        return deviceView.sendButton.rx.tap.asObservable()
    }

    var disconnectButtonObservable: Observable<Void> {
        return deviceView.disconnectButton.rx.tap.asObservable()
    }

    var sendGoalButtonObservable: Observable<Void> {
        return deviceView.sendGoalButton.rx.tap.asObservable()
    }

    var settingsButtonObservable: Observable<Void> {
        return moreBarButton.rx.tap.asObservable()
    }

    private let disposeBag = DisposeBag()
    private let viewModel: DeviceViewModel

    private let moreBarButton = UIBarButtonItem.moreBarButton

    init(viewModel: DeviceViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)

        navigationItem.leftBarButtonItem = UIBarButtonItem.logoBarButtonView
        navigationItem.rightBarButtonItem = moreBarButton
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func loadView() {
        view = deviceView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        bind(viewMode: viewModel)
    }

    private func bind(viewMode: DeviceViewModel) {
        let output = viewMode.transform(input: .init())

        deviceView
            .batteryView
            .bind(viewModel: output.batteryViewModel)

        output
            .connectionDate
            .drive(deviceView.connectionTimeLabel.rx.attributedText)
            .disposed(by: disposeBag)

        output
            .deviceImage
            .drive(deviceView.deviceImageView.rx.image)
            .disposed(by: disposeBag)

        _ = deviceView
            .connectionView
            .bind(viewModel: output.connectionViewModel)

//        connectDriver.debug("con").drive(onNext: { _ in
//
//        }).disposed(by: disposeBag)
    }
}

extension DeviceViewController {

    private class DeviceView: BackgroundView {

        lazy var connectionView: DeviceConnectionView = {
            let view = DeviceConnectionView()
            return view
        }()

        lazy var connectionTimeLabel: UILabel = {
            let view = UILabel()
            view.textColor = .darkGray
            view.font = .systemFont(ofSize: 14)
            view.numberOfLines = 0

            return view
        }()

        lazy var deviceImageView: UIImageView = {
            let view = UIImageView()
            view.contentMode = .scaleAspectFit
            view.image = UIImage(named: "device_disconnected")
            return view
        }()

        lazy var connectButton: UIButton = {
            let button = UIButton(type: .system)
            button.setTitle("Connect", for: .normal)
            button.setTitleColor(.black, for: .normal)

            return button
        }()

        lazy var disconnectButton: UIButton = {
            let button = UIButton(type: .system)
            button.setTitle("disconnect", for: .normal)
            button.setTitleColor(.black, for: .normal)

            return button
        }()

        lazy var sendButton: UIButton = {
            let button = UIButton(type: .system)
            button.setTitle("Send", for: .normal)
            button.setTitleColor(.black, for: .normal)

            return button
        }()

        lazy var sendGoalButton: UIButton = {
            let button = UIButton(type: .system)
            button.setTitle("Send Goal", for: .normal)
            button.setTitleColor(.black, for: .normal)

            return button
        }()

        private lazy var containerView: UIView = {
            let view = UIView()
            view.backgroundColor = .white
            return view
        }()

        lazy var batteryView: BatteryView = {
            let view = BatteryView()
            return view
        }()

        override init() {
            super.init()
            configureLayout()
        }

        private func configureLayout() {
            let stackView = [connectButton, disconnectButton, sendButton, sendGoalButton].asStackView(axis: .horizontal, distribution: .equalSpacing, spacing: 10)

            let containerStackView = [
                connectionView,
                containerView,
                stackView
            ].asStackView(axis: .vertical, spacing: 10)

            addSubview(containerStackView)

            containerView.addSubview(batteryView)
            containerView.addSubview(connectionTimeLabel)
            containerView.addSubview(deviceImageView)

            containerStackView.snp.makeConstraints {
                $0.top.equalTo(safeAreaLayoutGuide.snp.top).offset(15)
                $0.leading.equalTo(safeAreaLayoutGuide.snp.leading).offset(15)
                $0.right.equalTo(safeAreaLayoutGuide.snp.right).offset(-15)
            }

            containerView.snp.makeConstraints {
                $0.height.equalTo(snp.width)
            }

            batteryView.snp.makeConstraints {
                $0.top.equalTo(containerView.snp.top).offset(10)
                $0.trailing.equalTo(containerView.snp.trailing).offset(-10)
            }

            connectionTimeLabel.snp.makeConstraints {
                $0.centerY.equalTo(batteryView.snp.centerY)
                $0.leading.equalTo(containerView.snp.leading).offset(10)
            }

            stackView.snp.makeConstraints {
                $0.height.equalTo(50)
            }

            deviceImageView.snp.makeConstraints {
                $0.top.equalTo(containerView.snp.top)
                $0.bottom.equalTo(containerView.snp.bottom)
                $0.centerX.equalTo(containerView.snp.centerX)
            }
        }

        required init?(coder: NSCoder) {
            return nil
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            containerView.dropShadow(color: .black, offSet: CGSize(width: 0.0, height: 0.5), radius: 2.5)
        }
    }
}
