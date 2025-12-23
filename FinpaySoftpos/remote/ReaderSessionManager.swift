//
//  ReaderSessionManager.swift
//  FinpaySoftpos
//
//  Created by Gamal Ragab on 03/09/2025.
//

import Foundation
import os.log
import Combine
import SwiftUI

#if canImport(ProximityReader)
import ProximityReader
#endif

/// Manages the lifecycle of the PaymentCardReader and session operations.
public final class ReaderSessionManager:ObservableObject {
    
    // MARK: - Properties
    private var logger: ReaderLogger = ConsoleReaderLogger()
    
    fileprivate var reader: PaymentCardReader?
    fileprivate var session: PaymentCardReaderSession?
    
    /// Stores the last successful card read result.
    public private(set) var lastPaymentCardResult: PaymentCardReadResult?
    
    /// Stores the token used for reader operations.
    private var readerToken: String = ""
    
    // MARK: - Initialization
    
    /// Initializes the reader and ensures terms & conditions are accepted.
    public func initialize(_ token: String? = nil) async throws {
        
        let consoleLogger: ReaderLogger = ConsoleReaderLogger()
        let fileLogger: ReaderLogger = FileReaderLogger() ?? ConsoleReaderLogger()
        // Explicit type annotation here 👇 fixes the ambiguity
        self.logger = CompositeReaderLogger(loggers: [consoleLogger, fileLogger] as [ReaderLogger])
        
        
        readerToken = token ?? ""
        logger.log("🔄 Initializing ReaderSessionManager...")
        
        try await createProximityReader()
        try await presentTermsAndConditions()
        
        logger.log("✅ ReaderSessionManager initialization completed.")
    }
    
    // MARK: - Setup
    
    /// Creates the Proximity Reader instance.
    private func createProximityReader() async throws {
        guard PaymentCardReader.isSupported else {
            logger.log("❌ Tap to Pay is not supported on this device.")
            throw SBSException.readerNotSupported
        }
        
        reader = PaymentCardReader()
        logger.log("✅ PaymentCardReader initialized successfully.")
    }
    
