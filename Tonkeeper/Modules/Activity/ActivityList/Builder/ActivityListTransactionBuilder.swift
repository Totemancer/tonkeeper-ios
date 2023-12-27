//
//  ActivityListTransactionBuilder.swift
//  Tonkeeper
//
//  Created by Grigory on 7.6.23..
//

import Foundation
import UIKit
import WalletCoreKeeper

struct ActivityListTransactionBuilder {
  private let accountEventActionContentProvider: AccountEventActionContentProvider
  
  init(accountEventActionContentProvider: AccountEventActionContentProvider) {
    self.accountEventActionContentProvider = accountEventActionContentProvider
  }
  
  func buildTransactionModel(type: ActivityEventViewModel.ActionViewModel.ActionType,
                             subtitle: String?,
                             amount: String?,
                             subamount: String?,
                             time: String?,
                             status: String?,
                             comment: String? = nil,
                             description: String? = nil,
                             collectible: ActivityEventViewModel.ActionViewModel.CollectibleViewModel? = nil) -> TransactionCellContentView.Model {
    let textContentModel = DefaultCellTextContentView.Model(
      title: accountEventActionContentProvider.title(actionType: type),
      amount: amount?.attributed(with: .label1, alignment: .right, color: type.amountColor),
      subamount: subamount?.attributed(with: .label1, alignment: .right, color: type.subamountColor),
      topLeftDescriptionValue: subtitle,
      topLeftDescriptionSubvalue: nil,
      topRightDescriptionValue: time
    )
    let contentModel = DefaultCellContentView.Model(
      textContentModel: textContentModel,
      image: .image(type.icon, tinColor: .Icon.secondary, backgroundColor: .Background.contentTint)
    )
    var statusModel: TransactionCellContentView.TransactionCellStatusView.Model?
    if let status = status {
      statusModel = .init(status: status.attributed(with: .body2, color: .Accent.orange))
    }
    
    var commentModel: TransactionCellContentView.TransactionCellCommentView.Model?
    if let comment = comment, !comment.isEmpty {
      commentModel = .init(comment: comment.attributed(with: .body2, color: .Text.primary))
    }
    
    var descriptionModel: TransactionCellContentView.TransactionCellCommentView.Model?
    if let description = description, !description.isEmpty {
      descriptionModel = .init(comment: description.attributed(with: .body2, color: .Text.primary))
    }
    
    var nftModel: TransactionCellContentView.TransactionCellNFTView.Model?
    if let collectible = collectible {
      nftModel = .init(image: .with(image: collectible.image), name: collectible.name, collectionName: collectible.collectionName)
    }
    
    let transactionModel = TransactionCellContentView.Model(
      defaultContentModel: contentModel,
      statusModel: statusModel,
      commentModel: commentModel,
      descriptionModel: descriptionModel,
      nftModel: nftModel)
    
    return transactionModel
  }
}

extension ActivityEventViewModel.ActionViewModel.ActionType {
  var icon: UIImage? {
    switch self {
    case .sent:
      return .Icons.Transaction.sent
    case .receieved:
      return .Icons.Transaction.receieved
    case .mint:
      return .Icons.Transaction.receieved
    case .burn:
      return .Icons.Transaction.sent
    case .depositStake:
      return .Icons.Transaction.sent
    case .withdrawStake:
      return .Icons.Transaction.sent
    case .withdrawStakeRequest:
      return .Icons.Transaction.receieved
    case .jettonSwap:
      return .Icons.Transaction.swap
    case .spam:
      return .Icons.Transaction.spam
    case .bounced:
      return .Icons.Transaction.bounced
    case .subscribed:
      return .Icons.Transaction.subscribed
    case .unsubscribed:
      return .Icons.Transaction.unsubscribed
    case .walletInitialized:
      return .Icons.Transaction.walletInitialized
    case .contractExec:
      return .Icons.Transaction.smartContractExec
    case .nftCollectionCreation:
      return .Icons.Transaction.nftCollectionCreation
    case .nftCreation:
      return .Icons.Transaction.nftCreation
    case .removalFromSale:
      return .Icons.Transaction.removalFromSale
    case .nftPurchase:
      return .Icons.Transaction.nftPurchase
    case .bid:
      return .Icons.Transaction.bid
    case .putUpForAuction:
      return .Icons.Transaction.putUpForAuction
    case .endOfAuction:
      return .Icons.Transaction.endOfAuction
    case .putUpForSale:
      return .Icons.Transaction.putUpForSale
    case .domainRenew:
      return .Icons.Transaction.smartContractExec
    }
  }
  
  var amountColor: UIColor {
    switch self {
    case .sent,
        .depositStake,
        .subscribed,
        .unsubscribed,
        .walletInitialized,
        .nftCollectionCreation,
        .nftCreation,
        .removalFromSale,
        .nftPurchase, 
        .bid,
        .putUpForAuction,
        .endOfAuction,
        .contractExec,
        .putUpForSale,
        .burn,
        .domainRenew:
      return .Text.primary
    case .receieved, .bounced, .mint, .withdrawStake, .jettonSwap:
      return .Accent.green
    case .spam, .withdrawStakeRequest:
      return .Text.tertiary
    }
  }
  
  var subamountColor: UIColor {
    switch self {
    case .jettonSwap:
      return .Text.primary
    default:
      return .Text.primary
    }
  }
}
