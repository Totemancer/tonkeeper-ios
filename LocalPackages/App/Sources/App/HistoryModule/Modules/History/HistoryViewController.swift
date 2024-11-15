import UIKit
import TKUIKit
import TKCoordinator
import TKLocalize

final class HistoryViewController: ContentListEmptyViewController {

  private let viewModel: HistoryViewModel
  private let historyListViewController: HistoryListViewController
  
  init(viewModel: HistoryViewModel,
       historyListViewController: HistoryListViewController) {
    self.viewModel = viewModel
    self.historyListViewController = historyListViewController
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setup()
    
    viewModel.viewDidLoad()
  }
}

private extension HistoryViewController {
  func setup() {
    customView.navigationBarView.title = TKLocales.History.title
    
    setupBindings()
    
    setListViewController(historyListViewController)
  }
  
  func setupBindings() {
    viewModel.didUpdateState = { [weak self] state in
      self?.setState(state, animated: false)
    }
    
    viewModel.didUpdateEmptyModel = { [weak self] model in
      self?.emptyViewController.configure(model: model)
    }
    
    viewModel.didUpdateIsConnecting = { [weak self] isConnecting in
      self?.customView.navigationBarView.isConnecting = isConnecting
    }
  }
}
