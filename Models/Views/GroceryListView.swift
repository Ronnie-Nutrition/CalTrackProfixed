import SwiftUI

struct GroceryListView: View {
    @StateObject private var groceryService = GroceryListService.shared
    @State private var showingAddItem = false
    @State private var showingSavedLists = false
    @State private var expandedCategories: Set<GroceryCategory> = Set(GroceryCategory.allCases)

    var body: some View {
        NavigationStack {
            Group {
                if let list = groceryService.currentList {
                    groceryListContent(list)
                } else {
                    emptyState
                }
            }
            .navigationTitle("Grocery List")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if groceryService.currentList != nil {
                        Menu {
                            Button(action: { showingSavedLists = true }) {
                                Label("Saved Lists", systemImage: "folder")
                            }
                            Button(action: shareList) {
                                Label("Share List", systemImage: "square.and.arrow.up")
                            }
                            Button(action: { groceryService.saveCurrentList() }) {
                                Label("Save List", systemImage: "square.and.arrow.down")
                            }
                            Divider()
                            Button(role: .destructive) {
                                groceryService.clearCheckedItems()
                            } label: {
                                Label("Clear Checked", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if groceryService.currentList != nil {
                        Button(action: { showingAddItem = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddGroceryItemView()
            }
            .sheet(isPresented: $showingSavedLists) {
                SavedGroceryListsView()
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        ContentUnavailableView(
            "No Grocery List",
            systemImage: "cart",
            description: Text("Generate a meal plan first, then create your grocery list from it")
        )
    }

    // MARK: - Grocery List Content
    private func groceryListContent(_ list: GroceryList) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Progress Card
                progressCard(list)

                // Items by Category
                ForEach(GroceryCategory.allCases, id: \.self) { category in
                    if let items = list.itemsByCategory[category], !items.isEmpty {
                        categorySection(category: category, items: items)
                    }
                }

                // Total Cost
                costSummary(list)
            }
            .padding()
        }
        .background(AppColors.primaryBackground)
    }

    // MARK: - Progress Card
    private func progressCard(_ list: GroceryList) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Shopping Progress")
                        .font(.headline)
                    Text("\(list.checkedCount) of \(list.items.count) items")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 60, height: 60)

                    Circle()
                        .trim(from: 0, to: list.progress)
                        .stroke(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: list.progress)

                    Text("\(Int(list.progress * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }

    // MARK: - Category Section
    private func categorySection(category: GroceryCategory, items: [GroceryItem]) -> some View {
        VStack(spacing: 0) {
            // Header
            Button(action: {
                withAnimation {
                    if expandedCategories.contains(category) {
                        expandedCategories.remove(category)
                    } else {
                        expandedCategories.insert(category)
                    }
                }
            }) {
                HStack {
                    Image(systemName: category.icon)
                        .foregroundColor(category.color)
                        .frame(width: 30)

                    Text(category.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    Text("\(items.filter { !$0.isChecked }.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)

                    Image(systemName: expandedCategories.contains(category) ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(category.color.opacity(0.1))
                )
            }

            // Items
            if expandedCategories.contains(category) {
                VStack(spacing: 1) {
                    ForEach(items) { item in
                        GroceryItemRow(item: item) {
                            groceryService.toggleItem(item)
                        } onDelete: {
                            groceryService.removeItem(item)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Cost Summary
    private func costSummary(_ list: GroceryList) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Estimated Total")
                    .font(.headline)
                Text("Prices are approximate")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("$\(String(format: "%.2f", list.totalEstimatedCost))")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.green)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }

    // MARK: - Share List
    private func shareList() {
        guard let list = groceryService.currentList else { return }

        var shareText = "Grocery List\n\n"

        for category in GroceryCategory.allCases {
            if let items = list.itemsByCategory[category], !items.isEmpty {
                shareText += "\(category.rawValue):\n"
                for item in items {
                    let checkmark = item.isChecked ? "[x]" : "[ ]"
                    shareText += "  \(checkmark) \(item.name) - \(item.quantity)\n"
                }
                shareText += "\n"
            }
        }

        shareText += "Estimated Total: $\(String(format: "%.2f", list.totalEstimatedCost))"

        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
}

// MARK: - Grocery Item Row
struct GroceryItemRow: View {
    let item: GroceryItem
    let onToggle: () -> Void
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(item.isChecked ? .green : .gray)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .strikethrough(item.isChecked)
                    .foregroundColor(item.isChecked ? .secondary : .primary)

                Text(item.quantity)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("$\(String(format: "%.2f", item.estimatedCost))")
                .font(.caption)
                .foregroundColor(.secondary)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.7))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppColors.secondaryBackground)
        )
    }
}

// MARK: - Add Grocery Item View
struct AddGroceryItemView: View {
    @StateObject private var groceryService = GroceryListService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var quantity = ""
    @State private var cost = ""
    @State private var selectedCategory: GroceryCategory = .other

    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Item Name", text: $name)
                    TextField("Quantity (e.g., 2 lbs)", text: $quantity)
                    TextField("Estimated Cost", text: $cost)
                        .keyboardType(.decimalPad)
                }

                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(GroceryCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(category.color)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let costValue = Double(cost) ?? 0
                        groceryService.addCustomItem(
                            name: name,
                            category: selectedCategory,
                            quantity: quantity.isEmpty ? "1" : quantity,
                            cost: costValue
                        )
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Saved Grocery Lists View
struct SavedGroceryListsView: View {
    @StateObject private var groceryService = GroceryListService.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if groceryService.savedLists.isEmpty {
                    ContentUnavailableView(
                        "No Saved Lists",
                        systemImage: "folder",
                        description: Text("Save your current list to access it later")
                    )
                } else {
                    ForEach(groceryService.savedLists) { list in
                        Button(action: {
                            groceryService.currentList = list
                            dismiss()
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(list.createdAt, style: .date)
                                        .font(.headline)
                                    Text("\(list.items.count) items")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Text("$\(String(format: "%.2f", list.totalEstimatedCost))")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Saved Lists")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    GroceryListView()
}
