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
final class Group {
    var id: UUID
    var name: String
    var colorName: String // For visual distinction
    var iconName: String? // SF Symbol
    var sortOrder: Int
    var createdAt: Date
    
    init(name: String, colorName: String = "blue", iconName: String? = nil, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.colorName = colorName
        self.iconName = iconName
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }
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
    var group: Group? // Associated group

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
        notes: String? = nil,
        group: Group? = nil
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
        self.group = group
    }
}
