import WidgetKit
import SwiftUI

@main
struct CalTrackWidgetBundle: WidgetBundle {
    var body: some Widget {
        CalorieProgressWidget()
        FastingTimerWidget()
        NutritionSummaryWidget()
    }
}
