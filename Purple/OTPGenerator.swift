//
//  OTPGenerator.swift
//  Purple
//
//  Created by Jimmy Bosse on 9/20/25.
//

import Foundation
import CryptoKit
import CommonCrypto

class OTPGenerator {

    // MARK: - TOTP Generation

    static func generateTOTP(
        secret: Data,
        algorithm: OTPAlgorithm = .sha1,
        digits: Int = 6,
        period: Int = 30,
        timestamp: Date = Date()
    ) -> String {
        let timeCounter = Int64(timestamp.timeIntervalSince1970) / Int64(period)
        return generateHOTP(secret: secret, counter: timeCounter, algorithm: algorithm, digits: digits)
    }

    // MARK: - HOTP Generation

    static func generateHOTP(
        secret: Data,
        counter: Int64,
        algorithm: OTPAlgorithm = .sha1,
        digits: Int = 6
    ) -> String {
        // Convert counter to big-endian bytes
        var counterData = Data(count: 8)
        counterData.withUnsafeMutableBytes { bytes in
            let buffer = bytes.bindMemory(to: UInt64.self)
            buffer[0] = UInt64(counter).bigEndian
        }

        // Generate HMAC
        let hmac = calculateHMAC(data: counterData, key: secret, algorithm: algorithm)

        // Dynamic truncation
        let offset = Int(hmac[hmac.count - 1] & 0x0f)
        let truncatedHash = hmac.subdata(in: offset..<(offset + 4))

        var otp: UInt32 = 0
        truncatedHash.withUnsafeBytes { bytes in
            otp = bytes.load(as: UInt32.self).bigEndian
        }

        otp &= 0x7fffffff
        otp %= UInt32(pow(10, Double(digits)))

        return String(format: "%0\(digits)d", otp)
    }

    // MARK: - HMAC Calculation

    private static func calculateHMAC(data: Data, key: Data, algorithm: OTPAlgorithm) -> Data {
        switch algorithm {
        case .sha1:
            return Data(HMAC<Insecure.SHA1>.authenticationCode(for: data, using: SymmetricKey(data: key)))
        case .sha256:
            return Data(HMAC<SHA256>.authenticationCode(for: data, using: SymmetricKey(data: key)))
        case .sha512:
            return Data(HMAC<SHA512>.authenticationCode(for: data, using: SymmetricKey(data: key)))
        }
    }

    // MARK: - Time Remaining

    static func timeRemaining(for period: Int, at timestamp: Date = Date()) -> Int {
        let elapsed = Int(timestamp.timeIntervalSince1970) % period
        return period - elapsed
    }

    // MARK: - Progress (0.0 - 1.0)

    static func progress(for period: Int, at timestamp: Date = Date()) -> Double {
        let elapsed = Int(timestamp.timeIntervalSince1970) % period
        return Double(elapsed) / Double(period)
    }

    // MARK: - Secret Key Validation

    static func isValidBase32Secret(_ secret: String) -> Bool {
        let cleanSecret = secret.replacingOccurrences(of: " ", with: "").uppercased()
        let base32Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        return cleanSecret.allSatisfy { base32Alphabet.contains($0) }
    }

    // MARK: - Base32 Decoding

    static func decodeBase32Secret(_ secret: String) -> Data? {
        let cleanSecret = secret.replacingOccurrences(of: " ", with: "").uppercased()

        guard isValidBase32Secret(cleanSecret) else {
            return nil
        }

        return Data(base32Encoded: cleanSecret)
    }
}

// MARK: - Base32 Data Extension

extension Data {
    init?(base32Encoded string: String) {
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        let cleanString = string.uppercased().replacingOccurrences(of: " ", with: "")

        var result = Data()
        var buffer: UInt64 = 0
        var bitsLeft = 0

        for char in cleanString {
            guard let index = alphabet.firstIndex(of: char) else {
                return nil
            }

            buffer = (buffer << 5) | UInt64(alphabet.distance(from: alphabet.startIndex, to: index))
            bitsLeft += 5

            if bitsLeft >= 8 {
                result.append(UInt8((buffer >> (bitsLeft - 8)) & 0xFF))
                bitsLeft -= 8
            }
        }

        self = result
    }
}
