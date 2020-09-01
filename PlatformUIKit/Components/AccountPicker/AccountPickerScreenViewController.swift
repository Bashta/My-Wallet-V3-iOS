//
//  AccountPickerScreenViewController.swift
//  PlatformUIKit
//
//  Created by Paulo on 05/08/2020.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

import RxCocoa
import RxDataSources
import RxSwift
import ToolKit

public final class AccountPickerScreenViewController: BaseScreenViewController {

    // MARK: - Types

    private typealias RxDataSource = RxTableViewSectionedReloadDataSource<AccountPickerSectionViewModel>

    // MARK: - Private IBOutlets

    private var tableView: UITableView!

    // MARK: - Private Properties

    private let presenter: AccountPickerScreenPresenter
    private let disposeBag = DisposeBag()

    // MARK: - Setup

    public init(presenter: AccountPickerScreenPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    // MARK: - Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupNavigationBar()
    }

    // MARK: - Private Functions

    private func setupNavigationBar() {
        titleViewStyle = presenter.titleViewStyle
        set(barStyle: presenter.barStyle,
            leadingButtonStyle: presenter.leadingButton,
            trailingButtonStyle: presenter.trailingButton
        )
    }

    private func setupTableView() {
        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = .white
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.separatorColor = .clear
        tableView.alwaysBounceVertical = true
        tableView.registerNibCell(CurrentBalanceTableViewCell.self)
        tableView.registerNibCell(AccountGroupBalanceTableViewCell.self)
        view.addSubview(tableView)
        tableView.layoutToSuperview(.top, .bottom, .leading, .trailing)

        let dataSource = RxDataSource(configureCell: { [weak self] _, _, indexPath, item in
            guard let self = self else { return UITableViewCell() }
            let cell: UITableViewCell
            switch item.presenter {
            case .accountGroup(let presenter):
                cell = self.totalBalanceCell(for: indexPath, presenter: presenter)
            case .singleAccount(let presenter):
                cell = self.balanceCell(for: indexPath, presenter: presenter)
            }
            cell.selectionStyle = .none
            return cell
        })

        presenter.sectionObservable
            .bindAndCatch(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        tableView.rx.modelSelected(AccountPickerCellItem.self)
            .bindAndCatch(weak: self) { (self, model) in
                self.presenter.record(selection: model.account)
                self.dismiss(animated: true, completion: nil)
            }
            .disposed(by: disposeBag)
    }

    private func balanceCell(for indexPath: IndexPath, presenter: CurrentBalanceCellPresenting) -> UITableViewCell {
        let cell = tableView.dequeue(CurrentBalanceTableViewCell.self, for: indexPath)
        cell.presenter = presenter
        return cell
    }

    private func totalBalanceCell(for indexPath: IndexPath, presenter: AccountGroupBalanceCellPresenter) -> AccountGroupBalanceTableViewCell {
        let cell = tableView.dequeue(AccountGroupBalanceTableViewCell.self, for: indexPath)
        cell.presenter = presenter
        return cell
    }
}