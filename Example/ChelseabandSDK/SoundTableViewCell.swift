//
//  SoundTableViewCell.swift
//  ChelseabandSDK_Example
//
//  Created by Vladyslav Shepitko on 03.12.2020.
//  Copyright © 2020 Sonerim. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import ChelseabandSDK

class SoundTableViewCell: UITableViewCell {

    private lazy var title: UILabel = {
        let view = UILabel()
        view.textColor = .black
        return view
    }()

    private lazy var dropdownPicker: DropdownPicker<Sound> = {
        let view = DropdownPicker<Sound>(values: Sound.allCases)
        return view
    }()

    private lazy var iconImageView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = .red
        return view
    }()

    var disposeBag = DisposeBag()

    var selectionObservable: Observable<Sound> {
        return dropdownPicker.selectedObservable
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        contentView.backgroundColor = .white

        setupLayout()
    }

    private func setupLayout() {
        contentView.addSubview(iconImageView)
        contentView.addSubview(dropdownPicker)
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

        dropdownPicker.snp.makeConstraints {
            $0.trailing.equalTo(contentView.snp.trailing).inset(10)
            $0.centerY.equalTo(iconImageView .snp.centerY)
        }
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func prepareForReuse() {
        disposeBag = DisposeBag()
    }

    func bind(viewModel: SoundRowViewModel) {
        viewModel.title.bind(to: title.rx.text).disposed(by: disposeBag)

        //NOTE: Replace with binders
        viewModel.sound.debug("b").subscribe(onNext: { sound in
            self.dropdownPicker.set(value: sound)
        }).disposed(by: disposeBag)
    }
}

