//
//  ContentView.swift
//  Purple
//
//  Created by Jimmy Bosse on 9/20/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var accounts: [OTPAccount]
    @StateObject private var otpService = OTPService.shared
    @State private var showingAddAccount = false
    @State private var searchText = ""

    var filteredAccounts: [OTPAccount] {
        if searchText.isEmpty {
            return accounts.sorted { $0.serviceName < $1.serviceName }
        } else {
            return accounts.filter { account in
                account.serviceName.localizedCaseInsensitiveContains(searchText) ||
                account.accountName.localizedCaseInsensitiveContains(searchText)
            }.sorted { $0.serviceName < $1.serviceName }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundSecondary.ignoresSafeArea()

                VStack {
                    if accounts.isEmpty {
                        EmptyStateView {
                            showingAddAccount = true
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredAccounts) { account in
                                    OTPAccountCard(account: account, otpService: otpService)
                                        .transition(.asymmetric(
                                            insertion: .scale.combined(with: .opacity),
                                            removal: .opacity
                                        ))
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                        .searchable(text: $searchText, prompt: "Search accounts")
                    }
                }
            }
            .navigationTitle("Purple OTP")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation(.spring()) {
                            showingAddAccount = true
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.purplePrimary, Color.purpleSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }

                if !accounts.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                            .foregroundColor(.purplePrimary)
                    }
                }
            }
            .sheet(isPresented: $showingAddAccount) {
                AddAccountView(modelContext: modelContext)
            }
            .onAppear {
                updateAllCodes()
            }
        }
    }

    private func deleteAccounts(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let account = filteredAccounts[index]
                otpService.deleteAccount(account)
                modelContext.delete(account)
            }
        }
    }

    private func updateAllCodes() {
        for account in accounts {
            otpService.updateCode(for: account)
        }
    }
}

struct OTPAccountCard: View {
    let account: OTPAccount
    @ObservedObject var otpService: OTPService
    @State private var timeRemaining: Int = 0
    @State private var progress: Double = 0.0
    @State private var currentCode: String = ""
    @State private var timer: Timer?
    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.serviceName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(account.accountName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    if account.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }

                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.purplePrimary)
                        .font(.caption)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            // Code Section
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(formatCode(currentCode))
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.purplePrimary, Color.purpleSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .scaleEffect(isPressed ? 0.95 : 1.0)
                            .animation(.easeInOut(duration: 0.1), value: isPressed)

                        if account.type == .totp {
                            HStack(spacing: 6) {
                                Image(systemName: "clock")
                                    .foregroundColor(timeRemaining <= 5 ? .red : .secondary)
                                    .font(.caption2)

                                Text("Expires in \(timeRemaining)s")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(timeRemaining <= 5 ? .red : .secondary)
                            }
                        } else {
                            Text("HOTP Code")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    if account.type == .totp {
                        EnhancedCircularProgressView(progress: progress, timeRemaining: timeRemaining)
                            .frame(width: 50, height: 50)
                    } else {
                        Button(action: {
                            // TODO: Increment HOTP counter
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title3)
                                .foregroundColor(.purplePrimary)
                                .padding(12)
                                .background(Color.purpleLight)
                                .clipShape(Circle())
                        }
                    }
                }

                // Copy Button
                Button(action: {
                    if !currentCode.isEmpty {
                        isPressed = true
                        otpService.copyCodeToClipboard(currentCode)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isPressed = false
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "doc.on.clipboard")
                        Text("Copy Code")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .purpleButtonStyle()
                }
                .disabled(currentCode.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .cardStyle()
        .onAppear {
            updateCode()
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }

    private func formatCode(_ code: String) -> String {
        guard !code.isEmpty else { return "• • •  • • •" }
        let midIndex = code.index(code.startIndex, offsetBy: code.count / 2)
        return String(code[..<midIndex]) + "  " + String(code[midIndex...])
    }

    private func updateCode() {
        currentCode = otpService.generateCode(for: account) ?? ""

        if account.type == .totp {
            timeRemaining = OTPGenerator.timeRemaining(for: account.period)
            progress = OTPGenerator.progress(for: account.period)
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateCode()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

struct EnhancedCircularProgressView: View {
    let progress: Double
    let timeRemaining: Int

    var progressColor: Color {
        if timeRemaining <= 5 {
            return .red
        } else if timeRemaining <= 10 {
            return .orange
        } else {
            return .purplePrimary
        }
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(progressColor.opacity(0.2), lineWidth: 4)

            // Progress circle
            Circle()
                .trim(from: 0.0, to: CGFloat(progress))
                .stroke(
                    LinearGradient(
                        colors: [progressColor, progressColor.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1.0), value: progress)

            // Time text
            VStack(spacing: 2) {
                Text("\(timeRemaining)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(progressColor)

                Text("sec")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(progressColor.opacity(0.7))
            }
        }
    }
}

struct EmptyStateView: View {
    let onAddAccount: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.purpleLight, Color.purplePrimary.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)

                    Image(systemName: "lock.shield")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.purplePrimary, Color.purpleSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(spacing: 8) {
                    Text("Welcome to Purple OTP")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("Secure your accounts with two-factor authentication")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }

            VStack(spacing: 16) {
                Button(action: onAddAccount) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Your First Account")
                    }
                    .font(.headline)
                    .purpleButtonStyle()
                }

                Text("Scan QR codes or enter manually")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 32)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: OTPAccount.self, inMemory: true)
}
