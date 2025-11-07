import Foundation
import Network
import SwiftUI

/// Monitors network connectivity and provides offline mode functionality
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected = true
    @Published var connectionType = ConnectionType.unknown
    @Published var isExpensive = false
    
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.isExpensive = path.isExpensive
                
                // Determine connection type
                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self?.connectionType = .ethernet
                } else {
                    self?.connectionType = .unknown
                }
                
                // Log connection changes
                CrashlyticsManager.shared.log(
                    "Network status changed - Connected: \(path.status == .satisfied), Type: \(self?.connectionType ?? .unknown)",
                    category: "Network"
                )
            }
        }
        
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}

// MARK: - Network Error View
struct NetworkErrorView: View {
    let error: Error
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text(errorTitle)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(errorMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: retryAction) {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            
            if let apiError = error as? NutritionAPIService.APIError {
                Text(apiError.userFriendlyMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
        }
        .padding()
    }
    
    private var errorTitle: String {
        if let apiError = error as? NutritionAPIService.APIError {
            switch apiError {
            case .noInternetConnection:
                return "No Internet Connection"
            case .timeout:
                return "Request Timed Out"
            case .rateLimitExceeded:
                return "Too Many Requests"
            case .serverError:
                return "Server Error"
            default:
                return "Something Went Wrong"
            }
        }
        return "Connection Error"
    }
    
    private var errorMessage: String {
        if let apiError = error as? NutritionAPIService.APIError {
            switch apiError {
            case .noInternetConnection:
                return "Please check your internet connection and try again."
            case .timeout:
                return "The request took too long. Please try again."
            case .rateLimitExceeded:
                return "You've made too many requests. Please wait a moment before trying again."
            case .serverError:
                return "The server is experiencing issues. Please try again later."
            default:
                return "An unexpected error occurred. Please try again."
            }
        }
        return "We couldn't complete your request. Please try again."
    }
}

// MARK: - Offline Banner
struct OfflineBanner: View {
    @ObservedObject var networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: 10) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 14))
                
                Text("You're offline")
                    .font(.system(size: 14, weight: .medium))
                
                Spacer()
                
                Text("Some features limited")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.orange)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

// MARK: - API Error Extension
extension NutritionAPIService.APIError {
    var userFriendlyMessage: String {
        switch self {
        case .invalidURL:
            return "Invalid request configuration"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Unable to process response"
        case .unauthorized:
            return "Authentication required"
        case .rateLimitExceeded:
            return "API limit reached - try again in a few minutes"
        case .timeout:
            return "Request timed out - check your connection"
        case .noInternetConnection:
            return "No internet connection available"
        case .serverError(let code):
            return "Server error (\(code))"
        case .clientError(let code):
            return "Request error (\(code))"
        case .unexpectedStatusCode(let code):
            return "Unexpected response (\(code))"
        case .invalidResponse:
            return "Invalid server response"
        }
    }
}