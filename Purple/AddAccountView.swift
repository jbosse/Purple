//
//  AddAccountView.swift
//  Purple
//
//  Created by Jimmy Bosse on 9/20/25.
//

import SwiftUI
import SwiftData

struct AddAccountView: View {
    let modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var otpService = OTPService.shared
    @Query private var groups: [Group]

    @State private var serviceName = ""
    @State private var accountName = ""
    @State private var secretKey = ""
    @State private var selectedAlgorithm: OTPAlgorithm = .sha1
    @State private var selectedDigits = 6
    @State private var selectedPeriod = 30
    @State private var selectedType: OTPType = .totp
    @State private var selectedGroup: Group? = nil
    @State private var showingScanner = false
    @State private var showingAdvanced = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingNewGroup = false
    @State private var newGroupName = ""

    private let digitOptions = [6, 8]
    private let periodOptions = [15, 30, 60]

    var isFormValid: Bool {
        !serviceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !accountName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !secretKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        OTPGenerator.isValidBase32Secret(secretKey)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundSecondary.ignoresSafeArea()

                Form {
                    Section {
                        VStack(alignment: .leading, spacing: 16) {
                            CustomTextField(
                                title: "Service Name",
                                text: $serviceName,
                                placeholder: "e.g., Google, GitHub, Microsoft"
                            )

                            CustomTextField(
                                title: "Account Name",
                                text: $accountName,
                                placeholder: "e.g., your email or username"
                            )
                        }
                        .padding(.vertical, 8)
                    } header: {
                        HStack {
                            Image(systemName: "person.crop.circle")
                                .foregroundColor(.purplePrimary)
                            Text("Account Information")
                        }
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 16) {
                            CustomTextField(
                                title: "Secret Key",
                                text: $secretKey,
                                placeholder: "Enter your Base32 secret key"
                            )

                            if !secretKey.isEmpty && !OTPGenerator.isValidBase32Secret(secretKey) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                    Text("Invalid Base32 secret key")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }

                            Button(action: {
                                showingScanner = true
                            }) {
                                HStack {
                                    Image(systemName: "qrcode.viewfinder")
                                        .font(.title3)
                                    Text("Scan QR Code")
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.purpleLight)
                                .foregroundColor(.purplePrimary)
                                .cornerRadius(10)
                            }
                        }
                        .padding(.vertical, 8)
                    } header: {
                        HStack {
                            Image(systemName: "key")
                                .foregroundColor(.purplePrimary)
                            Text("Secret Key")
                        }
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Group")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Button("New Group") {
                                    showingNewGroup = true
                                }
                                .font(.caption)
                                .foregroundColor(.purplePrimary)
                            }
                            
                            Menu {
                                Button("No Group") {
                                    selectedGroup = nil
                                }
                                .foregroundColor(selectedGroup == nil ? .purplePrimary : .primary)
                                
                                if !groups.isEmpty {
                                    Divider()
                                    ForEach(groups.sorted(by: { $0.name < $1.name }), id: \.id) { group in
                                        Button(group.name) {
                                            selectedGroup = group
                                        }
                                        .foregroundColor(selectedGroup?.id == group.id ? .purplePrimary : .primary)
                                    }
                                }
                            } label: {
                                HStack {
                                    if let group = selectedGroup {
                                        HStack(spacing: 8) {
                                            if let iconName = group.iconName {
                                                Image(systemName: iconName)
                                                    .foregroundColor(.purplePrimary)
                                            }
                                            Text(group.name)
                                                .foregroundColor(.primary)
                                        }
                                    } else {
                                        Text("No Group")
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.backgroundTertiary)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.purplePrimary.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.vertical, 8)
                    } header: {
                        HStack {
                            Image(systemName: "folder")
                                .foregroundColor(.purplePrimary)
                            Text("Organization")
                        }
                    }

                    if showingAdvanced {
                        Section {
                            VStack(spacing: 16) {
                                CustomPicker(
                                    title: "Type",
                                    selection: $selectedType,
                                    options: OTPType.allCases
                                ) { type in
                                    Text(type.rawValue)
                                }

                                CustomPicker(
                                    title: "Algorithm",
                                    selection: $selectedAlgorithm,
                                    options: OTPAlgorithm.allCases
                                ) { algorithm in
                                    Text(algorithm.rawValue)
                                }

                                CustomPicker(
                                    title: "Digits",
                                    selection: $selectedDigits,
                                    options: digitOptions
                                ) { digits in
                                    Text("\(digits) digits")
                                }

                                if selectedType == .totp {
                                    CustomPicker(
                                        title: "Period",
                                        selection: $selectedPeriod,
                                        options: periodOptions
                                    ) { period in
                                        Text("\(period) seconds")
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        } header: {
                            HStack {
                                Image(systemName: "gearshape")
                                    .foregroundColor(.purplePrimary)
                                Text("Advanced Settings")
                            }
                        }
                    }

                    Section {
                        Button(showingAdvanced ? "Hide Advanced Settings" : "Show Advanced Settings") {
                            withAnimation(.easeInOut) {
                                showingAdvanced.toggle()
                            }
                        }
                        .foregroundColor(.purplePrimary)
                        .fontWeight(.medium)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.purplePrimary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addAccount()
                    }
                    .disabled(!isFormValid)
                    .fontWeight(.semibold)
                    .foregroundColor(isFormValid ? .purplePrimary : .gray)
                }
            }
            .sheet(isPresented: $showingScanner) {
                QRCodeScannerView { result in
                    handleQRCodeResult(result)
                }
            }
            .sheet(isPresented: $showingNewGroup) {
                NewGroupView(modelContext: modelContext) { newGroup in
                    selectedGroup = newGroup
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func addAccount() {
        let trimmedServiceName = serviceName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAccountName = accountName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSecretKey = secretKey.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let account = otpService.addAccount(
            serviceName: trimmedServiceName,
            accountName: trimmedAccountName,
            secretKey: trimmedSecretKey,
            algorithm: selectedAlgorithm,
            digits: selectedDigits,
            period: selectedPeriod,
            type: selectedType,
            group: selectedGroup
        ) else {
            errorMessage = "Failed to add account. Please check your secret key."
            showingError = true
            return
        }

        modelContext.insert(account)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save account: \(error.localizedDescription)"
            showingError = true
        }
    }

    private func handleQRCodeResult(_ result: String) {
        showingScanner = false

        guard let parsedData = otpService.parseOTPAuthURL(result) else {
            errorMessage = "Invalid QR code format"
            showingError = true
            return
        }

        serviceName = parsedData.serviceName
        accountName = parsedData.accountName
        secretKey = parsedData.secret
        selectedAlgorithm = parsedData.algorithm
        selectedDigits = parsedData.digits
        selectedPeriod = parsedData.period
        selectedType = parsedData.type
    }
}

// MARK: - Custom UI Components

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.purplePrimary.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

struct CustomPicker<T: Hashable, Content: View>: View {
    let title: String
    @Binding var selection: T
    let options: [T]
    let content: (T) -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            Picker(title, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    content(option).tag(option)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.backgroundTertiary)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.purplePrimary.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

#Preview {
    AddAccountView(modelContext: ModelContext(try! ModelContainer(for: OTPAccount.self, Group.self)))
}
