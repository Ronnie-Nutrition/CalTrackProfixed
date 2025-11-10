#!/usr/bin/env python3

import re
import uuid

# Read the project file
with open('CalTrackProFixed.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Generate UUIDs for the new files
healthkit_manager_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
health_integration_view_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]

# Add file references
file_refs_section = """		FB0B70BB2EABA62A004E511A /* AppState.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AppState.swift; sourceTree = "<group>"; };"""

new_file_refs = f"""{file_refs_section}
		{healthkit_manager_uuid} /* HealthKitManager.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "HealthKitManager.swift"; sourceTree = "<group>"; }};
		{health_integration_view_uuid} /* HealthIntegrationView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "HealthIntegrationView.swift"; sourceTree = "<group>"; }};"""

content = content.replace(file_refs_section, new_file_refs)

# Add build files
build_files_section = """		FB0B70BC2EABA62A004E511A /* AppState.swift in Sources */ = {isa = PBXBuildFile; fileRef = FB0B70BB2EABA62A004E511A /* AppState.swift */; };"""

new_build_files = f"""{build_files_section}
		{healthkit_manager_uuid[1:]} /* HealthKitManager.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {healthkit_manager_uuid} /* HealthKitManager.swift */; }};
		{health_integration_view_uuid[1:]} /* HealthIntegrationView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {health_integration_view_uuid} /* HealthIntegrationView.swift */; }};"""

content = content.replace(build_files_section, new_build_files)

# Add to source build phase
source_build_phase = """				FB0B70BC2EABA62A004E511A /* AppState.swift in Sources */,"""

new_source_build_phase = f"""{source_build_phase}
				{healthkit_manager_uuid[1:]} /* HealthKitManager.swift in Sources */,
				{health_integration_view_uuid[1:]} /* HealthIntegrationView.swift in Sources */,"""

content = content.replace(source_build_phase, new_source_build_phase)

# Add HealthKitManager.swift to Models group
models_group_section = """				FB0B70BB2EABA62A004E511A /* AppState.swift */,
				2F6C26D43F1F464982BA6B83 /* FoodEntry.swift */,"""

new_models_group = f"""{models_group_section}
				{healthkit_manager_uuid} /* HealthKitManager.swift */,"""

content = content.replace(models_group_section, new_models_group)

# Add HealthIntegrationView to Views group  
views_group_section = """				2F7918A6E341471E96592DB4 /* EnhancedInsightsView.swift */,
				97ACF8AA0784475D88719417 /* LiquidGlassComponents.swift */,"""

new_views_group = f"""{views_group_section}
				{health_integration_view_uuid} /* HealthIntegrationView.swift */,"""

content = content.replace(views_group_section, new_views_group)

# Write back the project file
with open('CalTrackProFixed.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("✓ Added Apple Health Integration files to Xcode project")
print(f"HealthKitManager.swift UUID: {healthkit_manager_uuid}")
print(f"HealthIntegrationView.swift UUID: {health_integration_view_uuid}")