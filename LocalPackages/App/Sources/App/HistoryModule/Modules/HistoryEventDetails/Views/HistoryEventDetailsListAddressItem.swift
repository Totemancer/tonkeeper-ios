import UIKit
import TKUIKit

struct HistoryEventDetailsListAddressItem: TKListContainerItem {
  func getView() -> UIView {
    let view = HistoryEventDetailsListAddressView(
      configuration: HistoryEventDetailsListAddressView.Configuration(
        title: title,
        value: value
      )
    )
    return view
  }
  
  private let title: String
  private let value: String
  let isHighlightable: Bool
  let copyValue: String?

  init(title: String,
       value: String,
       copyValue: String?,
       isHighlightable: Bool) {
    self.title = title
    self.value = value
    self.copyValue = copyValue
    self.isHighlightable = isHighlightable
  }
}

final class HistoryEventDetailsListAddressView: UIView {
  
  struct Configuration {
    let title: String
    let value: String
  }
  
  private let configuration: Configuration
  
  private let stackView = UIStackView()
  private let titleLabel = UILabel()
  private let valueLabel = UILabel()

  init(configuration: Configuration) {
    self.configuration = configuration
    super.init(frame: .zero)
    setup()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    stackView.axis = .vertical
    stackView.alignment = .leading
    
    addSubview(stackView)
    stackView.addArrangedSubview(titleLabel)
    stackView.addArrangedSubview(valueLabel)
    
    setupConstraints()
    setupConfiguration()
  }
  
  private func setupConstraints() {
    stackView.snp.makeConstraints { make in
      make.edges.equalTo(self).inset(16)
    }
  }
  
  private func setupConfiguration() {
    titleLabel.attributedText = configuration.title.withTextStyle(
      .body1,
      color: .Text.secondary,
      alignment: .left,
      lineBreakMode: .byTruncatingTail
    )
    valueLabel.attributedText = configuration.value.withTextStyle(
      .label1,
      color: .Text.primary,
      alignment: .left,
      lineBreakMode: .byTruncatingMiddle
    )
  }
}
