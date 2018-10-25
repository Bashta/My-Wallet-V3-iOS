//
//  SendLumensViewController.swift
//  Blockchain
//
//  Created by Alex McGregor on 10/16/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

import Foundation

protocol SendXLMViewControllerDelegate: class {
    func onLoad()
    func onXLMEntry(_ value: String)
    func onFiatEntry(_ value: String)
    func onPrimaryTapped(toAddress: String, amount: Decimal)
    func onConfirmPayTapped(_ paymentOperation: StellarPaymentOperation)
    func onUseMaxTapped()
}

@objc class SendLumensViewController: UIViewController, BottomButtonContainerView {
    
    // MARK: BottomButtonContainerView
    
    var originalBottomButtonConstraint: CGFloat!
    @IBOutlet var layoutConstraintBottomButton: NSLayoutConstraint!
    
    // MARK: Private IBOutlets (UILabel)
    
    @IBOutlet fileprivate var fromLabel: UILabel!
    @IBOutlet fileprivate var toLabel: UILabel!
    @IBOutlet fileprivate var walletNameLabel: UILabel!
    @IBOutlet fileprivate var feeLabel: UILabel!
    @IBOutlet fileprivate var feeAmountLabel: UILabel!
    @IBOutlet fileprivate var errorLabel: UILabel!
    @IBOutlet fileprivate var stellarSymbolLabel: UILabel!
    @IBOutlet fileprivate var fiatSymbolLabel: UILabel!
    
    // MARK: Private IBOutlets (UITextField)
    
    @IBOutlet fileprivate var stellarAddressField: UITextField!
    @IBOutlet fileprivate var stellarAmountField: UITextField!
    @IBOutlet fileprivate var fiatAmountField: UITextField!
    
    // MARK: Private IBOutlets (Other)
    
    @IBOutlet fileprivate var useMaxLabel: ActionableLabel!
    @IBOutlet fileprivate var primaryButtonContainer: PrimaryButtonContainer!
    @IBOutlet fileprivate var learnAbountStellarButton: UIButton!
    
    weak var delegate: SendXLMViewControllerDelegate?
    fileprivate var coordinator: SendXLMCoordinator!
    fileprivate var trigger: ActionableTrigger?
    private var pendingPaymentOperation: StellarPaymentOperation?
    
    // MARK: Factory
    
    @objc class func make() -> SendLumensViewController {
        let controller = SendLumensViewController.makeFromStoryboard()
        return controller
    }
    
    // MARK: ViewUpdate
    
    enum PresentationUpdate {
        case activityIndicatorVisibility(Visibility)
        case errorLabelVisibility(Visibility)
        case learnAboutStellarButtonVisibility(Visibility)
        case actionableLabelVisibility(Visibility)
        case errorLabelText(String)
        case feeAmountLabelText(String)
        case stellarAddressText(String)
        case xlmFieldTextColor(UIColor)
        case fiatFieldTextColor(UIColor)
        case actionableLabelTrigger(ActionableTrigger)
        case primaryButtonEnabled(Bool)
        case showPaymentConfirmation(StellarPaymentOperation)
        case hidePaymentConfirmation
        case paymentSuccess
    }

    // MARK: Public Methods

