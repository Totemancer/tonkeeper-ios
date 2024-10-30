import UIKit
import TKUIKit
import TKCore
import KeeperCore
import TKLocalize
import StoreKit

protocol BatteryRefillTransactionsSettingsModuleOutput: AnyObject {
  
}

protocol BatteryRefillTransactionsSettingsModuleInput: AnyObject {
  
}

protocol BatteryRefillTransactionsSettingsViewModel: AnyObject {
  var didUpdateSnapshot: ((BatteryRefillTransactionsSettings.Snapshot) -> Void)? { get set }
  
  func viewDidLoad()
}

final class BatteryRefillTransactionsSettingsViewModelImplementation: BatteryRefillTransactionsSettingsViewModel, BatteryRefillTransactionsSettingsModuleOutput, BatteryRefillTransactionsSettingsModuleInput {
  
  // MARK: - BatteryRefillTransactionsSettingsViewModel
  
  var didUpdateSnapshot: ((BatteryRefillTransactionsSettings.Snapshot) -> Void)?
  var didUpdateTitleView: ((TKUINavigationBarTitleView.Model) -> Void)?
  
  func viewDidLoad() {
    let batterySettins = keeperInfoStore.getState()?.batterySettings ?? BatterySettings()
    let snapshot = createSnapshot(configuration: configuration, batterySettings: batterySettins)
    didUpdateSnapshot?(snapshot)
  }
  
  private let configuration: Configuration
  private let keeperInfoStore: KeeperInfoStore
  
  init(configuration: Configuration,
       keeperInfoStore: KeeperInfoStore) {
    self.configuration = configuration
    self.keeperInfoStore = keeperInfoStore
  }
  
  private func createSnapshot(configuration: Configuration,
                              batterySettings: BatterySettings) -> BatteryRefillTransactionsSettings.Snapshot {
    var snapshot = BatteryRefillTransactionsSettings.Snapshot()
    
    snapshot.appendSections([.title])
    snapshot.appendItems([.title(
      TKTitleDescriptionCell.Configuration(
      model: TKTitleDescriptionView.Model(
        title: "Battery Settings",
        bottomDescription: "Selected transactions will be paid by Tonkeeper Battery."), 
      padding: NSDirectionalEdgeInsets(top: 0,
                                       leading: 32,
                                       bottom: 16,
                                       trailing: 32)))],
                         toSection: .title)
    
    snapshot.appendSections([.listItems])
    let items = BatterySupportedTransaction.allCases.map { transaction in
      
      let transactionPrice: NSDecimalNumber? = {
        switch transaction {
        case .swap:
          return configuration.batteryMeanFeesPriceSwapDecimaNumber
        case .jetton:
          return configuration.batteryMeanFeesPriceJettonDecimaNumber
        case .nft:
          return configuration.batteryMeanFeesPriceNFTDecimaNumber
        }
      }()
      
      let chargesCount = calculateChargesAmount(transactionPrice: transactionPrice, fee: configuration.batteryMeanFeesDecimaNumber)
      let caption = transaction.caption(chargesCount: chargesCount)
      let cellConfiguration = TKListItemCell.Configuration(
        listItemContentViewConfiguration: TKListItemContentView.Configuration(
          textContentViewConfiguration: TKListItemTextContentView.Configuration(
            titleViewConfiguration: TKListItemTitleView.Configuration(title: transaction.name),
            captionViewsConfigurations: [
              TKListItemTextView.Configuration(text: caption, color: .Text.secondary, textStyle: .body2, numberOfLines: 0)
            ]
          )
        )
      )
      
      let isOn: Bool = {
        switch transaction {
        case .swap:
          batterySettings.isSwapTransactionEnable
        case .jetton:
          batterySettings.isJettonTransactionEnable
        case .nft:
          batterySettings.isNFTTransactionEnable
        }
      }()
      
      let snapshotItem = BatteryRefillTransactionsSettings.SnapshotItem.listItem(
        BatteryRefillTransactionsSettings.ListItem(
          identifier: transaction.rawValue,
          accessory: .switch(
            TKListItemSwitchAccessoryView.Configuration(
              isOn: isOn,
              action: { [weak self] isOn in
                self?.setTransaction(transaction, isOn: isOn)
              }
            )
          ),
          cellConfiguration: cellConfiguration
        )
      )
      return snapshotItem
    }
    snapshot.appendItems(items, toSection: .listItems)
    
    return snapshot
  }
  
  private func setTransaction(_ transaction: BatterySupportedTransaction, isOn: Bool) {
    keeperInfoStore.updateState({ keeperInfo in
      guard let keeperInfo else { return nil }
      let batterySettings = {
        switch transaction {
        case .swap:
          keeperInfo.batterySettings.setIsSwapTransactionEnable(isEnable: isOn)
        case .jetton:
          keeperInfo.batterySettings.setIsJettonTransactionEnable(isEnable: isOn)
        case .nft:
          keeperInfo.batterySettings.setIsNFTTransactionEnable(isEnable: isOn)
        }
      }()
      return KeeperInfoStore.StateUpdate(newState: keeperInfo.updateBatterySettings(batterySettings))
    }, completion: nil)
  }
  
  private func calculateChargesAmount(transactionPrice: NSDecimalNumber?, fee: NSDecimalNumber?) -> Int {
    guard let transactionPrice, let fee else { return 0 }
    return transactionPrice
      .dividing(by: fee, withBehavior: NSDecimalNumberHandler.dividingRoundBehaviour)
      .rounding(accordingToBehavior: NSDecimalNumberHandler.roundBehaviour)
      .intValue
  }
}

private extension NSDecimalNumberHandler {
  static var dividingRoundBehaviour: NSDecimalNumberHandler {
    return NSDecimalNumberHandler(
      roundingMode: .plain,
      scale: 20,
      raiseOnExactness: false,
      raiseOnOverflow: false,
      raiseOnUnderflow: false,
      raiseOnDivideByZero: false
    )
  }
  
  static var roundBehaviour: NSDecimalNumberHandler {
    return NSDecimalNumberHandler(
      roundingMode: .plain,
      scale: 0,
      raiseOnExactness: false,
      raiseOnOverflow: false,
      raiseOnUnderflow: false,
      raiseOnDivideByZero: false
    )
  }
}