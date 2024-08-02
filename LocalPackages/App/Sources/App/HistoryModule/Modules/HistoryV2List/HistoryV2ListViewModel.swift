import UIKit
import TKUIKit
import TKLocalize
import KeeperCore
import TonSwift

protocol HistoryV2ListModuleOutput: AnyObject {
  var didUpdate: ((_ hasEvents: Bool) -> Void)? { get set }
  var didSelectEvent: ((AccountEventDetailsEvent) -> Void)? { get set }
  var didSelectNFT: ((Address) -> Void)? { get set }
}
protocol HistoryV2ListModuleInput: AnyObject {}
protocol HistoryV2ListViewModel: AnyObject {
  var didUpdateSnapshot: ((HistoryV2ListViewController.Snapshot) -> Void)? { get set }
  
  func viewDidLoad()
  func getEventCellModel(identifier: String) -> HistoryCell.Model?
  func getPaginationCellModel() -> HistoryV2ListPaginationCell.Model
  func loadNextPage()
}

final class HistoryV2ListViewModelImplementation: HistoryV2ListViewModel, HistoryV2ListModuleOutput, HistoryV2ListModuleInput {
  
  struct HistoryListSection {
    let date: Date
    let title: String?
    let events: [AccountEventModel]
  }
  
  var didUpdate: ((Bool) -> Void)?
  var didSelectEvent: ((AccountEventDetailsEvent) -> Void)?
  var didSelectNFT: ((Address) -> Void)?
  
  var didUpdateSnapshot: ((HistoryV2ListViewController.Snapshot) -> Void)?
  
  private let serialActor = SerialActor<Void>()
  private var relativeDate = Date()
  private var events = [AccountEvent]()
  private var eventsOrderMap = [String: Int]()
  private var snapshot = HistoryV2ListViewController.Snapshot()
  private var sections = [HistoryListSection]()
  private var sectionsOrderMap = [Date: Int]()
  private var eventCellModels = [String: HistoryCell.Model]()
  private var paginationCellModel = HistoryV2ListPaginationCell.Model(state: .none)
  private var loadNFTsTasks = [Address: Task<NFT, Swift.Error>]()
  
  private let wallet: Wallet
  private let paginationLoader: HistoryPaginationLoader
  private let nftService: NFTService
  private let accountEventMapper: AccountEventMapper
  private let dateFormatter: DateFormatter
  private let historyEventMapper: HistoryEventMapper
  
  init(wallet: Wallet,
       paginationLoader: HistoryPaginationLoader,
       nftService: NFTService,
       accountEventMapper: AccountEventMapper,
       dateFormatter: DateFormatter,
       historyEventMapper: HistoryEventMapper) {
    self.wallet = wallet
    self.paginationLoader = paginationLoader
    self.nftService = nftService
    self.accountEventMapper = accountEventMapper
    self.dateFormatter = dateFormatter
    self.historyEventMapper = historyEventMapper
  }
  
  func viewDidLoad() {
    setupLoader()
  }
  
  func getEventCellModel(identifier: String) -> HistoryCell.Model? {
    return eventCellModels[identifier]
  }
  
  func getPaginationCellModel() -> HistoryV2ListPaginationCell.Model {
    return paginationCellModel
  }
  
  func loadNextPage() {
    paginationLoader.loadNext()
  }
}

private extension HistoryV2ListViewModelImplementation {

  func setupLoader() {
    Task {
      let stream = await paginationLoader.createStream()
      for await event in stream {
        await self.serialActor.addTask {
          await self.handleLoaderEvent(event)
        }
      }
    }
    paginationLoader.reload()
  }
  
  func handleLoaderEvent(_ event: HistoryPaginationLoader.Event) async {
    switch event {
    case .cached(let events):
      didUpdate?(true)
      handleCached(events)
    case .loading:
      didUpdate?(true)
      handleLoading()
    case .loadingFailed:
      didUpdate?(false)
    case .loaded(let accountEvents, let hasMore):
      guard !accountEvents.events.isEmpty else {
        didUpdate?(false)
        return
      }
      await handleLoaded(accountEvents, hasMore: hasMore)
    case .loadedPage(let accountEvents, let hasMore):
      await handleLoadedPage(accountEvents, hasMore: hasMore)
    case .pageLoading:
      handlePageLoading()
    case .pageLoadingFailed:
      handlePageLoadingFailed()
    }
  }
  
  func reset() {
    relativeDate = Date()
    events = []
    eventsOrderMap.removeAll()
    sections.removeAll()
    sectionsOrderMap.removeAll()
    snapshot.deleteAllItems()
  }
  
