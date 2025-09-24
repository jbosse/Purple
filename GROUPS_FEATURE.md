# Group Codes Feature Documentation

## Overview
The Group Codes feature allows users to organize their OTP codes into custom categories, making it easier to find specific codes especially when managing many accounts across different contexts.

## Features

### 1. Custom Groups
- Create unlimited custom groups with meaningful names
- Assign icons to groups for visual identification
- Groups are sorted alphabetically in the UI

### 2. Default Groups
On first app launch, Purple OTP creates these default groups:
- **Personal** 👤 (Blue) - For personal accounts
- **Work** 🏢 (Orange) - For work-related accounts  
- **Development** 💻 (Green) - For development/testing accounts
- **Production** 🖥️ (Red) - For production environment accounts

### 3. Group Assignment
- When adding new accounts, users can select a group or leave ungrouped
- Existing accounts without groups appear in an "Ungrouped" section
- Quick group creation available during account addition

### 4. Visual Organization
- Accounts are displayed grouped by their assigned group
- Group headers show the group name, icon, and account count
- Search functionality works across groups, service names, and account names
- Clean visual separation between groups

### 5. Group Management
- Access group management via the "Groups" button in the toolbar
- Create new groups with custom names and icons
- Delete groups (accounts are moved to "Ungrouped")
- View account counts per group

## User Benefits

### Problem Solved
Users previously had to scroll through many codes to find the right one, especially when:
- Not remembering how a code was originally labeled
- Managing both personal and work codes
- Handling multiple environments (Test, QA, Stage, Production)

### Solution Provided
- **Quick Organization**: Codes grouped by context/purpose
- **Easy Navigation**: Visual headers and icons for rapid identification  
- **Flexible Categorization**: Custom groups for any organizational system
- **Reduced Cognitive Load**: No more scanning through long lists
- **Context Switching**: Easy separation of personal vs work vs environment codes

## Implementation Details

### Data Model
- `Group` model with name, icon, color, and sort order
- `OTPAccount` updated with optional `group` relationship
- SwiftData handles persistence and relationships

### UI Components
- `GroupSection`: Displays grouped accounts with headers
- `NewGroupView`: Modal for creating new groups
- `GroupManagerView`: Comprehensive group management interface
- Enhanced `AddAccountView` with group selection

### Technical Features
- Automatic default group creation on first launch
- Relationship management for group deletion (accounts moved to ungrouped)
- Search functionality enhanced to include group names
- Smooth animations for group operations

## Usage Examples

### Creating a New Group
1. Tap "Groups" in the toolbar
2. Tap "New Group" 
3. Enter group name (e.g., "Banking", "Social Media", "DevOps")
4. Select an icon
5. Tap "Create"

### Adding Account to Group
1. Tap the + button to add new account
2. Fill in service and account details
3. In the "Organization" section, select desired group
4. Complete account creation

### Managing Groups
1. Access "Groups" from the toolbar
2. View all groups with account counts
3. Delete groups (swipe left or use delete button)
4. Create new groups as needed

## Future Enhancements
- Group color customization
- Drag and drop account reorganization
- Group-based backup/export
- Favorite groups pinning
- Group-specific security settings