import Foundation
import UIKit
import TKUIKit
import TKCore
import KeeperCore
import TKLocalize

protocol HistoryEventDetailsModuleOutput: AnyObject {
  
}

protocol HistoryEventDetailsViewModel: AnyObject {
  
  var didUpdateConfiguration: ((TKPopUp.Configuration) -> Void)? { get set }
  
  func viewDidLoad()
}

final class HistoryEventDetailsViewModelImplementation: HistoryEventDetailsViewModel, HistoryEventDetailsModuleOutput {
  
  // MARK: - HistoryEventDetailsModuleOutput
  
  // MARK: - HistoryEventDetailsViewModel
  
  var didUpdateConfiguration: ((TKPopUp.Configuration) -> Void)?
  
  func viewDidLoad() {
    setupContent()
  }
  
  // MARK: - Dependencies
  
  private let event: AccountEventDetailsEvent
  private let historyEventDetailsMapper: HistoryEventDetailsMapper
  private let urlOpener: URLOpener
  private let configurationStore: ConfigurationStore
  
  // MARK: - Init
  
  init(event: AccountEventDetailsEvent,
       historyEventDetailsMapper: HistoryEventDetailsMapper,
       urlOpener: URLOpener,
       configurationStore: ConfigurationStore) {
    self.event = event
    self.historyEventDetailsMapper = historyEventDetailsMapper
    self.urlOpener = urlOpener
    self.configurationStore = configurationStore
  }
}

private extension HistoryEventDetailsViewModelImplementation {
  
  func setupContent() {
    let model = self.historyEventDetailsMapper.mapEvent(event: event)
    self.configure(model: model)
  }
  
  func configure(model: HistoryEventDetailsMapper.Model) {
    var items = [TKPopUp.Item]()
    
    if let spamItem = configureSpamItem(model: model) {
      items.append(spamItem)
    }
    if let headerImage = configureHeaderImage(model: model) {
      items.append(headerImage)
    }
    
    let labelsGroup: TKPopUp.Component.GroupComponent = {
      var items = [TKPopUp.Item]()
      
      items.append(contentsOf: configureNFTItems(model: model))
      
      if let aboveTitle = model.aboveTitle {
        items.append(TKPopUp.Component.LabelComponent(
          text: aboveTitle.withTextStyle(.h2, color: .Text.tertiary, alignment: .center),
          numberOfLines: 1,
          bottomSpace: 4)
        )
      }
      if let title = model.title {
        items.append(TKPopUp.Component.LabelComponent(
          text: title.withTextStyle(.h2, color: .Text.primary, alignment: .center),
          numberOfLines: 1,
          bottomSpace: 4)
        )
      }
      if let fiatPrice = model.fiatPrice {
        items.append(TKPopUp.Component.LabelComponent(
          text: fiatPrice.withTextStyle(.body1, color: .Text.secondary, alignment: .center),
          numberOfLines: 1,
          bottomSpace: 4)
        )
      }
      if let date = model.date {
        items.append(TKPopUp.Component.LabelComponent(
          text: date.withTextStyle(.body1, color: .Text.secondary, alignment: .center),
          numberOfLines: 1,
          bottomSpace: 0)
        )
      }
      if let status = model.status {
        items.append(TKPopUp.Component.LabelComponent(
          text: status.withTextStyle(.body1, color: .Accent.orange, alignment: .center),
          numberOfLines: 1,
          bottomSpace: 0)
        )
      }
      return TKPopUp.Component.GroupComponent(
        padding: UIEdgeInsets(top: 0, left: 32, bottom: 32, right: 32),
        items: items
      )
    }()
    items.append(labelsGroup)
    if let listItem = configureListItems(model: model) {
      items.append(
        TKPopUp.Component.GroupComponent(
          padding: UIEdgeInsets(top: 0, left: 16, bottom: 16, right: 16),
          items: [listItem]
        )
      )
    }
    
    items.append(TKPopUp.Component.GroupComponent(
      padding: UIEdgeInsets(top: 16, left: 0, bottom: 0, right: 0),
      items: [configureTransactionButton()]
    ))
    
    let configuration = TKPopUp.Configuration(items: items)
    
    didUpdateConfiguration?(configuration)
  }
  
