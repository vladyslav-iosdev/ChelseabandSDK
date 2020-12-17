//
//  SettingsViewController.swift
//  ChelseabandSDK_Example
//
//  Created by Vladyslav Shepitko on 25.11.2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import ChelseabandSDK

class BackgroundView: UIImageView {

    init() {
        super.init(image: UIImage.init(named: "background"))
        contentMode = .scaleAspectFill
        isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) {
        nil
    }
}

class SettingsViewController: UIViewController {

    private let viewModel: SettingsViewModel
    private lazy var settingsView: SettingsView = {
        let view = SettingsView()
        view.register(SoundTableViewCell.self)
        view.register(ToggleTableViewCell.self)
        view.registerHeaderFooterView(SettingsSectionView.self)
        view.delegate = self
        view.dataSource = self
        view.backgroundView = BackgroundView()
        view.backgroundColor = .clear
        view.separatorStyle = .none

        return view
    }()

    let disposeBag = DisposeBag()
    private var sections: [SettingsSection] = []

    let soundChangeObservable = PublishSubject<(sound: Sound, trigger: SoundTrigger)>.init()
    let lightChangeObservable = PublishSubject<(isOn: Bool, trigger: LightTrigger)>.init()
    let vibrationChangeObservable = PublishSubject<Bool>.init()

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    override func loadView() {
        view = settingsView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let output = viewModel.transform(input: .init())
        output.title.drive(navigationItem.rx.title).disposed(by: disposeBag)

        output.sections.drive(onNext: { [weak self] sections in
            guard let strongSelf = self else { return }

            strongSelf.sections = sections
            strongSelf.settingsView.reloadData()
        }).disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        return nil
    }
}

extension SettingsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .alerts(let viewModel, _):
            return viewModel.count
        case .sounds(let viewModel):
            return viewModel.count
        case .vibration:
            return 1
        }
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch sections[indexPath.section] {
        case .alerts(let viewModels, _):
            let cell: ToggleTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            let viewModel = viewModels[indexPath.row]

            cell.bind(viewModel: viewModel)

            Observable.combineLatest(cell.isSelectedObservable, Observable.just(viewModel.trigger))
                .map { (isOn: $0.0, trigger: $0.1) }
                .subscribe(lightChangeObservable)
                .disposed(by: cell.disposeBag)

            return cell
        case .sounds(let viewModels):
            let cell: SoundTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            let viewModel = viewModels[indexPath.row]
            cell.bind(viewModel: viewModel)

            Observable.combineLatest(cell.selectionObservable, Observable.just(viewModel.trigger))
                .map { (sound: $0.0, trigger: $0.1) }
                .subscribe(soundChangeObservable)
                .disposed(by: cell.disposeBag)

            return cell
        case .vibration(let viewModel):
            let cell: ToggleTableViewCell = tableView.dequeueReusableCell(for: indexPath)

            cell.bind(viewModel: viewModel)

            cell.isSelectedObservable
                .subscribe(vibrationChangeObservable)
                .disposed(by: cell.disposeBag)

            return cell
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch sections[section] {
        case .sounds, .vibration:
            return nil
        case .alerts(_, let viewModel):
            let view: SettingsSectionView = tableView.dequeueReusableHeaderFooterView()
            view.bind(viewModel: viewModel)

            return view
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return .none
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }

}

struct SettingsSectionViewModel {

    let title: Observable<String>

    init(title: String) {
        self.title = Observable.just(title)
    }
}

class SettingsSectionView: UITableViewHeaderFooterView {

    private lazy var title: UILabel = {
        let view = UILabel()
        view.textColor = .black
        view.font = .boldSystemFont(ofSize: 16)

        return view
    }()
    private let disposeBag = DisposeBag()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        setupLayout()
        contentView.backgroundColor = .clear
    }

    private func setupLayout() {
        contentView.addSubview(title)

        title.snp.makeConstraints {
            $0.top.equalTo(contentView.snp.top).inset(20)
            $0.leading.equalTo(contentView.snp.leading).offset(20)
            $0.bottom.equalTo(contentView.snp.bottom).inset(10)
        }
    }

    required init?(coder: NSCoder) {
        return nil
    }

    func bind(viewModel: SettingsSectionViewModel) {
        viewModel.title.bind(to: title.rx.text).disposed(by: disposeBag)
    }
}
