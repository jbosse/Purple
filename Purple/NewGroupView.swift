//
//  NewGroupView.swift
//  Purple
//
//  Created by Copilot on 12/13/24.
//

import SwiftUI
import SwiftData

struct NewGroupView: View {
  let modelContext: ModelContext
  let onGroupCreated: (Group) -> Void
  @Environment(\.dismiss) private var dismiss
  
  @State private var groupName = ""
  @State private var selectedColor = "blue"
  @State private var selectedIcon = "folder"
  @State private var showingError = false
  @State private var errorMessage = ""
  
  private let colors = ["blue", "green", "orange", "red", "purple", "pink", "yellow", "indigo"]
  private let icons = ["folder", "house", "building.2", "laptopcomputer", "server.rack", "gear", "person", "gamecontroller"]
  
  var isFormValid: Bool {
    !groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
  
  var body: some View {
    NavigationView {
      ZStack {
        Color.backgroundSecondary.ignoresSafeArea()
        
        Form {
          Section {
            CustomTextField(
              title: "Group Name",
              text: $groupName,
              placeholder: "e.g., Personal, Work, Production"
            )
          } header: {
            HStack {
              Image(systemName: "tag")
                .foregroundColor(.purplePrimary)
              Text("Group Information")
            }
          }
          
          Section {
            VStack(alignment: .leading, spacing: 12) {
              Text("Icon")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
              
              LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(icons, id: \.self) { icon in
                  Button(action: {
                    selectedIcon = icon
                  }) {
                    Image(systemName: icon)
                      .font(.title2)
                      .foregroundColor(selectedIcon == icon ? .white : .purplePrimary)
                      .frame(width: 44, height: 44)
                      .background(
                        selectedIcon == icon ? Color.purplePrimary : Color.purpleLight
                      )
                      .clipShape(RoundedRectangle(cornerRadius: 8))
                  }
                }
              }
            }
          } header: {
            HStack {
              Image(systemName: "paintbrush")
                .foregroundColor(.purplePrimary)
              Text("Appearance")
            }
          }
        }
        .scrollContentBackground(.hidden)
      }
      .navigationTitle("New Group")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") {
            dismiss()
          }
          .foregroundColor(.purplePrimary)
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Create") {
            createGroup()
          }
          .disabled(!isFormValid)
          .fontWeight(.semibold)
          .foregroundColor(isFormValid ? .purplePrimary : .gray)
        }
      }
      .alert("Error", isPresented: $showingError) {
        Button("OK") { }
      } message: {
        Text(errorMessage)
      }
    }
  }
  
  private func createGroup() {
    let trimmedName = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
    
    let newGroup = Group(
      name: trimmedName,
      colorName: selectedColor,
      iconName: selectedIcon
    )
    
    modelContext.insert(newGroup)
    
    do {
      try modelContext.save()
      onGroupCreated(newGroup)
      dismiss()
    } catch {
      errorMessage = "Failed to create group: \(error.localizedDescription)"
      showingError = true
    }
  }
}
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Group.self, configurations: config)
    let context = container.mainContext
    
    NewGroupView(modelContext: context) { _ in }
}
