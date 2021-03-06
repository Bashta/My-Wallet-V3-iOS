/*
 * 
 * Copyright (c) 2012, Ben Reeves. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301  USA
 */

#import <UIKit/UIKit.h>
#import "BCAddressSelectionView.h"
#import "BCConfirmPaymentView.h"
#import "BCLine.h"
#import "FeeTypes.h"
#import "QRCodeScannerSendViewController.h"
#import "Assets.h"
#import "DestinationAddressSource.h"

@class Wallet;

@interface SendBitcoinViewController : QRCodeScannerSendViewController <AddressSelectionDelegate>

// Must be a Bitcoin fork
@property (nonatomic, assign) LegacyAssetType assetType;
@property (nonatomic, assign, readonly) DestinationAddressSource addressSource;
@property (nonatomic, assign) BOOL surgeIsOccurring;

- (BOOL)transferAllMode;

- (IBAction)selectFromAddressClicked:(id)sender;
- (IBAction)addressBookClicked:(id)sender;
- (IBAction)closeKeyboardClicked:(id)sender;
- (IBAction)feeOptionsClicked:(UIButton *)sender;

- (void)selectFromAddress:(NSString *)address;
- (void)selectToAddress:(NSString *)address;
- (void)selectFromAccount:(int)account;
- (void)selectToAccount:(int)account;

- (void)updateSendBalance:(NSNumber *)balance fees:(NSDictionary *)fees;

- (IBAction)sendPaymentClicked:(id)sender;
- (IBAction)labelAddressClicked:(id)sender;
- (IBAction)useAllClicked:(id)sender;

- (void)setAmountStringFromBitPayURL:(NSURL *)bitpayURL;
- (void)setAmountStringFromUrlHandler:(NSString*)amountString withToAddress:(NSString*)string;

- (void)didCheckForOverSpending:(NSNumber *)amount fee:(NSNumber *)fee;
- (void)didGetMaxFee:(NSNumber *)fee amount:(NSNumber *)amount dust:(NSNumber *)dust willConfirm:(BOOL)willConfirm;
- (void)didUpdateTotalAvailable:(NSNumber *)sweepAmount finalFee:(NSNumber *)finalFee;
- (void)didGetFee:(NSNumber *)fee dust:(NSNumber *)dust txSize:(NSNumber *)txSize;
- (void)didChangeSatoshiPerByte:(NSNumber *)sweepAmount fee:(NSNumber *)fee dust:(NSNumber *)dust updateType:(FeeUpdateType)updateType;

- (void)setupTransferAll;
- (void)getInfoForTransferAllFundsToDefaultAccount;
- (void)transferFundsToDefaultAccountFromAddress:(NSString *)address;
- (void)updateTransferAllAmount:(NSNumber *)amount fee:(NSNumber *)fee addressesUsed:(NSArray *)addressesUsed;
- (void)showSummaryForTransferAll;
- (void)sendDuringTransferAll:(NSString *)secondPassword;
- (void)didErrorDuringTransferAll:(NSString *)error secondPassword:(NSString *)secondPassword;

- (void)reload;
- (void)reloadAfterMultiAddressResponse;
- (void)reloadSymbols;
- (void)reloadFeeAmountLabel;
- (void)resetFromAddress;

- (void)hideKeyboard;
- (void)hideKeyboardForced;

- (void)enablePaymentButtons;

- (void)hideSelectFromAndToButtonsIfAppropriate;
// Called on manual logout
- (void)clearToAddressAndAmountFields;

@end