  func handleLoading() {
    reset()
    snapshot.appendSections([.shimmer])
    snapshot.appendItems([.shimmer], toSection: .shimmer)
    DispatchQueue.main.async { [snapshot] in
      self.didUpdateSnapshot?(snapshot)
    }
  }
  
  func handleCached(_ accountEvents: [AccountEvent]) {
    reset()
    accountEvents.forEach { event in
      self.events.append(event)
      eventsOrderMap[event.eventId] = self.events.count - 1
    }
    handleAccountEvents(accountEvents, hasMore: false)
  }
  
  func handleLoaded(_ accountEvents: AccountEvents, hasMore: Bool) async {
    reset()
    accountEvents.events.forEach { event in
      self.events.append(event)
      eventsOrderMap[event.eventId] = self.events.count - 1
    }
    await handleEventsWithNFTs(events: accountEvents.events)
    handleAccountEvents(accountEvents.events, hasMore: hasMore)
  }
  
  func handleLoadedPage(_ accountEvents: AccountEvents, hasMore: Bool) async {
    if snapshot.indexOfSection(.shimmer) != nil {
      snapshot.deleteSections([.shimmer])
    }
    accountEvents.events.forEach { event in
      self.events.append(event)
      eventsOrderMap[event.eventId] = self.events.count - 1
    }
    await handleEventsWithNFTs(events: accountEvents.events)
    handleAccountEvents(accountEvents.events, hasMore: hasMore)
  }
  
