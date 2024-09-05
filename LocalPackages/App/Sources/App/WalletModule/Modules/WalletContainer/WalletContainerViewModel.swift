import Foundation
import TKUIKit
import UIKit
import KeeperCore

protocol WalletContainerModuleOutput: AnyObject {
  var walletButtonHandler: (() -> Void)? { get set }
  var didTapSettingsButton: ((Wallet) -> Void)? { get set }
}

protocol WalletContainerViewModel: AnyObject {
  var didUpdateModel: ((WalletContainerView.Model) -> Void)? { get set }
  
  func viewDidLoad()
  func didTapWalletButton()
}

final class WalletContainerViewModelImplementation: WalletContainerViewModel, WalletContainerModuleOutput {
  
  // MARK: - WalletContainerModuleOutput
  
  var walletButtonHandler: (() -> Void)?
  var didTapSettingsButton: ((Wallet) -> Void)?
  
  // MARK: - WalletContainerViewModel
  
  var didUpdateModel: ((WalletContainerView.Model) -> Void)?
  
  func viewDidLoad() {
    walletsStore.addObserver(self) { observer, event in
      DispatchQueue.main.async {
        switch event {
        case .didChangeActiveWallet(let wallet):
          self.wallet = wallet
        case .didUpdateWalletMetaData(let wallet):
          self.wallet = wallet
        default: break
        }
      }
    }
    setInitialState()
  }
  
  // MARK: - State
  
  private var wallet: Wallet? {
    didSet {
      guard let wallet,
            wallet.metaData != oldValue?.metaData else { return }
      didUpdateModel?(createModel(wallet: wallet))
    }
  }
  
  func didTapWalletButton() {
    walletButtonHandler?()
  }

  // MARK: - Dependencies
  
  private let walletsStore: WalletsStoreV3
  
  // MARK: - Init
  
  init(walletsStore: WalletsStoreV3) {
    self.walletsStore = walletsStore
  }
  
  private func setInitialState() {
    guard let wallet = try? walletsStore.getActiveWallet() else { return }
    self.wallet = wallet
  }
}

private extension WalletContainerViewModelImplementation {
  func createModel(wallet: Wallet) -> WalletContainerView.Model {
    let icon: WalletContainerWalletButton.Model.Icon
    switch wallet.icon {
    case .emoji(let emoji):
      icon = .emoji(emoji)
    case .icon(let image):
      icon = .image(image.image)
    }
    
    let walletButtonConfiguration = WalletContainerWalletButton.Model(
      title: wallet.label,
      icon: icon,
      color: wallet.tintColor.uiColor
    )

    var settingsButtonConfiguration = TKButton.Configuration.accentButtonConfiguration(
      padding: UIEdgeInsets(
        top: 10,
        left: 10,
        bottom: 10,
        right: 10
      )
    )
    settingsButtonConfiguration.content.icon = .TKUIKit.Icons.Size28.gearOutline
    settingsButtonConfiguration.iconTintColor = .Icon.secondary
    settingsButtonConfiguration.action = { [weak self] in
      self?.didTapSettingsButton?(wallet)
    }

    let topBarViewModel = WalletContainerTopBarView.Model(
      walletButtonConfiguration: walletButtonConfiguration,
      settingButtonConfiguration: settingsButtonConfiguration
    )
    return WalletContainerView.Model(
      topBarViewModel: topBarViewModel
    )
  }
}
