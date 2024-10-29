import Foundation

public final class RootAssembly {
  public let appInfoProvider: AppInfoProvider
  public let repositoriesAssembly: RepositoriesAssembly
  private let servicesAssembly: ServicesAssembly
  public let storesAssembly: StoresAssembly
  public let coreAssembly: CoreAssembly
  public let formattersAssembly: FormattersAssembly
  public let mappersAssembly: MappersAssembly
  public let walletsUpdateAssembly: WalletsUpdateAssembly
  private let configurationAssembly: ConfigurationAssembly
  private let buySellAssembly: BuySellAssembly
  public let passcodeAssembly: PasscodeAssembly
  private let apiAssembly: APIAssembly
  private let loadersAssembly: LoadersAssembly
  public let backgroundUpdateAssembly: BackgroundUpdateAssembly
  public let rnAssembly: RNAssembly

  init(appInfoProvider: AppInfoProvider,
       repositoriesAssembly: RepositoriesAssembly,
       coreAssembly: CoreAssembly,
       servicesAssembly: ServicesAssembly,
       storesAssembly: StoresAssembly,
       formattersAssembly: FormattersAssembly,
       mappersAssembly: MappersAssembly,
       walletsUpdateAssembly: WalletsUpdateAssembly,
       configurationAssembly: ConfigurationAssembly,
       buySellAssembly: BuySellAssembly,
       passcodeAssembly: PasscodeAssembly,
       apiAssembly: APIAssembly,
       loadersAssembly: LoadersAssembly,
       backgroundUpdateAssembly: BackgroundUpdateAssembly,
       rnAssembly: RNAssembly) {
    self.appInfoProvider = appInfoProvider
    self.repositoriesAssembly = repositoriesAssembly
    self.coreAssembly = coreAssembly
    self.servicesAssembly = servicesAssembly
    self.storesAssembly = storesAssembly
    self.formattersAssembly = formattersAssembly
    self.mappersAssembly = mappersAssembly
    self.walletsUpdateAssembly = walletsUpdateAssembly
    self.configurationAssembly = configurationAssembly
    self.buySellAssembly = buySellAssembly
    self.passcodeAssembly = passcodeAssembly
    self.apiAssembly = apiAssembly
    self.loadersAssembly = loadersAssembly
    self.backgroundUpdateAssembly = backgroundUpdateAssembly
    self.rnAssembly = rnAssembly
  }
  
  private var _rootController: RootController?
  public func rootController() -> RootController {
    if let rootController = _rootController {
      return rootController
    } else {
      let rootController = RootController(
        configuration: configurationAssembly.configuration,
        knownAccountsStore: loadersAssembly.knownAccountsStore,
        deeplinkParser: DeeplinkParser(),
        keeperInfoRepository: repositoriesAssembly.keeperInfoRepository(),
        mnemonicsRepository: repositoriesAssembly.mnemonicsRepository(),
        buySellProvider: buySellAssembly.buySellProvider
      )
      self._rootController = rootController
      return rootController
    }
  }

  public func onboardingAssembly() -> OnboardingAssembly {
    OnboardingAssembly(
      walletsUpdateAssembly: walletsUpdateAssembly,
      passcodeAssembly: passcodeAssembly,
      storesAssembly: storesAssembly
    )
  }
  
  public func mainAssembly() -> MainAssembly {
    let tonConnectAssembly = TonConnectAssembly(
      repositoriesAssembly: repositoriesAssembly,
      servicesAssembly: servicesAssembly,
      storesAssembly: storesAssembly,
      apiAssembly: apiAssembly,
      coreAssembly: coreAssembly,
      formattersAssembly: formattersAssembly
    )
    return MainAssembly(
      appInfoProvider: appInfoProvider,
      repositoriesAssembly: repositoriesAssembly,
      walletUpdateAssembly: walletsUpdateAssembly,
      servicesAssembly: servicesAssembly,
      storesAssembly: storesAssembly,
      formattersAssembly: formattersAssembly,
      mappersAssembly: mappersAssembly,
      configurationAssembly: configurationAssembly,
      buySellAssembly: buySellAssembly,
      passcodeAssembly: passcodeAssembly,
      tonConnectAssembly: tonConnectAssembly,
      apiAssembly: apiAssembly,
      loadersAssembly: loadersAssembly,
      backgroundUpdateAssembly: backgroundUpdateAssembly
    )
  }
}
