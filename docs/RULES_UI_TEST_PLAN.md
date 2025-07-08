# Rules Management UI Test Plan

## Feature Overview
A dedicated window for users to view, create, edit, test, and share categorization rules.

## User Stories to Test
1. As a user, I want to see all my active rules in one place
2. As a user, I want to create rules from example transactions
3. As a user, I want to test rules before saving them
4. As a user, I want to enable/disable rules without deleting
5. As a user, I want to export/share my rules

## Component Breakdown

### RulesListView
- Display all rules (system + custom)
- Sort by: Priority, Name, Last Used, Success Rate
- Filter by: Active/Inactive, Custom/System
- Search functionality

### RuleDetailView
- Show rule conditions
- Display match statistics
- Edit rule properties
- Test against sample data

### RuleBuilderView
- Create from transaction
- Add multiple conditions
- Set priority and confidence
- Preview matches

### RuleExportView
- Select rules to export
- Preview export data
- Generate shareable file

## Test Categories

### Unit Tests
- RuleViewModel logic
- Rule filtering/sorting
- Export/import validation
- Conflict resolution

### Integration Tests
- RuleStorageService integration
- CategoryService rule updates
- File system operations

### UI Tests
- Navigation flow
- Form validation
- Drag-and-drop priority
- Keyboard shortcuts

### Performance Tests
- Load 1000+ rules
- Search responsiveness
- Sort operation speed

## Edge Cases
- Duplicate rule names
- Invalid regex patterns
- Circular rule dependencies
- Import conflicts
- Empty states