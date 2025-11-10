# PRD: Food Diary Core Feature

## Introduction/Overview
The Food Diary is the central feature of CalTrackPro, allowing users to log, view, and manage their daily food intake. It provides a comprehensive view of nutritional consumption organized by meals and dates, solving the problem of manual nutrition tracking with an intuitive, persistent diary system.

## Goals
1. Enable users to log all meals and snacks throughout the day
2. Provide clear visualization of daily nutritional intake
3. Support meal categorization (breakfast, lunch, dinner, snacks)
4. Enable editing and deletion of food entries
5. Persist data locally with automatic cloud sync

## User Stories
1. As a user, I want to log my meals by meal type so I can track eating patterns
2. As a user, I want to see my total daily nutrition summary at a glance
3. As a user, I want to edit portions of logged foods when I realize I ate more/less
4. As a user, I want to view previous days' entries to track progress
5. As a health-conscious user, I want to see if I'm meeting my daily nutrition goals

## Functional Requirements
1. The system must organize entries by date and meal type
2. The system must display running totals for calories and macros
3. The system must support adding foods from search or barcode scan
4. The system must allow editing quantity/portions of existing entries
5. The system must support deleting individual food entries
6. The system must persist all data using SwiftData
7. The system must support date navigation (view different days)
8. The system must calculate and display meal subtotals
9. The system must show progress toward daily goals (if set)
10. The system must support copying meals from previous days

## Non-Goals (Out of Scope)
- Meal planning/future date entries
- Recipe creation within diary view
- Social sharing of diary entries
- Photo attachment to meals
- Meal timing/intermittent fasting tracking

## Design Considerations
- Clean, scannable layout with clear meal sections
- Visual indicators for goal progress
- Intuitive swipe gestures for entry management
- Consistent color coding for meal types
- Responsive design for different screen sizes

## Technical Considerations
- SwiftData for local persistence
- @Query for reactive data updates
- Efficient data model for food entries
- Date handling for different time zones
- Performance optimization for large entry counts

## Success Metrics
1. Users log food entries at least 3 times per day on average
2. 90% of users successfully edit an entry within first week
3. Less than 1% data loss reported
4. Average time to log a meal under 30 seconds

## Open Questions
1. Should we support custom meal types beyond the standard four?
2. How many days of history should be readily accessible?
3. Should we implement meal templates for frequently eaten combinations?