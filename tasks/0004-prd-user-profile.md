# PRD: User Profile & Goals

## Introduction/Overview
The User Profile feature allows users to set personal information and nutritional goals, creating a personalized experience in CalTrackPro. This feature solves the problem of generic nutrition tracking by tailoring recommendations and progress tracking to individual user needs and objectives.

## Goals
1. Enable users to set personalized daily nutrition goals
2. Store user preferences and dietary information
3. Calculate personalized recommendations based on user data
4. Provide goal progress visualization throughout the app
5. Support different dietary preferences and restrictions

## User Stories
1. As a new user, I want to set my nutrition goals during onboarding so the app can track my progress
2. As a user trying to lose weight, I want to set a calorie deficit goal
3. As a user building muscle, I want to set specific protein targets
4. As a user with dietary restrictions, I want to note my preferences for future features
5. As a user, I want to update my goals as my fitness journey evolves

## Functional Requirements
1. The system must store user profile data: name, age, height, weight, activity level
2. The system must allow setting daily goals for: calories, protein, carbs, fat, fiber
3. The system must persist profile data using SwiftData
4. The system must validate goal inputs (reasonable ranges)
5. The system must calculate BMR/TDEE if user wants recommendations
6. The system must support both metric and imperial units
7. The system must allow editing all profile fields
8. The system must integrate goals with diary progress display
9. The system must support goal presets (lose weight, maintain, gain muscle)
10. The system must handle profile data migration between app versions

## Non-Goals (Out of Scope)
- Social profiles or sharing
- Photo uploads/avatars
- Detailed fitness tracking integration
- Medical condition tracking
- Supplement tracking
- Water intake goals

## Design Considerations
- Clear, friendly onboarding flow
- Intuitive goal-setting interface with visual feedback
- Easy access to edit profile from settings
- Non-judgmental language around goals
- Clear data privacy messaging

## Technical Considerations
- SwiftData model for UserProfile
- Singleton pattern for current user
- Input validation for health metrics
- Goal calculation algorithms
- Unit conversion utilities

## Success Metrics
1. 80% of new users complete profile setup
2. 60% of users set custom nutrition goals
3. 40% of users adjust goals within first month
4. User retention increases by 25% with goal setting

## Open Questions
1. Should we integrate with HealthKit for automatic data?
2. Should we support multiple profiles per device?
3. How often should we prompt users to update their goals?