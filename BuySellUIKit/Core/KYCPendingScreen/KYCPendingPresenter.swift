//
//  KYCPendingPresenter.swift
//  Blockchain
//
//  Created by Paulo on 22/01/2020.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

import DIKit
import Localization
import PlatformUIKit
import RxCocoa
import RxRelay
import RxSwift
import ToolKit

final class KYCPendingPresenter: RibBridgePresenter, PendingStatePresenterAPI {

    // MARK: - Types

    private typealias LocalizedString = LocalizationConstants.SimpleBuy.KYCScreen
    private typealias AccessibilityId = Accessibility.Identifier.SimpleBuy.KYCScreen
    private typealias AnalyticsEvent = AnalyticsEvents.SimpleBuy

    // MARK: - Properties

    let title = LocalizedString.title
    
    var tap: Observable<URL> {
        .empty()
    }

    var viewModel: Driver<PendingStateViewModel> {
        modelRelay.asDriver()
    }

    private let disposeBag = DisposeBag()
    private let interactor: KYCPendingInteractor
    private unowned let stateService: RoutingStateEmitterAPI
    private let analyticsRecorder: AnalyticsEventRecorderAPI
    private var modelRelay: BehaviorRelay<PendingStateViewModel>!

    // MARK: - Setup
    
    init(stateService: RoutingStateEmitterAPI,
         interactor: KYCPendingInteractor,
         analyticsRecorder: AnalyticsEventRecorderAPI = resolve()) {
        self.analyticsRecorder = analyticsRecorder
        self.stateService = stateService
        self.interactor = interactor
        super.init(interactable: interactor)
        modelRelay = BehaviorRelay(value: model(verificationState: .loading))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        interactor
            .verificationState
            .takeWhile { $0 != .completed }
            .map(weak: self) { (self, state) in
                self.model(verificationState: state)
            }
            .bindAndCatch(to: modelRelay)
            .disposed(by: disposeBag)
        
        interactor.verificationState
            .map { $0.analyticsEvent }
            .bindAndCatch(to: analyticsRecorder.recordRelay)
            .disposed(by: disposeBag)

        interactor
            .verificationState
            .filter { $0 == .completed }
            .mapToVoid()
            .bindAndCatch(to: stateService.nextRelay)
            .disposed(by: disposeBag)

        interactor.startPollingForGoldTier()
    }
    
    private func model(verificationState: KYCPendingVerificationState) -> PendingStateViewModel {
        func actionButton(title: String) -> ButtonViewModel {
            let button = ButtonViewModel.primary(with: title)
            button.tapRelay
                .bindAndCatch(to: stateService.previousRelay)
                .disposed(by: disposeBag)
            return button
        }

        switch verificationState {
        case .ineligible:
            return PendingStateViewModel(
                compositeStatusViewType: .image(PendingStateViewModel.Image.region.name),
                title: LocalizedString.Ineligible.title,
                subtitle: LocalizedString.Ineligible.subtitle,
                button: actionButton(title: LocalizedString.Ineligible.button)
            )
        case .completed,
             .loading:
            return PendingStateViewModel(
                compositeStatusViewType: .loader,
                title: LocalizedString.Verifying.title,
                subtitle: LocalizedString.Verifying.subtitle,
                button: actionButton(title: LocalizedString.button)
            )
        case .manualReview:
            return PendingStateViewModel(
                compositeStatusViewType: .image(PendingStateViewModel.Image.triangleError.name),
                title: LocalizedString.ManualReview.title,
                subtitle: LocalizedString.ManualReview.subtitle,
                button: actionButton(title: LocalizedString.button)
            )
        case .pending:
            return PendingStateViewModel(
                compositeStatusViewType: .image(PendingStateViewModel.Image.clock.name),
                title: LocalizedString.PendingReview.title,
                subtitle: LocalizedString.PendingReview.subtitle,
                button: actionButton(title: LocalizedString.button)
            )
        }
    }
}
