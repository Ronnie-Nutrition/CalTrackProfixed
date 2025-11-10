#!/usr/bin/env python3

import re
import uuid

# Read the project file
with open('CalTrackProFixed.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Generate UUIDs for the new files
theme_manager_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
appearance_settings_view_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]

# Add file references
file_refs_section = """		FB0B70BB2EABA62A004E511A /* AppState.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AppState.swift; sourceTree = "<group>"; };"""

new_file_refs = f"""{file_refs_section}
		{theme_manager_uuid} /* ThemeManager.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "ThemeManager.swift"; sourceTree = "<group>"; }};
		{appearance_settings_view_uuid} /* AppearanceSettingsView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "AppearanceSettingsView.swift"; sourceTree = "<group>"; }};"""

content = content.replace(file_refs_section, new_file_refs)

# Add build files
build_files_section = """		FB0B70BC2EABA62A004E511A /* AppState.swift in Sources */ = {isa = PBXBuildFile; fileRef = FB0B70BB2EABA62A004E511A /* AppState.swift */; };"""

new_build_files = f"""{build_files_section}
		{theme_manager_uuid[1:]} /* ThemeManager.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {theme_manager_uuid} /* ThemeManager.swift */; }};
		{appearance_settings_view_uuid[1:]} /* AppearanceSettingsView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {appearance_settings_view_uuid} /* AppearanceSettingsView.swift */; }};"""

content = content.replace(build_files_section, new_build_files)

# Add to source build phase
source_build_phase = """				FB0B70BC2EABA62A004E511A /* AppState.swift in Sources */,"""

new_source_build_phase = f"""{source_build_phase}
				{theme_manager_uuid[1:]} /* ThemeManager.swift in Sources */,
				{appearance_settings_view_uuid[1:]} /* AppearanceSettingsView.swift in Sources */,"""

content = content.replace(source_build_phase, new_source_build_phase)

# Add ThemeManager to Services group
services_group_section = """				E0A8F2D42AF1A6B300D7E8FB /* NutritionAPIService.swift */,"""

new_services_group = f"""{services_group_section}
				{theme_manager_uuid} /* ThemeManager.swift */,"""

content = content.replace(services_group_section, new_services_group)

# Add AppearanceSettingsView to Views group  
views_group_section = """				2F7918A6E341471E96592DB4 /* EnhancedInsightsView.swift */,
				97ACF8AA0784475D88719417 /* LiquidGlassComponents.swift */,"""

new_views_group = f"""{views_group_section}
				{appearance_settings_view_uuid} /* AppearanceSettingsView.swift */,"""

content = content.replace(views_group_section, new_views_group)

# Write back the project file
with open('CalTrackProFixed.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("✓ Added Theme files to Xcode project")
print(f"ThemeManager.swift UUID: {theme_manager_uuid}")
print(f"AppearanceSettingsView.swift UUID: {appearance_settings_view_uuid}")