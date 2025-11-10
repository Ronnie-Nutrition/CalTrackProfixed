#!/usr/bin/env python3

import re
import os

# Read the project file
with open('CalTrackProFixed.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Count initial occurrences
initial_count = content.count('Models/Views/Models/Views/')
print(f"Found {initial_count} occurrences of duplicated paths")

# Replace all forms of duplicated paths
replacements = [
    # Direct duplications
    ('Models/Views/Models/Views/', 'Models/Views/'),
    ('Services/Services/', 'Services/'),
    ('Models/Models/', 'Models/'),
    # In quoted paths
    ('"Models/Views/Models/Views/', '"Models/Views/'),
    ('"Services/Services/', '"Services/'),
    ('"Models/Models/', '"Models/'),
    # In path specifications
    ('path = "Models/Views/Models/Views/', 'path = "Models/Views/'),
    ('path = "Services/Services/', 'path = "Services/'),
    ('path = "Models/Models/', 'path = "Models/'),
]

# Apply all replacements
for old, new in replacements:
    count = content.count(old)
    if count > 0:
        print(f"Replacing {count} instances of: {old}")
        content = content.replace(old, new)

# Additional pattern-based replacements for any missed cases
content = re.sub(r'(/Models/Views)/\1/', r'\1/', content)
content = re.sub(r'(/Services)/\1/', r'\1/', content)
content = re.sub(r'(/Models)/\1/', r'\1/', content)

# Write back
with open('CalTrackProFixed.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

# Verify the fix
final_count = content.count('Models/Views/Models/Views/')
print(f"\nAfter fix: {final_count} remaining duplicated paths")

if final_count == 0:
    print("✓ Successfully fixed all duplicated paths!")
else:
    print("⚠️  Some duplicated paths may still remain")

# List some files to verify they exist
print("\nVerifying key files exist:")
key_files = [
    'Models/Views/AppearanceSettingsView.swift',
    'Models/Views/AdvancedUIComponents.swift', 
    'Services/ThemeManager.swift',
    'Models/Views/PremiumUpgradeView.swift',
    'Models/Views/DataExportView.swift'
]

for file_path in key_files:
    full_path = os.path.join('/Users/ronniecraig/CalTrackProfixed', file_path)
    exists = "✓" if os.path.exists(full_path) else "✗"
    print(f"  {exists} {file_path}")