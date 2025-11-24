import SwiftUI

/// Onboarding page for iCloud sync opt-in
struct CloudKitOptInPageView: View {
    @Binding var enableCloudKit: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // iCloud icon
            Image(systemName: "icloud.fill")
                .font(.system(size: 80))
                .foregroundColor(.cyan)
                .symbolEffect(.bounce, value: enableCloudKit)
            
            // Title
            Text("iCloud Sync")
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Description
            VStack(spacing: 16) {
                Text("Enable iCloud sync to access your expenses across all your devices.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(icon: "iphone", text: "Access on iPhone, iPad, and Mac")
                    FeatureRow(icon: "lock.shield.fill", text: "End-to-end encrypted")
                    FeatureRow(icon: "arrow.triangle.2.circlepath", text: "Automatic sync")
                    FeatureRow(icon: "externaldrive.badge.icloud", text: "Backup to iCloud")
                }
                .padding(.horizontal, 40)
                .padding(.top, 8)
            }
            
            // Toggle
            VStack(spacing: 12) {
                Toggle(isOn: $enableCloudKit) {
                    Text("Enable iCloud Sync")
                        .font(.headline)
                }
                .toggleStyle(.switch)
                .padding(.horizontal, 40)
                
                Text(enableCloudKit ? "Your data will sync across all your devices" : "You can enable this later in Settings")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.top, 20)
            
            Spacer()
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.cyan)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

