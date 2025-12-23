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
    
    @Published var token: String = ""
    @Published var amount: Decimal = ReaderConfig.defaultAmount
    @Published var currency: String = ReaderConfig.defaultCurrency
    @Published var transactionType: PaymentCardTransactionRequest.TransactionType = ReaderConfig.defaultTransactionType
    
    @Published var showTransactionPopup = false
    @Published var lastTransactionSummary = ""
    
    // Validation errors
    @Published var tokenError: String? = nil
    @Published var amountError: String? = nil
    @Published var currencyError: String? = nil
    
    @Published var progress: Int = 0
    @Published var resultMessages: [String] = []
    
    @Published var isInitialized: Bool = false
    @Published var isConfigured: Bool = false
    @Published var isConfiguring: Bool = false
    @Published var isSetupCompleted: Bool = false  // new state
    
    private let manager = ReaderSessionManager()
    
    // MARK: - Lifecycle
    func startAutoSetup() async {
        addResult("🚀 Starting automatic setup...")
        await fetchToken()
        
        guard !token.isEmpty else {
            addResult("❌ Token is empty, setup aborted.")
            return
        }
        
        await initializeReader()
        
        guard isInitialized else {
            addResult("❌ Initialization failed, setup aborted.")
            return
        }
        
        await configureReader()
        
        if isConfigured {
            addResult("✅ Reader setup completed successfully.")
            isSetupCompleted = true
        } else {
            addResult("❌ Configuration failed.")
        }
    }
    
    // MARK: - Reader Steps
    
    func initializeReader() async {
        do {
            try await manager.initialize(token)
            isInitialized = true
            addResult("✅ Reader initialized successfully.")
        } catch {
            isInitialized = false
            addResult("❌ Initialization failed: \(error.localizedDescription)")
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
            addResult("✅ Reader configured successfully.")
        } catch {
            isConfigured = false
            addResult("❌ Configuration failed: \(error.localizedDescription)")
        }
        
        isConfiguring = false
    }
    
    func readCard() async {
        do {
            let result = try await manager.readCard(amount: amount, currencyCode: currency, transactionType: transactionType)
            lastTransactionSummary = """
                     ✅ Transaction Successful
                     
                     Type: \(transactionType.self)
                     Amount: \(amount)
                     Currency: \(currency)
                     """
            showTransactionPopup = true
            addResult("✅ Card read result:\n\(String(describing: result))")
        } catch {
            addResult("❌ Card read failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Utilities
    
    func addResult(_ message: String) {
        withAnimation {
            resultMessages.append(message)
        }
    }
    
    func clearResults() {
        resultMessages.removeAll()
        FileReaderLogger.clearLogs()
    }
}
