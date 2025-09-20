//
//  OTPService.swift
//  Purple
//
//  Created by Jimmy Bosse on 9/20/25.
//

import Foundation
import Combine

class OTPService: ObservableObject {
    static let shared = OTPService()

    @Published var currentCodes: [UUID: String] = [:]
    @Published var timeRemaining: [UUID: Int] = [:]
    @Published var progress: [UUID: Double] = [:]

    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        startTimer()
    }

    deinit {
        stopTimer()
    }

    // MARK: - Timer Management

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateAllCodes()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Code Generation

    func generateCode(for account: OTPAccount) -> String? {
        guard let secretData = KeychainManager.shared.retrieve(for: account.secretKeyIdentifier) else {
            return nil
        }

        switch account.type {
        case .totp:
            return OTPGenerator.generateTOTP(
                secret: secretData,
                algorithm: account.algorithm,
                digits: account.digits,
                period: account.period
            )
        case .hotp:
            return OTPGenerator.generateHOTP(
                secret: secretData,
                counter: Int64(account.counter),
                algorithm: account.algorithm,
                digits: account.digits
            )
        }
    }

    // MARK: - Update Codes

    func updateCode(for account: OTPAccount) {
        if let code = generateCode(for: account) {
            currentCodes[account.id] = code

            if account.type == .totp {
                timeRemaining[account.id] = OTPGenerator.timeRemaining(for: account.period)
                progress[account.id] = OTPGenerator.progress(for: account.period)
            }
        }
    }

    func updateAllCodes() {
        // This will be called from the main view to update all visible accounts
        objectWillChange.send()
    }

    // MARK: - Account Management

    func addAccount(
        serviceName: String,
        accountName: String,
        secretKey: String,
        algorithm: OTPAlgorithm = .sha1,
        digits: Int = 6,
        period: Int = 30,
        type: OTPType = .totp
    ) -> OTPAccount? {
        let secretIdentifier = KeychainManager.generateSecretIdentifier()

        guard KeychainManager.shared.storeBase32Secret(secretKey, for: secretIdentifier) else {
            return nil
        }

        let account = OTPAccount(
            serviceName: serviceName,
            accountName: accountName,
            secretKeyIdentifier: secretIdentifier,
            algorithm: algorithm,
            digits: digits,
            period: period,
            type: type
        )

        updateCode(for: account)
        return account
    }

    func deleteAccount(_ account: OTPAccount) {
        // Remove from Keychain
        _ = KeychainManager.shared.delete(for: account.secretKeyIdentifier)

        // Remove from local storage
        currentCodes.removeValue(forKey: account.id)
        timeRemaining.removeValue(forKey: account.id)
        progress.removeValue(forKey: account.id)
    }

    // MARK: - Code Copying

    func copyCodeToClipboard(_ code: String) {
        UIPasteboard.general.string = code

        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }

    // MARK: - OTPAuth URL Parsing

    func parseOTPAuthURL(_ url: String) -> (serviceName: String, accountName: String, secret: String, algorithm: OTPAlgorithm, digits: Int, period: Int, type: OTPType)? {
        guard let urlComponents = URLComponents(string: url),
              urlComponents.scheme == "otpauth",
              let host = urlComponents.host,
              let type = OTPType(rawValue: host.uppercased()) else {
            return nil
        }

        let path = urlComponents.path.dropFirst() // Remove leading "/"
        let pathComponents = path.components(separatedBy: ":")

        let serviceName = pathComponents.first ?? "Unknown Service"
        let accountName = pathComponents.count > 1 ? pathComponents[1] : "Unknown Account"

        guard let queryItems = urlComponents.queryItems,
              let secret = queryItems.first(where: { $0.name == "secret" })?.value else {
            return nil
        }

        let algorithm = queryItems.first(where: { $0.name == "algorithm" })?.value
            .flatMap { OTPAlgorithm(rawValue: $0.uppercased()) } ?? .sha1

        let digits = queryItems.first(where: { $0.name == "digits" })?.value
            .flatMap { Int($0) } ?? 6

        let period = queryItems.first(where: { $0.name == "period" })?.value
            .flatMap { Int($0) } ?? 30

        return (serviceName, accountName, secret, algorithm, digits, period, type)
    }
}

// MARK: - UIKit Bridge

import UIKit

extension OTPService {
    func triggerHapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}
