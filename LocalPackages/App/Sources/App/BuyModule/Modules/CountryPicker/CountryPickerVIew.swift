import UIKit
import TKUIKit

final class CountryPickerView: TKView {
  let collectionView = TKUICollectionView(frame: .zero, collectionViewLayout: .init())

  override func setup() {
    super.setup()
    
    backgroundColor = .Background.page
    collectionView.backgroundColor = .Background.page
    
    addSubview(collectionView)
    
    setupConstraints()
  }
  
  override func setupConstraints() {
    collectionView.snp.makeConstraints { make in
      make.edges.equalTo(self)
    }
  }
}

