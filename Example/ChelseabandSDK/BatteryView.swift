//
//  BatteryView.swift
//  ChelseabandSDK_Example
//
//  Created by Vladyslav Shepitko on 15.12.2020.
//  Copyright © 2020 Sonerim. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa 

class BatteryView: UIView {

    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

    private let percentageLabel: UILabel = {
        let view = UILabel()
        view.font = .systemFont(ofSize: 12, weight: .bold)
        view.textColor = .black
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)

        return view
    }()

    init() {
        super.init(frame: .zero)
        configureLayout()
    }

    required init?(coder: NSCoder) {
        return nil
    }

    private let disposeBag = DisposeBag()

    private func configureLayout() {
        addSubview(imageView)
        addSubview(percentageLabel)

        let stackView = UIStackView(arrangedSubviews: [percentageLabel, imageView])
        stackView.spacing = 5
        stackView.axis = .horizontal

        addSubview(stackView)

        stackView.snp.makeConstraints {
            $0.edges.equalTo(self)
        }

        imageView.snp.makeConstraints {
            $0.height.width.equalTo(30)
        }
    }

    func bind(viewModel: BatteryViewModel) {
        let output = viewModel.transform(input: .init())

        output.batteryImage.drive(imageView.rx.image).disposed(by: disposeBag)
        output.batteryPercentage.drive(percentageLabel.rx.text).disposed(by: disposeBag)
        output.isHidden.drive(rx.isHidden).disposed(by: disposeBag)
    }
}
