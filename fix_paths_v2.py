#!/usr/bin/env python3

import re

# Read the project file
with open('CalTrackProFixed.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Fix duplicated paths like "Models/Views/Models/Views/file.swift" -> "Models/Views/file.swift"
content = re.sub(r'Models/Views/Models/Views/', 'Models/Views/', content)
content = re.sub(r'Services/Services/', 'Services/', content)
content = re.sub(r'Models/Models/', 'Models/', content)

print("✓ Fixed duplicated paths in Xcode project")

# Write back the project file
with open('CalTrackProFixed.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("✓ Updated CalTrackProFixed.xcodeproj")

# Verify some key files exist
import os

key_files = [
    'Services/ThemeManager.swift',
    'Models/Views/AppearanceSettingsView.swift', 
    'Models/Views/AdvancedUIComponents.swift',
    'Services/SubscriptionManager.swift',
    'Models/Views/PremiumUpgradeView.swift'
]

for file_path in key_files:
    full_path = os.path.join('/Users/ronniecraig/CalTrackProfixed', file_path)
    if os.path.exists(full_path):
        print(f"✓ Verified: {file_path}")
    else:
        print(f"⚠️  Missing: {file_path}")