//
//  SendConfirmationModalConfigurationBuilder.swift
//  Tonkeeper
//
//  Created by Grigory on 5.6.23..
//

import Foundation

struct SendConfirmationModalConfigurationBuilder {
  static func configuration(title: String,
                            image: Image,
                            recipient: String? = nil,
                            recipientAddress: String,
                            amount: String,
                            fiatAmount: String?,
                            fee: String,
                            fiatFee: String?,
                            comment: String? = nil,
                            showActivity: Bool = true,
                            tapAction: (( @escaping (Bool) -> Void ) -> Void)? = nil,
                            completion: ((Bool) -> Void)? = nil
  ) -> ModalContentViewController.Configuration {
    let header = ModalContentViewController.Configuration.Header(
      image: image,
      title: title,
      topDescription: .description
    )
    
    var listItems: [ModalContentViewController.Configuration.ListItem] = [
      .init(left: .recipientAddressTitle, rightTop: recipientAddress, rightBottom: nil),
      .init(left: .amountTitle, rightTop: amount, rightBottom: fiatAmount),
      .init(left: .feeTitle, rightTop: fee, rightBottom: fiatFee)
    ]
    
    if let recipient = recipient {
      listItems.insert(.init(left: .recipientTitle, rightTop: recipient, rightBottom: nil), at: 0)
    }
    
    if let comment = comment {
      listItems.append(.init(left: .commentTitle, rightTop: comment, rightBottom: nil))
    }
    
    let buttons = ModalContentViewController.Configuration.ActionBar.Button(
      title: .buttonTitle,
      configuration: .primaryLarge,
      tapAction: tapAction,
      showActivityClosure: { showActivity },
      completion: completion
    )
    
    let actionBarItems: [ModalContentViewController.Configuration.ActionBar.Item] = [
      .buttons([buttons])
    ]
    
    let actionBar = ModalContentViewController.Configuration.ActionBar(items: actionBarItems)
    
    let configuration = ModalContentViewController.Configuration(
      header: header,
      listItems: listItems,
      actionBar: actionBar)
    
    return configuration
  }
}

private extension String {
  static let description = "Confirm action"
  static let recipientTitle = "Recipient"
  static let recipientAddressTitle = "Recipient address"
  static let amountTitle = "Amount"
  static let feeTitle = "Fee"
  static let commentTitle = "Comment"
  static let buttonTitle = "Confirm and send"
}
