import Foundation
import KeeperCore

struct WalletsListModelState {
  let wallets: [Wallet]
  let selectedWallet: Int?
}

protocol WalletsListModel: AnyObject {
  var isEditable: Bool { get }
  var didUpdateState: ((WalletsListModelState) -> Void)? { get set }
  
  func getState() -> WalletsListModelState
  func selectWallet(wallet: Wallet)
  func moveWallet(fromIndex: Int, toIndex: Int)
}

final class WalletsPickerListModel: WalletsListModel {
  private let walletsStore: WalletsStore
  
  init(walletsStore: WalletsStore) {
    self.walletsStore = walletsStore
    walletsStore.addObserver(self) { observer, event in
      DispatchQueue.main.async {
        switch event {
        case .didAddWallets,
            .didDeleteWallet,
            .didChangeActiveWallet,
            .didMoveWallet,
            .didUpdateWalletMetaData:
          observer.updateState()
        default: break
        }
      }
    }
  }
  
  var isEditable: Bool {
    true
  }
  
  var didUpdateState: ((WalletsListModelState) -> Void)?
  
  func getState() -> WalletsListModelState {
    guard let state = try? walletsStore.stateWallets else {
      return WalletsListModelState(
        wallets: [],
        selectedWallet: nil
      )
    }
    
    return WalletsListModelState(
      wallets: state.wallets,
      selectedWallet: state.wallets.firstIndex(of: state.activeWalelt)
    )
  }
  
  func selectWallet(wallet: Wallet) {
    Task {
      do {
        guard try await walletsStore.getActiveWallet() != wallet else { return }
        await walletsStore.setWalletActive(wallet)
      } catch { return  }
    }
  }
  
  func moveWallet(fromIndex: Int, toIndex: Int) {
    Task {
      await walletsStore.moveWallet(fromIndex: fromIndex, toIndex: toIndex)
    }
  }
  
  private func updateState() {
    guard let state = try? walletsStore.stateWallets else {
      return
    }
    didUpdateState?(
      WalletsListModelState(
        wallets: state.wallets,
        selectedWallet: state.wallets.firstIndex(of: state.activeWalelt)
      )
    )
  }
}

final class TonConnectWalletsPickerListModel: WalletsListModel {
  
  var didSelectWallet: ((Wallet) -> Void)?
  
  private let walletsStore: WalletsStore
  
  init(walletsStore: WalletsStore) {
    self.walletsStore = walletsStore
  }
  
  var isEditable: Bool {
    false
  }
  
  var didUpdateState: ((WalletsListModelState) -> Void)?
  
  func getState() -> WalletsListModelState {
    guard let state = try? walletsStore.stateWallets else {
      return WalletsListModelState(
        wallets: [],
        selectedWallet: nil
      )
    }

    let wallets = state.wallets.filter { $0.isTonconnectAvailable }
    guard let activeWallet = (wallets.first(where: { $0 == state.activeWalelt }) ?? wallets.first) else {
      return WalletsListModelState(wallets: wallets, selectedWallet: nil)
    }
    return WalletsListModelState(wallets: wallets, selectedWallet: wallets.firstIndex(of: activeWallet))
  }
  
  func selectWallet(wallet: Wallet) {
    DispatchQueue.main.async {
      self.didSelectWallet?(wallet)
    }
  }
  
  func moveWallet(fromIndex: Int, toIndex: Int) {}
}