import Foundation
import SwiftUI
import Combine

// MARK: - Grocery Item
struct GroceryItem: Codable, Identifiable, Hashable {
    var id = UUID()
    let name: String
    let category: GroceryCategory
    var quantity: String
    var estimatedCost: Double
    var isChecked: Bool
    var fromMeals: [String] // Which meals need this item

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: GroceryItem, rhs: GroceryItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Grocery Category
enum GroceryCategory: String, Codable, CaseIterable {
    case produce = "Produce"
    case protein = "Meat & Protein"
    case dairy = "Dairy & Eggs"
    case grains = "Grains & Bread"
    case pantry = "Pantry Staples"
    case frozen = "Frozen"
    case beverages = "Beverages"
    case condiments = "Condiments & Sauces"
    case snacks = "Snacks"
    case other = "Other"

    var icon: String {
        switch self {
        case .produce: return "leaf.fill"
        case .protein: return "fish.fill"
        case .dairy: return "cup.and.saucer.fill"
        case .grains: return "takeoutbag.and.cup.and.straw.fill"
        case .pantry: return "archivebox.fill"
        case .frozen: return "snowflake"
        case .beverages: return "waterbottle.fill"
        case .condiments: return "drop.fill"
        case .snacks: return "popcorn.fill"
        case .other: return "bag.fill"
        }
    }

    var color: Color {
        switch self {
        case .produce: return .green
        case .protein: return .red
        case .dairy: return .blue
        case .grains: return .orange
        case .pantry: return .brown
        case .frozen: return .cyan
        case .beverages: return .purple
        case .condiments: return .yellow
        case .snacks: return .pink
        case .other: return .gray
        }
    }
}

// MARK: - Grocery List
struct GroceryList: Codable, Identifiable {
    var id = UUID()
    let createdAt: Date
    let mealPlanId: String?
    var items: [GroceryItem]
    var totalEstimatedCost: Double

    var checkedCount: Int {
        items.filter { $0.isChecked }.count
    }

    var progress: Double {
        guard !items.isEmpty else { return 0 }
        return Double(checkedCount) / Double(items.count)
    }

    var itemsByCategory: [GroceryCategory: [GroceryItem]] {
        Dictionary(grouping: items, by: { $0.category })
    }
}

// MARK: - Grocery List Service
@MainActor
class GroceryListService: ObservableObject {
    static let shared = GroceryListService()

    @Published var currentList: GroceryList?
    @Published var savedLists: [GroceryList] = []

    private let userDefaults = UserDefaults.standard
    private let currentListKey = "current_grocery_list"
    private let savedListsKey = "saved_grocery_lists"

