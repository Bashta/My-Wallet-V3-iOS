//
//  Accessibility+Backup.swift
//  Blockchain
//
//  Created by AlexM on 2/25/20.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

import PlatformUIKit

extension Accessibility.Identifier {
    
    enum Backup {
        enum IntroScreen {
            private static let prefix = "BackupFundsIntroScreen."
            static let titleLabel = "\(prefix)descriptionLabel"
            static let descriptionLabel = "\(prefix)descriptionLabel"
            static let secondaryDescriptionLabel = "\(prefix)secondaryDescriptionLabel"
            static let nextButton = "\(prefix)nextButton"
        }
        
        enum RecoveryPhrase {
            private static let prefix = "RecoveryPhraseScreen."
            static let titleLabel = "\(prefix)titleLabel"
            static let subtitleLabel = "\(prefix)subtitleLabel"
            static let descriptionLabel = "\(prefix)descriptionLabel"
            static let clipboardButton = "\(prefix)clipboardButton"
            
            enum View {
                private static let prefix = "RecoveryPhraseScreen.View."
                static let word = "\(prefix)word"
            }
        }
        
        enum VerifyBackup {
            private static let prefix = "VerifyBackupScreen."
            static let descriptionLabel = "\(prefix)descriptionLabel"
            static let firstNumberLabel = "\(prefix)firstNumberLabel"
            static let secondNumberLabel = "\(prefix)secondNumberLabel"
            static let thirdNumberLabel = "\(prefix)thirdNumberLabel"
            static let errorLabel = "\(prefix)errorLabel"
            static let verifyBackupButton = "\(prefix)verifyBackupButton"
        }
    }
}

