# Git Commit Guidelines for CalTrackPro

Following the ai-dev-tasks workflow and conventional commit standards.

## Commit Message Format

All commits must follow the conventional commit format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, missing semicolons, etc.)
- `refactor`: Code refactoring without changing functionality
- `perf`: Performance improvements
- `test`: Adding or modifying tests
- `chore`: Maintenance tasks, dependency updates
- `build`: Build system or external dependency changes
- `ci`: CI/CD configuration changes

### Examples

#### Simple Feature
```bash
git commit -m "feat(diary): add meal copying from previous days"
```

#### Feature with Details
```bash
git commit -m "feat(scanner): implement torch control for low-light scanning" \
  -m "- Add torch toggle button to scanner UI" \
  -m "- Implement torch state management" \
  -m "- Add haptic feedback on torch toggle" \
  -m "Related to task 1.3 in 0001-prd-camera-barcode-scanning"
```

#### Bug Fix
```bash
git commit -m "fix(api): handle rate limiting in nutrition search" \
  -m "- Implement exponential backoff" \
  -m "- Show user-friendly error messages" \
  -m "- Cache recent searches to reduce API calls"
```

#### Following Task Completion
When completing all subtasks under a parent task:
```bash
git commit -m "feat(profile): complete user onboarding flow implementation" \
  -m "- Add profile setup screens" \
  -m "- Implement goal calculation logic" \
  -m "- Add unit conversion utilities" \
  -m "- Create SwiftData models for persistence" \
  -m "Completes task 2.0 from tasks-0004-prd-user-profile"
```

## Task-Based Commits

Following ai-dev-tasks workflow:
1. Complete all subtasks under a parent task
2. Run tests to ensure nothing is broken
3. Stage changes: `git add .`
4. Commit with descriptive message referencing the task

## Best Practices

1. **Keep subject line under 50 characters**
2. **Use imperative mood** ("add feature" not "added feature")
3. **Reference task numbers** when applicable
4. **Include "why" in body** when the change isn't obvious
5. **List key changes** in bullet points for complex commits

## DO NOT

- Don't use generic messages like "fix bugs" or "update code"
- Don't combine unrelated changes in one commit
- Don't commit broken code
- Don't forget to reference the related task/PRD

## Migration Note

Previous commits didn't follow this format. All future commits should adhere to these guidelines to maintain consistency with the ai-dev-tasks workflow.