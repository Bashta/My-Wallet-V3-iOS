//
//  EthereumTransactionSigner.swift
//  EthereumKit
//
//  Created by Jack on 23/04/2019.
//  Copyright © 2019 Blockchain Luxembourg S.A. All rights reserved.
//

import BigInt
import PlatformKit
import RxSwift
import web3swift

public enum EthereumTransactionSignerError: Error {
    case mnemonicsError(Error)
    case signingError(Error)
    case keystoreError(Error)
    case incorrectChainId
}

protocol EthereumTransactionSignerAPI {
    
    func sign(
        transaction: EthereumTransactionCandidateCosted,
        nonce: BigUInt,
        keyPair: EthereumKeyPair
    ) -> Result<EthereumTransactionCandidateSigned, EthereumTransactionSignerError>
}

final class EthereumTransactionSigner: EthereumTransactionSignerAPI {
    
    func sign(
        transaction: EthereumTransactionCandidateCosted,
        nonce: BigUInt,
        keyPair: EthereumKeyPair
    ) -> Result<EthereumTransactionCandidateSigned, EthereumTransactionSignerError> {
        
        let mnemonics: Mnemonics
        do {
            mnemonics = try Mnemonics(keyPair.privateKey.mnemonic)
        } catch {
            return .failure(.mnemonicsError(error))
        }
        
        let keystore: BIP32Keystore
        do {
            keystore = try BIP32Keystore(
                mnemonics: mnemonics,
                password: keyPair.privateKey.password,
                prefixPath: HDNode.defaultPathMetamaskPrefix
            )
        } catch {
            return .failure(.keystoreError(error))
        }
        
        let account: web3swift.Address = web3swift.Address(keyPair.accountID)
        let password: String = keyPair.privateKey.password
        var transaction = transaction.transaction
        
        guard transaction.intrinsicChainID == NetworkId.mainnet.rawValue else {
            return .failure(.incorrectChainId)
        }
        
        transaction.nonce = nonce
        
        do {
            try Web3Signer.signTX(transaction: &transaction, keystore: keystore, account: account, password: password)
        } catch {
            return .failure(.signingError(error))
        }
        
        print("transaction: \(transaction)")
        
        // swiftlint:disable force_try
        return .success(try! EthereumTransactionCandidateSigned(transaction: transaction))
        // swiftlint:enable force_try
    }
}

extension web3swift.EthereumTransaction {
    public init(nonce: BigUInt, gasPrice: BigUInt, gasLimit: BigUInt, to: Address, value: BigUInt, data: Data) {
        self.init(
            gasPrice: gasPrice,
            gasLimit: gasLimit,
            to: to,
            value: value,
            data: data
        )
        self.nonce = nonce
    }
}
