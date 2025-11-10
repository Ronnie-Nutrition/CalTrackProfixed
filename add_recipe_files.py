#!/usr/bin/env python3

import re
import uuid

# Read the project file
with open('CalTrackProFixed.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Generate UUIDs for the new files
recipe_builder_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
recipe_library_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]

# Add file references
file_refs_section = """		FB0B70BB2EABA62A004E511A /* AppState.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AppState.swift; sourceTree = "<group>"; };"""

new_file_refs = f"""{file_refs_section}
		{recipe_builder_uuid} /* RecipeBuilderView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "RecipeBuilderView.swift"; sourceTree = "<group>"; }};
		{recipe_library_uuid} /* RecipeLibraryView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "RecipeLibraryView.swift"; sourceTree = "<group>"; }};"""

content = content.replace(file_refs_section, new_file_refs)

# Add build files
build_files_section = """		FB0B70BC2EABA62A004E511A /* AppState.swift in Sources */ = {isa = PBXBuildFile; fileRef = FB0B70BB2EABA62A004E511A /* AppState.swift */; };"""

new_build_files = f"""{build_files_section}
		{recipe_builder_uuid[1:]} /* RecipeBuilderView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {recipe_builder_uuid} /* RecipeBuilderView.swift */; }};
		{recipe_library_uuid[1:]} /* RecipeLibraryView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {recipe_library_uuid} /* RecipeLibraryView.swift */; }};"""

content = content.replace(build_files_section, new_build_files)

# Add to source build phase
source_build_phase = """				FB0B70BC2EABA62A004E511A /* AppState.swift in Sources */,"""

new_source_build_phase = f"""{source_build_phase}
				{recipe_builder_uuid[1:]} /* RecipeBuilderView.swift in Sources */,
				{recipe_library_uuid[1:]} /* RecipeLibraryView.swift in Sources */,"""

content = content.replace(source_build_phase, new_source_build_phase)

# Add to file group (Views section)
views_group_section = """				2F7918A6E341471E96592DB4 /* EnhancedInsightsView.swift */,
				97ACF8AA0784475D88719417 /* LiquidGlassComponents.swift */,"""

new_views_group = f"""{views_group_section}
				{recipe_builder_uuid} /* RecipeBuilderView.swift */,
				{recipe_library_uuid} /* RecipeLibraryView.swift */,"""

content = content.replace(views_group_section, new_views_group)

# Write back the project file
with open('CalTrackProFixed.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("✓ Added RecipeBuilderView.swift and RecipeLibraryView.swift to Xcode project")
print(f"RecipeBuilderView UUID: {recipe_builder_uuid}")
print(f"RecipeLibraryView UUID: {recipe_library_uuid}")