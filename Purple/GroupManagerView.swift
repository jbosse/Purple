//
//  GroupManagerView.swift
//  Purple
//
//  Created by Copilot on 12/13/24.
//

import SwiftUI
import SwiftData

struct GroupManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var groups: [Group]
    @Query private var accounts: [OTPAccount]
    @State private var showingNewGroup = false
    @State private var showingDeleteAlert = false
    @State private var groupToDelete: Group?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundSecondary.ignoresSafeArea()
                
                VStack {
                    if groups.isEmpty {
                        EmptyGroupsStateView {
                            showingNewGroup = true
                        }
                    } else {
                        List {
                            ForEach(groups.sorted(by: { $0.name < $1.name })) { group in
                                GroupRowView(
                                    group: group,
                                    accountCount: accounts.filter { $0.group?.id == group.id }.count
                                )
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button("Delete", role: .destructive) {
                                        groupToDelete = group
                                        showingDeleteAlert = true
                                    }
                                }
                            }
                            .onDelete(perform: deleteGroups)
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Manage Groups")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.purplePrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("New Group") {
                        showingNewGroup = true
                    }
                    .foregroundColor(.purplePrimary)
                }
            }
        }
        .sheet(isPresented: $showingNewGroup) {
            NewGroupView(modelContext: modelContext) { _ in }
        }
        .alert("Delete Group", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let group = groupToDelete {
                    deleteGroup(group)
                }
            }
        } message: {
            if let group = groupToDelete {
                let accountCount = accounts.filter { $0.group?.id == group.id }.count
                if accountCount > 0 {
                    Text("This will move \(accountCount) account(s) to \"Ungrouped\". This action cannot be undone.")
                } else {
                    Text("This action cannot be undone.")
                }
            }
        }
    }
    
    private func deleteGroups(offsets: IndexSet) {
        let sortedGroups = groups.sorted(by: { $0.name < $1.name })
        for index in offsets {
            deleteGroup(sortedGroups[index])
        }
    }
    
    private func deleteGroup(_ group: Group) {
        // Move all accounts in this group to ungrouped
        let groupAccounts = accounts.filter { $0.group?.id == group.id }
        for account in groupAccounts {
            account.group = nil
        }
        
        // Delete the group
        modelContext.delete(group)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete group: \(error)")
        }
    }
}

struct GroupRowView: View {
    let group: Group
    let accountCount: Int
    
    var body: some View {
        HStack(spacing: 12) {
            if let iconName = group.iconName {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(.purplePrimary)
                    .frame(width: 32, height: 32)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("\(accountCount) account\(accountCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(group.colorName.capitalized)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.purpleLight)
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
        .listRowBackground(Color.backgroundTertiary.opacity(0.5))
    }
}

struct EmptyGroupsStateView: View {
    let onAddGroup: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.purpleLight)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.purplePrimary)
                }
                
                VStack(spacing: 8) {
                    Text("No Groups Yet")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Create groups to organize your OTP codes by category, environment, or purpose")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            
            Button(action: onAddGroup) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Your First Group")
                }
                .font(.headline)
                .purpleButtonStyle()
            }
        }
        .padding(.horizontal, 32)
    }
}

#Preview {
    GroupManagerView()
        .modelContainer(for: [OTPAccount.self, Group.self], inMemory: true)
}