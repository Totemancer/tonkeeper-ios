import Foundation
import KeeperCore
import BigInt
import TonSwift
import TKCore
import TKLocalize

final class WalletBalanceBalanceModel {
  struct BalanceListItems {
    let wallet: Wallet
    let items: [ProcessedBalanceItem]
    let canManage: Bool
    let isSecure: Bool
  }
  
  var didUpdateItems: ((BalanceListItems) -> Void)?
  
  private let actor = SerialActor<Void>()
  
  private let walletsStore: WalletsStoreV3
  private let balanceStore: ProcessedBalanceStoreV3
  private let stackingPoolsStore: StakingPoolsStoreV3
  private let tokenManagementStore: TokenManagementStoreV3
  private let appSettingsStore: AppSettingsV3Store
  
  init(walletsStore: WalletsStoreV3,
       balanceStore: ProcessedBalanceStoreV3,
       stackingPoolsStore: StakingPoolsStoreV3,
       tokenManagementStore: TokenManagementStoreV3,
       appSettingsStore: AppSettingsV3Store) {
    self.walletsStore = walletsStore
    self.balanceStore = balanceStore
    self.stackingPoolsStore = stackingPoolsStore
    self.tokenManagementStore = tokenManagementStore
    self.appSettingsStore = appSettingsStore
    
    walletsStore.addObserver(self) { observer, event in
      observer.didGetWalletsStoreEvent(event)
    }
    
    balanceStore.addObserver(self) { observer, event in
      observer.didGetBalanceStoreEvent(event)
    }
    
    stackingPoolsStore.addObserver(self) { observer, event in
      observer.didGetStackingPoolsStoreEvent(event)
    }
    
    tokenManagementStore.addObserver(self) { observer, event in
      observer.didGetTokenManagementStoreStoreEvent(event)
    }
    
    appSettingsStore.addObserver(self) { observer, event in
      observer.didGetAppSettingsStoreEvent(event)
    }
  }
  
  func getItems() throws -> BalanceListItems {
    let activeWallet = try walletsStore.getActiveWallet()
    let isSecureMode = appSettingsStore.getState().isSecureMode
    let balanceState = balanceStore.getState()[activeWallet]
    let tokenManagementState = tokenManagementStore.getState()[activeWallet]
    let stakingPools = stackingPoolsStore.getState()[activeWallet]
    return createItems(
      wallet: activeWallet,
      balanceState: balanceState,
      stakingPools: stakingPools ?? [],
      tokenManagementState: tokenManagementState,
      isSecureMode: isSecureMode
    )
  }
  
  func getItems() async throws -> BalanceListItems {
    let activeWallet = try await walletsStore.getActiveWallet()
    let isSecureMode = await appSettingsStore.getState().isSecureMode
    let balanceState = await balanceStore.getState()[activeWallet]
    let tokenManagementState = await tokenManagementStore.getState()[activeWallet]
    let stakingPools = await stackingPoolsStore.getState()[activeWallet]
    return createItems(
      wallet: activeWallet,
      balanceState: balanceState,
      stakingPools: stakingPools ?? [],
      tokenManagementState: tokenManagementState,
      isSecureMode: isSecureMode
    )
  }
  
  private func didGetWalletsStoreEvent(_ event: WalletsStoreV3.Event) {
    Task {
      switch event {
      case .didChangeActiveWallet:
        await self.actor.addTask(block: { await self.updateItems() })
      default: break
      }
    }
  }
  
  private func didGetBalanceStoreEvent(_ event: ProcessedBalanceStoreV3.Event) {
    Task {
      switch event {
      case .didUpdateProccessedBalance(_, let wallet):
        switch await walletsStore.getState() {
        case .empty: break
        case .wallets(let state):
          guard state.activeWalelt == wallet else { return }
          await self.actor.addTask(block: { await self.updateItems() })
        }
      }
    }
  }
  
