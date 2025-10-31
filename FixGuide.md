# Common Xcode Integration Fixes

## Error: "Cannot find 'View' in scope"
**Solution**: Add `import SwiftUI` at the top of the file

## Error: "Cannot find 'Query' in scope"
**Solution**: Add `import SwiftData` at the top of the file

## Error: "Cannot find type 'FoodEntry' in scope"
**Solution**: 
1. Make sure FoodEntry.swift is added to your target
2. Check that the file is in the correct group in Xcode

## Error: Camera/Photo Library not working
**Solution**: 
1. Run on a real device (not simulator) for camera
2. Check Info.plist has the usage descriptions

## Error: "No such module 'Charts'"
**Solution**: Charts is built into iOS 16+. Make sure:
1. Your deployment target is iOS 17.0
2. Add `import Charts` where needed

## To Change Deployment Target:
1. Select project → CalTrackPro target
2. General tab → Minimum Deployments → iOS 17.0

## To Clean Build:
1. Product → Clean Build Folder (Shift + Cmd + K)
2. Product → Build (Cmd + B)

