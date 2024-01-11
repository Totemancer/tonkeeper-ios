import UIKit
import TKCoordinator
import TKUIKit
import TKScreenKit
import Passcode

public final class ImportWalletCoordinator: RouterCoordinator<NavigationControllerRouter> {
  var didCancel: (() -> Void)?
  var didImportWallet: (() -> Void)?
  
  public override func start() {
    openInputRecoveryPhrase()
  }
}

private extension ImportWalletCoordinator {
  func openInputRecoveryPhrase() {
    let inputRecoveryPhrase = TKInputRecoveryPhraseAssembly.module(
      validator: InputRecoveryPhraseValidator(), 
      suggestsProvider: InputRecoveryPhraseSuggestsProvider()
    )
    
    inputRecoveryPhrase.output.didInputRecoveryPhrase = { [weak self] phrase in
      self?.openCreatePasscode()
    }
    
    inputRecoveryPhrase.viewController.setupBackButton()
    
    router.push(
      viewController: inputRecoveryPhrase.viewController,
      animated: true,
      onPopClosures: { [weak self] in
        self?.didCancel?()
      },
      completion: nil)
  }
  
  func openCreatePasscode() {
    let coordinator = Passcode().createCreatePasscodeCoordinator(router: router)
    
    coordinator.didCancel = { [weak self, weak coordinator] in
      guard let coordinator = coordinator else { return }
      self?.removeChild(coordinator)
    }
    
    coordinator.didCreatePasscode = { [weak self, weak coordinator] passcode in
      guard let coordinator = coordinator else { return }
      self?.removeChild(coordinator)
      self?.didImportWallet?()
    }
    
    addChild(coordinator)
    coordinator.start()
  }
}