  private func didGetStackingPoolsStoreEvent(_ event: StakingPoolsStoreV3.Event) {
    Task {
      switch event {
      case .didUpdateStakingPools(_, let wallet):
        switch await walletsStore.getState() {
        case .empty: break
        case .wallets(let state):
          guard state.activeWalelt == wallet else { return }
          await self.actor.addTask(block: { await self.updateItems() })
        }
      }
    }
  }
  
  private func didGetTokenManagementStoreStoreEvent(_ event: TokenManagementStoreV3.Event) {
    Task {
      switch event {
      case .didUpdateState(let wallet):
        switch await walletsStore.getState() {
        case .empty: break
        case .wallets(let state):
          guard state.activeWalelt == wallet else { return }
          await self.actor.addTask(block: { await self.updateItems() })
        }
      }
    }
  }
  
  private func didGetAppSettingsStoreEvent(_ event: AppSettingsV3Store.Event) {
    Task {
      await self.actor.addTask(block: { await self.updateItems() })
    }
  }
  
  private func updateItems() async {
    let walletsStoreState = await walletsStore.getState()
    switch walletsStoreState {
    case .empty: break
    case .wallets(let walletsState):
      let isSecureMode = await appSettingsStore.getState().isSecureMode
      let balanceState = await balanceStore.getState()[walletsState.activeWalelt]
      let tokenManagementState = await tokenManagementStore.getState()[walletsState.activeWalelt]
      let stakingPools = await stackingPoolsStore.getState()[walletsState.activeWalelt]
      let items = createItems(
        wallet: walletsState.activeWalelt,
        balanceState: balanceState,
        stakingPools: stakingPools ?? [],
        tokenManagementState: tokenManagementState,
        isSecureMode: isSecureMode
      )
      didUpdateItems?(items)
    }
  }
  
  private func createItems(wallet: Wallet,
                           balanceState: ProcessedBalanceState?,
                           stakingPools: [StackingPoolInfo],
                           tokenManagementState: TokenManagementState?,
                           isSecureMode: Bool) -> BalanceListItems {
    guard let balance = balanceState?.balance else {
      return BalanceListItems(wallet: wallet, items: [], canManage: false, isSecure: isSecureMode)
    }
    
    let statePinnedItems = tokenManagementState?.pinnedItems ?? []
    let stateHiddenItems = tokenManagementState?.hiddenItems ?? []
    
    var pinnedItems = [ProcessedBalanceItem]()
    var unpinnedItems = [ProcessedBalanceItem]()
    
    for item in balance.items {
      if statePinnedItems.contains(item.identifier) {
        pinnedItems.append(item)
      } else {
        guard !stateHiddenItems.contains(item.identifier) else {
          continue
        }
        unpinnedItems.append(item)
      }
    }
    
    let sortedPinnedItems = pinnedItems.sorted {
      guard let lIndex = statePinnedItems.firstIndex(of: $0.identifier) else {
        return false
      }
      guard let rIndex = statePinnedItems.firstIndex(of: $1.identifier) else {
        return true
      }
      
      return lIndex < rIndex
    }
    
    let sortedUnpinnedItems = unpinnedItems.sorted {
      switch ($0, $1) {
      case (.ton, _):
        return true
      case (_, .ton):
        return false
      case (.staking(let lModel), .staking(let rModel)):
        return lModel.amountConverted > rModel.amountConverted
      case (.staking, _):
        return true
      case (_, .staking):
        return false
      case (.jetton(let lModel), .jetton(let rModel)):
        switch (lModel.jetton.jettonInfo.verification, rModel.jetton.jettonInfo.verification) {
        case (.whitelist, .whitelist):
          return lModel.converted > rModel.converted
        case (.whitelist, _):
          return true
        case (_, .whitelist):
          return false
        default:
          return lModel.converted > rModel.converted
        }
      }
    }
    
    let items = BalanceListItems(
      wallet: wallet,
      items: sortedPinnedItems + sortedUnpinnedItems,
      canManage: balance.items.count > 2,
      isSecure: isSecureMode
    )
    return items
  }
}
