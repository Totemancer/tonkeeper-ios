//
//  AccountEventActionContentProvider.swift
//  Tonkeeper
//
//  Created by Grigory Serebryanyy on 31.10.2023.
//

import Foundation
import WalletCoreKeeper

protocol AccountEventActionContentProvider {
  func title(actionType: ActivityEventViewModel.ActionViewModel.ActionType) -> String?
}

struct ActivityListAccountEventActionContentProvider: AccountEventActionContentProvider {
  func title(actionType: ActivityEventViewModel.ActionViewModel.ActionType) -> String? {
    switch actionType {
    case .sent:
      return "Sent"
    case .receieved:
      return "Received"
    case .mint:
      return "Received"
    case .burn:
      return "Sent"
    case .depositStake:
      return "Stake"
    case .withdrawStake:
      return "Unstake"
    case .withdrawStakeRequest:
      return "Unstake Request"
    case .jettonSwap:
      return "Swap"
    case .spam:
      return "Spam"
    case .bounced:
      return "Bounced"
    case .subscribed:
      return "Received"
    case .unsubscribed:
      return "Unsubscribed"
    case .walletInitialized:
      return "Wallet initialized"
    case .contractExec:
      return "Call contract"
    case .nftCollectionCreation:
      return "NFT сollection creation"
    case .nftCreation:
      return "NFT creation"
    case .removalFromSale:
      return "Removal from sale"
    case .nftPurchase:
      return "NFT purchase"
    case .bid:
      return "Bid"
    case .putUpForAuction:
      return "Put up for auction"
    case .endOfAuction:
      return "End of auction"
    case .putUpForSale:
      return "Put up for sale"
    case .domainRenew:
      return "Domain Renew"
    }
  }
}

struct TonConnectConfirmationAccountEventActionContentProvider: AccountEventActionContentProvider {
  func title(actionType: ActivityEventViewModel.ActionViewModel.ActionType) -> String? {
    switch actionType {
    case .sent:
      return "Send"
    case .receieved:
      return "Receive"
    case .mint:
      return "Receive"
    case .burn:
      return "Send"
    case .depositStake:
      return "Stake"
    case .withdrawStake:
      return "Unstake"
    case .withdrawStakeRequest:
      return "Unstake Request"
    case .jettonSwap:
      return "Swap"
    case .spam:
      return "Spam"
    case .bounced:
      return "Bounce"
    case .subscribed:
      return "Receive"
    case .unsubscribed:
      return "Unsubscribe"
    case .walletInitialized:
      return "Wallet initialize"
    case .contractExec:
      return "Call contract"
    case .nftCollectionCreation:
      return "NFT сollection creation"
    case .nftCreation:
      return "NFT creation"
    case .removalFromSale:
      return "Removal from sale"
    case .nftPurchase:
      return "NFT purchase"
    case .bid:
      return "Bid"
    case .putUpForAuction:
      return "Put up for auction"
    case .endOfAuction:
      return "End of auction"
    case .putUpForSale:
      return "Put up for sale"
    case .domainRenew:
      return "Renew Domain"
    }
  }
}
