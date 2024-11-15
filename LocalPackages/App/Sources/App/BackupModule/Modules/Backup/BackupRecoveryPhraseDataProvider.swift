import UIKit
import TKUIKit
import TKScreenKit
import TKLocalize
import KeeperCore

struct BackupRecoveryPhraseDataProvider: TKRecoveryPhraseDataProvider {
  
  public var didTapNext: (() -> Void)?
  
  var model: TKRecoveryPhraseView.Model {
    createModel()
  }
  
  private let phrase: [String]
  
  init(phrase: [String]) {
    self.phrase = phrase
  }
}

private extension BackupRecoveryPhraseDataProvider {
  func createModel() -> TKRecoveryPhraseView.Model {
    let phraseListViewModel = TKRecoveryPhraseListView.Model(
      wordModels: phrase
        .enumerated()
        .map { index, word in
          TKRecoveryPhraseItemView.Model(index: index + 1, word: word)
        }
    )
    
    return TKRecoveryPhraseView.Model(
      titleDescriptionModel: TKTitleDescriptionView.Model(
        title: TKLocales.Backup.Check.title,
        bottomDescription: TKLocales.Backup.Check.caption
      ),
      phraseListViewModel: phraseListViewModel,
      buttons: [
        TKRecoveryPhraseView.Model.Button(
          model: TKUIActionButton.Model(title: TKLocales.Backup.Check.Button.title),
          category: .primary,
          action: {
            self.didTapNext?()
          }
        )
      ]
    )
  }
}
