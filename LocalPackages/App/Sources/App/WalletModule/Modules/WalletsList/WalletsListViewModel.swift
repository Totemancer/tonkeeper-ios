import Foundation
import TKUIKit
import UIKit
import KeeperCore
import TKLocalize

protocol WalletsListModuleOutput: AnyObject {
  var addButtonEvent: (() -> Void)? { get set }
  var didSelectWallet: (() -> Void)? { get set }
  var didTapEditWallet: ((Wallet) -> Void)? { get set }
}

protocol WalletsListViewModel: AnyObject {
  var didUpdateSnapshot: ((_ snapshot: NSDiffableDataSourceSnapshot<WalletsListSection, WalletsListItem>, _ isAnimated: Bool) -> Void)? { get set }
  var didUpdateSelected: ((Int?) -> Void)? { get set }
  var didUpdateHeaderItem: ((TKPullCardHeaderItem) -> Void)? { get set }
  var didUpdateIsEditing: ((Bool) -> Void)? { get set }
  
  func viewDidLoad()
  func moveWallet(fromIndex: Int, toIndex: Int)
  func didTapEdit(item: WalletsListItem)
  func getItemModel(identifier: String) -> AnyHashable?
  func didSelectItem(_ item: WalletsListItem)
  func canReorderItem(_ item: WalletsListItem) -> Bool
  func didTapAddWalletButton()
}

final class WalletsListViewModelImplementation: WalletsListViewModel, WalletsListModuleOutput {
  
  // MARK: - WalletsListModuleOutput
  
  var addButtonEvent: (() -> Void)?
  var didSelectWallet: (() -> Void)?
  var didTapEditWallet: ((Wallet) -> Void)?
  
  // MARK: - WalletsListViewModel
  
  var didUpdateSnapshot: ((_ snapshot: NSDiffableDataSourceSnapshot<WalletsListSection, WalletsListItem>, _ isAnimated: Bool) -> Void)?
  var didUpdateSelected: ((Int?) -> Void)?
  var didUpdateHeaderItem: ((TKPullCardHeaderItem) -> Void)?
  var didUpdateIsEditing: ((Bool) -> Void)?
  
  func viewDidLoad() {
    model.didUpdateWalletsState = { [weak self] walletsState in
      self?.didUpdateWalletsState(walletsState)
    }
    model.setInitialState()
    totalBalancesStore.addObserver(self, notifyOnAdded: true) { [weak self] observer, state in
      self?.didUpdateTotalBalanceState(state)
    }
  }
  
  func moveWallet(fromIndex: Int, toIndex: Int) {
    queue.async {
      self.model.moveWallet(fromIndex: fromIndex, toIndex: toIndex)
    }
  }
  
  func didTapEdit(item: WalletsListItem) {
    switch item {
    case .wallet(let identifier):
      queue.async {
        guard let wallets = self.walletsState?.wallets,
              let wallet = wallets.first(where: { $0.id == identifier }) else { return }
        DispatchQueue.main.async {
          self.didTapEditWallet?(wallet)
        }
      }
    default:
      return
    }
  }
  
  func getItemModel(identifier: String) -> AnyHashable? {
    switch identifier {
    case .addWalletButtonCellIdentifier:
      return WalletsListAddWalletCell.Model(content: TKButton.Configuration.Content(title: .plainString(TKLocales.WalletsList.add_wallet)))
    default:
      return itemModels[identifier]
    }
  }
  
  func didTapAddWalletButton() {
    addButtonEvent?()
  }
  
  func didSelectItem(_ item: WalletsListItem) {
    switch item {
    case .wallet(let identifier):
      queue.async {
        guard let wallets = self.walletsState?.wallets,
              let wallet = wallets.first(where: { $0.id == identifier }) else {
          return
        }
        self.model.selectWallet(wallet: wallet)
        DispatchQueue.main.async {
          UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
          self.didSelectWallet?()
        }
      }
    case .addWalletButton:
      return
    }
  }
  
  func canReorderItem(_ item: WalletsListItem) -> Bool {
    switch item {
    case .wallet: return true && isEditing
    default: return false
    }
  }
  
  // MARK: - State
  
  private let queue = DispatchQueue(label: "WalletListViewModelUpdateQueue", target: .global(qos: .default))
  private var snapshot = NSDiffableDataSourceSnapshot<WalletsListSection, String>()
  private var itemModels = [String: AnyHashable]()
  private var walletsState: WalletsState?
  private var totalBalanceState: WalletsTotalBalanceStoreV2.State?
  private var isEditing: Bool = false {
    didSet {
      didUpdateIsEditing?(isEditing)
      didUpdateSelected?(isEditing ? nil : selectedIndex)
      updateHeaderItem()
    }
  }
  private var isEditable: Bool = false {
    didSet {
      updateHeaderItem()
    }
  }
  private var selectedIndex: Int? {
    didSet {
      didUpdateSelected?(selectedIndex)
    }
  }
  
  // MARK: - Dependencies
  
  private let model: WalletsListModel
  private let totalBalancesStore: WalletsTotalBalanceStoreV2
  private let amountFormatter: AmountFormatter
  
  // MARK: - Init
  
  init(model: WalletsListModel,
       totalBalancesStore: WalletsTotalBalanceStoreV2,
       amountFormatter: AmountFormatter) {
    self.model = model
    self.totalBalancesStore = totalBalancesStore
    self.amountFormatter = amountFormatter
  }
}

