import Foundation
import SwiftUI

/// Manages global app state
@MainActor
@Observable
class AppState {
    var isInitializing = true
    
    init() {
        // App starts in initializing state
    }
}

