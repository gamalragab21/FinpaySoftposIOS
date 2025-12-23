//
//  Config.swift
//  FinpaySoftpos
//
//  Created by Gamal Ragab on 03/09/2025.
//

import Foundation
#if canImport(ProximityReader)
import ProximityReader
#endif


public struct ReaderConfig {
    public static let defaultToken: String = "<your default token here>"
    public static let defaultCurrency: String = "USD"
    public static let defaultAmount: Decimal = 25.0
    public static let defaultTransactionType: PaymentCardTransactionRequest.TransactionType = .purchase
}
