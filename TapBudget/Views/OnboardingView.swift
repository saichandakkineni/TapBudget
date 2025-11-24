import SwiftUI

/// Onboarding tutorial view for new users
struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage: Int = 0
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to TapBudget",
            description: "Track your expenses effortlessly. No spreadsheets, no complexity.",
            imageName: "dollarsign.circle.fill",
            color: .blue
        ),
        OnboardingPage(
            title: "Quick Expense Entry",
            description: "Tap a category, enter an amount, and you're done. It's that simple.",
            imageName: "plus.circle.fill",
            color: .green
        ),
        OnboardingPage(
            title: "Smart Budget Tracking",
            description: "Set budgets for each category and get alerts when you're approaching limits.",
            imageName: "chart.pie.fill",
            color: .orange
        ),
        OnboardingPage(
            title: "Visual Insights",
            description: "See your spending patterns with beautiful charts and monthly summaries.",
            imageName: "chart.bar.fill",
            color: .purple
        ),
        OnboardingPage(
            title: "Export & Share",
            description: "Export your expenses to CSV or PDF whenever you need them.",
            imageName: "square.and.arrow.up.fill",
            color: .red
        )
    ]
    
    var body: some View {
        ZStack {
            // Background gradient - safe array access
            LinearGradient(
                colors: [
                    (currentPage < pages.count ? pages[currentPage].color.opacity(0.1) : Color.blue.opacity(0.1)),
                    Color(.systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .padding()
                    .foregroundColor(.secondary)
                }
                
                // Page content
                TabView(selection: Binding(
                    get: { min(currentPage, max(0, pages.count - 1)) },
                    set: { currentPage = min($0, max(0, pages.count - 1)) }
                )) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .onAppear {
                    // Ensure currentPage is within bounds
                    currentPage = min(currentPage, max(0, pages.count - 1))
                }
                
                // Bottom buttons
                HStack(spacing: 20) {
                    if currentPage > 0 {
                        Button("Previous") {
                            withAnimation {
                                currentPage = max(0, currentPage - 1)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                    
                    Button(currentPage >= pages.count - 1 ? "Get Started" : "Next") {
                        if currentPage >= pages.count - 1 {
                            completeOnboarding()
                        } else {
                            withAnimation {
                                currentPage = min(pages.count - 1, currentPage + 1)
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        withAnimation {
            isPresented = false
        }
    }
}

/// Individual onboarding page data
struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
    let color: Color
}

/// View for a single onboarding page
struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon
            Image(systemName: page.imageName)
                .font(.system(size: 80))
                .foregroundColor(page.color)
                .symbolEffect(.bounce, value: page.color)
            
            // Title
            Text(page.title)
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Description
            Text(page.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

/// Helper to check if onboarding should be shown
extension UserDefaults {
    static var hasCompletedOnboarding: Bool {
        get {
            UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding")
        }
    }
}

