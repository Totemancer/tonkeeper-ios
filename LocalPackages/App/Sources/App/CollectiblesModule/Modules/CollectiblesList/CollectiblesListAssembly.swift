import Foundation
import TKCore
import KeeperCore

struct CollectiblesListAssembly {
  private init() {}
  static func module(
    wallet: Wallet,
    keeperCoreMainAssembly: KeeperCore.MainAssembly
  ) -> MVVMModule<CollectiblesListViewController, CollectiblesListModuleOutput, Void> {
    let viewModel = CollectiblesListViewModelImplementation(
      wallet: wallet,
      walletsStore: keeperCoreMainAssembly.walletAssembly.walletsStore,
      walletNFTStore: keeperCoreMainAssembly.storesAssembly.walletNFTsStore,
      nftManagementStore: keeperCoreMainAssembly.mainStoresAssembly.accountNFTsManagementStore(wallet: wallet)
    )
    let viewController = CollectiblesListViewController(viewModel: viewModel)
    return .init(view: viewController, output: viewModel, input: Void())
  }
}
