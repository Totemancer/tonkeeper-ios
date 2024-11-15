import Foundation
import TonSwift

public enum WalletContractVersion: String, Codable, CaseIterable, Comparable, Hashable {
  /// Regular wallets
  case v3R1, v3R2, v4R1, v4R2, v5Beta = "w5 beta", v5R1 = "w5"

  public static var currentVersion: WalletContractVersion {
    .v5R1
  }
  
  private var intValue: Int {
    switch self {
    case .v3R1:
      return 1
    case .v3R2:
      return 2
    case .v4R1:
      return 3
    case .v4R2:
      return 4
    case .v5Beta:
      return 5
    case .v5R1:
      return 6
    }
  }
  
  public static func < (lhs: WalletContractVersion, rhs: WalletContractVersion) -> Bool {
    lhs.intValue < rhs.intValue
  }
}

extension WalletContractVersion: CellCodable {
  public func storeTo(builder: Builder) throws {
    switch self {
    case .v3R1:
      try builder.store(uint: 1, bits: 4)
    case .v3R2:
      try builder.store(uint: 2, bits: 4)
    case .v4R1:
      try builder.store(uint: 3, bits: 4)
    case .v4R2:
      try builder.store(uint: 4, bits: 4)
    case .v5Beta:
      try builder.store(uint: 5, bits: 4)
    case .v5R1:
      try builder.store(uint: 6, bits: 4)
    }
  }
  
  public static func loadFrom(slice: Slice) throws -> WalletContractVersion {
    return try slice.tryLoad { s in
      let type = try s.loadUint(bits: 4)
      switch type {
      case 1:
        return .v3R1
      case 2:
        return .v3R2
      case 3:
        return .v4R1
      case 4:
        return .v4R2
      case 5:
        return .v5Beta
      case 6:
        return .v5R1
      default:
        throw TonError.custom("Invalid WalletContractVersion type");
      }
    }
  }
}
