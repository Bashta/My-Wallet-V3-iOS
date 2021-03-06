//
//  CheckoutContentDescriptionLabelInteractor.swift
//  BuySellUIKit
//
//  Created by Alex McGregor on 9/1/20.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

import Localization
import PlatformKit
import PlatformUIKit
import RxRelay
import RxSwift

final class CheckoutContentDescriptionLabelInteractor {
    
    typealias InteractionState = LabelContent.State.Interaction
    typealias LocalizationId = LocalizationConstants.LineItem.Transactional
    
    final class AssetPrice: LabelContentInteracting {
        private lazy var setup: Void = {
            service
                .price(for: quoteCurrency, in: baseCurrency)
                .asObservable()
                .map { $0.moneyValue }
                /// This should never happen.
                .catchErrorJustReturn(.zero(currency: quoteCurrency.currency))
                .map { $0.toDisplayString(includeSymbol: true) }
                .map { .loaded(next: .init(text: $0)) }
                .bindAndCatch(to: stateRelay)
                .disposed(by: disposeBag)
        }()
        
        let stateRelay = BehaviorRelay<InteractionState>(value: .loading)
        var state: Observable<InteractionState> {
            _ = setup
            return stateRelay.asObservable()
        }
        
        // MARK: - Private Properties
        
        private let service: PriceServiceAPI
        private let baseCurrency: Currency
        private let quoteCurrency: Currency
        private let disposeBag = DisposeBag()
        
        // MARK: - Private Accessors
        
        init(service: PriceServiceAPI,
             baseCurrency: Currency,
             quoteCurrency: Currency) {
            self.service = service
            self.baseCurrency = baseCurrency
            self.quoteCurrency = quoteCurrency
        }
    }
    
}
