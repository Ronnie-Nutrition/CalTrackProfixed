#!/usr/bin/env python3

import re
import uuid

# Read the project file
with open('CalTrackProFixed.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Generate UUIDs for the new files
food_recognition_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
ai_camera_view_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
ai_recognition_view_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
recognition_result_view_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]

# Add file references
file_refs_section = """		FB0B70BB2EABA62A004E511A /* AppState.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AppState.swift; sourceTree = "<group>"; };"""

new_file_refs = f"""{file_refs_section}
		{food_recognition_uuid} /* FoodRecognition.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "FoodRecognition.swift"; sourceTree = "<group>"; }};
		{ai_camera_view_uuid} /* AIFoodCameraView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "AIFoodCameraView.swift"; sourceTree = "<group>"; }};
		{ai_recognition_view_uuid} /* AIFoodRecognitionView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "AIFoodRecognitionView.swift"; sourceTree = "<group>"; }};
		{recognition_result_view_uuid} /* FoodRecognitionResultView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "FoodRecognitionResultView.swift"; sourceTree = "<group>"; }};"""

content = content.replace(file_refs_section, new_file_refs)

# Add build files
build_files_section = """		FB0B70BC2EABA62A004E511A /* AppState.swift in Sources */ = {isa = PBXBuildFile; fileRef = FB0B70BB2EABA62A004E511A /* AppState.swift */; };"""

new_build_files = f"""{build_files_section}
		{food_recognition_uuid[1:]} /* FoodRecognition.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {food_recognition_uuid} /* FoodRecognition.swift */; }};
		{ai_camera_view_uuid[1:]} /* AIFoodCameraView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {ai_camera_view_uuid} /* AIFoodCameraView.swift */; }};
		{ai_recognition_view_uuid[1:]} /* AIFoodRecognitionView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {ai_recognition_view_uuid} /* AIFoodRecognitionView.swift */; }};
		{recognition_result_view_uuid[1:]} /* FoodRecognitionResultView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {recognition_result_view_uuid} /* FoodRecognitionResultView.swift */; }};"""

content = content.replace(build_files_section, new_build_files)

# Add to source build phase
source_build_phase = """				FB0B70BC2EABA62A004E511A /* AppState.swift in Sources */,"""

new_source_build_phase = f"""{source_build_phase}
				{food_recognition_uuid[1:]} /* FoodRecognition.swift in Sources */,
				{ai_camera_view_uuid[1:]} /* AIFoodCameraView.swift in Sources */,
				{ai_recognition_view_uuid[1:]} /* AIFoodRecognitionView.swift in Sources */,
				{recognition_result_view_uuid[1:]} /* FoodRecognitionResultView.swift in Sources */,"""

content = content.replace(source_build_phase, new_source_build_phase)

# Add FoodRecognition.swift to Models group
models_group_section = """				FB0B70BB2EABA62A004E511A /* AppState.swift */,
				2F6C26D43F1F464982BA6B83 /* FoodEntry.swift */,"""

new_models_group = f"""{models_group_section}
				{food_recognition_uuid} /* FoodRecognition.swift */,"""

content = content.replace(models_group_section, new_models_group)

# Add Views to Views group  
views_group_section = """				2F7918A6E341471E96592DB4 /* EnhancedInsightsView.swift */,
				97ACF8AA0784475D88719417 /* LiquidGlassComponents.swift */,"""

new_views_group = f"""{views_group_section}
				{ai_camera_view_uuid} /* AIFoodCameraView.swift */,
				{ai_recognition_view_uuid} /* AIFoodRecognitionView.swift */,
				{recognition_result_view_uuid} /* FoodRecognitionResultView.swift */,"""

content = content.replace(views_group_section, new_views_group)

# Write back the project file
with open('CalTrackProFixed.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("✓ Added AI Food Recognition files to Xcode project")
print(f"FoodRecognition.swift UUID: {food_recognition_uuid}")
print(f"AIFoodCameraView.swift UUID: {ai_camera_view_uuid}")
print(f"AIFoodRecognitionView.swift UUID: {ai_recognition_view_uuid}")
print(f"FoodRecognitionResultView.swift UUID: {recognition_result_view_uuid}")