    // Ingredient database - maps meal/food names to their ingredients
    private let ingredientDatabase: [String: [(name: String, category: GroceryCategory, quantity: String, cost: Double)]] = [
        // Breakfast items
        "scrambled eggs": [
            ("Eggs (dozen)", .dairy, "1", 4.99),
            ("Butter", .dairy, "1", 4.49)
        ],
        "egg white omelette": [
            ("Eggs (dozen)", .dairy, "1", 4.99),
            ("Bell Peppers", .produce, "2", 2.99),
            ("Spinach", .produce, "1 bag", 3.49)
        ],
        "protein pancakes": [
            ("Protein Powder", .pantry, "1", 29.99),
            ("Oats", .grains, "1 container", 4.99),
            ("Eggs (dozen)", .dairy, "1", 4.99),
            ("Banana", .produce, "1 bunch", 1.49)
        ],
        "cottage cheese bowl": [
            ("Cottage Cheese", .dairy, "1 container", 4.99),
            ("Mixed Berries", .produce, "1 container", 5.99),
            ("Almonds", .snacks, "1 bag", 7.99)
        ],
        "bacon & eggs": [
            ("Bacon", .protein, "1 pack", 7.99),
            ("Eggs (dozen)", .dairy, "1", 4.99)
        ],
        "avocado eggs": [
            ("Avocados", .produce, "3", 4.99),
            ("Eggs (dozen)", .dairy, "1", 4.99)
        ],
        "smoked salmon plate": [
            ("Smoked Salmon", .protein, "1 pack", 12.99),
            ("Cream Cheese", .dairy, "1", 3.99),
            ("Capers", .condiments, "1 jar", 4.99)
        ],
        "greek yogurt parfait": [
            ("Greek Yogurt", .dairy, "1 large", 6.99),
            ("Granola", .grains, "1 bag", 5.99),
            ("Honey", .pantry, "1 bottle", 7.99),
            ("Mixed Berries", .produce, "1 container", 5.99)
        ],
        "overnight oats": [
            ("Oats", .grains, "1 container", 4.99),
            ("Milk", .dairy, "1 gallon", 4.49),
            ("Chia Seeds", .pantry, "1 bag", 8.99),
            ("Maple Syrup", .pantry, "1 bottle", 9.99)
        ],
        "tofu scramble": [
            ("Firm Tofu", .protein, "2 blocks", 5.98),
            ("Turmeric", .pantry, "1 jar", 4.99),
            ("Bell Peppers", .produce, "2", 2.99),
            ("Onion", .produce, "1", 0.99)
        ],

        // Lunch items
        "grilled chicken salad": [
            ("Chicken Breast", .protein, "1 lb", 8.99),
            ("Mixed Greens", .produce, "1 container", 4.99),
            ("Cherry Tomatoes", .produce, "1 pint", 3.99),
            ("Cucumber", .produce, "1", 1.29),
            ("Olive Oil", .pantry, "1 bottle", 9.99)
        ],
        "chicken & rice bowl": [
            ("Chicken Breast", .protein, "1 lb", 8.99),
            ("Rice", .grains, "1 bag", 4.99),
            ("Broccoli", .produce, "1 head", 2.49),
            ("Soy Sauce", .condiments, "1 bottle", 3.99)
        ],
        "turkey meatballs": [
            ("Ground Turkey", .protein, "1 lb", 6.99),
            ("Breadcrumbs", .grains, "1 container", 2.99),
            ("Eggs (dozen)", .dairy, "1", 4.99),
            ("Marinara Sauce", .condiments, "1 jar", 4.99)
        ],
        "mediterranean bowl": [
            ("Falafel (frozen)", .frozen, "1 box", 5.99),
            ("Hummus", .dairy, "1 container", 4.99),
            ("Pita Bread", .grains, "1 pack", 3.49),
            ("Cucumber", .produce, "1", 1.29),
            ("Tomatoes", .produce, "2", 2.49),
            ("Feta Cheese", .dairy, "1 container", 5.99)
        ],
        "cobb salad": [
            ("Chicken Breast", .protein, "1 lb", 8.99),
            ("Bacon", .protein, "1 pack", 7.99),
            ("Eggs (dozen)", .dairy, "1", 4.99),
            ("Avocados", .produce, "2", 3.49),
            ("Blue Cheese", .dairy, "1", 5.99),
            ("Romaine Lettuce", .produce, "1 head", 2.99)
        ],
        "buddha bowl": [
            ("Quinoa", .grains, "1 bag", 6.99),
            ("Chickpeas (canned)", .pantry, "2 cans", 3.98),
            ("Sweet Potato", .produce, "2", 2.99),
            ("Tahini", .condiments, "1 jar", 7.99),
            ("Kale", .produce, "1 bunch", 2.99)
        ],
        "black bean tacos": [
            ("Black Beans (canned)", .pantry, "2 cans", 2.98),
            ("Corn Tortillas", .grains, "1 pack", 3.49),
            ("Salsa", .condiments, "1 jar", 4.49),
            ("Avocados", .produce, "2", 3.49),
            ("Cilantro", .produce, "1 bunch", 0.99),
            ("Lime", .produce, "2", 0.98)
        ],

        // Dinner items
        "grilled ribeye steak": [
            ("Ribeye Steak", .protein, "2", 29.99),
            ("Garlic", .produce, "1 head", 0.79),
            ("Rosemary", .produce, "1 bunch", 2.99),
            ("Butter", .dairy, "1", 4.49)
        ],
        "baked salmon fillet": [
            ("Salmon Fillets", .protein, "1 lb", 14.99),
            ("Lemon", .produce, "2", 1.29),
            ("Dill", .produce, "1 bunch", 2.49),
            ("Olive Oil", .pantry, "1 bottle", 9.99)
        ],
        "grilled chicken thighs": [
            ("Chicken Thighs", .protein, "2 lbs", 9.99),
            ("Olive Oil", .pantry, "1 bottle", 9.99),
            ("Paprika", .pantry, "1 jar", 3.99),
            ("Garlic Powder", .pantry, "1 jar", 3.49)
        ],
        "shrimp stir-fry": [
            ("Shrimp", .protein, "1 lb", 12.99),
            ("Mixed Vegetables (frozen)", .frozen, "1 bag", 3.99),
            ("Soy Sauce", .condiments, "1 bottle", 3.99),
            ("Ginger", .produce, "1 piece", 1.49),
            ("Rice", .grains, "1 bag", 4.99)
        ],
        "pork chops": [
            ("Pork Chops", .protein, "4", 11.99),
            ("Apple Cider Vinegar", .pantry, "1 bottle", 4.99),
            ("Thyme", .produce, "1 bunch", 2.49)
        ],
        "chickpea curry": [
            ("Chickpeas (canned)", .pantry, "2 cans", 3.98),
            ("Coconut Milk", .pantry, "2 cans", 5.98),
            ("Curry Paste", .condiments, "1 jar", 5.99),
            ("Onion", .produce, "2", 1.98),
            ("Rice", .grains, "1 bag", 4.99)
        ],
        "tofu stir-fry": [
            ("Firm Tofu", .protein, "2 blocks", 5.98),
            ("Mixed Vegetables (frozen)", .frozen, "1 bag", 3.99),
            ("Soy Sauce", .condiments, "1 bottle", 3.99),
            ("Sesame Oil", .pantry, "1 bottle", 6.99),
            ("Rice", .grains, "1 bag", 4.99)
        ],

        // Snacks
        "protein shake": [
            ("Protein Powder", .pantry, "1", 29.99),
            ("Milk", .dairy, "1 gallon", 4.49),
            ("Banana", .produce, "1 bunch", 1.49)
        ],
        "greek yogurt cup": [
            ("Greek Yogurt", .dairy, "1 large", 6.99)
        ],
        "trail mix": [
            ("Trail Mix", .snacks, "1 bag", 7.99)
        ],
        "apple with peanut butter": [
            ("Apples", .produce, "4", 4.99),
            ("Peanut Butter", .pantry, "1 jar", 5.99)
        ],
        "hummus & veggies": [
            ("Hummus", .dairy, "1 container", 4.99),
            ("Carrots", .produce, "1 bag", 2.49),
            ("Celery", .produce, "1 bunch", 2.49)
        ],
        "hard boiled eggs": [
            ("Eggs (dozen)", .dairy, "1", 4.99)
        ],
        "mixed nuts": [
            ("Mixed Nuts", .snacks, "1 can", 9.99)
        ],

        // Sides
        "sweet potato": [
            ("Sweet Potatoes", .produce, "3", 3.99)
        ],
        "steamed asparagus": [
            ("Asparagus", .produce, "1 bunch", 4.99)
        ],
        "roasted brussels sprouts": [
            ("Brussels Sprouts", .produce, "1 lb", 4.49),
            ("Olive Oil", .pantry, "1 bottle", 9.99)
        ]
    ]

