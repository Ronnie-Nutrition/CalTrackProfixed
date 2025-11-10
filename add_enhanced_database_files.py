#!/usr/bin/env python3

import re
import uuid

# Read the project file
with open('CalTrackProFixed.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Generate UUIDs for the new files
enhanced_db_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
usda_service_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
openfood_service_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
edamam_service_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
enhanced_search_view_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
search_filters_view_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
enhanced_detail_view_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]

# Add file references
file_refs_section = """		FB0B70BB2EABA62A004E511A /* AppState.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AppState.swift; sourceTree = "<group>"; };"""

new_file_refs = f"""{file_refs_section}
		{enhanced_db_uuid} /* EnhancedFoodDatabase.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "EnhancedFoodDatabase.swift"; sourceTree = "<group>"; }};
		{usda_service_uuid} /* USDAFoodDataService.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "USDAFoodDataService.swift"; sourceTree = "<group>"; }};
		{openfood_service_uuid} /* OpenFoodFactsService.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "OpenFoodFactsService.swift"; sourceTree = "<group>"; }};
		{edamam_service_uuid} /* EdamamService.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "EdamamService.swift"; sourceTree = "<group>"; }};
		{enhanced_search_view_uuid} /* EnhancedFoodSearchView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "EnhancedFoodSearchView.swift"; sourceTree = "<group>"; }};
		{search_filters_view_uuid} /* SearchFiltersView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "SearchFiltersView.swift"; sourceTree = "<group>"; }};
		{enhanced_detail_view_uuid} /* EnhancedFoodDetailView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "EnhancedFoodDetailView.swift"; sourceTree = "<group>"; }};"""

content = content.replace(file_refs_section, new_file_refs)

# Add build files
build_files_section = """		FB0B70BC2EABA62A004E511A /* AppState.swift in Sources */ = {isa = PBXBuildFile; fileRef = FB0B70BB2EABA62A004E511A /* AppState.swift */; };"""

new_build_files = f"""{build_files_section}
		{enhanced_db_uuid[1:]} /* EnhancedFoodDatabase.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {enhanced_db_uuid} /* EnhancedFoodDatabase.swift */; }};
		{usda_service_uuid[1:]} /* USDAFoodDataService.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {usda_service_uuid} /* USDAFoodDataService.swift */; }};
		{openfood_service_uuid[1:]} /* OpenFoodFactsService.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {openfood_service_uuid} /* OpenFoodFactsService.swift */; }};
		{edamam_service_uuid[1:]} /* EdamamService.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {edamam_service_uuid} /* EdamamService.swift */; }};
		{enhanced_search_view_uuid[1:]} /* EnhancedFoodSearchView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {enhanced_search_view_uuid} /* EnhancedFoodSearchView.swift */; }};
		{search_filters_view_uuid[1:]} /* SearchFiltersView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {search_filters_view_uuid} /* SearchFiltersView.swift */; }};
		{enhanced_detail_view_uuid[1:]} /* EnhancedFoodDetailView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {enhanced_detail_view_uuid} /* EnhancedFoodDetailView.swift */; }};"""

content = content.replace(build_files_section, new_build_files)

# Add to source build phase
source_build_phase = """				FB0B70BC2EABA62A004E511A /* AppState.swift in Sources */,"""

new_source_build_phase = f"""{source_build_phase}
				{enhanced_db_uuid[1:]} /* EnhancedFoodDatabase.swift in Sources */,
				{usda_service_uuid[1:]} /* USDAFoodDataService.swift in Sources */,
				{openfood_service_uuid[1:]} /* OpenFoodFactsService.swift in Sources */,
				{edamam_service_uuid[1:]} /* EdamamService.swift in Sources */,
				{enhanced_search_view_uuid[1:]} /* EnhancedFoodSearchView.swift in Sources */,
				{search_filters_view_uuid[1:]} /* SearchFiltersView.swift in Sources */,
				{enhanced_detail_view_uuid[1:]} /* EnhancedFoodDetailView.swift in Sources */,"""

content = content.replace(source_build_phase, new_source_build_phase)

# Add services to Services group
services_group_section = """				E0A8F2D42AF1A6B300D7E8FB /* NutritionAPIService.swift */,"""

new_services_group = f"""{services_group_section}
				{enhanced_db_uuid} /* EnhancedFoodDatabase.swift */,
				{usda_service_uuid} /* USDAFoodDataService.swift */,
				{openfood_service_uuid} /* OpenFoodFactsService.swift */,
				{edamam_service_uuid} /* EdamamService.swift */,"""

content = content.replace(services_group_section, new_services_group)

# Add Views to Views group  
views_group_section = """				2F7918A6E341471E96592DB4 /* EnhancedInsightsView.swift */,
				97ACF8AA0784475D88719417 /* LiquidGlassComponents.swift */,"""

new_views_group = f"""{views_group_section}
				{enhanced_search_view_uuid} /* EnhancedFoodSearchView.swift */,
				{search_filters_view_uuid} /* SearchFiltersView.swift */,
				{enhanced_detail_view_uuid} /* EnhancedFoodDetailView.swift */,"""

content = content.replace(views_group_section, new_views_group)

# Write back the project file
with open('CalTrackProFixed.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("✓ Added Enhanced Food Database files to Xcode project")
print(f"EnhancedFoodDatabase.swift UUID: {enhanced_db_uuid}")
print(f"USDAFoodDataService.swift UUID: {usda_service_uuid}")
print(f"OpenFoodFactsService.swift UUID: {openfood_service_uuid}")
print(f"EdamamService.swift UUID: {edamam_service_uuid}")
print(f"EnhancedFoodSearchView.swift UUID: {enhanced_search_view_uuid}")
print(f"SearchFiltersView.swift UUID: {search_filters_view_uuid}")
print(f"EnhancedFoodDetailView.swift UUID: {enhanced_detail_view_uuid}")