import SwiftUI

/// Splash screen shown while app initializes
struct SplashView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // App Icon or Logo
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                
                Text("TapBudget")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                ProgressView()
                    .scaleEffect(1.2)
                    .padding(.top, 20)
                
                Text("Loading...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 10)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

