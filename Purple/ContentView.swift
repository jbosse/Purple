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
    @Query private var groups: [Group]
    @StateObject private var otpService = OTPService.shared
    @State private var showingAddAccount = false
    @State private var showingGroupManager = false
    @State private var searchText = ""
    @State private var editMode: EditMode = .inactive
    // Tracks which groups are expanded (keyed by UUID string or "ungrouped")
    @State private var expandedGroups: Set<String> = []

    var filteredAccounts: [OTPAccount] {
        if searchText.isEmpty {
            return accounts.sorted { $0.serviceName < $1.serviceName }
        } else {
            return accounts.filter { account in
                account.serviceName.localizedCaseInsensitiveContains(searchText) ||
                account.accountName.localizedCaseInsensitiveContains(searchText) ||
                (account.group?.name.localizedCaseInsensitiveContains(searchText) ?? false)
            }.sorted { $0.serviceName < $1.serviceName }
        }
    }

    var groupedAccounts: [(group: Group?, accounts: [OTPAccount])] {
        let grouped = Dictionary(grouping: filteredAccounts) { $0.group }
        let sortedGroups = grouped.keys.sorted { lhs, rhs in
            switch (lhs, rhs) {
            case (nil, _):
                return false  // No group goes last
            case (_, nil):
                return true   // Groups come before no group
            case let (group1?, group2?):
                return group1.name < group2.name
            }
        }

        return sortedGroups.map { group in
            (group: group, accounts: grouped[group]?.sorted { $0.serviceName < $1.serviceName } ?? [])
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
                            LazyVStack(spacing: 20) {
                                ForEach(groupedAccounts, id: \.group?.id) { groupData in
                                    if !groupData.accounts.isEmpty {
                                        let key = groupData.group?.id.uuidString ?? "ungrouped"
                                        GroupSection(
                                            group: groupData.group,
                                            accounts: groupData.accounts,
                                            otpService: otpService,
                                            modelContext: modelContext,
                                            editMode: $editMode,
                                            isExpanded: expandedGroups.contains(key),
                                            onToggle: {
                                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                                    if expandedGroups.contains(key) {
                                                        expandedGroups.remove(key)
                                                    } else {
                                                        expandedGroups.insert(key)
                                                    }
                                                }
                                            },
                                            onDelete: { account in
                                                deleteAccount(account)
                                            },
                                            onEdit: { _ in }
                                        )
                                        .transition(.asymmetric(
                                            insertion: .scale.combined(with: .opacity),
                                            removal: .opacity
                                        ))
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                        .searchable(text: $searchText, prompt: "Search accounts or groups")
                    }
                }
            }
            .navigationTitle("Purple OTP")
            .navigationBarTitleDisplayMode(.large)
            .environment(\.editMode, $editMode)
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

                    ToolbarItem(placement: .topBarLeading) {
                        Button("Groups") {
                            showingGroupManager = true
                        }
                        .foregroundColor(.purplePrimary)
                        .disabled(editMode == .active)
                    }
                }
            }
            .sheet(isPresented: $showingAddAccount) {
                AddAccountView(modelContext: modelContext)
            }
            .sheet(isPresented: $showingGroupManager) {
                GroupManagerView()
            }
            .onAppear {
                updateAllCodes()
                createDefaultGroupsIfNeeded()
            }
        }
    }

    private func deleteAccount(_ account: OTPAccount) {
        withAnimation {
            otpService.deleteAccount(account)
            modelContext.delete(account)
            do {
                try modelContext.save()
            } catch {
                print("Failed to delete account: \(error)")
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

    private func createDefaultGroupsIfNeeded() {
        // Only create default groups if no groups exist yet
        if groups.isEmpty {
            let defaultGroups = [
                Group(name: "Personal", colorName: "blue", iconName: "person.crop.circle", sortOrder: 1),
                Group(name: "Work", colorName: "orange", iconName: "building.2", sortOrder: 2),
                Group(name: "Development", colorName: "green", iconName: "laptopcomputer", sortOrder: 3),
                Group(name: "Production", colorName: "red", iconName: "server.rack", sortOrder: 4)
            ]

            for group in defaultGroups {
                modelContext.insert(group)
            }

            do {
                try modelContext.save()
            } catch {
                print("Failed to create default groups: \(error)")
            }
        }
    }
}

struct GroupSection: View {
    let group: Group?
    let accounts: [OTPAccount]
    @ObservedObject var otpService: OTPService
    let modelContext: ModelContext
    @Binding var editMode: EditMode
    let isExpanded: Bool
    let onToggle: () -> Void
    let onDelete: (OTPAccount) -> Void
    let onEdit: (OTPAccount) -> Void

    @State private var showingEditAccount: OTPAccount?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    if let group = group {
                        if let iconName = group.iconName {
                            Image(systemName: iconName)
                                .font(.title3)
                                .foregroundColor(.purplePrimary)
                                .frame(width: 24, height: 24)
                        }

                        Text(group.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    } else {
                        Image(systemName: "tray")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .frame(width: 24, height: 24)

                        Text("Ungrouped")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }

                    Text("(\(accounts.count))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background((group == nil ? Color.gray.opacity(0.2) : Color.purpleLight))
                        .clipShape(Capsule())

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.down.circle.fill" : "chevron.right.circle.fill")
                        .foregroundColor(.purplePrimary)
                        .font(.title3)
                        .symbolEffect(.rotate, value: isExpanded)
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)

            if isExpanded {
                LazyVStack(spacing: 12) {
                    ForEach(accounts) { account in
                        OTPAccountCard(account: account, otpService: otpService)
                            .contextMenu {
                                Button {
                                    showingEditAccount = account
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }

                                Button(role: .destructive) {
                                    onDelete(account)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .overlay(alignment: .center) {
                                SwiftUI.Group {
                                    if editMode == .active {
                                        HStack {
                                            Button {
                                                onDelete(account)
                                            } label: {
                                                Image(systemName: "minus.circle.fill")
                                                    .foregroundColor(.red)
                                                    .background(Color.white, in: Circle())
                                            }
                                            .padding(.leading, 8)

                                            Spacer()

                                            Button {
                                                showingEditAccount = account
                                            } label: {
                                                Image(systemName: "pencil.circle.fill")
                                                    .foregroundColor(.purplePrimary)
                                                    .background(Color.white, in: Circle())
                                            }
                                            .padding(.trailing, 8)
                                        }
                                    }
                                }
                            }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .sheet(item: $showingEditAccount) { account in
                    EditAccountView(account: account, modelContext: modelContext)
                }
            }
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
        .modelContainer(for: [OTPAccount.self, Group.self], inMemory: true)
}