  func configureSpamItem(model: HistoryEventDetailsMapper.Model) -> TKPopUp.Item? {
    guard model.isScam else { return nil }
    return nil
  }
  
  func configureHeaderImage(model: HistoryEventDetailsMapper.Model) -> TKPopUp.Item? {
    guard !model.isScam else { return nil }
    guard let headerImage = model.headerImage else { return nil }
    
    switch headerImage {
    case .image(let tokenImage):
      return TKPopUp.Component.ImageComponent(
        image: TKImageView.Model(image: tokenImage.tkImage,
                                 tintColor: .Icon.primary,
                                 size: .size(CGSize(width: 76, height: 76)),
                                 corners: .circle,
                                 padding: .zero),
        bottomSpace: 20
      )
    case .swap(let fromImage, let toImage):
      return HistoryEventDetailsSwapHeaderComponent(
        configuration: HistoryEventDetailsSwapHeaderView.Configuration(
          leftImageModel: TKImageView.Model(
            image: fromImage.tkImage,
            tintColor: .Icon.primary,
            size: .size(CGSize(width: 76, height: 76)),
            corners: .circle
          ),
          rightImageModel: TKImageView.Model(
            image: toImage.tkImage,
            tintColor: .Icon.primary,
            size: .size(CGSize(width: 76, height: 76)),
            corners: .circle
          )
        ),
        bottomSpace: 20
      )
    case .nft(let url):
      return TKPopUp.Component.ImageComponent(
        image: TKImageView.Model(image: TKImage.urlImage(url),
                                 size: .size(CGSize(width: 96, height: 96)),
                                 corners: .cornerRadius(cornerRadius: 20),
                                 padding: .zero),
        bottomSpace: 20
      )
    }
  }
  
  func configureNFTItems(model: HistoryEventDetailsMapper.Model) -> [TKPopUp.Item] {
    guard !model.isScam else { return [] }
    guard let nftModel = model.nftModel else { return [] }
    guard let nftName = nftModel.name else { return [] }
    var items = [TKPopUp.Item]()
    items.append(TKPopUp.Component.LabelComponent(text: nftName.withTextStyle(.h2, color: .Text.primary, alignment: .center)))
    if let collectionName = nftModel.collectionName {
      items.append(
        HistoryEventDetailsNFTCollectionComponent(
          configuration: HistoryEventDetailsNFTCollectionView.Configuration(
            name: collectionName,
            isVerified: nftModel.isVerified
          ),
          bottomSpace: 16
        )
      )
    }
    return items
  }
  
  private func configureListItems(model: HistoryEventDetailsMapper.Model) -> TKPopUp.Component.List? {
    guard !model.listItems.isEmpty else { return nil }
    return TKPopUp.Component.List(
      configuration: TKListContainerView.Configuration(
        items: model.listItems.map {
          listItem in
          configureListItem(listItem)
        }
      )
    )
  }
  
