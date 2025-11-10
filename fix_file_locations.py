#!/usr/bin/env python3

import re
import os

# Read the project file
with open('CalTrackProFixed.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Map actual file locations - check where files really exist
actual_file_locations = {}

# Find all Swift files in the project
for root, dirs, files in os.walk('/Users/ronniecraig/CalTrackProfixed'):
    for file in files:
        if file.endswith('.swift'):
            rel_path = os.path.relpath(os.path.join(root, file), '/Users/ronniecraig/CalTrackProfixed')
            actual_file_locations[file] = rel_path

print("Found actual file locations:")
for filename, path in actual_file_locations.items():
    print(f"  {filename} -> {path}")

# Key files that need path corrections in project
key_corrections = {
    'HealthKitManager.swift': 'Models/HealthKitManager.swift',  # Use the one in Models, not Utilities
    'FoodRecognition.swift': 'Models/FoodRecognition.swift'
}

# Apply corrections to project file
for filename, correct_path in key_corrections.items():
    if filename in actual_file_locations:
        # Replace any incorrect path references
        pattern = rf'path = "[^"]*{re.escape(filename)}"'
        replacement = f'path = "{correct_path}"'
        content = re.sub(pattern, replacement, content)
        print(f"Fixed path for {filename} -> {correct_path}")

# One more pass to clean up any remaining duplicated paths
content = re.sub(r'/Models/Views/Models/Views/', '/Models/Views/', content)
content = re.sub(r'/Services/Services/', '/Services/', content)

print("✓ Applied file location corrections")

# Write back the project file
with open('CalTrackProFixed.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("✓ Updated CalTrackProFixed.xcodeproj with correct file paths")

# Verify the corrected files exist
print("\nVerifying corrected file locations:")
for filename, path in key_corrections.items():
    full_path = os.path.join('/Users/ronniecraig/CalTrackProfixed', path)
    if os.path.exists(full_path):
        print(f"✓ {path}")
    else:
        print(f"⚠️  MISSING: {path}")
        # Show where it actually is
        if filename in actual_file_locations:
            print(f"    Actually located at: {actual_file_locations[filename]}")