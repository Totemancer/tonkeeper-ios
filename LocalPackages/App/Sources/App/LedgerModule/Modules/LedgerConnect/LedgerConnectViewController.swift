import UIKit
import TKUIKit
import TKLocalize

final class LedgerConnectViewController: GenericViewViewController<LedgerConnectView>, TKBottomSheetContentViewController {
  private let viewModel: LedgerConnectViewModel
  
  // MARK: - TKBottomSheetContentViewController
  
  var didUpdateHeight: (() -> Void)?
  
  var headerItem: TKUIKit.TKPullCardHeaderItem? {
    TKUIKit.TKPullCardHeaderItem(title: TKLocales.LedgerConnect.title)
  }
  
  var didUpdatePullCardHeaderItem: ((TKUIKit.TKPullCardHeaderItem) -> Void)?
  
  func calculateHeight(withWidth width: CGFloat) -> CGFloat {
    customView.containerView.systemLayoutSizeFitting(
      CGSize(
        width: width,
        height: 0
      ),
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel
    ).height
  }
  
  init(viewModel: LedgerConnectViewModel) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupBindings()
    viewModel.viewDidLoad()
  }
}

private extension LedgerConnectViewController {
  func setupBindings() {
    viewModel.didUpdateModel = { [weak self] model in
      self?.customView.configure(model: model)
    }
    
    viewModel.didShowTurnOnBluetoothAlert = { [weak self] in
      self?.showTurnOnBluetoothAlert()
    }
  }
  
  func showTurnOnBluetoothAlert() {
    let alertController = UIAlertController(
      title: "Bluetooth is off",
      message: "Please turn on Bluetooth to use this feature",
      preferredStyle: .alert
    )
    alertController.addAction(UIAlertAction(title: "Open Settings", style: .default, handler: { _ in
      if let url = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
      }
    }))
    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    self.present(alertController, animated: true)
  }
}
