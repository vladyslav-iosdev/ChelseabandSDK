//
//  DropdownPicker.swift
//  ChelseabandSDK_Example
//
//  Created by Vladyslav Shepitko on 03.12.2020.
//  Copyright © 2020 Sonerim. All rights reserved.
//

import UIKit
import DropDown
import SnapKit
import RxSwift
import RxCocoa

public protocol DropdownPickerValue: Equatable {
    var title: String { get }
} 

class DropdownPicker<T: DropdownPickerValue>: UIControl {

    private var values: [T]

    private lazy var dropDown: DropDown = {
        let control = DropDown()
        control.translatesAutoresizingMaskIntoConstraints = false
        control.anchorView = self
        control.dataSource = values.map{ $0.title }
        control.dismissMode = .onTap

        return control
    }()

    private lazy var placeholder: UILabel = {
        let label = UILabel()
        label.textColor = .darkGray
        label.font = .systemFont(ofSize: 16)

        return label
    }()

    var selectedValue: T? {
        get {
            if let index = dropDown.indexForSelectedRow {
                return values[index]
            }
            return nil
        }
    }

    var selectedObservable: Observable<T> {
        return selectedSubject.compactMap {
            $0
        }.asObservable()
    }
    private var selectedSubject = BehaviorSubject<T?>(value: nil)
    private let disposeBag = DisposeBag()

    init(values: [T]) {
        self.values = values
        super.init(frame: .zero)

        setupLayout()
        isUserInteractionEnabled = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        addGestureRecognizer(tap)

        dropDown.selectionAction = { [weak self] index, value in
            guard let strongSelf = self else { return }

            strongSelf.selectedSubject.onNext(values[index])
        }

        selectedSubject.subscribe(onNext: { value in
            self.set(value: value)
        }).disposed(by: disposeBag)
    }

    func set(value: T?) {
        self.placeholder.text = value?.title ?? "Placeholder"

        if let value = value, let index = values.firstIndex(of: value) {
            dropDown.selectRow(index)
        }
    }

    private func setupLayout() {
        let stackView = [placeholder].asStackView(spacing: 5)

        addSubview(stackView)

        stackView.snp.makeConstraints {
            $0.edges.equalTo(snp.edges)
        }

        placeholder.snp.makeConstraints {
            $0.height.equalTo(30)
        }
    }

    @discardableResult override func becomeFirstResponder() -> Bool {
        dropDown.show()
        return true
    }

    required init?(coder: NSCoder) {
        return nil
    }

    @objc private func didTap(_ sender: UITapGestureRecognizer) {
        dropDown.show()
    }
}
