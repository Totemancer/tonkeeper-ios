import UIKit
import TKUIKit

final class LedgerConnectView: TKView, ConfigurableView {

  let containerView = UIView()
  let contentView = LedgerContentView()
  let buttonsStackView = UIStackView()
  let cancelButton = TKButton()
  let continueButton = TKButton()
  
  override func setup() {
    addSubview(containerView)
    containerView.addSubview(contentView)
    containerView.addSubview(buttonsStackView)
    
    buttonsStackView.spacing = .buttonsSpacing
    buttonsStackView.distribution = .fillEqually
    
    buttonsStackView.addArrangedSubview(cancelButton)
    buttonsStackView.addArrangedSubview(continueButton)
    
    containerView.snp.makeConstraints { make in
      make.edges.equalTo(self)
    }
    
    contentView.snp.makeConstraints { make in
      make.top.equalTo(containerView)
      make.left.equalTo(containerView).inset(16)
      make.right.equalTo(containerView).inset(16).priority(.required.advanced(by: -1))
    }
    
    buttonsStackView.snp.makeConstraints { make in
      make.top.equalTo(contentView.snp.bottom).offset(UIEdgeInsets.buttonsPadding.top)
      make.left.equalTo(containerView).inset(UIEdgeInsets.buttonsPadding)
      make.right.bottom.equalTo(containerView).inset(UIEdgeInsets.buttonsPadding)
        .priority(.required.advanced(by: -1))
    }
  }
  
  struct Model {
    let contentViewModel: LedgerContentView.Model
    let cancelButton: TKButton.Configuration
    let continuteButton: TKButton.Configuration
  }
  
  func configure(model: Model) {
    contentView.configure(model: model.contentViewModel)
    cancelButton.configuration = model.cancelButton
    continueButton.configuration = model.continuteButton
  }
}

private extension CGFloat {
  static let buttonsSpacing: CGFloat = 16
}

private extension UIEdgeInsets {
  static let buttonsPadding = UIEdgeInsets(top: 32, left: 16, bottom: 16, right: 16)
}