    /// Presents terms & conditions if not already accepted by the merchant.
    private func presentTermsAndConditions() async throws {
        let token = TokenProvider.tokenProvider.buildToken(readerToken)
        logger.log("🔄 Checking Terms & Conditions with token: \(token.rawValue)")
        
        guard let reader else {
            logger.log("❌ Reader is nil, aborting Terms & Conditions check.")
            throw SBSException.readerNotInitialized
        }
        
        if #available(iOS 16.4, *) {
            if try await !reader.isAccountLinked(using: token) {
                do {
                    try await reader.linkAccount(using: token)
                    logger.log("✅ Account successfully linked.")
                } catch {
                    logger.log("❌ Error linking account: \(error.localizedDescription)")
                    throw SBSException.accountLinkedError(error.localizedDescription)
                }
            } else {
                logger.log("ℹ️ Account already linked, skipping.")
            }
        } else {
            logger.log("❌ iOS version below 16.4, Terms & Conditions not supported.")
            throw SBSException.iOSVersionBelow_16_4
        }
    }
    
    // MARK: - Configuration
    
    /// Configures the device and streams progress updates until completion.
    @available(iOS 16.0, *)
    public func configureDevice() -> AsyncThrowingStream<Int, Error> {
        AsyncThrowingStream { continuation in
            Task {
                guard let reader else {
                    continuation.finish(throwing: SBSException.readerNotInitialized)
                    return
                }

                let token = TokenProvider.tokenProvider.buildToken(readerToken)
                logger.log("🔄 Starting device configuration with token: \(token.rawValue)")

                do {
                    var didSeeProgress = false

                    // Timeout safeguard
                    Task {
                        try? await Task.sleep(nanoseconds: 10_000_000_000) // 8s
                        if !Task.isCancelled && !didSeeProgress {
                            continuation.yield(100)
                            continuation.finish()
                        }
                    }

                    let events = reader.events

                    Task {
                        for await event in events {
                            if case .updateProgress(let progress) = event {
                                didSeeProgress = true
                                logger.log("📈 Configuration progress: \(progress)%")
                                continuation.yield(progress)

                                if progress >= 100 {
                                    logger.log("✅ Reader successfully prepared.")
                                    continuation.finish()
                                }
                            } else {
                                logger.log("ℹ️ Event received during configuration: \(event)")
                            }
                        }
                    }

                    self.session = try await reader.prepare(using: token)
                    logger.log("✅ Session created successfully. Listening for progress updates...")
                } catch {
                    logger.log("❌ Failed to prepare reader: \(error.localizedDescription)")
                    continuation.finish(throwing: SBSException.tokenExpiered(error.localizedDescription))
                }
            }
        }
    }

    
    // MARK: - Operations
    
    /// Reads a payment card and returns the result.
    public func readCard(amount: Decimal,currencyCode: String,transactionType:  PaymentCardTransactionRequest.TransactionType) async throws -> PaymentCardReadResult {
        guard let session else {
            logger.log("❌ Session is nil, cannot read card.")
            throw SBSException.sessionNotInitialized
        }
        
        logger.log("🔄 Starting card read with:")
        logger.log("   • Amount: \(amount)")
        logger.log("   • Currency: \(currencyCode)")
        logger.log("   • TransactionType: \(transactionType)")
        
        let request = PaymentCardTransactionRequest(
            amount: amount,
            currencyCode: currencyCode,
            for: transactionType
        )
        
        do {
            let result = try await session.readPaymentCard(request)
            logger.log("✅ Card read succeeded. Raw result: \(result)")
            
            if #available(iOS 16.4, *) {
                self.lastPaymentCardResult = result
//                lastPaymentCardResult = try await capturePIN()
                return lastPaymentCardResult!
            } else {
                logger.log("⚠️ iOS version below 16.4, card read not supported.")
                throw SBSException.iOSVersionBelow_16_4
            }
        } catch {
            logger.log("❌ Card read failed: \(error.localizedDescription)")
            throw SBSException.cardReadFailed(error.localizedDescription)
        }
    }
    
    // MARK: - PIN Capture
    
    /// Captures the cardholder's PIN after a successful card read.
    ///
    /// - Parameters:
    ///   - token: The PIN token provided by the reader session after a card read.
    ///   - cardReaderTransactionID: The ID of the transaction to link the PIN to.
    /// - Returns: A `PaymentCardReadResult` including the PIN capture result.
    @available(iOS 16.0, macCatalyst 17.0, *)
    public func capturePIN() async throws -> PaymentCardReadResult {
        
        guard let session else {
            logger.log("❌ Session is nil, cannot capture PIN.")
            throw SBSException.sessionNotInitialized
        }
        
        let pinTokendd = "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjNkNjNkNjViLWJhMDktNGVhMS05N2YwLTczYzg3MzdkYTkyYSJ9.eyJhdWQiOiJjZXJ0aWZpY2F0aW9uLXBvcy12MSIsImV4cCI6MTc1Nzc2Mjg2NywiaWF0IjoxNzU3NTkwMDY3LCJqdGkiOiI0YzEyN2MyYS02ZTE0LTQyODgtYThlZS02NWY3NjBiYzJlM2EiLCJtaWQiOiIxMDEwMTAwMTAxIiwibWJuIjoiTWluZVNlYyIsIm1jYyI6MTAwMCwidHBpZCI6IjRjNzAyMDAwLTAwMDAtMDAwMC0wNWE5LTg3ZTc2ODdkYTYyOCJ9.WpCZtd1dM0cLXMm0grFc5rnVZIPWRrzsyKgKnJpVOHChUzntkxk6o1tLB6m4_mgQSZKvNL1QyOZdTK4C3vucHg"
        
        let token = TokenProvider.tokenProvider.buildPinToken(pinTokendd)
        logger.log("🔄 Starting PIN capture  with token: \(token.rawValue)")
        
        logger.log("🔄 Starting PIN capture for transaction ID: \(String(describing: lastPaymentCardResult?.id))")
        
        do {
            let result = try await session.capturePIN(using: token,
                                                      cardReaderTransactionID: "25727353-8a22-471a-ac13-ddf2d843fe10")
            
            logger.log("✅ PIN captured successfully. Result: \(result)")
            
            // Store last result so it can be accessed later.
            if #available(iOS 16.4, *) {
                self.lastPaymentCardResult = result
            }
            
            return result
        } catch {
            logger.log("❌ Failed to capture PIN: \(error.localizedDescription)")
            throw SBSException.cardReadFailed("PIN capture failed: \(error.localizedDescription)")
        }
    }
}
