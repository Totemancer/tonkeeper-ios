import Foundation
import TonSwift
import BigInt

public enum Deeplink: Equatable {
  public struct TransferData: Equatable {
    public let recipient: String
    public let amount: BigUInt?
    public let comment: String?
    public let jettonAddress: Address?
  }
  
  public struct SwapData: Equatable {
    public let fromToken: String?
    public let toToken: String?
  }
  
  case transfer(TransferData)
  case buyTon
  case staking
  case pool(Address)
  case exchange(provider: String)
  case swap(SwapData)
  case action(eventId: String)
  case publish(sign: Data)
  case externalSign(ExternalSignDeeplink)
  case tonconnect(TonConnectParameters)
  case dapp(URL)
}

public enum ExternalSignDeeplink: Equatable {
  case link(publicKey: TonSwift.PublicKey, name: String)
}
