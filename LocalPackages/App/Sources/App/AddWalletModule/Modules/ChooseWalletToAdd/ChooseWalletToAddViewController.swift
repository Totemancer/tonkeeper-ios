import UIKit
import TKUIKit

final class ChooseWalletToAddViewController: GenericViewViewController<ChooseWalletToAddView>, KeyboardObserving {
  private let viewModel: ChooseWalletToAddViewModel
  
  private lazy var collectionController = ChooseWalletToAddCollectionController(
    collectionView: customView.collectionView,
    headerViewProvider: { [customView] in customView.titleDescriptionView }
  )
  
  init(viewModel: ChooseWalletToAddViewModel) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupBindings()
    setupCollectionController()
    viewModel.viewDidLoad()
  }
}

private extension ChooseWalletToAddViewController {
  func setupBindings() {
    viewModel.didUpdateModel = { [customView] in
      customView.configure(model: $0)
    }
    
    viewModel.didUpdateTitleDescriptionModel = { [customView] in
      customView.titleDescriptionView.configure(model: $0)
    }
    
    viewModel.didUpdateList = { [collectionController] in
      collectionController.setSections($0)
    }
    
    viewModel.didSelectItems = { [customView] indexPaths in
      indexPaths.forEach {
        customView.collectionView.selectItem(at: $0, animated: false, scrollPosition: [])
      }
    }
  }
  
  func setupCollectionController() {
    collectionController.didSelect = { [weak viewModel] in
      viewModel?.select(at: $0)
    }
    
    collectionController.didDeselect = { [weak viewModel] in
      viewModel?.deselect(at: $0)
    }
  }
}
