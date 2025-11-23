import SwiftUI

/// A toast-style notification view that appears temporarily
struct ToastView: View {
    let message: String
    let icon: String
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.white)
                
                Text(message)
                    .foregroundColor(.white)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.black.opacity(0.8))
            .cornerRadius(12)
            .padding(.horizontal, 20)
            .padding(.bottom, 50)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .opacity(isPresented ? 1 : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPresented)
    }
}

/// View modifier to show toast notifications
struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let icon: String
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                ToastView(message: message, icon: icon, isPresented: $isPresented)
                    .zIndex(1000)
            }
        }
        .onChange(of: isPresented) { _, newValue in
            if newValue {
                // Auto-dismiss after 2 seconds
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    await MainActor.run {
                        isPresented = false
                    }
                }
            }
        }
    }
}

extension View {
    func toast(isPresented: Binding<Bool>, message: String, icon: String = "checkmark.circle.fill") -> some View {
        modifier(ToastModifier(isPresented: isPresented, message: message, icon: icon))
    }
}

