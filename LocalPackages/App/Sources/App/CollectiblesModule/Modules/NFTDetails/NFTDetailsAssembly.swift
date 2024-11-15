import Foundation
import TKCore
import KeeperCore

struct NFTDetailsAssembly {
  private init() {}
  static func module(
    wallet: Wallet,
    nft: NFT,
    keeperCoreMainAssembly: KeeperCore.MainAssembly
  ) -> MVVMModule<NFTDetailsViewController, NFTDetailsModuleOutput, Void> {
    let viewModel = NFTDetailsViewModelImplementation(
      nft: nft,
      wallet: wallet,
      dnsService: keeperCoreMainAssembly.servicesAssembly.dnsService(),
      appSetttingsStore: keeperCoreMainAssembly.storesAssembly.appSettingsStore,
      walletNftManagementStore: keeperCoreMainAssembly.storesAssembly.walletNFTsManagementStore(wallet: wallet)
    )
    let viewController = NFTDetailsViewController(viewModel: viewModel)
    return .init(view: viewController, output: viewModel, input: Void())
  }
}
