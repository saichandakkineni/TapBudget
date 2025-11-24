# CloudKit Implementation Plan

## Critical Requirements
1. **App MUST launch immediately** - no blocking operations
2. **CloudKit is OPT-IN** - user must explicitly enable it
3. **Clear messaging** - onboarding explains iCloud sync benefits
4. **Graceful fallback** - app works perfectly without CloudKit
5. **No data loss** - existing local data must be preserved

## Implementation Strategy

### Phase 1: CloudKit Preference Management
- Create `CloudKitPreferenceManager` to store opt-in state
- Store preference in UserDefaults
- Check preference before ModelContainer initialization
- Default: CloudKit DISABLED (local-only)

### Phase 2: Onboarding Integration
- Add iCloud sync opt-in page to onboarding
- Clear explanation of benefits:
  - "Sync your data across all your devices"
  - "Access your expenses on iPhone, iPad, and Mac"
  - "Automatic backup to iCloud"
- User can skip or enable
- Only show if CloudKit is available

### Phase 3: Safe ModelContainer Initialization
- Check CloudKit preference in `init()`
- If enabled AND available: Create ModelContainer with `cloudKitDatabase: .automatic`
- If disabled OR unavailable: Create local-only ModelContainer
- **CRITICAL**: ModelContainer.init() is synchronous but non-blocking - CloudKit operations happen async
- Keep all fallback strategies for robustness

### Phase 4: Settings Integration
- Add "iCloud Sync" toggle in Settings
- Show sync status (syncing, synced, error)
- Allow user to disable CloudKit sync
- Warn about disabling (data stays local)

### Phase 5: CloudKit Status & Error Handling
- Check CloudKit availability safely
- Show clear error messages if:
  - Not signed into iCloud
  - CloudKit unavailable
  - Sync errors occur
- Never block app launch for CloudKit errors

## Key Safety Measures

1. **ModelContainer Initialization**:
   - Always succeeds (local-only fallback)
   - CloudKit enabled only if user opted in
   - CloudKit availability checked safely

2. **Error Handling**:
   - All CloudKit operations wrapped in try-catch
   - Errors logged but don't crash app
   - User sees friendly error messages

3. **Data Migration**:
   - When user enables CloudKit: Existing local data automatically syncs
   - When user disables CloudKit: Data stays local, no deletion
   - SwiftData handles migration automatically

4. **Testing**:
   - Test with CloudKit enabled
   - Test with CloudKit disabled
   - Test with no iCloud account
   - Test with CloudKit unavailable
   - Test app launch in all scenarios

## Code Changes Required

1. **New File**: `CloudKitPreferenceManager.swift`
   - Manages CloudKit opt-in preference
   - Safe availability checking

2. **Modify**: `TapBudgetApp.swift`
   - Check CloudKit preference in init()
   - Conditionally enable CloudKit in ModelConfiguration
   - Keep all fallback strategies

3. **Modify**: `OnboardingView.swift`
   - Add iCloud sync opt-in page
   - Only show if CloudKit available

4. **Modify**: `SettingsView.swift`
   - Add iCloud Sync toggle
   - Show sync status

5. **Enhance**: `CloudKitAvailability.swift`
   - Better availability checking
   - Check entitlements, iCloud sign-in

## Testing Checklist

- [ ] App launches with CloudKit disabled
- [ ] App launches with CloudKit enabled
- [ ] App launches without iCloud account
- [ ] Onboarding shows iCloud opt-in when available
- [ ] User can enable CloudKit from onboarding
- [ ] User can enable/disable CloudKit from settings
- [ ] Data syncs across devices when enabled
- [ ] Existing data preserved when enabling CloudKit
- [ ] No data loss when disabling CloudKit
- [ ] Error messages are user-friendly
- [ ] App never blocks on CloudKit operations

