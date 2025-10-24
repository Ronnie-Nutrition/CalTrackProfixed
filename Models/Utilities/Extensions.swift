import Foundation
import SwiftUI

extension Calendar {
    func startOfDay(for date: Date) -> Date {
        return self.dateInterval(of: .day, for: date)?.start ?? date
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}