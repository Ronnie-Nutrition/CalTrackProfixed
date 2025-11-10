#!/usr/bin/env ruby

# Script to add missing Swift files to Xcode project
require 'xcodeproj'

project_path = 'CalTrackProFixed.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Files to add
files_to_add = [
  'Models/Views/EnhancedInsightsView.swift',
  'Models/Views/LiquidGlassComponents.swift'
]

files_to_add.each do |file_path|
  if File.exist?(file_path)
    puts "Adding #{file_path} to Xcode project..."
    
    # Add file reference
    file_ref = project.main_group.new_reference(file_path)
    file_ref.path = file_path
    
    # Add to target
    target.add_file_references([file_ref])
    
    puts "✓ Added #{file_path}"
  else
    puts "✗ File not found: #{file_path}"
  end
end

# Save the project
project.save

puts "Done! Project updated successfully."