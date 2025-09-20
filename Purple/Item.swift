//
//  OTPAccount.swift
//  Purple
//
//  Created by Jimmy Bosse on 9/20/25.
//

import Foundation
import SwiftData

enum OTPAlgorithm: String, Codable, CaseIterable {
    case sha1 = "SHA1"
    case sha256 = "SHA256"
    case sha512 = "SHA512"
}

enum OTPType: String, Codable, CaseIterable {
    case totp = "TOTP"
    case hotp = "HOTP"
}

@Model
final class OTPAccount {
    var id: UUID
    var serviceName: String
    var accountName: String
    var secretKeyIdentifier: String // Keychain identifier, not the actual secret
    var algorithm: OTPAlgorithm
    var digits: Int
    var period: Int // For TOTP
    var counter: Int // For HOTP
    var type: OTPType
    var createdAt: Date
    var lastUsed: Date?
    var isFavorite: Bool
    var iconName: String? // SF Symbol or custom icon
    var notes: String?

    init(
        serviceName: String,
        accountName: String,
        secretKeyIdentifier: String,
        algorithm: OTPAlgorithm = .sha1,
        digits: Int = 6,
        period: Int = 30,
        counter: Int = 0,
        type: OTPType = .totp,
        iconName: String? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.serviceName = serviceName
        self.accountName = accountName
        self.secretKeyIdentifier = secretKeyIdentifier
        self.algorithm = algorithm
        self.digits = digits
        self.period = period
        self.counter = counter
        self.type = type
        self.createdAt = Date()
        self.lastUsed = nil
        self.isFavorite = false
        self.iconName = iconName
        self.notes = notes
    }
}
