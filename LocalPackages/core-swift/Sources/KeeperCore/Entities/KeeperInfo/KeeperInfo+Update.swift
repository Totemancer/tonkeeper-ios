import Foundation

// MARK: - Wallet

extension KeeperInfo {

  func updateWallets(_ wallets: [Wallet]) -> KeeperInfo {
    KeeperInfo(
      wallets: wallets,
      currentWallet: self.currentWallet,
      currency: self.currency,
      securitySettings: self.securitySettings,
      appSettings: self.appSettings,
      country: country,
      assetsPolicy: self.assetsPolicy,
      appCollection: self.appCollection
    )
  }
  
  func updateActiveWallet(_ wallet: Wallet) -> KeeperInfo {
    KeeperInfo(
      wallets: wallets,
      currentWallet: wallet,
      currency: self.currency,
      securitySettings: self.securitySettings,
      appSettings: self.appSettings,
      country: country,
      assetsPolicy: self.assetsPolicy,
      appCollection: self.appCollection
    )
  }
  
  func updateWallets(_ wallets: [Wallet],
                     activeWallet: Wallet) -> KeeperInfo {
    KeeperInfo(
      wallets: wallets,
      currentWallet: activeWallet,
      currency: self.currency,
      securitySettings: self.securitySettings,
      appSettings: self.appSettings,
      country: country,
      assetsPolicy: self.assetsPolicy,
      appCollection: self.appCollection
    )
  }
  
  // MARK: - Wallet Parameters
  
  func updateWallet(_ wallet: Wallet,
                    metaData: WalletMetaData) -> (keeperInfo: KeeperInfo, wallet: Wallet) {
    let updatedWallet = Wallet(
      id: wallet.id,
      identity: wallet.identity,
      metaData: metaData,
      setupSettings: wallet.setupSettings,
      notificationSettings: wallet.notificationSettings,
      backupSettings: wallet.backupSettings,
      addressBook: wallet.addressBook
    )
    return (updateWallet(updatedWallet), updatedWallet)
  }
  
  func updateWallet(_ wallet: Wallet,
                    setupSettings: WalletSetupSettings) -> (keeperInfo: KeeperInfo, wallet: Wallet) {
    let updatedWallet = Wallet(
      id: wallet.id,
      identity: wallet.identity,
      metaData: wallet.metaData,
      setupSettings: setupSettings,
      notificationSettings: wallet.notificationSettings,
      backupSettings: wallet.backupSettings,
      addressBook: wallet.addressBook
    )
    return (updateWallet(updatedWallet), updatedWallet)
  }
  
  func updateWallet(_ wallet: Wallet,
                    notificationSettings: NotificationSettings) -> (keeperInfo: KeeperInfo, wallet: Wallet) {
    let updatedWallet = Wallet(
      id: wallet.id,
      identity: wallet.identity,
      metaData: wallet.metaData,
      setupSettings: wallet.setupSettings,
      notificationSettings: notificationSettings,
      backupSettings: wallet.backupSettings,
      addressBook: wallet.addressBook
    )
    return (updateWallet(updatedWallet), updatedWallet)
  }
  
  func deleteWallet(_ wallet: Wallet) -> KeeperInfo? {
    guard let walletIndex = wallets.firstIndex(of: wallet) else {
      return self
    }
    var updatedWallets = wallets
    updatedWallets.remove(at: walletIndex)
    
    guard !updatedWallets.isEmpty else { return nil }
    
    var updatedKeeperInfo = updateWallets(updatedWallets)
    if updatedWallets.isEmpty {
      return nil
    } else if currentWallet == wallet {
      updatedKeeperInfo = updatedKeeperInfo.updateActiveWallet(updatedWallets[0])
    }
    return updatedKeeperInfo
  }
  
  func moveWallet(fromIndex: Int, toIndex: Int) -> KeeperInfo {
    guard fromIndex < wallets.count,
          fromIndex >= 0,
          toIndex < wallets.count,
          toIndex >= 0 else {
      return self
    }
    var updatedWallets = wallets
    let wallet = updatedWallets.remove(at: fromIndex)
    updatedWallets.insert(wallet, at: toIndex)
    
    return updateWallets(updatedWallets)
  }
  
  // MARK: - Currency
  
  func updateCurrency(_ currency: Currency) -> KeeperInfo {
    KeeperInfo(
      wallets: self.wallets,
      currentWallet: self.currentWallet,
      currency: currency,
      securitySettings: self.securitySettings,
      appSettings: self.appSettings,
      country: self.country,
      assetsPolicy: self.assetsPolicy,
      appCollection: self.appCollection
    )
  }

