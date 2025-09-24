//
//  EditAccountView.swift
//  Purple
//
//  Created by Copilot on 12/13/24.
//

import SwiftUI
import SwiftData

struct EditAccountView: View {
    @Environment(\.dismiss) private var dismiss
    let account: OTPAccount
    let modelContext: ModelContext
    @Query private var groups: [Group]
    
    @State private var selectedGroup: Group?
    @State private var showingNewGroup = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundSecondary.ignoresSafeArea()
                
                Form {
                    Section {
                        HStack {
                            Text("Service")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(account.serviceName)
                                .foregroundColor(.primary)
                        }
                        
                        HStack {
                            Text("Account")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(account.accountName)
                                .foregroundColor(.primary)
                        }
                    } header: {
                        HStack {
                            Image(systemName: "person.crop.circle")
                                .foregroundColor(.purplePrimary)
                            Text("Account Information")
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
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Edit Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.purplePrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.purplePrimary)
                }
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
        .onAppear {
            selectedGroup = account.group
        }
    }
    
    private func saveChanges() {
        account.group = selectedGroup
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save changes: \(error.localizedDescription)"
            showingError = true
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: OTPAccount.self, Group.self, configurations: config)
    let context = container.mainContext
    
    let testAccount = OTPAccount(
        serviceName: "Test Service",
        accountName: "test@example.com",
        secretKeyIdentifier: "test-key"
    )
    
    return EditAccountView(account: testAccount, modelContext: context)
}