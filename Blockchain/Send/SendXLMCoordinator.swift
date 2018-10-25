//
//  SendXLMCoordinator.swift
//  Blockchain
//
//  Created by Alex McGregor on 10/24/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

import Foundation
import RxSwift

class SendXLMCoordinator {
    fileprivate let serviceProvider: XLMServiceProvider
    fileprivate let interface: SendXLMInterface
    fileprivate let disposables = CompositeDisposable()
    fileprivate var services: XLMServices {
        return serviceProvider.services
    }
    
    init(serviceProvider: XLMServiceProvider, interface: SendXLMInterface) {
        self.serviceProvider = serviceProvider
        self.interface = interface
        if let controller = interface as? SendLumensViewController {
            controller.delegate = self
        }
    }

    deinit {
        disposables.dispose()
    }
    
    enum InternalEvent {
        case insufficientFunds
        case noStellarAccount
        case noXLMAccount
    }
    
    // MARK: Private Functions

    fileprivate func accountDetailsTrigger() -> Observable<StellarAccount> {
        return services.operation.operations.concatMap { _ -> Observable<StellarAccount> in
            return self.services.accounts.currentStellarAccount(fromCache: false).asObservable()
        }
    }
    
    fileprivate func observeOperations() {
        let disposable = Observable.combineLatest(accountDetailsTrigger(), services.ledger.current)
            .subscribeOn(MainScheduler.asyncInstance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (account, ledger) in
                // The users account (and thus balance)
                // may have changed due to an operation.
            }, onError: { error in
                guard let serviceError = error as? StellarServiceError else { return }
                Logger.shared.error(error.localizedDescription)
            })
        services.operation.start()
        disposables.insertWithDiscardableResult(disposable)
    }
    
    fileprivate func handle(internalEvent: InternalEvent) {
        switch internalEvent {
        case .insufficientFunds:
            // TODO
            break
        case .noStellarAccount,
             .noXLMAccount:
            let trigger = ActionableTrigger(text: "Minimum of", CTA: "1 XLM", secondary: "needed for new accounts.") {
                // TODO: On `1 XLM` selection, show the minimum balance screen.
            }
            let ledger = services.ledger.current
            interface.apply(updates: [.actionableLabelTrigger(trigger),
                                      .fiatFieldTextColor(.error),
                                      .xlmFieldTextColor(.error),
                                      .errorLabelVisibility(.hidden),
                                      .feeAmountLabelText("0.00 XLM")])
            break
        }
    }
    
}

extension SendXLMCoordinator: SendXLMViewControllerDelegate {
    func onLoad() {
        // TODO: Users may have a `defaultAccount` but that doesn't mean
        // that they have an `StellarAccount` as it must be funded.
        let disposable = services.accounts.currentStellarAccount(fromCache: true).asObservable()
            .subscribeOn(MainScheduler.asyncInstance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { account in
                /// The user has a StellarAccount, we should enable the input fields.
                /// Begin observing operations and updating the user account.
                self.observeOperations()
            }, onError: { [weak self] error in
                guard let this = self else { return }
                guard let serviceError = error as? StellarServiceError else { return }
                switch serviceError {
                case .noXLMAccount:
                    this.handle(internalEvent: .noXLMAccount)
                case .noDefaultAccount:
                    this.handle(internalEvent: .noStellarAccount)
                default:
                    break
                }
                this.handle(internalEvent: .insufficientFunds)
                Logger.shared.error(error.localizedDescription)
            })
        disposables.insertWithDiscardableResult(disposable)
    }
    
    func onXLMEntry(_ value: String) {
        
    }
    
    func onFiatEntry(_ value: String) {
        
    }
    
    func onSecondaryPasswordValidated() {
        
    }

    func onConfirmPayTapped(_ paymentOperation: StellarPaymentOperation) {
        let transaction = services.transaction
        let disposable = services.repository.loadStellarKeyPair()
            .asObservable()
            .do(onNext: { [weak self] _ in
                self?.interface.apply(updates: [
                    .hidePaymentConfirmation,
                    .activityIndicatorVisibility(.visible)
                ])
            }).flatMap { keyPair -> Completable in
                return transaction.send(paymentOperation, sourceKeyPair: keyPair)
            }.subscribeOn(MainScheduler.asyncInstance)
            .observeOn(MainScheduler.instance)
            .subscribe(onError: { [weak self] error in
                Logger.shared.error("Failed to send XLM. Error: \(error)")
                self?.interface.apply(updates: [
                    .errorLabelText(LocalizationConstants.Stellar.cannotSendXLMAtThisTime),
                    .activityIndicatorVisibility(.hidden)
                ])
            }, onCompleted: { [weak self] in
                self?.interface.apply(updates: [
                    .paymentSuccess,
                    .activityIndicatorVisibility(.hidden)
                ])
            })
        disposables.insertWithDiscardableResult(disposable)
    }
    
    func onPrimaryTapped(toAddress: String, amount: Decimal) {
        let disposable = services.ledger.current
            .take(1)
            .subscribeOn(MainScheduler.asyncInstance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] ledger in
                guard let strongSelf = self else { return }

                guard let sourceAccount = strongSelf.services.repository.defaultAccount else { return }

                guard let feeInStroops = ledger.baseFeeInStroops else {
                    Logger.shared.error("Fee is nil.")
                    strongSelf.interface.apply(updates: [
                        .errorLabelText(LocalizationConstants.Stellar.cannotSendXLMAtThisTime)
                    ])
                    return
                }

                let feeInXlm = Decimal(feeInStroops / Constants.Conversions.stroopsInXlm)
                let operation = StellarPaymentOperation(
                    destinationAccountId: toAddress,
                    amountInXlm: amount,
                    sourceAccount: sourceAccount,
                    feeInXlm: feeInXlm
                )
                strongSelf.interface.apply(updates: [
                    .showPaymentConfirmation(operation)
                ])
        }, onError: { [weak self] error in
            Logger.shared.error("Could not fetch ledger")
            self?.interface.apply(updates: [
                .errorLabelText(LocalizationConstants.Stellar.cannotSendXLMAtThisTime)
            ])
        })
        disposables.insertWithDiscardableResult(disposable)
    }

    func onUseMaxTapped() {
        
    }
}
