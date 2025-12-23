//
//  TokenResponse.swift
//  FinpaySoftpos
//
//  Created by Gamal Ragab on 10/09/2025.
//

struct TokenResponse: Codable {
    let code: Int
    let msg: String
    let data: TokenData
}

struct TokenData: Codable {
    let token: String
}
