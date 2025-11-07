import SwiftUI

/// Global error handling view modifier
struct ErrorHandlingViewModifier: ViewModifier {
    @Binding var error: Error?
    let retryAction: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: Binding<Bool>(
                get: { error != nil },
                set: { if !$0 { error = nil } }
            )) {
                Button("OK") {
                    error = nil
                }
                
                if let retryAction = retryAction {
                    Button("Retry") {
                        error = nil
                        retryAction()
                    }
                }
            } message: {
                Text(error?.localizedDescription ?? "An unknown error occurred")
            }
    }
}

extension View {
    func errorAlert(error: Binding<Error?>, retry: (() -> Void)? = nil) -> some View {
        modifier(ErrorHandlingViewModifier(error: error, retryAction: retry))
    }
}

/// Loading state view
struct LoadingView: View {
    let message: String
    
    init(_ message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
}

/// Empty state view
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Result state enum for views
enum ViewState<T> {
    case idle
    case loading
    case loaded(T)
    case error(Error)
    
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    var error: Error? {
        if case .error(let error) = self { return error }
        return nil
    }
    
    var data: T? {
        if case .loaded(let data) = self { return data }
        return nil
    }
}