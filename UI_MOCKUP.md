# Purple OTP - Group Codes UI Mockup

## Main Screen (ContentView) - Before Groups
```
┌─────────────────────────────────────┐
│ Purple OTP                      [+] │
├─────────────────────────────────────┤
│ 🔍 Search accounts...               │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ GitHub                      ⭐   │ │
│ │ john@example.com                │ │
│ │ 123 456                         │ │
│ │ ⏱ 15s remaining               │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ AWS Console                     │ │
│ │ admin@company.com               │ │
│ │ 789 012                         │ │
│ │ ⏱ 22s remaining               │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ Personal Gmail                  │ │
│ │ personal@gmail.com              │ │
│ │ 345 678                         │ │
│ │ ⏱ 08s remaining               │ │
│ └─────────────────────────────────┘ │
│ ... (more accounts)                 │
└─────────────────────────────────────┘
```

## Main Screen (ContentView) - After Groups Implementation
```
┌─────────────────────────────────────┐
│ Purple OTP           Groups     [+] │
├─────────────────────────────────────┤
│ 🔍 Search accounts or groups...     │
├─────────────────────────────────────┤
│ 👤 Personal (2)                     │
│ ┌─────────────────────────────────┐ │
│ │ GitHub                      ⭐   │ │
│ │ john@example.com                │ │
│ │ 123 456                   📋    │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ Personal Gmail                  │ │
│ │ personal@gmail.com              │ │
│ │ 345 678                   📋    │ │
│ └─────────────────────────────────┘ │
│                                     │
│ 🏢 Work (3)                         │
│ ┌─────────────────────────────────┐ │
│ │ AWS Console                     │ │
│ │ admin@company.com               │ │
│ │ 789 012                   📋    │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ Office 365                      │ │
│ │ john@company.com                │ │
│ │ 456 789                   📋    │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ Slack                           │ │
│ │ john@company.com                │ │
│ │ 234 567                   📋    │ │
│ └─────────────────────────────────┘ │
│                                     │
│ 🖥️ Production (2)                   │
│ ┌─────────────────────────────────┐ │
│ │ Server Dashboard                │ │
│ │ admin@server.com                │ │
│ │ 890 123                   📋    │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ Database Admin                  │ │
│ │ db_admin                        │ │
│ │ 567 890                   📋    │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

## Add Account Screen - Group Selection
```
┌─────────────────────────────────────┐
│ Cancel    Add Account           Add │
├─────────────────────────────────────┤
│ 👤 Account Information              │
│ ┌─────────────────────────────────┐ │
│ │ Service Name                    │ │
│ │ GitHub                          │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ Account Name                    │ │
│ │ john@example.com                │ │
│ └─────────────────────────────────┘ │
│                                     │
│ 🔑 Secret Key                       │
│ ┌─────────────────────────────────┐ │
│ │ Enter your Base32 secret key    │ │
│ │ JBSWY3DPEHPK3PXP                │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ 📷 Scan QR Code                  │ │
│ └─────────────────────────────────┘ │
│                                     │
│ 📁 Organization          New Group  │
│ ┌─────────────────────────────────┐ │
│ │ 👤 Personal               ▼     │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ⚙️ Show Advanced Settings           │
│                                     │
└─────────────────────────────────────┘
```

## Groups Management Screen
```
┌─────────────────────────────────────┐
│ Done       Manage Groups   New Group│
├─────────────────────────────────────┤
│ 👤 Personal                  Blue   │
│    2 accounts                       │
│                                     │
│ 🏢 Work                     Orange  │
│    3 accounts                       │
│                                     │
│ 💻 Development             Green    │
│    0 accounts                       │
│                                     │
│ 🖥️ Production               Red     │
│    2 accounts                       │
│                                     │
│ 🏦 Banking                  Purple  │
│    1 account                        │
│                                     │
│ [ + Add New Group ]                 │
└─────────────────────────────────────┘
```

## New Group Creation Screen
```
┌─────────────────────────────────────┐
│ Cancel      New Group        Create │
├─────────────────────────────────────┤
│ 🏷️ Group Information                │
│ ┌─────────────────────────────────┐ │
│ │ Group Name                      │ │
│ │ Banking                         │ │
│ └─────────────────────────────────┘ │
│                                     │
│ 🎨 Appearance                       │
│ Icon                                │
│ ┌───┬───┬───┬───┐                   │
│ │📁 │🏠 │🏢 │💻 │                   │
│ ├───┼───┼───┼───┤                   │
│ │🖥️ │⚙️ │👤 │🎮 │                   │
│ └───┴───┴───┴───┘                   │
│                                     │
│ [🏦] ← Selected                      │
│                                     │
└─────────────────────────────────────┘
```

## Key Visual Improvements
1. **Clear Group Headers** - Name, icon, and count
2. **Visual Separation** - Space between groups  
3. **Contextual Organization** - Related accounts together
4. **Easy Management** - Accessible group tools
5. **Flexible Categorization** - Custom groups for any use case