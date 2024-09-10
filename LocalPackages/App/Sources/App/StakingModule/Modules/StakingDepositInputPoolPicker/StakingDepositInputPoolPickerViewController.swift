import UIKit
import TKUIKit
import KeeperCore
import BigInt

final class StakingDepositInputPoolPickerViewController: UIViewController, StakingInputDetailsModuleInput {
  
  var didTapPicker: ((_ model: StakingListModel) -> Void)?
  
  private var selectedStackingPoolInfo: StackingPoolInfo?
  
  private let listItemButton = TKListItemButton()
  
  private let wallet: Wallet
  private let stakingPoolsStore: StakingPoolsStore
  private let decimalFormatter: DecimalAmountFormatter
  private let amountFormatter: AmountFormatter
  
  init(wallet: Wallet,
       stakingPoolsStore: StakingPoolsStore,
       decimalFormatter: DecimalAmountFormatter,
       amountFormatter: AmountFormatter) {
    self.wallet = wallet
    self.stakingPoolsStore = stakingPoolsStore
    self.decimalFormatter = decimalFormatter
    self.amountFormatter = amountFormatter
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.addSubview(listItemButton)
    
    listItemButton.snp.makeConstraints { make in
      make.edges.equalTo(self.view)
    }
  }
  
  func configureWith(stackingPoolInfo: StackingPoolInfo,
                     tonAmount: BigUInt,
                     isMostProfitable: Bool) {
    self.selectedStackingPoolInfo = stackingPoolInfo
    let profit: BigUInt = {
      let apy = stackingPoolInfo.apy
      let apyFractionLength = max(Int(-apy.exponent), 0)
      let apyPlain = NSDecimalNumber(decimal: apy).multiplying(byPowerOf10: Int16(apyFractionLength))
      let apyBigInt = BigUInt(stringLiteral: apyPlain.stringValue)
      
      let scalingFactor = BigUInt(100) * BigUInt(10).power(apyFractionLength)
      
      return tonAmount * apyBigInt / scalingFactor
    }()
    
    let configuration = mapStakingPoolItem(
      stackingPoolInfo,
      isMostProfitable: isMostProfitable,
      profit: profit
    )
    
    DispatchQueue.main.async {
      self.listItemButton.configuration = TKListItemButton.Configuration(
        listItemConfiguration: configuration,
        accessory: .icon(
          TKListItemIconAccessoryView.Configuration(
            icon: .TKUIKit.Icons.Size16.switch,
            tintColor: .Icon.tertiary
          )
        ),
        tapClosure: {
          [weak self] in
          self?.getPickerSections(completion: { model in
            self?.didTapPicker?(model)
          })
        }
      )
    }
  }
}

private extension StakingDepositInputPoolPickerViewController {
  func mapStakingPoolItem(_ item: StackingPoolInfo, 
                          isMostProfitable: Bool,
                          profit: BigUInt) -> TKListItemContentViewV2.Configuration {
    let tagText: String? = isMostProfitable ? .mostProfitableTag : nil
    let percentFormatted = decimalFormatter.format(amount: item.apy, maximumFractionDigits: 2)
    var subtitle = "\(String.apy) ≈ \(percentFormatted)%"
    if profit >= BigUInt(stringLiteral: "1000000000") {
      let formatted = amountFormatter.formatAmount(
        profit,
        fractionDigits: TonInfo.fractionDigits,
        maximumFractionDigits: 2,
        symbol: TonInfo.symbol
      )
      subtitle += " · \(formatted)"
    }
    
    let title = item.name
    
    var tagConfiguration: TKTagView.Configuration?
    if let tagText {
      tagConfiguration = .accentTag(text: tagText, color: .Accent.green)
    }
    
    return TKListItemContentViewV2.Configuration(
      iconViewConfiguration: TKListItemIconViewV2.Configuration(
        content: .image(
          TKImageView.Model(
            image: .image(item.implementation.icon),
            tintColor: .clear,
            size: .size(CGSize(width: 44, height: 44)),
            corners: .circle
          )
        ),
        alignment: .center,
        backgroundColor: .clear,
        size: CGSize(width: 44, height: 44)
      ),
      textContentViewConfiguration: TKListItemTextContentViewV2.Configuration(
        titleViewConfiguration: TKListItemTitleView.Configuration(title: title,
                                                                  tagConfiguration: tagConfiguration),
        captionViewsConfigurations: [
          TKListItemTextView.Configuration(text: subtitle, color: .Text.secondary, textStyle: .body2)
        ]
      )
    )
  }
  
  func getPickerSections(completion: @escaping (StakingListModel) -> Void) {
    guard let pools = self.stakingPoolsStore.getState()[wallet] else {
      return
    }
    
    let liquidPools = pools.filterByPoolKind(.liquidTF)
      .sorted(by: { $0.apy > $1.apy })
    let whalesPools = pools.filterByPoolKind(.whales)
      .sorted(by: { $0.apy > $1.apy })
    let tfPools = pools.filterByPoolKind(.tf)
      .sorted(by: { $0.apy > $1.apy })
    
    var sections = [StakingListSection]()
    
    sections.append(
      StakingListSection(
        title: .liquidStakingTitle,
        items: liquidPools.enumerated().map { index, pool in
            .pool(StakingListPool(pool: pool, isMaxAPY: index == 0))
        }
      )
    )
    
    func createGroup(_ pools: [StackingPoolInfo]) -> StakingListItem? {
      guard !pools.isEmpty else { return nil }
      let groupName = pools[0].implementation.name
      let groupImage = pools[0].implementation.icon
      let groupApy = pools[0].apy
      let minAmount = BigUInt(UInt64(pools[0].minStake))
      return StakingListItem.group(
        StakingListGroup(
          name: groupName,
          image: groupImage,
          apy: groupApy,
          minAmount: minAmount,
          items: pools.enumerated().map { StakingListPool(pool: $1, isMaxAPY: $0 == 0) }
        )
      )
    }
    
    sections.append(
      StakingListSection(
        title: .otherTitle, items: [whalesPools, tfPools].compactMap { createGroup($0) }
      )
    )
    
    completion(
      StakingListModel(
        title: "Options",
        sections: sections,
        selectedPool: self.selectedStackingPoolInfo
      )
    )
  }
}

private extension String {
  static let mostProfitableTag = "MAX APY"
  static let apy = "APY"
  static let liquidStakingTitle = "Liquid Staking"
  static let otherTitle = "Other"
}
