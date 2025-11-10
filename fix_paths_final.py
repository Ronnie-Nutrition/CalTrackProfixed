#!/usr/bin/env python3

import re

# Read the project file
with open('CalTrackProFixed.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Show what we're looking for
print("Searching for problematic path patterns...")

# Find and fix all duplicated path patterns more aggressively
patterns_to_fix = [
    (r'Models/Views/Models/Views/', 'Models/Views/'),
    (r'Services/Services/', 'Services/'),
    (r'Models/Models/', 'Models/'),
    (r'path = "Models/Views/Models/Views/', 'path = "Models/Views/'),
    (r'"Models/Views/Models/Views/', '"Models/Views/')
]

changes_made = 0
for pattern, replacement in patterns_to_fix:
    matches = re.findall(pattern, content)
    if matches:
        print(f"Found {len(matches)} instances of: {pattern}")
        content = re.sub(pattern, replacement, content)
        changes_made += len(matches)

print(f"Total changes made: {changes_made}")

# Additional comprehensive fix - replace any file path that has duplicated segments
content = re.sub(r'(Models/Views)/\1/', r'\1/', content)
content = re.sub(r'(Services)/\1/', r'\1/', content)
content = re.sub(r'(Models)/\1/', r'\1/', content)

print("✓ Applied comprehensive path deduplication")

# Write back the project file
with open('CalTrackProFixed.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("✓ Updated CalTrackProFixed.xcodeproj")

# Verify some key files exist
import os

key_files_to_check = [
    'Services/ThemeManager.swift',
    'Models/Views/AppearanceSettingsView.swift', 
    'Models/Views/AdvancedUIComponents.swift',
    'Services/SubscriptionManager.swift',
    'Models/Views/PremiumUpgradeView.swift',
    'Models/Views/DataExportView.swift',
    'Services/HealthKitManager.swift',
    'Services/FoodRecognition.swift'
]

print("\nVerifying files exist:")
for file_path in key_files_to_check:
    full_path = os.path.join('/Users/ronniecraig/CalTrackProfixed', file_path)
    if os.path.exists(full_path):
        print(f"✓ {file_path}")
    else:
        print(f"⚠️  MISSING: {file_path}")
        
print("\nDone!")