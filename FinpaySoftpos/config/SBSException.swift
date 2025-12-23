//
//  SBSException.swift
//  FinpaySoftpos
//
//  Created by Gamal Ragab on 07/09/2025.
//

enum SBSException: Error {
    case readerNotSupported
    case readerNotInitialized
    case iOSVersionBelow_16_4
    case sessionNotInitialized
    case cardReadFailed(String)
    case accountLinkedError(String)
    case tokenExpiered(String)
}