  func updateRegion(_ region: SelectedCountry) -> KeeperInfo {
    KeeperInfo(
      wallets: self.wallets,
      currentWallet: self.currentWallet,
      currency: currency,
      securitySettings: self.securitySettings,
      appSettings: self.appSettings,
      country: region,
      assetsPolicy: self.assetsPolicy,
      appCollection: self.appCollection
    )
  }

  func updateSearchEngine(_ searchEngine: SearchEngine) -> KeeperInfo {
    let appSettings = AppSettings(
      isSecureMode: self.appSettings.isSecureMode,
      searchEngine: searchEngine
    )
    return KeeperInfo(
      wallets: self.wallets,
      currentWallet: self.currentWallet,
      currency: currency,
      securitySettings: self.securitySettings,
      appSettings: appSettings,
      country: self.country,
      assetsPolicy: self.assetsPolicy,
      appCollection: self.appCollection
    )
  }

  // MARK: - SecuritySettings
  
  func updateIsBiometryEnable(_ isBiometryEnable: Bool) -> KeeperInfo {
    let securitySettings = SecuritySettings(
      isBiometryEnabled: isBiometryEnable,
      isLockScreen: securitySettings.isLockScreen
    )
    return updateSecuritySettings(securitySettings)
  }
  
  func updateIsLockScreen(_ isLockScreen: Bool) -> KeeperInfo {
    let securitySettings = SecuritySettings(
      isBiometryEnabled: securitySettings.isBiometryEnabled,
      isLockScreen: isLockScreen
    )
    return updateSecuritySettings(securitySettings)
  }
  
  // MARK: - Settings
  
  func updateIsSetupFinished(_ isSetupFinished: Bool) -> KeeperInfo {
    let appSettings = AppSettings(
      isSecureMode: self.appSettings.isSecureMode,
      searchEngine: self.appSettings.searchEngine
    )
    
    return KeeperInfo(
      wallets: self.wallets,
      currentWallet: self.currentWallet,
      currency: self.currency,
      securitySettings: self.securitySettings,
      appSettings: appSettings,
      country: country,
      assetsPolicy: self.assetsPolicy,
      appCollection: self.appCollection
    )
  }
  
  func updateIsSecureMode(_ isSecureMode: Bool) -> KeeperInfo {
    let appSettings = AppSettings(
      isSecureMode: isSecureMode,
      searchEngine: self.appSettings.searchEngine
    )
    
    return KeeperInfo(
      wallets: self.wallets,
      currentWallet: self.currentWallet,
      currency: self.currency,
      securitySettings: self.securitySettings,
      appSettings: appSettings,
      country: country,
      assetsPolicy: self.assetsPolicy,
      appCollection: self.appCollection
    )
  }
  
  // MARK: - Notifications
  
  func updateWallet(_ wallet: Wallet,
                    notificationsIsOn: Bool) -> KeeperInfo {
    let notificationSettings = NotificationSettings(
      isOn: notificationsIsOn
    )
    return updateWallet(wallet, notificationSettings: notificationSettings).keeperInfo
  }
  
  // MARK: - Private
  
  private func updateWallet(_ wallet: Wallet) -> KeeperInfo {
    guard let walletIndex = wallets.firstIndex(of: wallet) else {
      return self
    }
    var updatedWallets = wallets
    updatedWallets.remove(at: walletIndex)
    updatedWallets.insert(wallet, at: walletIndex)
    
    var updatedKeeperInfo = updateWallets(updatedWallets)
    if currentWallet == wallet {
      updatedKeeperInfo = updatedKeeperInfo.updateActiveWallet(wallet)
    }
    return updatedKeeperInfo
  }
  
  func updateSecuritySettings(_ securitySettings: SecuritySettings) -> KeeperInfo {
    KeeperInfo(
      wallets: self.wallets,
      currentWallet: self.currentWallet,
      currency: self.currency,
      securitySettings: securitySettings,
      appSettings: self.appSettings,
      country: country,
      assetsPolicy: self.assetsPolicy,
      appCollection: self.appCollection
    )
  }
  
  func updateAppSettings(_ appSettings: AppSettings) -> KeeperInfo {
    KeeperInfo(
      wallets: self.wallets,
      currentWallet: self.currentWallet,
      currency: self.currency,
      securitySettings: self.securitySettings,
      appSettings: appSettings,
      country: country,
      assetsPolicy: self.assetsPolicy,
      appCollection: self.appCollection
    )
  }
}