    private init() {
        loadData()
    }

    // MARK: - Generate List from Meal Plan
    func generateGroceryList(from mealPlan: WeeklyMealPlan) -> GroceryList {
        var ingredientMap: [String: GroceryItem] = [:]

        // Extract all foods from the meal plan
        for dailyPlan in mealPlan.dailyPlans {
            for meal in dailyPlan.meals {
                for food in meal.foods {
                    let foodName = food.name.lowercased()

                    // Look up ingredients for this food
                    if let ingredients = findIngredients(for: foodName) {
                        for ingredient in ingredients {
                            let key = ingredient.name.lowercased()

                            if var existingItem = ingredientMap[key] {
                                // Add the meal to the list of meals needing this item
                                if !existingItem.fromMeals.contains(food.name) {
                                    existingItem.fromMeals.append(food.name)
                                }
                                ingredientMap[key] = existingItem
                            } else {
                                let newItem = GroceryItem(
                                    name: ingredient.name,
                                    category: ingredient.category,
                                    quantity: ingredient.quantity,
                                    estimatedCost: ingredient.cost,
                                    isChecked: false,
                                    fromMeals: [food.name]
                                )
                                ingredientMap[key] = newItem
                            }
                        }
                    } else {
                        // If no specific ingredients found, add the food item itself
                        let category = categorizeFood(food.name)
                        let key = food.name.lowercased()

                        if ingredientMap[key] == nil {
                            ingredientMap[key] = GroceryItem(
                                name: food.name,
                                category: category,
                                quantity: "as needed",
                                estimatedCost: 5.00, // Default estimate
                                isChecked: false,
                                fromMeals: [food.name]
                            )
                        }
                    }
                }
            }
        }

        let items = Array(ingredientMap.values).sorted { $0.category.rawValue < $1.category.rawValue }
        let totalCost = items.reduce(0) { $0 + $1.estimatedCost }

        let groceryList = GroceryList(
            createdAt: Date(),
            mealPlanId: mealPlan.id,
            items: items,
            totalEstimatedCost: totalCost
        )

        currentList = groceryList
        saveData()

        return groceryList
    }

