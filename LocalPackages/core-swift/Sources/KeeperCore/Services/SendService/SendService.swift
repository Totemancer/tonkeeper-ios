import Foundation
import TonAPI
import TonSwift

public protocol SendService {
  func loadSeqno(wallet: Wallet) async throws -> UInt64
  func loadTransactionInfo(boc: String, wallet: Wallet) async throws -> TonAPI.MessageConsequences
  func sendTransaction(boc: String, wallet: Wallet) async throws
  func getTimeoutSafely(wallet: Wallet, TTL: UInt64) async -> UInt64
  func getJettonCustomPayload(wallet: Wallet, jetton: Address) async throws -> JettonTransferPayload
  func getIndexingLatency(wallet: Wallet) async throws -> Int
}

final class SendServiceImplementation: SendService {
  private let apiProvider: APIProvider
  
  init(apiProvider: APIProvider) {
    self.apiProvider = apiProvider
  }
  
  func loadSeqno(wallet: Wallet) async throws -> UInt64 {
    try await UInt64(apiProvider.api(wallet.isTestnet).getSeqno(address: wallet.address))
  }
  
  func loadTransactionInfo(boc: String, wallet: Wallet) async throws -> TonAPI.MessageConsequences {
    try await apiProvider.api(wallet.isTestnet)
      .emulateMessageWallet(boc: boc)
  }
  
  func sendTransaction(boc: String, wallet: Wallet) async throws {
    try await apiProvider.api(wallet.isTestnet)
      .sendTransaction(boc: boc)
  }
  
  func getIndexingLatency(wallet: Wallet) async throws -> Int {
    try await apiProvider.api(wallet.isTestnet)
      .getStatus()
  }
  
  func getTimeoutSafely(wallet: Wallet, TTL: UInt64) async -> UInt64 {
    do {
      return try await UInt64(apiProvider.api(wallet.isTestnet)
        .getTime()) + TTL
    } catch {
      return UInt64(Date().timeIntervalSince1970) + TTL
    }
  }
  
  func getJettonCustomPayload(wallet: Wallet, jetton: Address) async throws -> JettonTransferPayload {
    try await apiProvider.api(wallet.isTestnet).getCustomPayload(address: wallet.address, jettonAddress: jetton)
  }
}

public extension SendService {
  func getTimeoutSafely(wallet: Wallet, TTL: UInt64 = TonSwift.DEFAULT_TTL) async -> UInt64 {
    return await getTimeoutSafely(wallet: wallet, TTL: TTL)
  }
}