    @objc func scanQrCodeForDestinationAddress() {
        let qrCodeScanner = QRCodeScannerSendViewController()
        qrCodeScanner.qrCodebuttonClicked(nil)
        qrCodeScanner.delegate = self
        present(qrCodeScanner, animated: false)
    }
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let services = XLMServices(configuration: .test)
        let provider = XLMServiceProvider(services: services)
        coordinator = SendXLMCoordinator(serviceProvider: provider, interface: self)
        view.frame = UIView.rootViewSafeAreaFrame(
            navigationBar: true,
            tabBar: true,
            assetSelector: true
        )
        originalBottomButtonConstraint = layoutConstraintBottomButton.constant
        setUpBottomButtonContainerView()
        useMaxLabel.delegate = self
        primaryButtonContainer.isEnabled = true
        primaryButtonContainer.actionBlock = { [unowned self] in
            guard let toAddress = self.stellarAddressField.text else { return }
            guard let amountString = self.stellarAmountField.text else { return }
            guard let amount = Decimal(string: amountString) else { return }
            self.delegate?.onPrimaryTapped(toAddress: toAddress, amount: amount)
        }
        delegate?.onLoad()
    }
    
    fileprivate func useMaxAttributes() -> [NSAttributedStringKey: Any] {
        let fontName = Constants.FontNames.montserratRegular
        let font = UIFont(name: fontName, size: 13.0) ?? UIFont.systemFont(ofSize: 13.0)
        return [.font: font,
                .foregroundColor: UIColor.darkGray]
    }
    
    fileprivate func useMaxActionAttributes() -> [NSAttributedStringKey: Any] {
        let fontName = Constants.FontNames.montserratRegular
        let font = UIFont(name: fontName, size: 13.0) ?? UIFont.systemFont(ofSize: 13.0)
        return [.font: font,
                .foregroundColor: UIColor.brandSecondary]
    }
    
    fileprivate func apply(_ update: PresentationUpdate) {
        switch update {
        case .activityIndicatorVisibility(let visibility):
            primaryButtonContainer.isLoading = (visibility == .visible)
        case .errorLabelVisibility(let visibility):
            errorLabel.isHidden = visibility.isHidden
        case .learnAboutStellarButtonVisibility(let visibility):
            learnAbountStellarButton.isHidden = visibility.isHidden
        case .actionableLabelVisibility(let visibility):
            useMaxLabel.isHidden = visibility.isHidden
        case .errorLabelText(let value):
            errorLabel.text = value
        case .feeAmountLabelText(let value):
            feeAmountLabel.text = value
        case .stellarAddressText(let value):
            stellarAddressField.text = value
        case .xlmFieldTextColor(let color):
            stellarAmountField.textColor = color
        case .fiatFieldTextColor(let color):
            fiatAmountField.textColor = color
        case .actionableLabelTrigger(let trigger):
            self.trigger = trigger
            let primary = NSMutableAttributedString(
                string: trigger.primaryString,
                attributes: useMaxAttributes()
            )
            
            let CTA = NSAttributedString(
                string: " " + trigger.callToAction,
                attributes: useMaxActionAttributes()
            )
            
            primary.append(CTA)
            
            if let secondary = trigger.secondaryString {
                let trailing = NSMutableAttributedString(
                    string: " " + secondary,
                    attributes: useMaxAttributes()
                )
                primary.append(trailing)
            }
            
            useMaxLabel.attributedText = primary
        case .primaryButtonEnabled(let enabled):
            primaryButtonContainer.isEnabled = enabled
        case .paymentSuccess:
            showPaymentSuccess()
        case .showPaymentConfirmation(let paymentOperation):
            showPaymentConfirmation(paymentOperation: paymentOperation)
        case .hidePaymentConfirmation:
            ModalPresenter.shared.closeAllModals()
        }
    }

    private func showPaymentSuccess() {
        AlertViewPresenter.shared.standardNotify(
            message: LocalizationConstants.SendAsset.paymentSent,
            title: LocalizationConstants.success
        )
    }

    private func showPaymentConfirmation(paymentOperation: StellarPaymentOperation) {
        self.pendingPaymentOperation = paymentOperation
        let viewModel = BCConfirmPaymentViewModel.initialize(with: paymentOperation)
        let confirmView = BCConfirmPaymentView(
            frame: view.frame,
            viewModel: viewModel,
            sendButtonFrame: primaryButtonContainer.frame
        )!
        confirmView.confirmDelegate = self
        ModalPresenter.shared.showModal(
            withContent: confirmView,
            closeType: ModalCloseTypeBack,
            showHeader: true,
            headerText: LocalizationConstants.SendAsset.confirmPayment
        )
    }
}

extension SendLumensViewController: SendXLMInterface {
    func apply(updates: [PresentationUpdate]) {
        updates.forEach({ apply($0) })
    }
}

extension SendLumensViewController: ConfirmPaymentViewDelegate {
    func confirmButtonDidTap(_ note: String?) {
        guard let paymentOperation = pendingPaymentOperation else {
            Logger.shared.warning("No pending payment operation")
            return
        }
        delegate?.onConfirmPayTapped(paymentOperation)
    }

    func feeInformationButtonClicked() {
        // TODO
    }
}

extension SendLumensViewController: ActionableLabelDelegate {
    func targetRange(_ label: ActionableLabel) -> NSRange? {
        return trigger?.actionRange()
    }
    
    func actionRequestingExecution(label: ActionableLabel) {
        guard let trigger = trigger else { return }
        trigger.execute()
    }
}

extension SendLumensViewController: QRCodeScannerViewControllerDelegate {
    func qrCodeScannerViewController(_ qrCodeScannerViewController: QRCodeScannerSendViewController, didScanString scannedString: String?) {
        qrCodeScannerViewController.dismiss(animated: false)
        guard let scanned = scannedString else { return }
        guard let payload = AssetURLPayloadFactory.create(fromString: scanned, assetType: .stellar) else {
            Logger.shared.error("Could not create payload from scanned string: \(scanned)")
            return
        }
        stellarAddressField.text = payload.address
        stellarAmountField.text = payload.amount
    }
}

extension BCConfirmPaymentViewModel {
    static func initialize(with paymentOperation: StellarPaymentOperation) -> BCConfirmPaymentViewModel {
        // TODO set actual values
        // TICKET: IOS-1523
        return BCConfirmPaymentViewModel(
            from: paymentOperation.sourceAccount.label ?? "",
            to: paymentOperation.destinationAccountId,
            totalAmountText: "\(paymentOperation.amountInXlm)",
            fiatTotalAMountText: "\(paymentOperation.amountInXlm)",
            cryptoWithFiatAmountText: "\(paymentOperation.amountInXlm)",
            amountWithFiatFeeText: "\(paymentOperation.amountInXlm + paymentOperation.feeInXlm)",
            buttonTitle: LocalizationConstants.SendAsset.send,
            showDescription: true,
            surgeIsOccurring: false,
            noteText: nil,
            warningText: nil
        )
    }
}