  private func configureListItem(_ modelListItem: HistoryEventDetailsMapper.Model.ListItem) -> TKListContainerItem {
    switch modelListItem {
    case .recipientName(let value, let copyValue):
      TKListContainerItemView.Model(
        title: "Recipient name",
        value: .value(
          TKListContainerItemDefaultValueView.Model(
            topValue: TKListContainerItemDefaultValueView.Model.Value(value: value)
          )
        ),
        isHighlightable: true,
        copyValue: copyValue
      )
    case .recipientAddress(let value, let copyValue):
      HistoryEventDetailsListAddressItem(
        title: "Recipient address",
        value: value,
        copyValue: copyValue,
        isHighlightable: true
      )
    case .senderName(let value, let copyValue):
      TKListContainerItemView.Model(
        title: "Sender name",
        value: .value(
          TKListContainerItemDefaultValueView.Model(
            topValue: TKListContainerItemDefaultValueView.Model.Value(value: value)
          )
        ),
        isHighlightable: true,
        copyValue: copyValue
      )
    case .senderAddress(let value, let copyValue):
      HistoryEventDetailsListAddressItem(
        title: "Sender address",
        value: value,
        copyValue: copyValue,
        isHighlightable: true
      )
    case .sender(let value, let copyValue):
      TKListContainerItemView.Model(
        title: "Sender",
        value: .value(
          TKListContainerItemDefaultValueView.Model(
            topValue: TKListContainerItemDefaultValueView.Model.Value(value: value)
          )
        ),
        isHighlightable: true,
        copyValue: copyValue
      )
    case let .fee(value, converted):
      TKListContainerItemView.Model(
        title: "Fee",
        value: .value(
          TKListContainerItemDefaultValueView.Model(
            topValue: TKListContainerItemDefaultValueView.Model.Value(value: value),
            bottomValue: TKListContainerItemDefaultValueView.Model.Value(value: converted)
          )
        ),
        isHighlightable: false,
        copyValue: nil
      )
    case .refund(let value, let converted):
      TKListContainerItemView.Model(
        title: "Refund",
        value: .value(
          TKListContainerItemDefaultValueView.Model(
            topValue: TKListContainerItemDefaultValueView.Model.Value(value: value),
            bottomValue: TKListContainerItemDefaultValueView.Model.Value(value: converted)
          )
        ),
        isHighlightable: false,
        copyValue: nil
      )
    case .comment(let string):
      TKListContainerItemView.Model(
        title: "Comment",
        value: .value(
          TKListContainerItemDefaultValueView.Model(
            topValue: TKListContainerItemDefaultValueView.Model.Value(value: string, numberOfLines: 0)
          )
        ),
        isHighlightable: true,
        copyValue: string
      )
    case .encryptedComment:
      TKListContainerItemView.Model(
        title: "Encrypted comment",
        value: .value(
          TKListContainerItemDefaultValueView.Model(
            topValue: TKListContainerItemDefaultValueView.Model.Value(value: "AAA", numberOfLines: 0)
          )
        ),
        isHighlightable: true,
        copyValue: nil
      )
    case .description(let string):
      TKListContainerItemView.Model(
        title: "Description",
        value: .value(
          TKListContainerItemDefaultValueView.Model(
            topValue: TKListContainerItemDefaultValueView.Model.Value(value: string, numberOfLines: 0)
          )
        ),
        isHighlightable: true,
        copyValue: string
      )
    case .operation(let value):
      TKListContainerItemView.Model(
        title: "Operation",
        value: .value(
          TKListContainerItemDefaultValueView.Model(
            topValue: TKListContainerItemDefaultValueView.Model.Value(value: value, numberOfLines: 0)
          )
        ),
        isHighlightable: true,
        copyValue: value
      )
    case let .other(title, value, copyValue):
      TKListContainerItemView.Model(
        title: title,
        value: .value(
          TKListContainerItemDefaultValueView.Model(
            topValue: TKListContainerItemDefaultValueView.Model.Value(value: value, numberOfLines: 0)
          )
        ),
        isHighlightable: true,
        copyValue: copyValue
      )
    }
  }
  
