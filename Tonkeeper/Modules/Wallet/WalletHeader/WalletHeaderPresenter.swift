//
//  WalletHeaderPresenter.swift
//  Tonkeeper
//
//  Created by Grigory on 25.5.23..
//

import Foundation

final class WalletHeaderPresenter {
  
  // MARK: - Module
  
  weak var viewInput: WalletHeaderViewInput?
  weak var output: WalletHeaderModuleOutput?
}

// MARK: - WalletHeaderPresenterIntput

extension WalletHeaderPresenter: WalletHeaderPresenterInput {
  func viewDidLoad() {
    let model = WalletHeaderView.Model(balance: "$24,374",
                                       address: "EQF2…G21Z")
    viewInput?.update(with: model)
    
    let buttonModels = createHeaderButtonModels()
    viewInput?.updateButtons(with: buttonModels)
  }
  
  func didTapAddressButton() {}
}

// MARK: - WalletHeaderModuleInput

extension WalletHeaderPresenter: WalletHeaderModuleInput {}

// MARK: - WalletHeaderPresenter

private extension WalletHeaderPresenter {
  func createHeaderButtonModels() -> [WalletHeaderButtonModel] {
    let types: [WalletHeaderButtonModel.ButtonType] = [.buy, .send, .receive, .sell]
    return types.map {
      let buttonModel = Button.Model(icon: $0.icon)
      let iconButtonModel = IconButton.Model(buttonModel: buttonModel, title: $0.title)
      let model = WalletHeaderButtonModel(viewModel: iconButtonModel) {}
      return model
    }
  }
}