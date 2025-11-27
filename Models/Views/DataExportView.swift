import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DataExportView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Query private var foodEntries: [FoodEntry]
    @Query private var recipes: [Recipe]
    @Query private var goals: [Goal]
    
    @State private var selectedExportType: ExportType = .nutrition
    @State private var selectedFormat: ExportFormat = .csv
    @State private var selectedTimeRange: ExportTimeRange = .lastMonth
    @State private var customStartDate = Date()
    @State private var customEndDate = Date()
    @State private var isExporting = false
    @State private var showUpgrade = false
    @State private var exportProgress: Double = 0
    @State private var showingDocumentPicker = false
    @State private var exportedURL: URL?
    
    var body: some View {
        NavigationStack {
            ZStack {
                GlassmorphismBackground(colors: [.blue, .purple, .indigo])
                
                if subscriptionManager.hasAccessTo(.exportData) {
                    exportContent
                } else {
                    premiumRequiredView
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
        }
        .premiumFeature(.exportData)
        .fileExporter(
            isPresented: $showingDocumentPicker,
            document: exportedURL.map { ExportDocument(url: $0) },
            contentType: selectedFormat.contentType,
            defaultFilename: defaultFilename
        ) { result in
            handleExportResult(result)
        }
    }
    
    // MARK: - Export Content
    
    private var exportContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                exportOptionsCard
                timeRangeCard
                dataPreviewCard
                exportButtonCard
                
                if isExporting {
                    exportProgressCard
                }
                
                quickActionsCard
            }
            .padding()
        }
    }
    
    private var exportOptionsCard: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Export Options")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 16) {
                    // Data Type Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Data Type")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack(spacing: 8) {
                            ForEach(ExportType.allCases, id: \.self) { type in
                                ExportTypeButton(
                                    type: type,
                                    isSelected: selectedExportType == type
                                ) {
                                    selectedExportType = type
                                }
                            }
                        }
                    }
                    
                    // Format Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Export Format")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack(spacing: 8) {
                            ForEach(ExportFormat.allCases, id: \.self) { format in
                                FormatButton(
                                    format: format,
                                    isSelected: selectedFormat == format
                                ) {
                                    selectedFormat = format
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private var timeRangeCard: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Time Range")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 12) {
                    ForEach(ExportTimeRange.allCases, id: \.self) { range in
                        TimeRangeRow(
                            range: range,
                            isSelected: selectedTimeRange == range
                        ) {
                            selectedTimeRange = range
                        }
                    }
                    
                    if selectedTimeRange == .custom {
                        customDateRange
                    }
                }
            }
            .padding()
        }
    }
    
    private var customDateRange: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Start Date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    DatePicker("", selection: $customStartDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("End Date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    DatePicker("", selection: $customEndDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(8)
        }
    }
    
    private var dataPreviewCard: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Data Preview")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(getDataCount()) records")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    DataPreviewRow(
                        icon: selectedExportType.icon,
                        label: selectedExportType.displayName,
                        count: getDataCount(),
                        color: selectedExportType.color
                    )
                    
                    if selectedFormat == .pdf {
                        DataPreviewRow(
                            icon: "chart.bar.fill",
                            label: "Charts & Analytics",
                            count: 5,
                            color: .purple
                        )
                        
                        DataPreviewRow(
                            icon: "list.bullet",
                            label: "Summary Tables",
                            count: 3,
                            color: .blue
                        )
                    }
                }
            }
            .padding()
        }
    }
    
    private var exportButtonCard: some View {
        LiquidGlassCard {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Export Size")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(estimatedFileSize)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Format")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(selectedFormat.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(action: startExport) {
                    HStack {
                        if isExporting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title2)
                        }
                        
                        Text(isExporting ? "Exporting..." : "Export Data")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .disabled(isExporting)
                .liquidPulse(color: .blue, intensity: 0.3)
            }
            .padding()
        }
    }
    
    private var exportProgressCard: some View {
        LiquidGlassCard {
            VStack(spacing: 16) {
                HStack {
                    Text("Exporting Data")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(Int(exportProgress * 100))%")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                ProgressView(value: exportProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .tint(.blue)
                
                Text("Preparing your data for export. This may take a moment...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .liquidPulse(color: .blue, intensity: 0.2)
    }
    
    private var quickActionsCard: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Quick Actions")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 12) {
                    QuickActionRow(
                        icon: "calendar",
                        title: "Export Last 30 Days",
                        description: "CSV format with nutrition data",
                        action: exportLast30Days
                    )
                    
                    QuickActionRow(
                        icon: "doc.text",
                        title: "Monthly Report",
                        description: "PDF with charts and insights",
                        action: exportMonthlyReport
                    )
                    
                    QuickActionRow(
                        icon: "book.fill",
                        title: "Recipe Collection",
                        description: "All your saved recipes",
                        action: exportRecipes
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - Premium Required View
    
    private var premiumRequiredView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 12) {
                Text("Data Export Premium")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Export your nutrition data in multiple formats, generate comprehensive reports, and sync with other health apps.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 16) {
                PremiumFeatureHighlight(
                    icon: "tablecells",
                    title: "CSV & Excel Export",
                    description: "Raw data for analysis in spreadsheets"
                )
                
                PremiumFeatureHighlight(
                    icon: "doc.text",
                    title: "PDF Reports",
                    description: "Beautiful reports with charts and insights"
                )
                
                PremiumFeatureHighlight(
                    icon: "cloud.fill",
                    title: "Cloud Sync",
                    description: "Sync with other health and fitness apps"
                )
                
                PremiumFeatureHighlight(
                    icon: "calendar.badge.plus",
                    title: "Custom Date Ranges",
                    description: "Export any time period you choose"
                )
            }
            
            Button(action: {
                showUpgrade = true
            }) {
                HStack {
                    Image(systemName: "crown.fill")
                        .font(.title2)
                    
                    Text("Upgrade to Premium")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .liquidPulse(color: .blue, intensity: 0.3)
            .padding(.horizontal)
            
            Spacer()
        }
        .sheet(isPresented: $showUpgrade) {
            PremiumUpgradeView(sourceFeature: .exportData)
        }
    }
    
    // MARK: - Helper Methods
    
    private var estimatedFileSize: String {
        let recordCount = getDataCount()
        let bytesPerRecord = selectedFormat == .pdf ? 500 : 100
        let totalBytes = recordCount * bytesPerRecord
        
        if totalBytes < 1024 * 1024 {
            return "\(totalBytes / 1024) KB"
        } else {
            return String(format: "%.1f MB", Double(totalBytes) / (1024 * 1024))
        }
    }
    
    private var defaultFilename: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        
        return "CalTrackPro_\(selectedExportType.rawValue)_\(dateString).\(selectedFormat.fileExtension)"
    }
    
    private func getDataCount() -> Int {
        let (startDate, endDate) = getDateRange()
        
        switch selectedExportType {
        case .nutrition:
            return foodEntries.filter { 
                $0.timestamp >= startDate && $0.timestamp <= endDate 
            }.count
        case .recipes:
            return recipes.count
        case .goals:
            // Return total goals count (date filtering done at export time)
            return goals.count
        case .complete:
            let nutritionCount = foodEntries.filter { 
                $0.timestamp >= startDate && $0.timestamp <= endDate 
            }.count
            return nutritionCount + recipes.count + goals.count
        }
    }
    
    private func getDateRange() -> (Date, Date) {
        let calendar = Calendar.current
        let now = Date()
        
        let startDate: Date
        let endDate = now
        
        switch selectedTimeRange {
        case .lastWeek:
            startDate = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        case .lastMonth:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .last3Months:
            startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .lastYear:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        case .allTime:
            startDate = calendar.date(from: DateComponents(year: 2020)) ?? now
        case .custom:
            return (customStartDate, customEndDate)
        }
        
        return (startDate, endDate)
    }
    
    // MARK: - Export Actions
    
    private func startExport() {
        isExporting = true
        exportProgress = 0
        
        Task {
            await performExport()
        }
    }
    
    private func performExport() async {
        // Simulate export progress
        for i in 1...10 {
            await MainActor.run {
                exportProgress = Double(i) / 10.0
            }
            try? await Task.sleep(nanoseconds: 300_000_000)
        }
        
        // Generate export URL
        await MainActor.run {
            exportedURL = generateExportFile()
            showingDocumentPicker = true
            isExporting = false
        }
    }
    
    private func generateExportFile() -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = defaultFilename
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        let (startDate, endDate) = getDateRange()
        
        switch selectedFormat {
        case .csv:
            return generateCSVFile(at: fileURL, startDate: startDate, endDate: endDate)
        case .pdf:
            return generatePDFFile(at: fileURL, startDate: startDate, endDate: endDate)
        case .json:
            return generateJSONFile(at: fileURL, startDate: startDate, endDate: endDate)
        }
    }
    
    private func generateCSVFile(at url: URL, startDate: Date, endDate: Date) -> URL? {
        let filteredEntries = foodEntries.filter { 
            $0.timestamp >= startDate && $0.timestamp <= endDate 
        }
        
        var csvContent = "Date,Food,Calories,Protein,Carbs,Fat,Meal Type\n"
        
        for entry in filteredEntries {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let dateString = dateFormatter.string(from: entry.timestamp)
            
            csvContent += "\(dateString),\(entry.name),\(entry.totalCalories),\(entry.totalProtein),\(entry.totalCarbs),\(entry.totalFat),\(entry.mealType.rawValue)\n"
        }
        
        do {
            try csvContent.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("Error writing CSV file: \(error)")
            return nil
        }
    }
    
    private func generatePDFFile(at url: URL, startDate: Date, endDate: Date) -> URL? {
        // In a real implementation, this would generate a PDF report
        // For now, we'll create a placeholder
        let pdfContent = "PDF Report Placeholder"
        
        do {
            try pdfContent.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("Error writing PDF file: \(error)")
            return nil
        }
    }
    
    private func generateJSONFile(at url: URL, startDate: Date, endDate: Date) -> URL? {
        let filteredEntries = foodEntries.filter { 
            $0.timestamp >= startDate && $0.timestamp <= endDate 
        }
        
        let exportData = ExportData(
            exportDate: Date(),
            dateRange: ExportDateRange(start: startDate, end: endDate),
            entries: filteredEntries.map { ExportEntry(from: $0) }
        )
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(exportData)
            try data.write(to: url)
            return url
        } catch {
            print("Error writing JSON file: \(error)")
            return nil
        }
    }
    
    private func exportLast30Days() {
        selectedExportType = .nutrition
        selectedFormat = .csv
        selectedTimeRange = .lastMonth
        startExport()
    }
    
    private func exportMonthlyReport() {
        selectedExportType = .complete
        selectedFormat = .pdf
        selectedTimeRange = .lastMonth
        startExport()
    }
    
    private func exportRecipes() {
        selectedExportType = .recipes
        selectedFormat = .json
        selectedTimeRange = .allTime
        startExport()
    }
    
    private func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            print("Export saved to: \(url)")
        case .failure(let error):
            print("Export failed: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct ExportTypeButton: View {
    let type: ExportType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : type.color)
                
                Text(type.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? type.color : .gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FormatButton: View {
    let format: ExportFormat
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(format.fileExtension.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(format.displayName)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? .blue : .gray.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TimeRangeRow: View {
    let range: ExportTimeRange
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                
                Text(range.displayName)
                    .font(.subheadline)
                
                Spacer()
                
                if let description = range.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DataPreviewRow: View {
    let icon: String
    let label: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(label)
                .font(.subheadline)
            
            Spacer()
            
            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
}

struct QuickActionRow: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Data Models

enum ExportType: String, CaseIterable {
    case nutrition, recipes, goals, complete
    
    var displayName: String {
        switch self {
        case .nutrition: return "Nutrition"
        case .recipes: return "Recipes"
        case .goals: return "Goals"
        case .complete: return "Complete"
        }
    }
    
    var icon: String {
        switch self {
        case .nutrition: return "fork.knife"
        case .recipes: return "book.fill"
        case .goals: return "target"
        case .complete: return "doc.on.doc"
        }
    }
    
    var color: Color {
        switch self {
        case .nutrition: return .green
        case .recipes: return .orange
        case .goals: return .purple
        case .complete: return .blue
        }
    }
}

enum ExportFormat: String, CaseIterable {
    case csv, pdf, json
    
    var displayName: String {
        switch self {
        case .csv: return "Spreadsheet"
        case .pdf: return "Report"
        case .json: return "Raw Data"
        }
    }
    
    var fileExtension: String {
        rawValue
    }
    
    var contentType: UTType {
        switch self {
        case .csv: return .commaSeparatedText
        case .pdf: return .pdf
        case .json: return .json
        }
    }
}

enum ExportTimeRange: CaseIterable {
    case lastWeek, lastMonth, last3Months, lastYear, allTime, custom
    
    var displayName: String {
        switch self {
        case .lastWeek: return "Last Week"
        case .lastMonth: return "Last Month"
        case .last3Months: return "Last 3 Months"
        case .lastYear: return "Last Year"
        case .allTime: return "All Time"
        case .custom: return "Custom Range"
        }
    }
    
    var description: String? {
        switch self {
        case .lastWeek: return "7 days"
        case .lastMonth: return "30 days"
        case .last3Months: return "90 days"
        case .lastYear: return "365 days"
        case .allTime: return "Everything"
        case .custom: return nil
        }
    }
}

// MARK: - Export Document

struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.plainText, .pdf, .json, .commaSeparatedText]
    
    var url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        // Handle reading the document if needed
        self.url = URL(fileURLWithPath: "temp")
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return try FileWrapper(url: url)
    }
}

// MARK: - Export Data Models

struct ExportData: Codable {
    let exportDate: Date
    let dateRange: ExportDateRange
    let entries: [ExportEntry]
}

struct ExportDateRange: Codable {
    let start: Date
    let end: Date
}

struct ExportEntry: Codable {
    let id: String
    let timestamp: Date
    let foodName: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let mealType: String
    
    init(from foodEntry: FoodEntry) {
        self.id = foodEntry.id.uuidString
        self.timestamp = foodEntry.timestamp
        self.foodName = foodEntry.name
        self.calories = foodEntry.totalCalories
        self.protein = foodEntry.totalProtein
        self.carbs = foodEntry.totalCarbs
        self.fat = foodEntry.totalFat
        self.mealType = foodEntry.mealType.rawValue
    }
}

#Preview {
    DataExportView()
        .modelContainer(for: [FoodEntry.self, Recipe.self, Goal.self])
}