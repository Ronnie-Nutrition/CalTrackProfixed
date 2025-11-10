#!/usr/bin/env python3

import re

# Read the project file
with open('CalTrackProFixed.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Define path corrections
path_corrections = {
    'ThemeManager.swift': 'Services/ThemeManager.swift',
    'AppearanceSettingsView.swift': 'Models/Views/AppearanceSettingsView.swift',
    'AdvancedUIComponents.swift': 'Models/Views/AdvancedUIComponents.swift',
    'SubscriptionManager.swift': 'Services/SubscriptionManager.swift',
    'PremiumUpgradeView.swift': 'Models/Views/PremiumUpgradeView.swift',
    'MealPlanningView.swift': 'Models/Views/MealPlanningView.swift',
    'AdvancedAnalyticsView.swift': 'Models/Views/AdvancedAnalyticsView.swift',
    'DataExportView.swift': 'Models/Views/DataExportView.swift',
    'EnhancedFoodDatabase.swift': 'Services/EnhancedFoodDatabase.swift',
    'USDAFoodDataService.swift': 'Services/USDAFoodDataService.swift',
    'OpenFoodFactsService.swift': 'Services/OpenFoodFactsService.swift',
    'EdamamService.swift': 'Services/EdamamService.swift',
    'EnhancedFoodSearchView.swift': 'Models/Views/EnhancedFoodSearchView.swift',
    'SearchFiltersView.swift': 'Models/Views/SearchFiltersView.swift',
    'EnhancedFoodDetailView.swift': 'Models/Views/EnhancedFoodDetailView.swift',
    'HealthKitManager.swift': 'Services/HealthKitManager.swift',
    'HealthIntegrationView.swift': 'Models/Views/HealthIntegrationView.swift',
    'FoodRecognition.swift': 'Services/FoodRecognition.swift',
    'AIFoodCameraView.swift': 'Models/Views/AIFoodCameraView.swift',
    'AIFoodRecognitionView.swift': 'Models/Views/AIFoodRecognitionView.swift',
    'FoodRecognitionResultView.swift': 'Models/Views/FoodRecognitionResultView.swift',
    'Goal.swift': 'Models/Goal.swift',
    'Achievement.swift': 'Models/Achievement.swift',
    'SmartGoalsView.swift': 'Models/Views/SmartGoalsView.swift',
    'GoalCreatorView.swift': 'Models/Views/GoalCreatorView.swift',
    'GoalDetailView.swift': 'Models/Views/GoalDetailView.swift',
    'AchievementDetailView.swift': 'Models/Views/AchievementDetailView.swift',
    'Recipe.swift': 'Models/Recipe.swift',
    'RecipeBuilderView.swift': 'Models/Views/RecipeBuilderView.swift',
    'RecipeLibraryView.swift': 'Models/Views/RecipeLibraryView.swift'
}

# Fix file paths in PBXFileReference entries
for filename, correct_path in path_corrections.items():
    # Pattern to match file references
    pattern = rf'(path = ")({filename})("; sourceTree = "<group>";)'
    replacement = rf'\1{correct_path}\3'
    content = re.sub(pattern, replacement, content)

print("✓ Fixed file paths in Xcode project")

# Write back the project file
with open('CalTrackProFixed.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("✓ Updated CalTrackProFixed.xcodeproj with correct file paths")

# Verify some key files exist
import os
for filename, correct_path in list(path_corrections.items())[:5]:
    full_path = os.path.join('/Users/ronniecraig/CalTrackProfixed', correct_path)
    if os.path.exists(full_path):
        print(f"✓ Verified: {correct_path}")
    else:
        print(f"⚠️  Missing: {correct_path}")