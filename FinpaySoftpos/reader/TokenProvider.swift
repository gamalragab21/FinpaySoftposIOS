//
//  TokenProvider.swift
//  FinpaySoftpos
//
//  Created by Gamal Ragab on 03/09/2025.
//


import Foundation
#if canImport(ProximityReader)
import ProximityReader


@available(iOS 15.4, *)
class TokenProvider {

    static let tokenProvider = TokenProvider()

    func buildToken(_ token: String? = nil) -> PaymentCardReader.Token {
        let finalToken = token?.isEmpty == false ? token! : ReaderConfig.defaultToken
        
        #if targetEnvironment(simulator)
        return PaymentCardReader.Token(rawValue: finalToken)
        #else
        // In production, you should use a fetched token from your PSP.
        return PaymentCardReader.Token(rawValue: finalToken)
        #endif
    }
    
    func buildPinToken(_ token: String? = nil) -> PaymentCardReaderSession.PINToken {
        let finalToken = token?.isEmpty == false ? token! : ReaderConfig.defaultToken
        
        #if targetEnvironment(simulator)
        return PaymentCardReaderSession.PINToken(rawValue: finalToken)
        #else
        // In production, you should use a fetched token from your PSP.
        return PaymentCardReaderSession.PINToken(rawValue: finalToken)
        #endif
    }
}
#endif