  func handlePageLoading() {
    if #available(iOS 15.0, *) {
      snapshot.reconfigureItems([.pagination])
    } else {
      snapshot.reloadItems([.pagination])
    }
    DispatchQueue.main.async { [snapshot] in
      self.paginationCellModel = HistoryV2ListPaginationCell.Model(state: .loading)
      self.didUpdateSnapshot?(snapshot)
    }
  }
  
  func handlePageLoadingFailed() {
    if #available(iOS 15.0, *) {
      self.snapshot.reconfigureItems([.pagination])
    } else {
      self.snapshot.reloadItems([.pagination])
    }
    DispatchQueue.main.async {
      self.paginationCellModel = HistoryV2ListPaginationCell.Model(state: .error(title: "Failed", retryButtonAction: {
        
      }))
      self.didUpdateSnapshot?(self.snapshot)
    }
  }
  
  func handleAccountEvents(_ accountsEvents: [AccountEvent], hasMore: Bool) {
    snapshot.deleteSections([.pagination])
    
    let calendar = Calendar.current
    var models = [String: HistoryCell.Model]()
    for event in accountsEvents {
      let eventDate = Date(timeIntervalSince1970: event.timestamp)
      let eventSectionDateComponents: DateComponents
      let eventDateFormat: String

      if calendar.isDateInToday(eventDate)
          || calendar.isDateInYesterday(eventDate)
          || calendar.isDate(eventDate, equalTo: relativeDate, toGranularity: .month) {
        eventSectionDateComponents = calendar.dateComponents([.year, .month, .day], from: eventDate)
        eventDateFormat = "HH:mm"
      } else if calendar.isDate(eventDate, equalTo: relativeDate, toGranularity: .year) {
        eventSectionDateComponents = calendar.dateComponents([.year, .month], from: eventDate)
        eventDateFormat = "dd MMM, HH:mm"
      } else {
        eventSectionDateComponents = calendar.dateComponents([.year, .month], from: eventDate)
        eventDateFormat = "dd MMM yyyy, HH:mm"
      }
      dateFormatter.dateFormat = eventDateFormat
      
      guard let sectionDate = calendar.date(from: eventSectionDateComponents) else { continue }
      
      let eventModel = mapEvent(event)
      let eventCellModel = mapEventCellModel(eventModel)
      models[eventModel.eventId] = eventCellModel
      
      if let sectionIndex = sectionsOrderMap[sectionDate],
         sections.count > sectionIndex {
        let section = sections[sectionIndex]
        let events = section.events + CollectionOfOne(eventModel)
          .sorted(by: { $0.date > $1.date })
        let updatedSection = HistoryListSection(
          date: section.date,
          title: section.title,
          events: events
        )
        
        sections.remove(at: sectionIndex)
        sections.insert(updatedSection, at: sectionIndex)
        
        let snapshotSection: HistoryV2ListSection = .events(
          HistoryV2ListEventsSection(
            date: section.date,
            title: section.title
          )
        ) 
        snapshot.deleteItems(snapshot.itemIdentifiers(inSection: snapshotSection))
        snapshot.appendItems(events.map { .event(identifier: $0.eventId) }, toSection: snapshotSection)
      } else {
        let section = HistoryListSection(
          date: sectionDate,
          title: mapEventsSectionDate(sectionDate),
          events: [eventModel]
        )
        
        sections = sections + CollectionOfOne(section)
          .sorted(by: { $0.date > $1.date })
        sectionsOrderMap = Dictionary(uniqueKeysWithValues: sections.enumerated().map {
          ($0.element.date, $0.offset) }
        )
        
        let snapshotSection: HistoryV2ListSection = .events(
          HistoryV2ListEventsSection(
            date: section.date,
            title: section.title
          )
        )
        
        if let sectionIndex = sectionsOrderMap[sectionDate],
           sectionIndex < snapshot.sectionIdentifiers.count {
          let previousSnapshotSection = snapshot.sectionIdentifiers[sectionIndex]
          snapshot.insertSections(
            [snapshotSection],
            beforeSection: previousSnapshotSection
          )
        } else {
          snapshot.appendSections([snapshotSection])
        }
        
        snapshot.appendItems([.event(identifier: eventModel.eventId)], toSection: snapshotSection)
      }
    }
    if hasMore {
      snapshot.appendSections([.pagination])
      snapshot.appendItems([.pagination])
    }
    DispatchQueue.main.async { [snapshot, models] in
      self.eventCellModels.merge(models) { $1 }
      self.didUpdateSnapshot?(snapshot)
    }
  }
  
  func mapEvent(_ event: AccountEvent) -> AccountEventModel {
    let calendar = Calendar.current
    let eventDate = Date(timeIntervalSince1970: event.timestamp)
    let eventDateFormat: String

    if calendar.isDateInToday(eventDate)
        || calendar.isDateInYesterday(eventDate)
        || calendar.isDate(eventDate, equalTo: relativeDate, toGranularity: .month) {
      eventDateFormat = "HH:mm"
    } else if calendar.isDate(eventDate, equalTo: relativeDate, toGranularity: .year) {
      eventDateFormat = "dd MMM, HH:mm"
    } else {
      eventDateFormat = "dd MMM yyyy, HH:mm"
    }
    dateFormatter.dateFormat = eventDateFormat

    let eventModel = accountEventMapper.mapEvent(
      event,
      eventDate: eventDate,
      accountEventRightTopDescriptionProvider: HistoryAccountEventRightTopDescriptionProvider(
        dateFormatter: dateFormatter
      ),
      isTestnet: wallet.isTestnet,
      nftProvider: { [weak self] address in
        guard let self else { return nil }
        return try? self.nftService.getNFT(address: address, isTestnet: self.wallet.isTestnet)
      }
    )
    
    return eventModel
  }
  
  func handleEventsWithNFTs(events: [AccountEvent]) async {
    let actions = events.flatMap { $0.actions }
    var nftAddressesToLoad = Set<Address>()
    for action in actions {
      switch action.type {
      case .nftItemTransfer(let nftItemTransfer):
        nftAddressesToLoad.insert(nftItemTransfer.nftAddress)
      case .nftPurchase(let nftPurchase):
        try? nftService.saveNFT(nft: nftPurchase.nft, isTestnet: wallet.isTestnet)
      default: continue
      }
    }
    guard !nftAddressesToLoad.isEmpty else { return }
    _ = try? await nftService.loadNFTs(addresses: Array(nftAddressesToLoad), isTestnet: wallet.isTestnet)
  }
  
  func mapEventCellModel(_ eventModel: AccountEventModel) -> HistoryCell.Model {
    return historyEventMapper.mapEvent(
      eventModel,
      nftAction: { [weak self] address in
        self?.didSelectNFT?(address)
      }, encryptedCommentAction: {
        
      },
      tapAction: { [weak self] accountEventDetailsEvent in
        self?.didSelectEvent?(accountEventDetailsEvent)
      }
    )
  }
  
  private func mapEventsSectionDate(_ date: Date) -> String? {
    let calendar = Calendar.current
    if calendar.isDateInToday(date) {
      return TKLocales.Dates.today
    } else if calendar.isDateInYesterday(date) {
      return TKLocales.Dates.yesterday
    } else if calendar.isDate(date, equalTo: Date(), toGranularity: .month) {
      dateFormatter.dateFormat = "d MMMM"
    } else if calendar.isDate(date, equalTo: Date(), toGranularity: .year) {
      dateFormatter.dateFormat = "LLLL"
    } else {
      dateFormatter.dateFormat = "LLLL y"
    }
    return dateFormatter.string(from: date).capitalized
  }
}