private extension WalletsListViewModelImplementation {
  func didUpdateWalletsState(_ walletsState: WalletsState) {
    queue.async {
      guard walletsState != self.walletsState else { return }
      self.update(walletsState, self.totalBalanceState)
    }
  }
  
  func didUpdateTotalBalanceState(_ totalBalanceState: WalletsTotalBalanceStoreV2.State) {
    queue.async {
      guard totalBalanceState != self.totalBalanceState else { return }
      self.update(self.walletsState, totalBalanceState)
    }
  }
  
  func update(_ walletsState: WalletsState?, _ totalBalanceState: WalletsTotalBalanceStoreV2.State?) {
    guard let walletsState else { return }
    var snapshot = NSDiffableDataSourceSnapshot<WalletsListSection, WalletsListItem>()
    snapshot.appendSections([.wallets, .addWallet])
    
    let isHighlightable = walletsState.wallets.count > 1
    var models = [String: AnyHashable]()
    var updatedItems = [WalletsListItem]()
    for wallet in walletsState.wallets {
      snapshot.appendItems([.wallet(wallet.id)], toSection: .wallets)
      let isWalletMetaDataUpdated = {
        wallet.metaData != self.walletsState?.wallets.first(where: { $0.id == wallet.id })?.metaData
      }()
      let isWalletBalanceUpdated = {
        totalBalanceState?.totalBalances[wallet] != self.totalBalanceState?.totalBalances[wallet]
      }()
      if isWalletMetaDataUpdated || isWalletBalanceUpdated {
        models[wallet.id] = createWalletModel(
          wallet,
          totalBalance: totalBalanceState?.totalBalances[wallet]?.totalBalance,
          currency: totalBalanceState?.currency,
          isHighlightable: isHighlightable
        )
        updatedItems.append(.wallet(wallet.id))
      }
    }
    if #available(iOS 15.0, *) {
      snapshot.reconfigureItems(updatedItems)
    } else {
      snapshot.reloadItems(updatedItems)
    }
    
    snapshot.appendItems([.addWalletButton(.addWalletButtonCellIdentifier)], toSection: .addWallet)
    
    let isEditable = walletsState.wallets.count > 1 && model.isEditable
    let selectedIndex = walletsState.wallets.firstIndex(of: walletsState.activeWallet)
    let isAnimated = self.walletsState != nil && self.totalBalanceState != nil
    
    self.walletsState = walletsState
    self.totalBalanceState = totalBalanceState
    
    DispatchQueue.main.async {
      self.isEditable = isEditable
      self.itemModels.merge(models) { _, value in
        value
      }
      self.didUpdateSnapshot?(snapshot, isAnimated)
      self.selectedIndex = selectedIndex
    }
  }
  
  func createWalletModel(_ wallet: Wallet,
                         totalBalance: TotalBalance?,
                         currency: Currency?,
                         isHighlightable: Bool) -> TKUIListItemCell.Configuration {
    let subtitle: String
    if let totalBalance {
      subtitle = amountFormatter.formatAmountWithoutFractionIfThousand(
        totalBalance.amount,
        fractionDigits: totalBalance.fractionalDigits,
        maximumFractionDigits: 2,
        currency: currency
      )
    } else {
      subtitle = "-"
    }
    
    let contentConfiguration = TKUIListItemContentView.Configuration(
      leftItemConfiguration: TKUIListItemContentLeftItem.Configuration(
        title: wallet.label.withTextStyle(.label1, color: .Text.primary, alignment: .left),
        tagViewModel: wallet.listTagConfiguration(),
        subtitle: subtitle.withTextStyle(.body2, color: .Text.secondary, alignment: .left),
        description: nil
      ),
      rightItemConfiguration: nil
    )
    
    let iconConfiguration = TKUIListItemIconView.Configuration(
      iconConfiguration: .emoji(
        TKUIListItemEmojiIconView.Configuration(
          emoji: wallet.emoji,
          backgroundColor: wallet.tintColor.uiColor
        )
      ),
      alignment: .center
    )
    
    let listItemConfiguration = TKUIListItemView.Configuration(
      iconConfiguration: iconConfiguration,
      contentConfiguration: contentConfiguration,
      accessoryConfiguration: TKUIListItemAccessoryView.Configuration.none
    )
    
    return TKUIListItemCell.Configuration(
      id: wallet.id,
      listItemConfiguration: listItemConfiguration,
      isHighlightable: isHighlightable,
      selectionClosure: nil
    )
  }
  
  func updateHeaderItem() {
    didUpdateHeaderItem?(createHeaderItem())
  }
  
  func createHeaderItem() -> TKPullCardHeaderItem {
    var leftButton: TKPullCardHeaderItem.LeftButton?
    if isEditable {
      let leftButtonModel = TKUIHeaderTitleIconButton.Model(
        title: isEditing ? TKLocales.Actions.done: TKLocales.Actions.edit
      )
      leftButton = TKPullCardHeaderItem.LeftButton(
        model: leftButtonModel) { [weak self] in
          self?.isEditing.toggle()
        }
    }
    return TKPullCardHeaderItem(
      title: TKLocales.WalletsList.title,
      leftButton: leftButton)
  }
}

private extension String {
  static let addWalletButtonCellIdentifier = "AddWalletButtonCellIdentifier"
}
