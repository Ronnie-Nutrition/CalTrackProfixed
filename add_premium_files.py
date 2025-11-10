#!/usr/bin/env python3

import re
import uuid

# Read the project file
with open('CalTrackProFixed.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Generate UUIDs for the new files
subscription_manager_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
premium_upgrade_view_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
meal_planning_view_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
advanced_analytics_view_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
data_export_view_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]

# Add file references
file_refs_section = """		FB0B70BB2EABA62A004E511A /* AppState.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AppState.swift; sourceTree = "<group>"; };"""

new_file_refs = f"""{file_refs_section}
		{subscription_manager_uuid} /* SubscriptionManager.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "SubscriptionManager.swift"; sourceTree = "<group>"; }};
		{premium_upgrade_view_uuid} /* PremiumUpgradeView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "PremiumUpgradeView.swift"; sourceTree = "<group>"; }};
		{meal_planning_view_uuid} /* MealPlanningView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "MealPlanningView.swift"; sourceTree = "<group>"; }};
		{advanced_analytics_view_uuid} /* AdvancedAnalyticsView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "AdvancedAnalyticsView.swift"; sourceTree = "<group>"; }};
		{data_export_view_uuid} /* DataExportView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "DataExportView.swift"; sourceTree = "<group>"; }};"""

content = content.replace(file_refs_section, new_file_refs)

# Add build files
build_files_section = """		FB0B70BC2EABA62A004E511A /* AppState.swift in Sources */ = {isa = PBXBuildFile; fileRef = FB0B70BB2EABA62A004E511A /* AppState.swift */; };"""

new_build_files = f"""{build_files_section}
		{subscription_manager_uuid[1:]} /* SubscriptionManager.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {subscription_manager_uuid} /* SubscriptionManager.swift */; }};
		{premium_upgrade_view_uuid[1:]} /* PremiumUpgradeView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {premium_upgrade_view_uuid} /* PremiumUpgradeView.swift */; }};
		{meal_planning_view_uuid[1:]} /* MealPlanningView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {meal_planning_view_uuid} /* MealPlanningView.swift */; }};
		{advanced_analytics_view_uuid[1:]} /* AdvancedAnalyticsView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {advanced_analytics_view_uuid} /* AdvancedAnalyticsView.swift */; }};
		{data_export_view_uuid[1:]} /* DataExportView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {data_export_view_uuid} /* DataExportView.swift */; }};"""

content = content.replace(build_files_section, new_build_files)

# Add to source build phase
source_build_phase = """				FB0B70BC2EABA62A004E511A /* AppState.swift in Sources */,"""

new_source_build_phase = f"""{source_build_phase}
				{subscription_manager_uuid[1:]} /* SubscriptionManager.swift in Sources */,
				{premium_upgrade_view_uuid[1:]} /* PremiumUpgradeView.swift in Sources */,
				{meal_planning_view_uuid[1:]} /* MealPlanningView.swift in Sources */,
				{advanced_analytics_view_uuid[1:]} /* AdvancedAnalyticsView.swift in Sources */,
				{data_export_view_uuid[1:]} /* DataExportView.swift in Sources */,"""

content = content.replace(source_build_phase, new_source_build_phase)

# Add SubscriptionManager to Services group
services_group_section = """				E0A8F2D42AF1A6B300D7E8FB /* NutritionAPIService.swift */,"""

new_services_group = f"""{services_group_section}
				{subscription_manager_uuid} /* SubscriptionManager.swift */,"""

content = content.replace(services_group_section, new_services_group)

# Add Views to Views group  
views_group_section = """				2F7918A6E341471E96592DB4 /* EnhancedInsightsView.swift */,
				97ACF8AA0784475D88719417 /* LiquidGlassComponents.swift */,"""

new_views_group = f"""{views_group_section}
				{premium_upgrade_view_uuid} /* PremiumUpgradeView.swift */,
				{meal_planning_view_uuid} /* MealPlanningView.swift */,
				{advanced_analytics_view_uuid} /* AdvancedAnalyticsView.swift */,
				{data_export_view_uuid} /* DataExportView.swift */,"""

content = content.replace(views_group_section, new_views_group)

# Write back the project file
with open('CalTrackProFixed.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("✓ Added Premium Features files to Xcode project")
print(f"SubscriptionManager.swift UUID: {subscription_manager_uuid}")
print(f"PremiumUpgradeView.swift UUID: {premium_upgrade_view_uuid}")
print(f"MealPlanningView.swift UUID: {meal_planning_view_uuid}")
print(f"AdvancedAnalyticsView.swift UUID: {advanced_analytics_view_uuid}")
print(f"DataExportView.swift UUID: {data_export_view_uuid}")