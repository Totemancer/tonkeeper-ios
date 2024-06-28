import UIKit
import TKUIKit

final class SettingsListCollectionController: TKCollectionController<SettingsListSection, AnyHashable> {
  
  typealias SettingsCellRegistration = UICollectionView.CellRegistration<SettingsCell, SettingsCell.Model>
  typealias SettingsTextCellRegistration = UICollectionView.CellRegistration<SettingsTextCell, SettingsTextCell.Model>
  typealias SettingsButtonCellRegistration = UICollectionView.CellRegistration<SettingsButtonCell, SettingsButtonCell.Model>
  typealias ListItemCellRegistration = UICollectionView.CellRegistration<TKUIListItemCell, TKUIListItemCell.Configuration>
  
  private let settingsCellRegistration: SettingsCellRegistration
  private let settingsTextCellRegistration: SettingsTextCellRegistration
  private let settingsButtonCellRegistration: SettingsButtonCellRegistration
  
  init(collectionView: UICollectionView,
       cellProvider: ((UICollectionView, IndexPath, AnyHashable) -> UICollectionViewCell?)? = nil) {
    let settingsCellRegistration = SettingsCellRegistration { cell, indexPath, itemIdentifier in
      cell.configure(model: itemIdentifier)
    }
    self.settingsCellRegistration = settingsCellRegistration
    
    let settingsTextCellRegistration = SettingsTextCellRegistration { cell, indexPath, itemIdentifier in
      cell.configure(model: itemIdentifier)
    }
    self.settingsTextCellRegistration = settingsTextCellRegistration
    
    let settingsButtonCellRegistration = SettingsButtonCellRegistration { cell, indexPath, itemIdentifier in
      cell.configure(model: itemIdentifier)
    }
    self.settingsButtonCellRegistration = settingsButtonCellRegistration
    
    let listItemCellRegistration = ListItemCellRegistration { cell, indexPath, itemIdentifier in
      cell.configure(configuration: itemIdentifier)
      cell.isFirstInSection = { ip in ip.item == 0 }
      cell.isLastInSection = { [weak collectionView] ip in
        guard let collectionView = collectionView else { return false }
        return ip.item == (collectionView.numberOfItems(inSection: ip.section) - 1)
      }
    }

    super.init(
      collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
        switch itemIdentifier {
        case let model as SettingsCell.Model:
          let cell = collectionView.dequeueConfiguredReusableCell(using: settingsCellRegistration, for: indexPath, item: model)
          return cell
        case let model as SettingsTextCell.Model:
          let cell = collectionView.dequeueConfiguredReusableCell(using: settingsTextCellRegistration, for: indexPath, item: model)
          return cell
        case let model as SettingsButtonCell.Model:
          return collectionView.dequeueConfiguredReusableCell(using: settingsButtonCellRegistration, for: indexPath, item: model)
        case let configuration as TKUIListItemCell.Configuration:
          return collectionView.dequeueConfiguredReusableCell(using: listItemCellRegistration, for: indexPath, item: configuration)
        default: return cellProvider?(collectionView, indexPath, itemIdentifier)
        }
      })
    
    collectionView.setCollectionViewLayout(TKCollectionLayout.layout(sectionLayout: { [weak self] sectionIndex in
      guard let self = self else { return nil }
      let section = self.dataSource.snapshot().sectionIdentifiers[sectionIndex]
      return TKCollectionLayout.listSectionLayout(
        padding: section.padding,
        heightDimension: .estimated(76))
    }), animated: false)
    
    collectionView.contentInset.bottom = 16
    collectionView.contentInset.top = -16
  }
  
  func setSettingsSections(_ sections: [SettingsListSection]) {
    var snapshot = dataSource.snapshot()
    snapshot.deleteAllItems()
    snapshot.appendSections(sections)
    for section in sections {
      snapshot.appendItems(section.items, toSection: section)
    }
    snapshot.reloadSections(sections)
    UIView.performWithoutAnimation {
      dataSource.apply(snapshot, animatingDifferences: true)
    }
  }
}
