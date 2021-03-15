//
//  AlertTableViewCell.swift
//  ChelseabandSDK_Example
//
//  Created by Vladyslav Shepitko on 03.12.2020.
//  Copyright © 2020 Sonerim. All rights reserved.
//

import UIKit
import RxSwift
import SnapKit

class ToggleTableViewCell: UITableViewCell {

    private lazy var title: UILabel = {
        let view = UILabel()
        view.textColor = .black
        return view
    }()

    private lazy var toggleView: UISwitch = {
        let view = UISwitch()
        return view
    }()

    private lazy var iconImageView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = .white
        return view
    }()

    var isSelectedObservable: Observable<Bool> {
        return toggleView.rx.isOn.skip(1).asObservable()
    }

    var disposeBag = DisposeBag()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        contentView.backgroundColor = .white
        setupLayout()
    }

    private func setupLayout() {
        contentView.addSubview(iconImageView)
        contentView.addSubview(toggleView)
        contentView.addSubview(title)

        iconImageView.snp.makeConstraints {
            $0.height.width.equalTo(30)
            $0.top.equalTo(contentView.snp.top).inset(10)
            $0.bottom.equalTo(contentView.snp.bottom).inset(10)
            $0.leading.equalTo(contentView.snp.leading).offset(10)
        }

        title.snp.makeConstraints {
            $0.leading.equalTo(iconImageView.snp.trailing).offset(10)
            $0.centerY.equalTo(iconImageView.snp.centerY)
        }

        toggleView.snp.makeConstraints {
            $0.trailing.equalTo(contentView.snp.trailing).inset(10)
            $0.centerY.equalTo(iconImageView.snp.centerY)
        }
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func prepareForReuse() {
        disposeBag = DisposeBag()
    }

    func bind(viewModel: ToggleViewModelType) {
        title.text = viewModel.title
        toggleView.isOn = viewModel.value
        iconImageView.image = viewModel.image
    }
}
