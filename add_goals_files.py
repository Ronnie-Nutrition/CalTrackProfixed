#!/usr/bin/env python3

import re
import uuid

# Read the project file
with open('CalTrackProFixed.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Generate UUIDs for the new files
goal_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
achievement_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
smart_goals_view_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
goal_creator_view_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
goal_detail_view_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
achievement_detail_view_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]

# Add file references
file_refs_section = """		FB0B70BB2EABA62A004E511A /* AppState.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AppState.swift; sourceTree = "<group>"; };"""

new_file_refs = f"""{file_refs_section}
		{goal_uuid} /* Goal.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "Goal.swift"; sourceTree = "<group>"; }};
		{achievement_uuid} /* Achievement.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "Achievement.swift"; sourceTree = "<group>"; }};
		{smart_goals_view_uuid} /* SmartGoalsView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "SmartGoalsView.swift"; sourceTree = "<group>"; }};
		{goal_creator_view_uuid} /* GoalCreatorView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "GoalCreatorView.swift"; sourceTree = "<group>"; }};
		{goal_detail_view_uuid} /* GoalDetailView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "GoalDetailView.swift"; sourceTree = "<group>"; }};
		{achievement_detail_view_uuid} /* AchievementDetailView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "AchievementDetailView.swift"; sourceTree = "<group>"; }};"""

content = content.replace(file_refs_section, new_file_refs)

# Add build files
build_files_section = """		FB0B70BC2EABA62A004E511A /* AppState.swift in Sources */ = {isa = PBXBuildFile; fileRef = FB0B70BB2EABA62A004E511A /* AppState.swift */; };"""

new_build_files = f"""{build_files_section}
		{goal_uuid[1:]} /* Goal.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {goal_uuid} /* Goal.swift */; }};
		{achievement_uuid[1:]} /* Achievement.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {achievement_uuid} /* Achievement.swift */; }};
		{smart_goals_view_uuid[1:]} /* SmartGoalsView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {smart_goals_view_uuid} /* SmartGoalsView.swift */; }};
		{goal_creator_view_uuid[1:]} /* GoalCreatorView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {goal_creator_view_uuid} /* GoalCreatorView.swift */; }};
		{goal_detail_view_uuid[1:]} /* GoalDetailView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {goal_detail_view_uuid} /* GoalDetailView.swift */; }};
		{achievement_detail_view_uuid[1:]} /* AchievementDetailView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {achievement_detail_view_uuid} /* AchievementDetailView.swift */; }};"""

content = content.replace(build_files_section, new_build_files)

# Add to source build phase
source_build_phase = """				FB0B70BC2EABA62A004E511A /* AppState.swift in Sources */,"""

new_source_build_phase = f"""{source_build_phase}
				{goal_uuid[1:]} /* Goal.swift in Sources */,
				{achievement_uuid[1:]} /* Achievement.swift in Sources */,
				{smart_goals_view_uuid[1:]} /* SmartGoalsView.swift in Sources */,
				{goal_creator_view_uuid[1:]} /* GoalCreatorView.swift in Sources */,
				{goal_detail_view_uuid[1:]} /* GoalDetailView.swift in Sources */,
				{achievement_detail_view_uuid[1:]} /* AchievementDetailView.swift in Sources */,"""

content = content.replace(source_build_phase, new_source_build_phase)

# Add Goal.swift and Achievement.swift to Models group
models_group_section = """				FB0B70BB2EABA62A004E511A /* AppState.swift */,
				2F6C26D43F1F464982BA6B83 /* FoodEntry.swift */,"""

new_models_group = f"""{models_group_section}
				{goal_uuid} /* Goal.swift */,
				{achievement_uuid} /* Achievement.swift */,"""

content = content.replace(models_group_section, new_models_group)

# Add Views to Views group  
views_group_section = """				2F7918A6E341471E96592DB4 /* EnhancedInsightsView.swift */,
				97ACF8AA0784475D88719417 /* LiquidGlassComponents.swift */,"""

new_views_group = f"""{views_group_section}
				{smart_goals_view_uuid} /* SmartGoalsView.swift */,
				{goal_creator_view_uuid} /* GoalCreatorView.swift */,
				{goal_detail_view_uuid} /* GoalDetailView.swift */,
				{achievement_detail_view_uuid} /* AchievementDetailView.swift */,"""

content = content.replace(views_group_section, new_views_group)

# Write back the project file
with open('CalTrackProFixed.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("✓ Added Goals and Achievements files to Xcode project")
print(f"Goal.swift UUID: {goal_uuid}")
print(f"Achievement.swift UUID: {achievement_uuid}")
print(f"SmartGoalsView.swift UUID: {smart_goals_view_uuid}")
print(f"GoalCreatorView.swift UUID: {goal_creator_view_uuid}")
print(f"GoalDetailView.swift UUID: {goal_detail_view_uuid}")
print(f"AchievementDetailView.swift UUID: {achievement_detail_view_uuid}")