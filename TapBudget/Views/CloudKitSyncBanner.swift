import SwiftUI

/// Banner shown on HomeView to prompt users to enable iCloud sync
/// Only shown if CloudKit is available, onboarding is complete, and sync is disabled
struct CloudKitSyncBanner: View {
    @State private var isCloudKitEnabled: Bool = CloudKitPreferenceManager.shared.isCloudKitEnabled
    @State private var isDismissed: Bool = UserDefaults.standard.bool(forKey: "cloudkit_banner_dismissed")
    @State private var onboardingComplete: Bool = UserDefaults.hasCompletedOnboarding
    
    // Only show if CloudKit is available, onboarding is complete, and sync is disabled
    var shouldShow: Bool {
        let cloudKitAvailable = CloudKitAvailability.isAvailable
        let syncDisabled = !isCloudKitEnabled
        let notDismissed = !isDismissed
        
        let shouldShow = cloudKitAvailable && onboardingComplete && syncDisabled && notDismissed
        
        // Debug logging
        print("🔍 CloudKitSyncBanner shouldShow check:")
        print("   CloudKit Available: \(cloudKitAvailable)")
        print("   Onboarding Complete: \(onboardingComplete)")
        print("   Sync Disabled: \(syncDisabled) (isCloudKitEnabled: \(isCloudKitEnabled))")
        print("   Not Dismissed: \(notDismissed) (isDismissed: \(isDismissed))")
        print("   Result: \(shouldShow ? "SHOWING" : "HIDDEN")")
        
        return shouldShow
    }
    
    var body: some View {
        Group {
            if shouldShow {
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                    Image(systemName: "icloud.fill")
                        .font(.title2)
                        .foregroundColor(.cyan)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enable iCloud Sync")
                            .font(.headline)
                        
                        Text("Sync your expenses across all your devices")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        enableCloudKit()
                    } label: {
                        Text("Enable")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.cyan)
                            .cornerRadius(8)
                    }
                    
                    Button {
                        dismissBanner()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                }
                .padding(.horizontal)
                .padding(.top, 8) // Add top padding to ensure visibility
                .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                // Refresh state when view appears
                refreshState()
            }
            .onChange(of: CloudKitPreferenceManager.shared.isCloudKitEnabled) { _, newValue in
                isCloudKitEnabled = newValue
            }
            .onChange(of: UserDefaults.hasCompletedOnboarding) { _, newValue in
                print("🔄 CloudKitSyncBanner: Onboarding completion changed to \(newValue)")
                onboardingComplete = newValue
                // Force view update
                withAnimation {
                    // Trigger view update
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OnboardingCompleted"))) { _ in
                // Listen for onboarding completion notification
                print("🔄 CloudKitSyncBanner: Received OnboardingCompleted notification")
                refreshState()
            }
            .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
                // Listen for UserDefaults changes
                print("🔄 CloudKitSyncBanner: Received UserDefaults change notification")
                refreshState()
            }
            } else {
                // Empty view when not showing - helps with debugging
                EmptyView()
                    .onAppear {
                        print("🔍 CloudKitSyncBanner: Not showing (shouldShow = false)")
                    }
                    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OnboardingCompleted"))) { _ in
                        // Listen for onboarding completion notification even when hidden
                        print("🔄 CloudKitSyncBanner (hidden): Received OnboardingCompleted notification")
                        refreshState()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
                        // Listen for UserDefaults changes even when hidden
                        print("🔄 CloudKitSyncBanner (hidden): Received UserDefaults change notification")
                        refreshState()
                    }
            }
        }
    }
    
    private func enableCloudKit() {
        CloudKitPreferenceManager.shared.isCloudKitEnabled = true
        isCloudKitEnabled = true
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Show success message (could use toast here)
        print("✅ iCloud Sync enabled from HomeView banner")
    }
    
    private func dismissBanner() {
        withAnimation {
            isDismissed = true
        }
        
        // Store dismissal preference
        UserDefaults.standard.set(true, forKey: "cloudkit_banner_dismissed")
        UserDefaults.standard.synchronize()
    }
    
    private func refreshState() {
        isCloudKitEnabled = CloudKitPreferenceManager.shared.isCloudKitEnabled
        isDismissed = UserDefaults.standard.bool(forKey: "cloudkit_banner_dismissed")
        onboardingComplete = UserDefaults.hasCompletedOnboarding
        print("🔄 CloudKitSyncBanner refreshState - isCloudKitEnabled: \(isCloudKitEnabled), isDismissed: \(isDismissed), onboardingComplete: \(onboardingComplete)")
    }
}

