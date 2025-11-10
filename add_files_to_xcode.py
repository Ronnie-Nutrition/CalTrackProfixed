#!/usr/bin/env python3

import re
import uuid

# Read the project file
with open('CalTrackProFixed.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Generate UUIDs for the new files
enhanced_insights_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
liquid_glass_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]

# Add file references
file_refs_section = """		FB0B70BB2EABA62A004E511A /* AppState.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AppState.swift; sourceTree = "<group>"; };"""

new_file_refs = f"""{file_refs_section}
		{enhanced_insights_uuid} /* EnhancedInsightsView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "Models/Views/EnhancedInsightsView.swift"; sourceTree = "<group>"; }};
		{liquid_glass_uuid} /* LiquidGlassComponents.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "Models/Views/LiquidGlassComponents.swift"; sourceTree = "<group>"; }};"""

content = content.replace(file_refs_section, new_file_refs)

# Add build files
build_files_section = """		FB0B70BC2EABA62A004E511A /* AppState.swift in Sources */ = {isa = PBXBuildFile; fileRef = FB0B70BB2EABA62A004E511A /* AppState.swift */; };"""

new_build_files = f"""{build_files_section}
		{enhanced_insights_uuid[1:]} /* EnhancedInsightsView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {enhanced_insights_uuid} /* EnhancedInsightsView.swift */; }};
		{liquid_glass_uuid[1:]} /* LiquidGlassComponents.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {liquid_glass_uuid} /* LiquidGlassComponents.swift */; }};"""

content = content.replace(build_files_section, new_build_files)

# Add to source build phase
source_build_phase = """				FB0B70BC2EABA62A004E511A /* AppState.swift in Sources */,"""

new_source_build_phase = f"""{source_build_phase}
				{enhanced_insights_uuid[1:]} /* EnhancedInsightsView.swift in Sources */,
				{liquid_glass_uuid[1:]} /* LiquidGlassComponents.swift in Sources */,"""

content = content.replace(source_build_phase, new_source_build_phase)

# Add to file group
file_group_section = """				FB0B70BB2EABA62A004E511A /* AppState.swift */,"""

new_file_group = f"""{file_group_section}
				{enhanced_insights_uuid} /* EnhancedInsightsView.swift */,
				{liquid_glass_uuid} /* LiquidGlassComponents.swift */,"""

content = content.replace(file_group_section, new_file_group)

# Write back the project file
with open('CalTrackProFixed.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("✓ Added EnhancedInsightsView.swift and LiquidGlassComponents.swift to Xcode project")
print(f"EnhancedInsightsView UUID: {enhanced_insights_uuid}")
print(f"LiquidGlassComponents UUID: {liquid_glass_uuid}")