  func configureTransactionButton() -> HistoryEventDetailsTransactionButtonComponent {
    let transaction = "Transaction ".withTextStyle(.label1, color: .Text.primary)
    let hash = String(event.accountEvent.eventId.prefix(8)).withTextStyle(.label1, color: .Text.secondary)
    let title = NSMutableAttributedString(attributedString: transaction)
    title.append(hash)
    
    return HistoryEventDetailsTransactionButtonComponent(
      configuration: HistoryEventDetailsTransactionButtonView.Configuration(
        title: title,
        action: { [configurationStore, event, urlOpener] in
          guard let transactionExplorer = configurationStore.getConfiguration().transactionExplorer else {
            return
          }
          let urlString = String(format: transactionExplorer.replacingOccurrences(of: "%s", with: "%@"), 
                                 event.accountEvent.eventId)
          guard let url = URL(string: urlString) else { return }
          urlOpener.open(url: url)
        }
      ),
      bottomSpace: 32
    )
  }
  
//  func configureDetails() {
//    Task {
//      let model = await self.historyEventDetailsController.model
//      await MainActor.run {
//        var headerItems = [TKModalCardViewController.Configuration.Item]()
//
//        headerItems.append(contentsOf: composeHeaderImageItems(with: model))
//
//        if let nftModel = model.nftModel {
//          headerItems.append(
//            contentsOf: configureNftItem(nftModel)
//          )
//        }
//
//        if let aboveTitle = model.aboveTitle {
//          headerItems.append(
//            .text(.init(text: aboveTitle.withTextStyle(.h2, color: .Text.tertiary, alignment: .center, lineBreakMode: .byWordWrapping), numberOfLines: 1), bottomSpacing: 4)
//          )
//        }
//        if let title = model.title {
//          headerItems.append(.text(.init(text: title.withTextStyle(.h2, color: .Text.primary, alignment: .center, lineBreakMode: .byWordWrapping), numberOfLines: 1), bottomSpacing: 4))
//        }
//        if let fiatPrice = model.fiatPrice {
//          headerItems.append(.text(.init(text: fiatPrice.withTextStyle(.body1, color: .Text.secondary, alignment: .center, lineBreakMode: .byWordWrapping), numberOfLines: 1), bottomSpacing: 4))
//        }
//        if let date = model.date {
//          headerItems.append(.text(.init(text: date.withTextStyle(.body1, color: .Text.secondary, alignment: .center, lineBreakMode: .byWordWrapping), numberOfLines: 1), bottomSpacing: 0))
//        }
//        
//        if let status = model.status {
//          headerItems.append(.text(.init(text: status.withTextStyle(.body1, color: .Accent.orange, alignment: .center, lineBreakMode: .byWordWrapping), numberOfLines: 1), bottomSpacing: 0))
//          headerItems.append(.customView(TKSpacingView(verticalSpacing: .constant(16)), bottomSpacing: 0))
//        }
//        
//        let listItems = model.listItems.map {
//          TKModalCardViewController.Configuration.ListItem.defaultItem(
//            left: $0.title,
//            rightTop: .value($0.topValue, numberOfLines: $0.topNumberOfLines, isFullString: $0.isTopValueFullString),
//            rightBottom: .value($0.bottomValue, numberOfLines: 1, isFullString: false))
//        }
//        let list = TKModalCardViewController.Configuration.ContentItem.list(listItems)
//        let buttonItem = TKModalCardViewController.Configuration.ContentItem.item(.customView(createOpenTransactionButtonContainerView(), bottomSpacing: 32))
//        
//        let configuration = TKModalCardViewController.Configuration(
//          header: TKModalCardViewController.Configuration.Header(items: headerItems),
//          content: TKModalCardViewController.Configuration.Content(items: [list, buttonItem]),
//          actionBar: nil
//        )
//        didUpdateConfiguration?(configuration)
//      }
//    }
//  }

//  func composeHeaderImageItems(with model: HistoryEventDetailsController.Model) -> [TKModalCardViewController.Configuration.Item] {
//    var headerItems = [TKModalCardViewController.Configuration.Item]()
//
//    guard !model.isScam else {
//      let view = HistoryEventDetailsScamView()
//      let text = TKLocales.ActionTypes.spam.uppercased()
//        .withTextStyle(.label2,
//                       color: .Text.primary,
//                       alignment: .center,
//                       lineBreakMode: .byTruncatingTail)
//      view.configure(model: HistoryEventDetailsScamView.Model(title: text))
//      headerItems.append(.customView(view, bottomSpacing: 12))
//      return headerItems
//    }
//
//    guard let headerImage = model.headerImage else {
//      return []
//    }
//
//    switch headerImage {
//    case .swap(let fromImage, let toImage):
//      let view = HistoryEventDetailsSwapHeaderImageView()
//      view.imageLoader = ImageLoader()
//      view.configure(model: HistoryEventDetailsSwapHeaderImageView.Model(
//        leftImage: .with(image: fromImage),
//        rightImage: .with(image: toImage))
//      )
//      headerItems.append(TKModalCardViewController.Configuration.Item.customView(view, bottomSpacing: 20))
//    case .image(let image):
//      let view = HistoreEventDetailsTokenHeaderImageView()
//      view.imageLoader = ImageLoader()
//      view.configure(model: HistoreEventDetailsTokenHeaderImageView.Model(
//        image: .with(image: image)
//      ))
//      headerItems.append(TKModalCardViewController.Configuration.Item.customView(view, bottomSpacing: 20))
//    case .nft(let image):
//      let view = HistoryEventDetailsNFTHeaderImageView()
//      view.imageLoader = ImageLoader()
//      view.configure(model: HistoryEventDetailsNFTHeaderImageView.Model(
//        image: .with(image: .url(image)),
//        size: CGSize(width: 96, height: 96)
//      ))
//      headerItems.append(TKModalCardViewController.Configuration.Item.customView(view, bottomSpacing: 20))
//    }
//
//    return headerItems
//  }

//  func configureNftItem(_ model: HistoryEventDetailsController.Model.NFT) ->  [TKModalCardViewController.Configuration.Item] {
//    var items =  [TKModalCardViewController.Configuration.Item]()
//    guard let nftName = model.name else {
//      return []
//    }
//    items.append(
//      .text(
//        .init(
//          text: nftName.withTextStyle(.h2, color: .Text.primary, alignment: .center, lineBreakMode: .byWordWrapping),
//          numberOfLines: 1
//        ),
//        bottomSpacing: 0
//      )
//    )
//    if let nftCollectionName = model.collectionName {
//      let text = nftCollectionName
//        .withTextStyle(
//          .body1,
//          color: .Text.secondary,
//          alignment: .center,
//          lineBreakMode: .byTruncatingTail
//        )
//
//      let label = UILabel()
//      label.attributedText = text
//
//      let stackView: UIStackView = {
//        let stackView = UIStackView(arrangedSubviews: [label])
//        stackView.alignment = .center
//        stackView.spacing = 4
//        stackView.distribution = .fill
//        return stackView
//      }()
//      let verificationImageView: UIImageView = {
//        let imageView = UIImageView()
//        imageView.contentMode = .center
//        imageView.image = .TKUIKit.Icons.Size16.verification
//        imageView.tintColor = .Icon.secondary
//        return imageView
//      }()
//
//      if model.isVerified == true {
//        stackView.addArrangedSubview(verificationImageView)
//      }
//
//      let view = UIView()
//      view.addSubview(stackView)
//      stackView.snp.makeConstraints { make in
//        make.top.bottom.equalToSuperview()
//        make.center.equalToSuperview()
//        make.width.lessThanOrEqualTo(view)
//      }
//
//      items.append(
//        .customView(view, bottomSpacing: 0)
//      )
//    }
//    items.append(.customView(TKSpacingView(verticalSpacing: .constant(16)), bottomSpacing: 0))
//    return items
//  }
}


