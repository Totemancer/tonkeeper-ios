import UIKit
import TKUIKit
import SnapKit

final class WalletContainerTopBarView: UIView, ConfigurableView {
  
  var isSeparatorHidden = true {
    didSet { separatorView.isHidden = isSeparatorHidden }
  }
  
  private let separatorView: UIView = {
    let view = UIView()
    view.backgroundColor = .Separator.common
    view.isHidden = true
    return view
  }()
  
  private let contentContainerView = UIView()
  let walletButton = WalletContainerWalletButton()
  private let settingsButton = TKIndicatorButton(frame: .zero)
  private let blurView = TKBlurView()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  struct Model {
    struct SettingsButtonModel {
      let configuration: TKButton.Configuration
      let isIndicatorVisible: Bool
    }
    let walletButtonConfiguration: WalletContainerWalletButton.Model
    let settingButtonConfiguration: SettingsButtonModel
  }
  
  func configure(model: Model) {
    walletButton.configure(model: model.walletButtonConfiguration)
    settingsButton.configuration = model.settingButtonConfiguration.configuration
    settingsButton.configureIndicatorVisibility(model.settingButtonConfiguration.isIndicatorVisible)
  }
}

private extension WalletContainerTopBarView {
  func setup() {
    addSubview(blurView)
    addSubview(contentContainerView)
    addSubview(separatorView)
    contentContainerView.addSubview(settingsButton)
    contentContainerView.addSubview(walletButton)
    setupConstraints()
  }
  
  func setupConstraints() {
    settingsButton.setContentHuggingPriority(.required, for: .horizontal)
    settingsButton.setContentCompressionResistancePriority(.required, for: .horizontal)
    
    blurView.snp.makeConstraints { make in
      make.edges.equalTo(self)
    }
    
    walletButton.snp.makeConstraints { make in
      make.centerX.equalTo(contentContainerView)
      make.centerY.equalTo(contentContainerView)
      make.right.lessThanOrEqualTo(settingsButton.snp.left)
    }
    
    contentContainerView.snp.makeConstraints { make in
      make.top.equalTo(safeAreaLayoutGuide)
      make.left.right.bottom.equalTo(self)
      make.height.equalTo(64)
    }
    
    settingsButton.snp.makeConstraints { make in
      make.right.equalTo(contentContainerView).inset(CGFloat.settingsButtonRightInset)
      make.centerY.equalTo(contentContainerView)
    }
    
    separatorView.snp.makeConstraints { make in
      make.left.right.equalTo(self)
      make.bottom.equalTo(self)
      make.height.equalTo(TKUIKit.Constants.separatorWidth)
    }
  }
}

private extension CGFloat {
  static let walletButtonTopInset: CGFloat = 12
  static let walletButtonBottomInset: CGFloat = 12
  static let settingsButtonRightInset: CGFloat = 8
}
