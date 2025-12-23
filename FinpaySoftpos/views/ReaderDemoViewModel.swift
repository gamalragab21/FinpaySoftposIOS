//
//  ReaderDemoViewModel.swift
//  FinpaySoftpos
//
//  Created by Gamal Ragab on 07/09/2025.
//

import Foundation
import SwiftUI
import ProximityReader

@MainActor
class ReaderDemoViewModel: ObservableObject {
    
    @Published var token: String = ReaderConfig.defaultToken
    @Published var amount: Decimal = ReaderConfig.defaultAmount
    @Published var currency: String = ReaderConfig.defaultCurrency
    @Published var transactionType: PaymentCardTransactionRequest.TransactionType = ReaderConfig.defaultTransactionType
    
    @Published var progress: Int = 0
    @Published var resultMessage: String?
    
    @Published var isInitialized: Bool = false
    @Published var isConfigured: Bool = false
    @Published var isConfiguring: Bool = false
    
    private let manager = ReaderSessionManager()
    
    func initializeReader() async {
        do {
            try await manager.initialize()
            isInitialized = true
            resultMessage = "✅ Reader initialized successfully."
        } catch {
            resultMessage = "❌ Initialization failed: \(error.localizedDescription)"
        }
    }
    
    func configureReader() async {
        isConfiguring = true
        progress = 0
        
        do {
            for try await p in manager.configureDevice() {
                progress = p
            }
            isConfigured = true
            resultMessage = "✅ Reader configured successfully."
        } catch {
            resultMessage = "❌ Configuration failed: \(error.localizedDescription)"
        }
        
        isConfiguring = false
    }
    
    func readCard() async {
        do {
            let result = try await manager.readCard()
            resultMessage = "✅ Card read result:\n\(String(describing: result))"
        } catch {
            resultMessage = "❌ Card read failed: \(error.localizedDescription)"
        }
    }
}