private extension HistoryEventDetailsViewModelImplementation {
//  func createOpenTransactionButtonContainerView() -> UIView {
//    let buttonContainer = UIView()
//    let button = HistoryEventOpenTransactionButton()
//
//    buttonContainer.addSubview(button)
//    button.translatesAutoresizingMaskIntoConstraints = false
//    NSLayoutConstraint.activate([
//      button.topAnchor.constraint(equalTo: buttonContainer.topAnchor),
//      button.centerXAnchor.constraint(equalTo: buttonContainer.centerXAnchor),
//      button.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor)
//    ])
//    
//    let model = HistoryEventOpenTransactionButton.Model(
//      title: "\(TKLocales.EventDetails.transaction) ",
//      transactionHash: historyEventDetailsController.transactionHash,
//      image: .TKUIKit.Icons.Size16.globe
//    )
//    
//    button.addAction(UIAction(handler: { [weak self] _ in
//      guard let self = self else { return }
//      self.urlOpener.open(url: self.historyEventDetailsController.transactionURL)
//    }), for: .touchUpInside)
//    
//    button.configure(model: model)
//    return buttonContainer
//  }
}

private extension TokenImage {
  var tkImage: TKImage {
    switch self {
    case .ton:
      return .image(.TKUIKit.Icons.Size44.tonCurrency)
    case .url(let url):
      return .urlImage(url)
    }
  }
}