    // MARK: - Find Ingredients
    private func findIngredients(for foodName: String) -> [(name: String, category: GroceryCategory, quantity: String, cost: Double)]? {
        let normalizedName = foodName.lowercased()

        // Direct match
        if let ingredients = ingredientDatabase[normalizedName] {
            return ingredients
        }

        // Partial match
        for (key, ingredients) in ingredientDatabase {
            if normalizedName.contains(key) || key.contains(normalizedName) {
                return ingredients
            }
        }

        return nil
    }

    // MARK: - Categorize Food
    private func categorizeFood(_ name: String) -> GroceryCategory {
        let lowercased = name.lowercased()

        let categoryKeywords: [GroceryCategory: [String]] = [
            .produce: ["salad", "vegetable", "fruit", "apple", "banana", "tomato", "lettuce", "spinach", "avocado", "broccoli", "asparagus"],
            .protein: ["chicken", "beef", "pork", "fish", "salmon", "tuna", "shrimp", "turkey", "steak", "lamb", "tofu"],
            .dairy: ["yogurt", "cheese", "milk", "cream", "egg", "butter"],
            .grains: ["rice", "bread", "pasta", "oats", "quinoa", "tortilla", "pita"],
            .frozen: ["frozen", "ice cream"],
            .snacks: ["nuts", "trail mix", "chips", "crackers", "jerky"],
            .beverages: ["shake", "smoothie", "juice", "coffee", "tea"],
            .condiments: ["sauce", "dressing", "oil", "vinegar"]
        ]

        for (category, keywords) in categoryKeywords {
            for keyword in keywords {
                if lowercased.contains(keyword) {
                    return category
                }
            }
        }

        return .other
    }

    // MARK: - Toggle Item
    func toggleItem(_ item: GroceryItem) {
        guard var list = currentList,
              let index = list.items.firstIndex(where: { $0.id == item.id }) else { return }

        list.items[index].isChecked.toggle()
        currentList = list
        saveData()
    }

    // MARK: - Add Custom Item
    func addCustomItem(name: String, category: GroceryCategory, quantity: String, cost: Double) {
        guard var list = currentList else { return }

        let newItem = GroceryItem(
            name: name,
            category: category,
            quantity: quantity,
            estimatedCost: cost,
            isChecked: false,
            fromMeals: ["Custom"]
        )

        list.items.append(newItem)
        list.totalEstimatedCost += cost
        currentList = list
        saveData()
    }

    // MARK: - Remove Item
    func removeItem(_ item: GroceryItem) {
        guard var list = currentList else { return }

        list.items.removeAll { $0.id == item.id }
        list.totalEstimatedCost = list.items.reduce(0) { $0 + $1.estimatedCost }
        currentList = list
        saveData()
    }

    // MARK: - Clear Checked Items
    func clearCheckedItems() {
        guard var list = currentList else { return }

        list.items.removeAll { $0.isChecked }
        list.totalEstimatedCost = list.items.reduce(0) { $0 + $1.estimatedCost }
        currentList = list
        saveData()
    }

    // MARK: - Save Current List
    func saveCurrentList() {
        guard let list = currentList else { return }
        savedLists.insert(list, at: 0)

        // Keep only last 10 lists
        if savedLists.count > 10 {
            savedLists = Array(savedLists.prefix(10))
        }

        saveData()
    }

    // MARK: - Persistence
    private func saveData() {
        if let currentList = currentList,
           let encoded = try? JSONEncoder().encode(currentList) {
            userDefaults.set(encoded, forKey: currentListKey)
        }

        if let encoded = try? JSONEncoder().encode(savedLists) {
            userDefaults.set(encoded, forKey: savedListsKey)
        }
    }

    private func loadData() {
        if let data = userDefaults.data(forKey: currentListKey),
           let list = try? JSONDecoder().decode(GroceryList.self, from: data) {
            currentList = list
        }

        if let data = userDefaults.data(forKey: savedListsKey),
           let lists = try? JSONDecoder().decode([GroceryList].self, from: data) {
            savedLists = lists
        }
    }
}
