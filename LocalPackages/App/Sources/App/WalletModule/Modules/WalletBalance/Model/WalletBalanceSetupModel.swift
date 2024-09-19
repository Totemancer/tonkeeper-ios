import Foundation
import KeeperCore

final class WalletBalanceSetupModel {
  struct State {
    enum Item: String {
      case notifications
      case telegramChannel
      case backup
      case biometry
    }
    
    let wallet: Wallet
    let isFinishEnable: Bool
    let items: [Item]
  }
  
  private let syncQueue = DispatchQueue(label: "WalletBalanceSetupModelQueue")
  
  var didUpdateState: ((State?) -> Void)?
  
  private let walletsStore: WalletsStore
  private let appSettingsStore: AppSettingsV3Store
  private let securityStore: SecurityStore
  private let walletNotificationStore: WalletNotificationStore
  private let mnemonicsRepository: MnemonicsRepository
  
  init(walletsStore: WalletsStore,
       appSettingsStore: AppSettingsV3Store,
       securityStore: SecurityStore,
       walletNotificationStore: WalletNotificationStore,
       mnemonicsRepository: MnemonicsRepository) {
    self.walletsStore = walletsStore
    self.appSettingsStore = appSettingsStore
    self.securityStore = securityStore
    self.walletNotificationStore = walletNotificationStore
    self.mnemonicsRepository = mnemonicsRepository
    
    walletsStore.addObserver(self) { observer, event in
      observer.didGetWalletsStoreEvent(event)
    }
    
    appSettingsStore.addObserver(self) { observer, event in
      observer.didGetAppSettingsStoreEvent(event)
    }
    
    securityStore.addObserver(self) { observer, event in
      observer.didGetSecurityStoreEvent(event)
    }
   
    walletNotificationStore.addObserver(self) { observer, event in
      observer.didGetWalletNotificationStoreEvent(event)
    }
  }
  
  func getState() -> State? {
    guard let wallet = try? walletsStore.getActiveWallet() else {
      return nil
    }
    let isSetupFinished = appSettingsStore.getState().isSetupFinished
    let isBiometryEnable = securityStore.getState().isBiometryEnable
    let isNotificationsOn = walletNotificationStore.getState()[wallet] ?? false
    return calculateState(
      wallet: wallet,
      isSetupFinished: isSetupFinished,
      isBiometryEnable: isBiometryEnable,
      isNotificationsOn: isNotificationsOn
    )
  }
  
  func finishSetup() {
    Task {
      await appSettingsStore.setIsSetupFinished(true)
    }
  }
  
  func turnOnBiometry(passcode: String) throws {
    Task {
      try mnemonicsRepository.savePassword(passcode)
      await self.securityStore.setIsBiometryEnable(true)
    }
  }
  
  func turnOffBiometry() throws {
    Task {
      try self.mnemonicsRepository.deletePassword()
      await self.securityStore.setIsBiometryEnable(false)
    }
  }
  
  func turnOnNotifications() async {
    guard let wallet = try? await walletsStore.getActiveWallet() else { return }
    await self.walletNotificationStore.setNotificationIsOn(true, wallet: wallet)
  }
  
  private func didGetWalletsStoreEvent(_ event: WalletsStore.Event) {
    syncQueue.async {
      switch event {
      case .didChangeActiveWallet:
        self.updateState()
      case .didUpdateWalletSetupSettings:
        self.updateState()
      default: break
      }
    }
  }
  
  private func didGetAppSettingsStoreEvent(_ event: AppSettingsV3Store.Event) {
    syncQueue.async {
      switch event {
      case .didUpdateIsSetupFinished:
        self.updateState()
      default: break
      }
    }
  }
  
  private func didGetSecurityStoreEvent(_ event: SecurityStore.Event) {
    syncQueue.async {
      switch event {
      case .didUpdateIsBiometryEnabled:
        self.updateState()
      default: break
      }
    }
  }
  
  private func didGetWalletNotificationStoreEvent(_ event: WalletNotificationStore.Event) {
    syncQueue.async {
      switch event {
      case .didUpdateNotificationsIsOn:
        self.updateState()
      }
    }
  }
  
  private func updateState() {
    let walletsStoreState = walletsStore.getState()
    switch walletsStoreState {
    case .empty: break
    case .wallets(let walletsState):
      let isSetupFinished = appSettingsStore.getState().isSetupFinished
      let isBiometryEnable = securityStore.getState().isBiometryEnable
      let isNotificationsOn = walletNotificationStore.getState()[walletsState.activeWalelt] ?? false
      let state = calculateState(
        wallet: walletsState.activeWalelt,
        isSetupFinished: isSetupFinished,
        isBiometryEnable: isBiometryEnable,
        isNotificationsOn: isNotificationsOn
      )
      didUpdateState?(state)
    }
  }
  
  private func calculateState(wallet: Wallet, 
                              isSetupFinished: Bool,
                              isBiometryEnable: Bool,
                              isNotificationsOn: Bool) -> State? {
    if isSetupFinished && (!wallet.isBackupAvailable || wallet.hasBackup)  {
      return nil
    }
    
    var items = [State.Item]()
    
    let isFinishEnable: Bool = {
      !wallet.isBackupAvailable || wallet.setupSettings.backupDate != nil
    }()
    
    if !isNotificationsOn {
      items.append(.notifications)
    }
    
    let isTelegramChannelVisible: Bool = {
      !isSetupFinished
    }()
    if isTelegramChannelVisible {
      items.append(.telegramChannel)
    }
    
    let isBiometryVisible: Bool = {
      !isSetupFinished && wallet.isBiometryAvailable && !isBiometryEnable
    }()
    if isBiometryVisible {
      items.append(.biometry)
    }
    
    let isBackupVisible: Bool = {
      wallet.isBackupAvailable && wallet.setupSettings.backupDate == nil
    }()
    if isBackupVisible {
      items.append(.backup)
    }
    
    let state = State(
      wallet: wallet,
      isFinishEnable: isFinishEnable,
      items: items
    )
    return state
  }
}
