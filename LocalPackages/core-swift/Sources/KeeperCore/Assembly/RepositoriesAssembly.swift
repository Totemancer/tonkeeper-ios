import Foundation
import CoreComponents

public struct RepositoriesAssembly {
  
  private let coreAssembly: CoreAssembly
  
  init(coreAssembly: CoreAssembly) {
    self.coreAssembly = coreAssembly
  }
  
  public func mnemonicRepository() -> WalletMnemonicRepository {
    coreAssembly.mnemonicVault()
  }
  
  public func mnemonicsRepository() -> MnemonicsRepository {
    coreAssembly.mnemonicsV3Vault {
      settingsRepository().seed
    }
  }
  
  public func settingsRepository() -> SettingsRepository {
    SettingsRepository(settingsVault: coreAssembly.settingsVault())
  }
  
  func keeperInfoRepository() -> KeeperInfoRepository {
    coreAssembly.sharedFileSystemVault()
  }
  
  func walletBalanceRepository() -> WalletBalanceRepository {
    WalletBalanceRepositoryImplementation(fileSystemVault: coreAssembly.fileSystemVault())
  }
  
  func totalBalanceRepository() -> TotalBalanceRepository {
    TotalBalanceRepositoryImplementation(fileSystemVault: coreAssembly.fileSystemVault())
  }
  
  func ratesRepository() -> RatesRepository {
    RatesRepositoryImplementation(fileSystemVault: coreAssembly.fileSystemVault())
  }
  
  func historyRepository() -> HistoryRepository {
    HistoryRepositoryImplementation(fileSystemVault: coreAssembly.fileSystemVault())
  }
  
  func nftRepository() -> NFTRepository {
    NFTRepositoryImplementation(fileSystemVault: coreAssembly.fileSystemVault())
  }
  
  func accountsNftRepository() -> AccountNFTRepository {
    AccountNFTRepositoryImplementation(fileSystemVault: coreAssembly.fileSystemVault())
  }
  
  public func passcodeRepository() -> PasscodeRepository {
    PasscodeRepositoryImplementation(passcodeVault: coreAssembly.passcodeVault())
  }
  
  func knownAccountsRepository() -> KnownAccountsRepository {
    KnownAccountsRepositoryImplementation(fileSystemVault: coreAssembly.fileSystemVault())
  }
  
  func buySellMethodsRepository() -> BuySellMethodsRepository {
    BuySellMethodsRepositoryImplementation(fileSystemVault: coreAssembly.fileSystemVault())
  }
  
  func chartDataRepository() -> ChartDataRepository {
    ChartDataRepositoryImplementation(fileSystemVault: coreAssembly.fileSystemVault())
  }
  
  func popularAppsRepository() -> PopularAppsRepository {
    PopularAppsRepositoryImplementation(fileSystemVault: coreAssembly.fileSystemVault())
  }
}
