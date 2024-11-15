import UIKit
import TKUIKit
import TKLocalize
import TKCore
import KeeperCore
import BigInt

struct ManageTokensListMapper {
    
  private let amountFormatter: AmountFormatter
  
  init(amountFormatter: AmountFormatter) {
    self.amountFormatter = amountFormatter
  }
  
  func mapTonItem(_ item: BalanceTonItemModel) -> TKListItemCell.Configuration {
    let amount = amountFormatter.formatAmount(
      item.amount,
      fractionDigits: item.fractionalDigits,
      maximumFractionDigits: 2,
      symbol: TonInfo.symbol
    )
    
    return TKListItemCell.Configuration(
      listItemContentViewConfiguration: TKListItemContentView.Configuration(
        iconViewConfiguration: .tonConfiguration(),
        textContentViewConfiguration: TKListItemTextContentView.Configuration(
          titleViewConfiguration: TKListItemTitleView.Configuration(title: TonInfo.symbol),
        captionViewsConfigurations: [
          TKListItemTextView.Configuration(text: amount, color: .Text.secondary, textStyle: .body2)
        ])
      )
    )
  }
  
  func mapJettonItem(_ item: BalanceJettonItemModel) -> TKListItemCell.Configuration {
    let amount = amountFormatter.formatAmount(
      item.amount,
      fractionDigits: item.fractionalDigits,
      maximumFractionDigits: 2,
      symbol: item.jetton.jettonInfo.symbol
    )
    
    return TKListItemCell.Configuration(
      listItemContentViewConfiguration: TKListItemContentView.Configuration(
        iconViewConfiguration: .configuration(jettonInfo: item.jetton.jettonInfo),
        textContentViewConfiguration: TKListItemTextContentView.Configuration(
          titleViewConfiguration: TKListItemTitleView.Configuration(title: item.jetton.jettonInfo.symbol ?? item.jetton.jettonInfo.name),
        captionViewsConfigurations: [
          TKListItemTextView.Configuration(text: amount, color: .Text.secondary, textStyle: .body2)
        ])
      )
    )
  }
  
  func mapStakingItem(_ item: BalanceStakingItemModel) -> TKListItemCell.Configuration {
    let amount = amountFormatter.formatAmount(
      BigUInt(item.info.amount),
      fractionDigits: TonInfo.fractionDigits,
      maximumFractionDigits: 2,
      symbol: TonInfo.symbol
    )
    
    return TKListItemCell.Configuration(
      listItemContentViewConfiguration: TKListItemContentView.Configuration(
        iconViewConfiguration: .configuration(poolInfo: item.poolInfo),
        textContentViewConfiguration: TKListItemTextContentView.Configuration(
          titleViewConfiguration: TKListItemTitleView.Configuration(title: item.poolInfo?.name ?? ""),
        captionViewsConfigurations: [
          TKListItemTextView.Configuration(text: amount, color: .Text.secondary, textStyle: .body2)
        ])
      )
    )
  }
}
