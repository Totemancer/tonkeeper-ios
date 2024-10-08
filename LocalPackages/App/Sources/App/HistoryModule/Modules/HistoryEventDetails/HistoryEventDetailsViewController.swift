import UIKit
import TKUIKit

final class HistoryEventDetailsViewController: GenericViewViewController<HistoryEventDetailsView>, TKBottomSheetScrollContentViewController {
  var scrollView: UIScrollView {
    popUpViewController.scrollView
  }
  
  var didUpdateHeight: (() -> Void)?
  
  var headerItem: TKUIKit.TKPullCardHeaderItem?
  
  var didUpdatePullCardHeaderItem: ((TKUIKit.TKPullCardHeaderItem) -> Void)?
  
  func calculateHeight(withWidth width: CGFloat) -> CGFloat {
    popUpViewController.calculateHeight(withWidth: width)
  }

  private let viewModel: HistoryEventDetailsViewModel
  
  private let popUpViewController = TKPopUp.ViewController()
  
  init(viewModel: HistoryEventDetailsViewModel) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setup()
    setupBindings()
    viewModel.viewDidLoad()
  }
}

private extension HistoryEventDetailsViewController {
  func setupBindings() {
    viewModel.didUpdateConfiguration = { [weak self] configuration in
      self?.popUpViewController.configuration = configuration
      self?.didUpdateHeight?()
    }
  }
  
  func setup() {
    setupModalContent()
  }
  
  func setupModalContent() {
    addChild(popUpViewController)
    customView.embedContent(popUpViewController.view)
    popUpViewController.didMove(toParent: self)
  }
}
