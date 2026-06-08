import UIKit
import MapKit

// MARK: - Root Tab Bar

final class ViewController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        tabBar.tintColor = DashStyle.red
        tabBar.unselectedItemTintColor = UIColor(white: 0.55, alpha: 1)
        viewControllers = [
            makeNav(root: HomeViewController(), title: "Home", icon: "house.fill", largeTitles: false),
            makeNav(root: BrowseViewController(), title: "Browse", icon: "magnifyingglass", largeTitles: false),
            makeNav(root: OrdersViewController(), title: "Orders", icon: "bag.fill", largeTitles: false),
            makeNav(root: AccountViewController(), title: "Account", icon: "person.fill", largeTitles: false),
        ]
    }

    private func makeNav(root: UIViewController, title: String, icon: String, largeTitles: Bool) -> UINavigationController {
        let nav = UINavigationController(rootViewController: root)
        nav.navigationBar.prefersLargeTitles = largeTitles
        nav.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: icon), tag: 0)
        return nav
    }
}

// MARK: - Models

struct DashCategory {
    let title: String
    let symbol: String
    let color: UIColor
}

struct MenuItem {
    let id: UUID
    let name: String
    let detail: String
    let price: Double
    let badge: String?

    /// Stable, lowercased, underscore-separated identifier derived from a
    /// menu item's display name. Used to build accessibility identifiers
    /// like `menu_item_<slug>` so the MCP tooling can tap specific items.
    /// Any non-alphanumeric character becomes an underscore; consecutive
    /// underscores collapse; leading/trailing underscores are trimmed.
    static func slug(from name: String) -> String {
        let lowered = name.lowercased()
        var out = ""
        var lastWasUnderscore = false
        for scalar in lowered.unicodeScalars {
            if CharacterSet.alphanumerics.contains(scalar) {
                out.append(Character(scalar))
                lastWasUnderscore = false
            } else if !lastWasUnderscore {
                out.append("_")
                lastWasUnderscore = true
            }
        }
        while out.hasPrefix("_") { out.removeFirst() }
        while out.hasSuffix("_") { out.removeLast() }
        return out
    }

    var slug: String { MenuItem.slug(from: name) }
}

struct MenuSection {
    let title: String
    let items: [MenuItem]
}

enum OrderType {
    case delivery
    case pickup
}

struct Restaurant {
    let id: UUID
    let name: String
    let cuisine: String
    let rating: Double
    let ratingCount: Int
    let deliveryFee: String
    let eta: String
    let distanceMiles: Double
    let heroColor: UIColor
    let imageName: String
    let tags: [String]
    let menu: [MenuSection]
    var pickupAvailable: Bool = true
    var pickupEta: String = "15-25 min"

    var averagePrice: Double {
        let items = menu.flatMap { $0.items }
        guard !items.isEmpty else { return 0 }
        let total = items.reduce(0.0) { $0 + $1.price }
        return total / Double(items.count)
    }

    var coordinate: CLLocationCoordinate2D {
        switch name {
        case "Whole Foods Market":
            return CLLocationCoordinate2D(latitude: 37.7748, longitude: -122.4312)
        case "Chipotle Mexican Grill":
            return CLLocationCoordinate2D(latitude: 37.7595, longitude: -122.4216)
        case "Domino's":
            return CLLocationCoordinate2D(latitude: 37.7867, longitude: -122.4085)
        case "Pizza Hut":
            return CLLocationCoordinate2D(latitude: 37.7829, longitude: -122.4122)
        case "Sweetgreen":
            return CLLocationCoordinate2D(latitude: 37.7726, longitude: -122.4168)
        case "Chick-fil-A":
            return CLLocationCoordinate2D(latitude: 37.7894, longitude: -122.4107)
        case "Sugarfish":
            return CLLocationCoordinate2D(latitude: 37.7814, longitude: -122.4047)
        case "Nobu":
            return CLLocationCoordinate2D(latitude: 37.7761, longitude: -122.4179)
        case "Five Guys":
            return CLLocationCoordinate2D(latitude: 37.7738, longitude: -122.4199)
        case "Shake Shack":
            return CLLocationCoordinate2D(latitude: 37.7842, longitude: -122.4064)
        case "Levain Bakery":
            return CLLocationCoordinate2D(latitude: 37.7876, longitude: -122.3998)
        case "Starbucks":
            return CLLocationCoordinate2D(latitude: 37.7796, longitude: -122.4141)
        case "Jamba":
            return CLLocationCoordinate2D(latitude: 37.7819, longitude: -122.4113)
        case "Kung Fu Tea":
            return CLLocationCoordinate2D(latitude: 37.7718, longitude: -122.4238)
        case "Jersey Mike's Subs":
            return CLLocationCoordinate2D(latitude: 37.7685, longitude: -122.4293)
        case "Panera Bread":
            return CLLocationCoordinate2D(latitude: 37.7828, longitude: -122.4134)
        case "CAVA":
            return CLLocationCoordinate2D(latitude: 37.7922, longitude: -122.3941)
        case "DashMart":
            return CLLocationCoordinate2D(latitude: 37.7811, longitude: -122.4119)
        case "Total Wine & More":
            return CLLocationCoordinate2D(latitude: 37.7651, longitude: -122.4326)
        case "The Bouqs Co.":
            return CLLocationCoordinate2D(latitude: 37.7692, longitude: -122.4266)
        case "CVS Pharmacy":
            return CLLocationCoordinate2D(latitude: 37.7856, longitude: -122.4056)
        case "PetSmart":
            return CLLocationCoordinate2D(latitude: 37.7703, longitude: -122.4472)
        case "Dick's Sporting Goods":
            return CLLocationCoordinate2D(latitude: 37.7674, longitude: -122.4551)
        case "Taco Bell":
            return CLLocationCoordinate2D(latitude: 37.7752, longitude: -122.4185)
        case "Wingstop":
            return CLLocationCoordinate2D(latitude: 37.7631, longitude: -122.4345)
        case "Popeyes":
            return CLLocationCoordinate2D(latitude: 37.7803, longitude: -122.4102)
        case "Peet's Coffee":
            return CLLocationCoordinate2D(latitude: 37.7888, longitude: -122.4012)
        case "McDonald's":
            return CLLocationCoordinate2D(latitude: 37.7837, longitude: -122.4092)
        case "Subway":
            return CLLocationCoordinate2D(latitude: 37.7862, longitude: -122.4032)
        case "Panda Express":
            return CLLocationCoordinate2D(latitude: 37.7779, longitude: -122.4155)
        case "Crumbl Cookies":
            return CLLocationCoordinate2D(latitude: 37.7712, longitude: -122.4275)
        case "La Taqueria":
            return CLLocationCoordinate2D(latitude: 37.7508, longitude: -122.4180)
        case "Souvla":
            return CLLocationCoordinate2D(latitude: 37.7764, longitude: -122.4230)
        case "Z & Y Restaurant":
            return CLLocationCoordinate2D(latitude: 37.7943, longitude: -122.4063)
        case "Dumpling Home":
            return CLLocationCoordinate2D(latitude: 37.7826, longitude: -122.3998)
        case "Marufuku Ramen":
            return CLLocationCoordinate2D(latitude: 37.7853, longitude: -122.4296)
        case "Burma Superstar":
            return CLLocationCoordinate2D(latitude: 37.7831, longitude: -122.4627)
        case "Tony's Pizza Napoletana":
            return CLLocationCoordinate2D(latitude: 37.8003, longitude: -122.4089)
        case "Hog Island Oyster Co.":
            return CLLocationCoordinate2D(latitude: 37.7955, longitude: -122.3934)
        case "Nari":
            return CLLocationCoordinate2D(latitude: 37.7852, longitude: -122.4310)
        case "Flour + Water":
            return CLLocationCoordinate2D(latitude: 37.7600, longitude: -122.4149)
        case "Sightglass Coffee":
            return CLLocationCoordinate2D(latitude: 37.7725, longitude: -122.4118)
        case "Tartine Manufactory":
            return CLLocationCoordinate2D(latitude: 37.7614, longitude: -122.4117)
        case "El Farolito":
            return CLLocationCoordinate2D(latitude: 37.7522, longitude: -122.4181)
        case "San Tung":
            return CLLocationCoordinate2D(latitude: 37.7636, longitude: -122.4686)
        case "Zuni Cafe":
            return CLLocationCoordinate2D(latitude: 37.7757, longitude: -122.4215)
        case "Nopalito":
            return CLLocationCoordinate2D(latitude: 37.7742, longitude: -122.4372)
        case "Kin Khao":
            return CLLocationCoordinate2D(latitude: 37.7868, longitude: -122.4078)
        case "State Bird Provisions":
            return CLLocationCoordinate2D(latitude: 37.7871, longitude: -122.4367)
        case "Trader Joe's":
            return CLLocationCoordinate2D(latitude: 37.7640, longitude: -122.4318)
        case "Safeway":
            return CLLocationCoordinate2D(latitude: 37.7645, longitude: -122.4265)
        case "Target":
            return CLLocationCoordinate2D(latitude: 37.7693, longitude: -122.4504)
        case "Tropical Smoothie Cafe":
            return CLLocationCoordinate2D(latitude: 37.7745, longitude: -122.4195)
        case "BevMo!":
            return CLLocationCoordinate2D(latitude: 37.7668, longitude: -122.4508)
        case "Walgreens":
            return CLLocationCoordinate2D(latitude: 37.7835, longitude: -122.4090)
        case "Curry Up Now":
            return CLLocationCoordinate2D(latitude: 37.7728, longitude: -122.4162)
        case "Pho Tai":
            return CLLocationCoordinate2D(latitude: 37.7818, longitude: -122.4135)
        case "In-N-Out Burger":
            return CLLocationCoordinate2D(latitude: 37.8069, longitude: -122.4185)
        case "Philz Coffee":
            return CLLocationCoordinate2D(latitude: 37.7646, longitude: -122.4222)
        case "KBBQ To Go":
            return CLLocationCoordinate2D(latitude: 37.7832, longitude: -122.4295)
        case "Mendocino Farms":
            return CLLocationCoordinate2D(latitude: 37.7895, longitude: -122.3985)
        case "Pokeworks":
            return CLLocationCoordinate2D(latitude: 37.7872, longitude: -122.3971)
        case "Yank Sing":
            return CLLocationCoordinate2D(latitude: 37.7862, longitude: -122.3928)
        case "Brenda's French Soul Food":
            return CLLocationCoordinate2D(latitude: 37.7819, longitude: -122.4134)
        case "4505 Burgers & BBQ":
            return CLLocationCoordinate2D(latitude: 37.7696, longitude: -122.4135)
        case "Oren's Hummus":
            return CLLocationCoordinate2D(latitude: 37.7847, longitude: -122.4068)
        case "Super Duper Burgers":
            return CLLocationCoordinate2D(latitude: 37.7892, longitude: -122.4003)
        case "Rooster & Rice":
            return CLLocationCoordinate2D(latitude: 37.7854, longitude: -122.4095)
        case "Che Fico":
            return CLLocationCoordinate2D(latitude: 37.7743, longitude: -122.4213)
        case "Delfina":
            return CLLocationCoordinate2D(latitude: 37.7612, longitude: -122.4245)
        case "Señor Sisig":
            return CLLocationCoordinate2D(latitude: 37.7649, longitude: -122.4188)
        case "Kitava":
            return CLLocationCoordinate2D(latitude: 37.7621, longitude: -122.4218)
        case "Boudin Bakery":
            return CLLocationCoordinate2D(latitude: 37.8083, longitude: -122.4157)
        case "Rich Table":
            return CLLocationCoordinate2D(latitude: 37.7763, longitude: -122.4225)
        case "Mama":
            return CLLocationCoordinate2D(latitude: 37.7989, longitude: -122.4368)
        case "Mister Jiu's":
            return CLLocationCoordinate2D(latitude: 37.7946, longitude: -122.4068)
        case "Lazy Bear":
            return CLLocationCoordinate2D(latitude: 37.7615, longitude: -122.4218)
        case "Swan Oyster Depot":
            return CLLocationCoordinate2D(latitude: 37.7906, longitude: -122.4218)
        case "Commis":
            return CLLocationCoordinate2D(latitude: 37.8305, longitude: -122.2598)
        case "Chez Panisse":
            return CLLocationCoordinate2D(latitude: 37.8796, longitude: -122.2685)
        case "Cholita Linda":
            return CLLocationCoordinate2D(latitude: 37.8305, longitude: -122.2605)
        case "Ippuku":
            return CLLocationCoordinate2D(latitude: 37.8700, longitude: -122.2680)
        default:
            return CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        }
    }

    var heroSymbolName: String {
        switch cuisine {
        case "Grocery":
            return "cart.fill"
        case "Mexican":
            return "flame.fill"
        case "Pizza":
            return "takeoutbag.and.cup.and.straw.fill"
        case "Healthy":
            return "leaf.fill"
        case "Japanese":
            return "fish.fill"
        case "Burgers":
            return "fork.knife.circle.fill"
        case "Drinks":
            return "cup.and.saucer.fill"
        case "Deli":
            return "bag.fill"
        case "Chicken":
            return "takeoutbag.and.cup.and.straw"
        case "Bakery":
            return "birthday.cake.fill"
        case "Salads":
            return "leaf.circle.fill"
        case "Coffee":
            return "cup.and.saucer.fill"
        case "Convenience":
            return "bag.circle.fill"
        case "Bottle Shop":
            return "wineglass.fill"
        case "Florist":
            return "gift.fill"
        case "Pharmacy":
            return "cross.case.fill"
        case "Pets":
            return "pawprint.fill"
        case "Sporting Goods":
            return "figure.run.circle.fill"
        case "Chinese":
            return "flame.fill"
        case "Greek":
            return "leaf.circle.fill"
        case "Burmese":
            return "flame.fill"
        case "Seafood":
            return "fish.fill"
        case "Thai":
            return "flame.fill"
        case "Italian":
            return "fork.knife"
        case "Indian":
            return "flame.fill"
        case "Vietnamese":
            return "leaf.fill"
        case "Korean":
            return "flame.fill"
        case "American":
            return "fork.knife.circle.fill"
        case "Retail":
            return "bag.fill"
        case "Hawaiian":
            return "fish.fill"
        case "Southern":
            return "fork.knife.circle.fill"
        case "BBQ":
            return "flame.fill"
        case "Mediterranean":
            return "leaf.circle.fill"
        case "Filipino":
            return "flame.fill"
        case "Caribbean":
            return "flame.fill"
        default:
            return "storefront.fill"
        }
    }

    var heroArtwork: UIImage? {
        UIImage(named: imageName) ?? UIImage(systemName: heroSymbolName)
    }

    var usesHeroAsset: Bool {
        UIImage(named: imageName) != nil
    }
}

struct Address {
    let id: UUID
    let label: String
    let detail: String

    var coordinate: CLLocationCoordinate2D {
        switch label {
        case "Home":
            return CLLocationCoordinate2D(latitude: 37.7766, longitude: -122.4241)
        case "Office":
            return CLLocationCoordinate2D(latitude: 37.7899, longitude: -122.4013)
        case "Studio":
            return CLLocationCoordinate2D(latitude: 37.7875, longitude: -122.4008)
        case "Friend":
            return CLLocationCoordinate2D(latitude: 37.7654, longitude: -122.4213)
        default:
            return CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        }
    }
}

enum PaymentAccountType: String, Codable {
    case checking
    case savings
    case credit
}

struct PaymentAccount: Codable {
    let id: UUID
    let name: String
    let type: PaymentAccountType
    let balance: Double
    let availableBalance: Double
    let currency: String
    let lastUpdated: Date
    let creditLimit: Double?

    var maskedNumber: String {
        switch type {
        case .checking: return "**** **** **** 6645"
        case .savings: return "**** **** **** 7814"
        case .credit: return "**** **** **** 2095"
        }
    }

    var network: String {
        switch type {
        case .credit: return "VISA"
        case .checking: return "VISA DEBIT"
        case .savings: return "MASTERCARD DEBIT"
        }
    }

    var displayName: String {
        "\(name) • \(maskedNumber)"
    }

    var availableForSpending: Double {
        availableBalance
    }
}

struct OrderTotals {
    let subtotal: Double
    let deliveryFee: Double
    let serviceFee: Double
    let tax: Double
    let tip: Double

    var total: Double {
        subtotal + deliveryFee + serviceFee + tax + tip
    }
}

struct CartItem {
    var item: MenuItem
    var quantity: Int
    let restaurantID: UUID
}

struct MenuItemAppearance {
    let symbol: String
    let tint: UIColor

    static func lookup(name: String, detail: String) -> MenuItemAppearance {
        let haystack = (name + " " + detail).lowercased()
        let rules: [(keywords: [String], symbol: String, tint: UIColor)] = [
            (["coffee", "espresso", "latte", "cappuccino", "macchiato", "mocha", "cortado", "americano", "cold brew"], "cup.and.saucer.fill", UIColor(red: 0.45, green: 0.27, blue: 0.18, alpha: 1)),
            (["tea", "matcha", "chai"], "leaf.fill", UIColor(red: 0.30, green: 0.55, blue: 0.32, alpha: 1)),
            (["smoothie", "milkshake", "shake", "frappe", "boba", "bubble tea"], "takeoutbag.and.cup.and.straw.fill", UIColor(red: 0.85, green: 0.40, blue: 0.55, alpha: 1)),
            (["soda", "cola", "pop", "sparkling", "seltzer", "fanta", "sprite"], "bubbles.and.sparkles.fill", UIColor(red: 0.55, green: 0.20, blue: 0.25, alpha: 1)),
            (["juice", "lemonade", "limeade", "agua fresca"], "drop.fill", UIColor(red: 0.95, green: 0.70, blue: 0.20, alpha: 1)),
            (["water", "bottle"], "drop.fill", UIColor(red: 0.30, green: 0.55, blue: 0.85, alpha: 1)),
            (["beer", "lager", "ipa", "ale", "stout"], "mug.fill", UIColor(red: 0.85, green: 0.65, blue: 0.20, alpha: 1)),
            (["wine", "champagne", "rosé", "sparkling wine"], "wineglass.fill", UIColor(red: 0.55, green: 0.10, blue: 0.20, alpha: 1)),
            (["cocktail", "martini", "margarita", "mojito", "old fashioned", "negroni"], "wineglass.fill", UIColor(red: 0.65, green: 0.30, blue: 0.65, alpha: 1)),

            (["pizza", "calzone", "stromboli", "flatbread"], "circle.grid.cross.fill", UIColor(red: 0.85, green: 0.30, blue: 0.20, alpha: 1)),
            (["burger", "cheeseburger", "patty", "smash"], "takeoutbag.and.cup.and.straw.fill", UIColor(red: 0.75, green: 0.45, blue: 0.20, alpha: 1)),
            (["sandwich", "hoagie", "sub", "panini", "club", "blt", "wrap", "burrito", "quesadilla", "taco", "tostada", "torta", "bao"], "rectangle.stack.fill", UIColor(red: 0.85, green: 0.55, blue: 0.30, alpha: 1)),
            (["chicken", "wings", "tenders", "drumstick", "poultry", "turkey"], "bird.fill", UIColor(red: 0.80, green: 0.55, blue: 0.20, alpha: 1)),
            (["beef", "steak", "ribeye", "sirloin", "filet", "brisket", "ribs", "rib eye"], "flame.fill", UIColor(red: 0.65, green: 0.20, blue: 0.20, alpha: 1)),
            (["bacon", "pork", "ham", "sausage", "chorizo", "salami", "pepperoni", "carnitas"], "flame.fill", UIColor(red: 0.80, green: 0.30, blue: 0.30, alpha: 1)),
            (["fish", "salmon", "tuna", "cod", "trout", "halibut", "ahi", "branzino"], "fish.fill", UIColor(red: 0.40, green: 0.55, blue: 0.75, alpha: 1)),
            (["sushi", "sashimi", "nigiri", "maki", "roll", "poke", "onigiri"], "fish.fill", UIColor(red: 0.55, green: 0.30, blue: 0.50, alpha: 1)),
            (["shrimp", "lobster", "crab", "prawn", "oyster", "scallop", "clam", "calamari"], "fish.fill", UIColor(red: 0.85, green: 0.50, blue: 0.40, alpha: 1)),

            (["salad", "greens", "kale", "spinach", "arugula", "romaine"], "leaf.fill", UIColor(red: 0.35, green: 0.65, blue: 0.35, alpha: 1)),
            (["bowl", "buddha", "grain", "rice bowl", "quinoa", "poke bowl"], "circle.fill", UIColor(red: 0.45, green: 0.55, blue: 0.30, alpha: 1)),
            (["soup", "broth", "ramen", "pho", "udon", "bisque", "chowder", "stew", "miso"], "cup.and.saucer.fill", UIColor(red: 0.70, green: 0.40, blue: 0.20, alpha: 1)),
            (["pasta", "spaghetti", "linguine", "fettuccine", "lasagna", "ravioli", "gnocchi", "carbonara", "bolognese", "alfredo"], "tornado", UIColor(red: 0.85, green: 0.55, blue: 0.20, alpha: 1)),
            (["fries", "chips", "wedges", "tater", "potato"], "rectangle.fill", UIColor(red: 0.90, green: 0.70, blue: 0.30, alpha: 1)),
            (["egg", "omelet", "frittata", "benedict", "scramble", "quiche"], "circle.fill", UIColor(red: 0.95, green: 0.80, blue: 0.30, alpha: 1)),
            (["cheese", "burrata", "mozzarella", "feta", "parmesan", "gouda", "brie"], "square.fill", UIColor(red: 0.95, green: 0.85, blue: 0.45, alpha: 1)),

            (["bread", "loaf", "baguette", "sourdough", "ciabatta", "focaccia", "naan", "pita", "tortilla"], "rectangle.fill", UIColor(red: 0.80, green: 0.60, blue: 0.35, alpha: 1)),
            (["bagel", "english muffin"], "circle.circle.fill", UIColor(red: 0.75, green: 0.55, blue: 0.25, alpha: 1)),
            (["croissant", "danish", "pastry", "scone", "muffin", "biscuit"], "leaf.arrow.triangle.circlepath", UIColor(red: 0.85, green: 0.65, blue: 0.30, alpha: 1)),

            (["cake", "cupcake", "tart", "pie", "cheesecake", "tiramisu", "éclair", "macaron", "donut", "doughnut"], "birthday.cake.fill", UIColor(red: 0.90, green: 0.50, blue: 0.65, alpha: 1)),
            (["cookie", "brownie", "blondie", "biscotti"], "circle.dashed", UIColor(red: 0.65, green: 0.40, blue: 0.20, alpha: 1)),
            (["ice cream", "gelato", "sorbet", "frozen yogurt", "froyo"], "snowflake", UIColor(red: 0.75, green: 0.85, blue: 0.95, alpha: 1)),
            (["chocolate", "truffle", "fudge", "ganache"], "square.fill", UIColor(red: 0.40, green: 0.20, blue: 0.10, alpha: 1)),
            (["candy", "lollipop", "gummi", "gummy", "caramel"], "sparkles", UIColor(red: 0.90, green: 0.30, blue: 0.50, alpha: 1)),

            (["apple", "pear", "banana", "berry", "berries", "strawberry", "raspberry", "blueberry", "blackberry", "grape", "melon", "watermelon", "pineapple", "mango", "kiwi", "peach", "plum", "cherry", "orange", "tangerine", "fruit"], "apple.logo", UIColor(red: 0.85, green: 0.30, blue: 0.30, alpha: 1)),
            (["avocado", "guacamole"], "leaf.fill", UIColor(red: 0.40, green: 0.65, blue: 0.30, alpha: 1)),
            (["broccoli", "cauliflower", "carrot", "onion", "tomato", "pepper", "cucumber", "zucchini", "eggplant", "mushroom", "vegetable", "veggie", "asparagus", "celery"], "leaf.fill", UIColor(red: 0.50, green: 0.70, blue: 0.30, alpha: 1)),

            (["sauce", "dressing", "dip", "salsa", "aioli", "tahini", "hummus", "tzatziki", "ketchup", "mustard"], "drop.fill", UIColor(red: 0.85, green: 0.45, blue: 0.30, alpha: 1)),
            (["spice", "seasoning", "pepper", "salt", "herb", "oregano", "basil", "thyme"], "leaf.fill", UIColor(red: 0.55, green: 0.45, blue: 0.30, alpha: 1)),
            (["cereal", "granola", "oats", "oatmeal", "porridge"], "circle.grid.3x3.fill", UIColor(red: 0.80, green: 0.65, blue: 0.40, alpha: 1)),
            (["nut", "almond", "cashew", "peanut", "pecan", "pistachio", "walnut"], "leaf.circle.fill", UIColor(red: 0.65, green: 0.45, blue: 0.25, alpha: 1)),

            (["yogurt", "milk", "cream", "kefir"], "drop.fill", UIColor(red: 0.85, green: 0.85, blue: 0.95, alpha: 1)),
            (["honey", "syrup", "jam", "jelly", "preserves"], "drop.degreesign.fill", UIColor(red: 0.90, green: 0.70, blue: 0.20, alpha: 1)),
            (["pet", "dog", "cat", "kibble", "treat"], "pawprint.fill", UIColor(red: 0.55, green: 0.45, blue: 0.30, alpha: 1)),

            (["paper towel", "napkin", "tissue", "toilet paper"], "doc.fill", UIColor(red: 0.60, green: 0.65, blue: 0.70, alpha: 1)),
            (["soap", "detergent", "cleaner", "wipe", "sponge", "trash bag"], "sparkles", UIColor(red: 0.45, green: 0.65, blue: 0.85, alpha: 1)),
        ]
        for rule in rules {
            for kw in rule.keywords {
                if haystack.contains(kw) {
                    return MenuItemAppearance(symbol: rule.symbol, tint: rule.tint)
                }
            }
        }
        return MenuItemAppearance(symbol: "fork.knife", tint: UIColor(white: 0.55, alpha: 1))
    }
}

struct ActiveOrder {
    let id: UUID
    let restaurant: Restaurant
    let items: [CartItem]
    let startDate: Date
    let etaMinutes: Int
    let distanceMiles: Double
    let scheduledFor: Date?
    var statusIndex: Int
    let orderType: OrderType
    let destinationAddress: Address
}

enum RestaurantSortOption: CaseIterable {
    case featured
    case priceLowHigh
    case priceHighLow
    case distanceLowHigh
    case distanceHighLow
    case ratingHighLow

    var title: String {
        switch self {
        case .featured:
            return "Featured"
        case .priceLowHigh:
            return "Price: Low to High"
        case .priceHighLow:
            return "Price: High to Low"
        case .distanceLowHigh:
            return "Distance: Nearest"
        case .distanceHighLow:
            return "Distance: Farthest"
        case .ratingHighLow:
            return "Rating: High to Low"
        }
    }
}

func sortRestaurants(_ restaurants: [Restaurant], by option: RestaurantSortOption) -> [Restaurant] {
    switch option {
    case .featured:
        return restaurants
    case .priceLowHigh:
        return restaurants.sorted { $0.averagePrice < $1.averagePrice }
    case .priceHighLow:
        return restaurants.sorted { $0.averagePrice > $1.averagePrice }
    case .distanceLowHigh:
        return restaurants.sorted { $0.distanceMiles < $1.distanceMiles }
    case .distanceHighLow:
        return restaurants.sorted { $0.distanceMiles > $1.distanceMiles }
    case .ratingHighLow:
        return restaurants.sorted {
            if $0.rating == $1.rating {
                return $0.ratingCount > $1.ratingCount
            }
            return $0.rating > $1.rating
        }
    }
}

private func configureHeroImageView(_ imageView: UIImageView, with restaurant: Restaurant, symbolPointSize: CGFloat) {
    imageView.backgroundColor = restaurant.heroColor
    imageView.image = restaurant.heroArtwork?.withRenderingMode(restaurant.usesHeroAsset ? .alwaysOriginal : .alwaysTemplate)
    imageView.tintColor = restaurant.usesHeroAsset ? nil : .white
    imageView.contentMode = restaurant.usesHeroAsset ? .scaleAspectFill : .center
    imageView.preferredSymbolConfiguration = restaurant.usesHeroAsset ? nil : UIImage.SymbolConfiguration(pointSize: symbolPointSize, weight: .semibold)
}

// MARK: - Store

extension Notification.Name {
    static let dashStoreDidChange = Notification.Name("DashStoreDidChange")
}

enum OrderPlacementError: LocalizedError {
    case emptyCart
    case missingPaymentMethod
    case insufficientFunds(required: Double, available: Double)

    var errorDescription: String? {
        switch self {
        case .emptyCart:
            return "Your cart is empty."
        case .missingPaymentMethod:
            return "Select a payment method to place this order."
        case .insufficientFunds(let required, let available):
            return String(format: "Insufficient funds. Total: $%.2f, Available: $%.2f", required, available)
        }
    }
}

final class MyBankAccountsService {
    private let appGroupID = "group.com.iosworld.benchmark.personalsuite"
    private let fileName = "mybank_accounts.json"

    private var accountsURL: URL {
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return appGroupURL.appendingPathComponent(fileName)
        }
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent(fileName)
    }

    func loadAccounts() -> [PaymentAccount] {
        guard let data = try? Data(contentsOf: accountsURL) else {
            return defaultAccounts()
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([PaymentAccount].self, from: data), !decoded.isEmpty {
            return decoded
        }
        return defaultAccounts()
    }

    private func defaultAccounts() -> [PaymentAccount] {
        let now = Date()
        return [
            PaymentAccount(
                id: UUID(),
                name: "Total Checking (...6645)",
                type: .checking,
                balance: 2150.32,
                availableBalance: 2150.32,
                currency: "USD",
                lastUpdated: now,
                creditLimit: nil
            ),
            PaymentAccount(
                id: UUID(),
                name: "Savings (...1032)",
                type: .savings,
                balance: 10250.00,
                availableBalance: 10250.00,
                currency: "USD",
                lastUpdated: now,
                creditLimit: nil
            ),
            PaymentAccount(
                id: UUID(),
                name: "Freedom Unlimited (...2095)",
                type: .credit,
                balance: 430.55,
                availableBalance: 1569.45,
                currency: "USD",
                lastUpdated: now,
                creditLimit: 2000.00
            )
        ]
    }
}

final class DashStore {
    static let shared = DashStore()

    let categories: [DashCategory]
    let browseCategories: [DashCategory]
    var restaurants: [Restaurant]
    private(set) var addresses: [Address]

    private(set) var selectedAddressID: UUID
    private(set) var cartItems: [CartItem] = []
    private(set) var scheduledDelivery: Date?
    private(set) var activeOrder: ActiveOrder?
    private(set) var pastOrders: [ActiveOrder] = []
    private let cartPersistenceKey = "doordash_cart_v1"

    private struct PersistedCartEntry: Codable {
        let itemID: UUID
        let restaurantID: UUID
        let quantity: Int
    }
    private(set) var selectedTipIndex: Int = 2
    func setTipIndex(_ index: Int) { selectedTipIndex = index; notify() }

    private(set) var profileName: String = "Jordan A."
    private(set) var profileEmail: String = "jordan.avery@email.com"
    func updateProfile(name: String?, email: String?) {
        if let name = name, !name.isEmpty { profileName = name }
        if let email = email, !email.isEmpty { profileEmail = email }
        notify()
    }

    private(set) var selectedOrderType: OrderType = .delivery
    private(set) var paymentAccounts: [PaymentAccount] = []
    private(set) var selectedPaymentAccountId: UUID?
    private let autoCompleteInterval: TimeInterval = 10 * 60
    private var autoCompleteWorkItem: DispatchWorkItem?
    private let accountsService = MyBankAccountsService()

    private init() {
        categories = [
            DashCategory(title: "Pizza", symbol: "flame", color: UIColor(red: 0.97, green: 0.80, blue: 0.36, alpha: 1)),
            DashCategory(title: "Burrito", symbol: "tortilla", color: UIColor(red: 0.95, green: 0.73, blue: 0.57, alpha: 1)),
            DashCategory(title: "Bowls", symbol: "leaf", color: UIColor(red: 0.70, green: 0.88, blue: 0.64, alpha: 1)),
            DashCategory(title: "Bakery", symbol: "birthday.cake", color: UIColor(red: 0.98, green: 0.76, blue: 0.81, alpha: 1)),
            DashCategory(title: "Smoothie", symbol: "drop", color: UIColor(red: 0.83, green: 0.93, blue: 0.99, alpha: 1)),
            DashCategory(title: "Chicken", symbol: "fork.knife", color: UIColor(red: 0.96, green: 0.78, blue: 0.68, alpha: 1)),
            DashCategory(title: "Sushi", symbol: "fish", color: UIColor(red: 0.70, green: 0.82, blue: 0.98, alpha: 1)),
            DashCategory(title: "Burgers", symbol: "circle", color: UIColor(red: 0.95, green: 0.84, blue: 0.55, alpha: 1)),
            DashCategory(title: "Salads", symbol: "leaf", color: UIColor(red: 0.78, green: 0.92, blue: 0.70, alpha: 1)),
            DashCategory(title: "Coffee", symbol: "cup.and.saucer", color: UIColor(red: 0.91, green: 0.86, blue: 0.78, alpha: 1)),
            DashCategory(title: "Desserts", symbol: "birthday.cake", color: UIColor(red: 0.99, green: 0.79, blue: 0.84, alpha: 1)),
            DashCategory(title: "Sandwiches", symbol: "fork.knife", color: UIColor(red: 0.95, green: 0.88, blue: 0.72, alpha: 1))
        ]

        browseCategories = [
            DashCategory(title: "Grocery", symbol: "cart", color: UIColor(red: 0.98, green: 0.76, blue: 0.40, alpha: 1)),
            DashCategory(title: "Convenience", symbol: "bag", color: UIColor(red: 0.92, green: 0.85, blue: 0.66, alpha: 1)),
            DashCategory(title: "Alcohol", symbol: "wineglass", color: UIColor(red: 0.86, green: 0.70, blue: 0.95, alpha: 1)),
            DashCategory(title: "Offers", symbol: "tag", color: UIColor(red: 0.98, green: 0.68, blue: 0.68, alpha: 1)),
            DashCategory(title: "Bakery", symbol: "birthday.cake", color: UIColor(red: 0.98, green: 0.76, blue: 0.81, alpha: 1)),
            DashCategory(title: "Deli", symbol: "fork.knife", color: UIColor(red: 0.95, green: 0.83, blue: 0.62, alpha: 1)),
            DashCategory(title: "Premium", symbol: "star", color: UIColor(red: 0.98, green: 0.84, blue: 0.42, alpha: 1)),
            DashCategory(title: "Pets", symbol: "pawprint", color: UIColor(red: 0.83, green: 0.90, blue: 0.98, alpha: 1)),
            DashCategory(title: "Snacks", symbol: "cup.and.saucer", color: UIColor(red: 0.92, green: 0.84, blue: 0.75, alpha: 1)),
            DashCategory(title: "Beauty", symbol: "sparkles", color: UIColor(red: 0.92, green: 0.76, blue: 0.97, alpha: 1)),
            DashCategory(title: "Packages", symbol: "shippingbox", color: UIColor(red: 0.90, green: 0.86, blue: 0.78, alpha: 1)),
            DashCategory(title: "Drinks", symbol: "drop", color: UIColor(red: 0.80, green: 0.90, blue: 0.98, alpha: 1)),
            DashCategory(title: "Desserts", symbol: "birthday.cake", color: UIColor(red: 0.98, green: 0.73, blue: 0.83, alpha: 1)),
            DashCategory(title: "Pantry", symbol: "tray", color: UIColor(red: 0.96, green: 0.88, blue: 0.66, alpha: 1)),
            DashCategory(title: "Flowers", symbol: "leaf", color: UIColor(red: 0.79, green: 0.93, blue: 0.74, alpha: 1)),
            DashCategory(title: "Gifts", symbol: "gift", color: UIColor(red: 0.96, green: 0.80, blue: 0.86, alpha: 1)),
            DashCategory(title: "DashMart", symbol: "cart.fill", color: UIColor(red: 0.98, green: 0.70, blue: 0.40, alpha: 1)),
            DashCategory(title: "Drugstore", symbol: "pill", color: UIColor(red: 0.80, green: 0.92, blue: 0.94, alpha: 1)),
            DashCategory(title: "Baby & Toys", symbol: "teddybear", color: UIColor(red: 0.90, green: 0.86, blue: 0.98, alpha: 1)),
            DashCategory(title: "Frozen", symbol: "snow", color: UIColor(red: 0.78, green: 0.88, blue: 0.99, alpha: 1)),
            DashCategory(title: "Electronics", symbol: "bolt", color: UIColor(red: 0.95, green: 0.82, blue: 0.60, alpha: 1)),
            DashCategory(title: "Home Goods", symbol: "house", color: UIColor(red: 0.85, green: 0.91, blue: 0.92, alpha: 1)),
            DashCategory(title: "Catering", symbol: "tray", color: UIColor(red: 0.92, green: 0.83, blue: 0.70, alpha: 1)),
            DashCategory(title: "Retail", symbol: "bag", color: UIColor(red: 0.93, green: 0.89, blue: 0.77, alpha: 1)),
            DashCategory(title: "Sporting", symbol: "sportscourt", color: UIColor(red: 0.80, green: 0.90, blue: 0.98, alpha: 1))
        ]

        paymentAccounts = accountsService.loadAccounts()


        let wholefoods = Restaurant(
            id: UUID(),
            name: "Whole Foods Market",
            cuisine: "Grocery",
            rating: 4.7,
            ratingCount: 1240,
            deliveryFee: "$0.00 delivery fee on $35+",
            eta: "45-60 min",
            distanceMiles: 1.6,
            heroColor: UIColor(red: 0.00, green: 0.47, blue: 0.22, alpha: 1),
            imageName: "whole_foods_hero",
            tags: ["Grocery", "Pantry", "Bakery", "Desserts", "Frozen", "DashMart"],
            menu: [
                MenuSection(title: "Produce", items: [
                    MenuItem(id: UUID(), name: "Organic Strawberries", detail: "1 lb clamshell", price: 5.99, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Organic Baby Spinach", detail: "5 oz container", price: 3.99, badge: nil),
                    MenuItem(id: UUID(), name: "Hass Avocados", detail: "4 count bag", price: 5.49, badge: nil),
                    MenuItem(id: UUID(), name: "Honeycrisp Apples", detail: "2 lb bag", price: 6.99, badge: nil)
                ]),
                MenuSection(title: "Bakery", items: [
                    MenuItem(id: UUID(), name: "Organic Sourdough Bread", detail: "Fresh baked loaf", price: 5.49, badge: nil),
                    MenuItem(id: UUID(), name: "Butter Croissants", detail: "4 count", price: 6.99, badge: nil),
                    MenuItem(id: UUID(), name: "Chocolate Chip Cookies", detail: "6 count", price: 5.99, badge: nil)
                ]),
                MenuSection(title: "Prepared Foods", items: [
                    MenuItem(id: UUID(), name: "Rotisserie Chicken", detail: "Lemon herb, whole", price: 9.99, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Sushi Combo Platter", detail: "12 piece assortment", price: 14.99, badge: nil),
                    MenuItem(id: UUID(), name: "Mac & Cheese", detail: "16 oz container", price: 8.99, badge: nil)
                ])
            ]
        )

        let chipotle = Restaurant(
            id: UUID(),
            name: "Chipotle Mexican Grill",
            cuisine: "Mexican",
            rating: 4.6,
            ratingCount: 2850,
            deliveryFee: "$0.00 delivery fee on $12+",
            eta: "15-25 min",
            distanceMiles: 2.1,
            heroColor: UIColor(red: 0.47, green: 0.11, blue: 0.04, alpha: 1),
            imageName: "chipotle_hero",
            tags: ["Burrito", "Bowls", "Catering", "Offers"],
            menu: [
                MenuSection(title: "Bowls", items: [
                    MenuItem(id: UUID(), name: "Chicken Bowl", detail: "White rice, black beans, fajita veggies, fresh tomato salsa, cheese, lettuce", price: 11.75, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Steak Bowl", detail: "Brown rice, pinto beans, roasted chili-corn salsa, sour cream, cheese", price: 12.90, badge: nil),
                    MenuItem(id: UUID(), name: "Sofritas Bowl", detail: "White rice, black beans, fresh tomato salsa, guacamole, lettuce", price: 11.25, badge: nil)
                ]),
                MenuSection(title: "Burritos", items: [
                    MenuItem(id: UUID(), name: "Chicken Burrito", detail: "Flour tortilla, rice, beans, chicken, salsa, sour cream, cheese, lettuce", price: 11.75, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Carnitas Burrito", detail: "Flour tortilla, rice, beans, carnitas, salsa, guacamole", price: 12.50, badge: nil),
                    MenuItem(id: UUID(), name: "Barbacoa Burrito", detail: "Flour tortilla, brown rice, pinto beans, barbacoa, salsa", price: 12.50, badge: nil)
                ]),
                MenuSection(title: "Sides & Extras", items: [
                    MenuItem(id: UUID(), name: "Chips & Guacamole", detail: "Fresh made daily", price: 5.95, badge: nil),
                    MenuItem(id: UUID(), name: "Chips & Queso Blanco", detail: "Creamy white queso", price: 5.25, badge: nil),
                    MenuItem(id: UUID(), name: "Large Chips", detail: "With lime and salt", price: 2.25, badge: nil)
                ])
            ]
        )

        let dominos = Restaurant(
            id: UUID(),
            name: "Domino's",
            cuisine: "Pizza",
            rating: 4.4,
            ratingCount: 3100,
            deliveryFee: "$1.99 delivery fee",
            eta: "25-40 min",
            distanceMiles: 3.3,
            heroColor: UIColor(red: 0.00, green: 0.40, blue: 0.70, alpha: 1),
            imageName: "dominos_hero",
            tags: ["Pizza", "Catering", "Offers", "Desserts"],
            menu: [
                MenuSection(title: "Pizzas", items: [
                    MenuItem(id: UUID(), name: "Pepperoni Hand Tossed", detail: "Medium 12\" hand-tossed pizza", price: 14.99, badge: "Best Seller"),
                    MenuItem(id: UUID(), name: "ExtravaganZZa", detail: "Pepperoni, ham, sausage, onions, green peppers, mushrooms, black olives", price: 17.99, badge: nil),
                    MenuItem(id: UUID(), name: "Pacific Veggie", detail: "Roasted red peppers, spinach, onions, mushrooms, tomatoes, feta", price: 16.99, badge: nil),
                    MenuItem(id: UUID(), name: "Buffalo Chicken", detail: "Grilled chicken, hot buffalo sauce, onions, mozzarella", price: 16.99, badge: nil),
                    MenuItem(id: UUID(), name: "Cheese Hand Tossed", detail: "Medium 12\" hand-tossed, classic mozzarella", price: 12.99, badge: nil),
                    MenuItem(id: UUID(), name: "MeatZZa", detail: "Pepperoni, ham, sausage, beef under a layer of cheese", price: 17.99, badge: nil)
                ]),
                MenuSection(title: "Chicken & Wings", items: [
                    MenuItem(id: UUID(), name: "Boneless Chicken Wings", detail: "8 pieces, choose your sauce", price: 8.99, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Bone-In Wings", detail: "8 pieces, hot buffalo or BBQ", price: 9.99, badge: nil),
                    MenuItem(id: UUID(), name: "Chicken Alfredo Pasta", detail: "Penne in creamy alfredo, grilled chicken, parmesan", price: 9.99, badge: nil)
                ]),
                MenuSection(title: "Sides", items: [
                    MenuItem(id: UUID(), name: "Parmesan Bread Twists", detail: "8 pieces with marinara", price: 6.99, badge: nil),
                    MenuItem(id: UUID(), name: "Stuffed Cheesy Bread", detail: "8 pieces stuffed with cheese and topped with garlic butter", price: 7.99, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Marbled Cookie Brownie", detail: "Chocolate chip cookie and fudge brownie", price: 6.99, badge: nil)
                ]),
                MenuSection(title: "Drinks", items: [
                    MenuItem(id: UUID(), name: "2-Liter Coca-Cola", detail: "Classic Coke, 2-liter bottle", price: 3.49, badge: nil),
                    MenuItem(id: UUID(), name: "20 oz Bottle", detail: "Coke, Diet Coke, Sprite, or Fanta", price: 2.49, badge: nil)
                ])
            ]
        )

        let pizzaHut = Restaurant(
            id: UUID(),
            name: "Pizza Hut",
            cuisine: "Pizza",
            rating: 4.3,
            ratingCount: 2670,
            deliveryFee: "$0.00 delivery fee on $20+",
            eta: "30-45 min",
            distanceMiles: 2.7,
            heroColor: UIColor(red: 0.80, green: 0.12, blue: 0.12, alpha: 1),
            imageName: "pizza_hut_hero",
            tags: ["Pizza", "Offers", "Desserts", "Catering"],
            menu: [
                MenuSection(title: "Pizzas", items: [
                    MenuItem(id: UUID(), name: "Pepperoni Lover's", detail: "Large original pan pizza loaded with pepperoni", price: 16.99, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Meat Lover's", detail: "Pepperoni, ham, pork, beef, Italian sausage, bacon", price: 17.99, badge: nil),
                    MenuItem(id: UUID(), name: "Supreme", detail: "Pepperoni, sausage, beef, mushrooms, bell peppers, onions", price: 17.49, badge: nil)
                ]),
                MenuSection(title: "Wings & Sides", items: [
                    MenuItem(id: UUID(), name: "Bone-Out Wings", detail: "8 pieces with ranch", price: 9.99, badge: nil),
                    MenuItem(id: UUID(), name: "Breadsticks", detail: "5 pieces with marinara", price: 5.99, badge: nil),
                    MenuItem(id: UUID(), name: "Stuffed Garlic Knots", detail: "6 pieces with cheese inside", price: 6.49, badge: nil)
                ]),
                MenuSection(title: "Desserts", items: [
                    MenuItem(id: UUID(), name: "Ultimate Hershey's Brownie", detail: "Rich chocolate brownie", price: 7.99, badge: nil),
                    MenuItem(id: UUID(), name: "Cinnabon Mini Rolls", detail: "10 bite-sized cinnamon rolls", price: 6.49, badge: nil)
                ])
            ]
        )

        let sweetgreen = Restaurant(
            id: UUID(),
            name: "Sweetgreen",
            cuisine: "Healthy",
            rating: 4.7,
            ratingCount: 890,
            deliveryFee: "$0.99 delivery fee",
            eta: "20-30 min",
            distanceMiles: 2.5,
            heroColor: UIColor(red: 0.68, green: 0.83, blue: 0.58, alpha: 1),
            imageName: "sweetgreen_hero",
            tags: ["Bowls", "Salads", "Premium", "Offers"],
            menu: [
                MenuSection(title: "Warm Bowls", items: [
                    MenuItem(id: UUID(), name: "Harvest Bowl", detail: "Roasted chicken, roasted sweet potatoes, apples, goat cheese, hot honey", price: 15.45, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Shroomami", detail: "Roasted tofu, warm portobello mix, raw beets, cucumber, basil", price: 14.25, badge: nil),
                    MenuItem(id: UUID(), name: "Chicken Pesto Parm", detail: "Roasted chicken, spicy broccoli, tomatoes, shaved parmesan, pesto vinaigrette", price: 15.95, badge: nil)
                ]),
                MenuSection(title: "Salads", items: [
                    MenuItem(id: UUID(), name: "Kale Caesar", detail: "Shredded kale, parmesan crisps, tomatoes, lime squeeze caesar", price: 13.25, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Guacamole Greens", detail: "Spring mix, avocado, tortilla chips, tomatoes, red onion, lime cilantro jalapeño vinaigrette", price: 14.50, badge: nil)
                ]),
                MenuSection(title: "Sides & Drinks", items: [
                    MenuItem(id: UUID(), name: "Rosemary Focaccia", detail: "Warm bread side", price: 2.95, badge: nil),
                    MenuItem(id: UUID(), name: "Hibiscus Clover Lemonade", detail: "16 oz", price: 4.50, badge: nil)
                ]),
                MenuSection(title: "Smoothies", items: [
                    MenuItem(id: UUID(), name: "Green Recovery Smoothie", detail: "Kale, banana, almond butter, protein powder, almond milk", price: 8.95, badge: "New"),
                    MenuItem(id: UUID(), name: "Berry Blast Smoothie", detail: "Strawberry, blueberry, banana, oat milk", price: 7.95, badge: nil)
                ])
            ]
        )

        let chickFilA = Restaurant(
            id: UUID(),
            name: "Chick-fil-A",
            cuisine: "Chicken",
            rating: 4.8,
            ratingCount: 4200,
            deliveryFee: "$0.00 delivery fee on $15+",
            eta: "15-25 min",
            distanceMiles: 2.4,
            heroColor: UIColor(red: 0.80, green: 0.04, blue: 0.14, alpha: 1),
            imageName: "chick_fil_a_hero",
            tags: ["Chicken", "Offers", "Catering", "Drinks"],
            menu: [
                MenuSection(title: "Entrees", items: [
                    MenuItem(id: UUID(), name: "Chick-fil-A Chicken Sandwich", detail: "Breaded chicken breast, pickles, toasted butter bun", price: 6.29, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Spicy Chicken Sandwich", detail: "Spicy breaded chicken breast, pickles, toasted butter bun", price: 6.69, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Chicken Nuggets", detail: "12-count, bite-sized chicken", price: 7.25, badge: nil),
                    MenuItem(id: UUID(), name: "Spicy Deluxe Sandwich", detail: "Spicy chicken, lettuce, tomato, pepper jack", price: 7.59, badge: nil)
                ]),
                MenuSection(title: "Sides", items: [
                    MenuItem(id: UUID(), name: "Waffle Potato Fries", detail: "Medium, waffle-cut and sea salted", price: 2.89, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Mac & Cheese", detail: "Creamy blend of cheeses", price: 4.39, badge: nil),
                    MenuItem(id: UUID(), name: "Chicken Noodle Soup", detail: "Medium cup", price: 4.65, badge: nil)
                ]),
                MenuSection(title: "Beverages", items: [
                    MenuItem(id: UUID(), name: "Frosted Lemonade", detail: "Lemonade blended with vanilla ice cream", price: 4.85, badge: nil),
                    MenuItem(id: UUID(), name: "Chocolate Milkshake", detail: "Hand-spun, whipped cream", price: 5.19, badge: nil)
                ])
            ]
        )

        let sugarfish = Restaurant(
            id: UUID(),
            name: "Sugarfish",
            cuisine: "Japanese",
            rating: 4.8,
            ratingCount: 1560,
            deliveryFee: "$2.99 delivery fee",
            eta: "35-50 min",
            distanceMiles: 4.2,
            heroColor: UIColor(red: 0.95, green: 0.94, blue: 0.90, alpha: 1),
            imageName: "sugarfish_hero",
            tags: ["Sushi", "Premium"],
            menu: [
                MenuSection(title: "Trust Me Sets", items: [
                    MenuItem(id: UUID(), name: "Trust Me", detail: "Tuna sashimi, salmon sashimi, yellowtail sashimi, tuna roll, salmon roll, blue crab hand roll", price: 30.00, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Trust Me Lite", detail: "Salmon sashimi, tuna roll, edamame", price: 20.00, badge: nil),
                    MenuItem(id: UUID(), name: "Notta Trust Me", detail: "Build your own selection of 6 items", price: 28.00, badge: nil)
                ]),
                MenuSection(title: "A La Carte", items: [
                    MenuItem(id: UUID(), name: "Salmon Sashimi", detail: "3 pieces, wild caught", price: 9.50, badge: nil),
                    MenuItem(id: UUID(), name: "Tuna Sashimi", detail: "3 pieces, bluefin", price: 11.00, badge: nil),
                    MenuItem(id: UUID(), name: "Yellowtail Sashimi", detail: "3 pieces", price: 10.50, badge: nil),
                    MenuItem(id: UUID(), name: "Blue Crab Hand Roll", detail: "Nori wrapped, warm rice", price: 8.50, badge: "Signature")
                ])
            ]
        )

        let nobu = Restaurant(
            id: UUID(),
            name: "Nobu",
            cuisine: "Japanese",
            rating: 4.9,
            ratingCount: 780,
            deliveryFee: "$3.99 delivery fee",
            eta: "40-55 min",
            distanceMiles: 3.6,
            heroColor: UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1),
            imageName: "nobu_hero",
            tags: ["Sushi", "Premium", "Offers"],
            menu: [
                MenuSection(title: "Signature Dishes", items: [
                    MenuItem(id: UUID(), name: "Black Cod with Miso", detail: "Marinated in den miso for 72 hours", price: 36.00, badge: "Signature"),
                    MenuItem(id: UUID(), name: "Yellowtail Jalapeño", detail: "Thin-sliced yellowtail, jalapeño, ponzu, olive oil", price: 28.00, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Rock Shrimp Tempura", detail: "Creamy spicy sauce", price: 22.00, badge: nil)
                ]),
                MenuSection(title: "Sushi & Sashimi", items: [
                    MenuItem(id: UUID(), name: "Omakase Nigiri Set", detail: "Chef's selection, 10 pieces", price: 48.00, badge: nil),
                    MenuItem(id: UUID(), name: "Sashimi Salad", detail: "Assorted sashimi over mixed greens, matsuhisa dressing", price: 26.00, badge: nil)
                ]),
                MenuSection(title: "Sides", items: [
                    MenuItem(id: UUID(), name: "Edamame", detail: "Steamed with sea salt", price: 8.00, badge: nil),
                    MenuItem(id: UUID(), name: "Miso Soup", detail: "Tofu, wakame, scallion", price: 6.00, badge: nil),
                    MenuItem(id: UUID(), name: "Crispy Rice with Spicy Tuna", detail: "4 pieces", price: 18.00, badge: nil)
                ])
            ]
        )

        let fiveGuys = Restaurant(
            id: UUID(),
            name: "Five Guys",
            cuisine: "Burgers",
            rating: 4.5,
            ratingCount: 3650,
            deliveryFee: "$0.00 delivery fee on $15+",
            eta: "20-35 min",
            distanceMiles: 2.8,
            heroColor: UIColor(red: 0.80, green: 0.10, blue: 0.10, alpha: 1),
            imageName: "five_guys_hero",
            tags: ["Burgers", "Convenience", "Offers"],
            menu: [
                MenuSection(title: "Burgers", items: [
                    MenuItem(id: UUID(), name: "Cheeseburger", detail: "Two hand-formed patties, American cheese, choose your toppings", price: 12.69, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Little Cheeseburger", detail: "One hand-formed patty, American cheese, choose your toppings", price: 9.69, badge: nil),
                    MenuItem(id: UUID(), name: "Bacon Cheeseburger", detail: "Two patties, American cheese, applewood smoked bacon", price: 13.99, badge: "Best Seller"),
                    MenuItem(id: UUID(), name: "Hamburger", detail: "Two hand-formed patties, choose your toppings", price: 11.69, badge: nil)
                ]),
                MenuSection(title: "Fries", items: [
                    MenuItem(id: UUID(), name: "Five Guys Style Fries", detail: "Regular, fresh cut in peanut oil", price: 6.29, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Cajun Fries", detail: "Regular, seasoned with cajun spice blend", price: 6.29, badge: nil),
                    MenuItem(id: UUID(), name: "Little Fries", detail: "Fresh cut, perfect for one", price: 4.89, badge: nil)
                ]),
                MenuSection(title: "Hot Dogs", items: [
                    MenuItem(id: UUID(), name: "Kosher Style Hot Dog", detail: "Split and grilled, choose your toppings", price: 7.69, badge: nil),
                    MenuItem(id: UUID(), name: "Cheese Dog", detail: "Split and grilled with melted cheese", price: 8.29, badge: nil)
                ])
            ]
        )

        let shakeShack = Restaurant(
            id: UUID(),
            name: "Shake Shack",
            cuisine: "Burgers",
            rating: 4.6,
            ratingCount: 2940,
            deliveryFee: "$0.99 delivery fee",
            eta: "20-30 min",
            distanceMiles: 2.0,
            heroColor: UIColor(red: 0.20, green: 0.50, blue: 0.20, alpha: 1),
            imageName: "shake_shack_hero",
            tags: ["Burgers", "Drinks", "Offers"],
            menu: [
                MenuSection(title: "Burgers", items: [
                    MenuItem(id: UUID(), name: "ShackBurger", detail: "Angus beef, lettuce, tomato, ShackSauce", price: 8.39, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "SmokeShack", detail: "Angus beef, cheese, applewood bacon, cherry peppers, ShackSauce", price: 9.79, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Shack Stack", detail: "Cheeseburger and crispy portobello mushroom topped with lettuce, tomato, ShackSauce", price: 10.89, badge: nil)
                ]),
                MenuSection(title: "Crinkle Cut Fries", items: [
                    MenuItem(id: UUID(), name: "Fries", detail: "Crispy crinkle cut fries", price: 4.29, badge: nil),
                    MenuItem(id: UUID(), name: "Cheese Fries", detail: "Crinkle cuts with cheese sauce", price: 5.59, badge: nil)
                ]),
                MenuSection(title: "Frozen Custard", items: [
                    MenuItem(id: UUID(), name: "Chocolate Shake", detail: "Dense frozen chocolate custard spun with milk", price: 6.59, badge: nil),
                    MenuItem(id: UUID(), name: "Vanilla Shake", detail: "Dense frozen vanilla custard spun with milk", price: 6.59, badge: nil),
                    MenuItem(id: UUID(), name: "Strawberry Shake", detail: "Dense frozen custard with real strawberries", price: 6.59, badge: nil)
                ])
            ]
        )

        let levain = Restaurant(
            id: UUID(),
            name: "Levain Bakery",
            cuisine: "Bakery",
            rating: 4.9,
            ratingCount: 1870,
            deliveryFee: "$0.00 delivery fee on $20+",
            eta: "25-35 min",
            distanceMiles: 1.4,
            heroColor: UIColor(red: 0.85, green: 0.65, blue: 0.40, alpha: 1),
            imageName: "levain_hero",
            tags: ["Bakery", "Desserts", "Coffee", "Gifts"],
            menu: [
                MenuSection(title: "Signature Cookies", items: [
                    MenuItem(id: UUID(), name: "Chocolate Chip Walnut", detail: "6 oz, crispy outside, gooey inside", price: 5.00, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Dark Chocolate Chocolate Chip", detail: "6 oz, double chocolate indulgence", price: 5.00, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Dark Chocolate Peanut Butter Chip", detail: "6 oz, rich and nutty", price: 5.00, badge: nil),
                    MenuItem(id: UUID(), name: "Oatmeal Raisin", detail: "6 oz, classic with cinnamon", price: 5.00, badge: nil)
                ]),
                MenuSection(title: "Breads & Pastries", items: [
                    MenuItem(id: UUID(), name: "Chocolate Babka", detail: "Braided brioche with chocolate filling", price: 14.00, badge: nil),
                    MenuItem(id: UUID(), name: "Cinnamon Brioche", detail: "Soft, buttery, swirled", price: 12.00, badge: nil)
                ]),
                MenuSection(title: "Gift Boxes", items: [
                    MenuItem(id: UUID(), name: "Cookie 4-Pack", detail: "Choose your flavors", price: 26.00, badge: "Giftable"),
                    MenuItem(id: UUID(), name: "Cookie 8-Pack", detail: "Assorted signature cookies", price: 48.00, badge: nil)
                ])
            ]
        )

        let starbucks = Restaurant(
            id: UUID(),
            name: "Starbucks",
            cuisine: "Coffee",
            rating: 4.5,
            ratingCount: 5200,
            deliveryFee: "$0.00 delivery fee on $15+",
            eta: "10-20 min",
            distanceMiles: 0.9,
            heroColor: UIColor(red: 0.00, green: 0.39, blue: 0.22, alpha: 1),
            imageName: "starbucks_hero",
            tags: ["Coffee", "Bakery", "Convenience", "Snacks"],
            menu: [
                MenuSection(title: "Hot Drinks", items: [
                    MenuItem(id: UUID(), name: "Caramel Macchiato", detail: "Grande, vanilla syrup, steamed milk, espresso, caramel drizzle", price: 6.45, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Caffè Latte", detail: "Grande, espresso with steamed milk", price: 5.75, badge: nil),
                    MenuItem(id: UUID(), name: "Pike Place Roast", detail: "Grande, smooth medium roast", price: 3.65, badge: nil)
                ]),
                MenuSection(title: "Cold Drinks", items: [
                    MenuItem(id: UUID(), name: "Iced Caramel Macchiato", detail: "Grande, vanilla, milk, espresso, caramel drizzle", price: 6.75, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Cold Brew", detail: "Grande, slow-steeped for 20 hours", price: 5.25, badge: nil),
                    MenuItem(id: UUID(), name: "Pink Drink", detail: "Grande, Strawberry Açaí Refresher with coconut milk", price: 6.25, badge: "Popular")
                ]),
                MenuSection(title: "Food", items: [
                    MenuItem(id: UUID(), name: "Bacon, Gouda & Egg Sandwich", detail: "Applewood-smoked bacon, aged Gouda, cage-free fried egg", price: 5.75, badge: nil),
                    MenuItem(id: UUID(), name: "Butter Croissant", detail: "Flaky, buttery layers", price: 3.95, badge: nil),
                    MenuItem(id: UUID(), name: "Cake Pop", detail: "Birthday cake or chocolate", price: 3.50, badge: nil)
                ])
            ]
        )

        let jamba = Restaurant(
            id: UUID(),
            name: "Jamba",
            cuisine: "Drinks",
            rating: 4.5,
            ratingCount: 1120,
            deliveryFee: "$0.00 delivery fee",
            eta: "15-25 min",
            distanceMiles: 1.5,
            heroColor: UIColor(red: 0.94, green: 0.58, blue: 0.16, alpha: 1),
            imageName: "jamba_hero",
            tags: ["Smoothie", "Drinks", "Snacks", "Bowls"],
            menu: [
                MenuSection(title: "Classic Smoothies", items: [
                    MenuItem(id: UUID(), name: "Caribbean Passion", detail: "Medium, mango, passion fruit-mango juice, orange sherbet", price: 8.29, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Mango-a-Go-Go", detail: "Medium, mango, passion fruit-mango juice", price: 8.29, badge: nil),
                    MenuItem(id: UUID(), name: "Razzmatazz", detail: "Medium, raspberries, strawberries, banana, orange sherbet", price: 8.29, badge: nil)
                ]),
                MenuSection(title: "Bowls", items: [
                    MenuItem(id: UUID(), name: "Açaí Primo Bowl", detail: "Açaí, blueberries, strawberries, granola, honey, banana", price: 10.99, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Chunky Strawberry Bowl", detail: "Strawberries, Greek yogurt, granola", price: 10.49, badge: nil)
                ]),
                MenuSection(title: "Shots", items: [
                    MenuItem(id: UUID(), name: "Ginger Shot", detail: "Ginger, lemon, cayenne", price: 3.49, badge: nil),
                    MenuItem(id: UUID(), name: "Wheatgrass Shot", detail: "Fresh wheatgrass", price: 3.49, badge: nil)
                ])
            ]
        )

        let kungFuTea = Restaurant(
            id: UUID(),
            name: "Kung Fu Tea",
            cuisine: "Drinks",
            rating: 4.7,
            ratingCount: 980,
            deliveryFee: "$0.00 delivery fee",
            eta: "15-25 min",
            distanceMiles: 1.2,
            heroColor: UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1),
            imageName: "kung_fu_tea_hero",
            tags: ["Drinks", "Snacks", "Desserts"],
            menu: [
                MenuSection(title: "Milk Tea", items: [
                    MenuItem(id: UUID(), name: "Classic Milk Tea", detail: "Large, signature black milk tea with tapioca", price: 6.25, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Taro Milk Tea", detail: "Large, creamy taro with tapioca", price: 6.75, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Thai Tea", detail: "Large, traditional Thai tea with milk", price: 6.50, badge: nil)
                ]),
                MenuSection(title: "Fruit Tea", items: [
                    MenuItem(id: UUID(), name: "Passion Fruit Green Tea", detail: "Large, with mango popping boba", price: 6.50, badge: nil),
                    MenuItem(id: UUID(), name: "Mango Green Tea", detail: "Large, with lychee jelly", price: 6.50, badge: nil)
                ]),
                MenuSection(title: "Punch", items: [
                    MenuItem(id: UUID(), name: "Kung Fu Punch", detail: "Large, fruity layered tea with tapioca", price: 7.25, badge: nil),
                    MenuItem(id: UUID(), name: "Peach Kiwi Punch", detail: "Large, refreshing peach and kiwi", price: 7.25, badge: nil)
                ])
            ]
        )

        let jerseyMikes = Restaurant(
            id: UUID(),
            name: "Jersey Mike's Subs",
            cuisine: "Deli",
            rating: 4.6,
            ratingCount: 2100,
            deliveryFee: "$0.00 delivery fee on $20+",
            eta: "20-30 min",
            distanceMiles: 1.9,
            heroColor: UIColor(red: 0.00, green: 0.34, blue: 0.62, alpha: 1),
            imageName: "jersey_mikes_hero",
            tags: ["Deli", "Convenience", "Catering", "Sandwiches"],
            menu: [
                MenuSection(title: "Cold Subs", items: [
                    MenuItem(id: UUID(), name: "#13 The Original Italian", detail: "Regular, provolone, ham, prosciuttini, cappacuolo, salami, pepperoni", price: 11.50, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "#7 Turkey & Provolone", detail: "Regular, turkey breast with provolone", price: 10.75, badge: "Popular"),
                    MenuItem(id: UUID(), name: "#6 Roast Beef & Provolone", detail: "Regular, premium roast beef", price: 11.25, badge: nil),
                    MenuItem(id: UUID(), name: "#2 Jersey Shore's Favorite", detail: "Regular, provolone, ham, cappacuolo", price: 10.95, badge: nil)
                ]),
                MenuSection(title: "Hot Subs", items: [
                    MenuItem(id: UUID(), name: "#17 Mike's Famous Philly", detail: "Regular, grilled onions, peppers, white American cheese", price: 12.50, badge: nil),
                    MenuItem(id: UUID(), name: "#43 Chipotle Cheese Steak", detail: "Regular, grilled onions, peppers, chipotle mayo, pepper jack", price: 12.95, badge: nil)
                ]),
                MenuSection(title: "Sides", items: [
                    MenuItem(id: UUID(), name: "Chips", detail: "Mike's kettle cooked sea salt chips", price: 2.50, badge: nil),
                    MenuItem(id: UUID(), name: "Chocolate Chip Cookie", detail: "Freshly baked", price: 2.00, badge: nil)
                ])
            ]
        )

        let panera = Restaurant(
            id: UUID(),
            name: "Panera Bread",
            cuisine: "Deli",
            rating: 4.5,
            ratingCount: 3400,
            deliveryFee: "$0.00 delivery fee on $15+",
            eta: "20-35 min",
            distanceMiles: 1.3,
            heroColor: UIColor(red: 0.29, green: 0.52, blue: 0.22, alpha: 1),
            imageName: "panera_hero",
            tags: ["Sandwiches", "Deli", "Coffee", "Offers"],
            menu: [
                MenuSection(title: "Soups", items: [
                    MenuItem(id: UUID(), name: "Broccoli Cheddar Soup", detail: "Bread bowl, creamy broccoli cheddar in a sourdough bread bowl", price: 9.59, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Creamy Tomato Soup", detail: "Cup, vine-ripened tomatoes pureed with fresh cream", price: 6.29, badge: nil)
                ]),
                MenuSection(title: "Sandwiches", items: [
                    MenuItem(id: UUID(), name: "Bacon Turkey Bravo", detail: "Smoked turkey, bacon, smoked Gouda, lettuce, tomato, signature sauce", price: 11.79, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Frontega Chicken Panini", detail: "Smoked chicken, mozzarella, tomatoes, red onions, chipotle mayo, focaccia", price: 11.99, badge: nil),
                    MenuItem(id: UUID(), name: "Toasted Steak & White Cheddar", detail: "Seasoned steak, white cheddar, pickled red onions, horseradish sauce", price: 12.49, badge: nil)
                ]),
                MenuSection(title: "Salads", items: [
                    MenuItem(id: UUID(), name: "Fuji Apple Chicken Salad", detail: "Chicken, mixed greens, apples, pecans, Gorgonzola, apple vinaigrette", price: 12.29, badge: nil),
                    MenuItem(id: UUID(), name: "Caesar Salad", detail: "Romaine, parmesan, croutons, caesar dressing", price: 10.29, badge: nil)
                ])
            ]
        )

        let cava = Restaurant(
            id: UUID(),
            name: "CAVA",
            cuisine: "Salads",
            rating: 4.7,
            ratingCount: 1450,
            deliveryFee: "$1.49 delivery fee",
            eta: "20-30 min",
            distanceMiles: 2.2,
            heroColor: UIColor(red: 0.14, green: 0.45, blue: 0.53, alpha: 1),
            imageName: "cava_hero",
            tags: ["Salads", "Bowls", "Premium"],
            menu: [
                MenuSection(title: "Bowls", items: [
                    MenuItem(id: UUID(), name: "Grilled Chicken Bowl", detail: "SplendidGreens, grilled chicken, hummus, crazy feta, tomato & onion, lemon herb tahini", price: 12.65, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Braised Lamb Bowl", detail: "SuperGreens, braised lamb, roasted eggplant dip, harissa, pickled onions", price: 14.25, badge: nil),
                    MenuItem(id: UUID(), name: "Falafel Bowl", detail: "RightRice, crispy falafel, tzatziki, tomato & cucumber, pita chips", price: 11.95, badge: "Popular")
                ]),
                MenuSection(title: "Pitas", items: [
                    MenuItem(id: UUID(), name: "Grilled Chicken Pita", detail: "Warm pita, grilled chicken, hummus, pickled onions, greens", price: 11.95, badge: nil),
                    MenuItem(id: UUID(), name: "Falafel Pita", detail: "Warm pita, falafel, tzatziki, tomato & cucumber", price: 11.25, badge: nil)
                ]),
                MenuSection(title: "Dips & Sides", items: [
                    MenuItem(id: UUID(), name: "Crazy Feta Dip & Pita Chips", detail: "Whipped feta with harissa", price: 4.75, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Hummus & Pita Chips", detail: "Classic smooth hummus", price: 4.25, badge: nil)
                ])
            ]
        )

        let dashMart = Restaurant(
            id: UUID(),
            name: "DashMart",
            cuisine: "Convenience",
            rating: 4.6,
            ratingCount: 2410,
            deliveryFee: "$0.99 delivery fee",
            eta: "15-25 min",
            distanceMiles: 1.0,
            heroColor: UIColor(red: 0.98, green: 0.70, blue: 0.40, alpha: 1),
            imageName: "dashmart_hero",
            tags: ["Convenience", "DashMart", "Snacks", "Drinks", "Pantry", "Frozen", "Baby & Toys", "Home Goods", "Electronics", "Packages", "Retail"],
            menu: [
                MenuSection(title: "Snacks & Drinks", items: [
                    MenuItem(id: UUID(), name: "Lay's Classic Chips", detail: "8 oz bag", price: 5.49, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Ben & Jerry's Half Baked", detail: "Pint", price: 7.99, badge: nil),
                    MenuItem(id: UUID(), name: "Red Bull 4-Pack", detail: "8.4 oz sugar free", price: 9.99, badge: nil)
                ]),
                MenuSection(title: "Essentials", items: [
                    MenuItem(id: UUID(), name: "Bounty Paper Towels", detail: "2 roll pack", price: 7.49, badge: nil),
                    MenuItem(id: UUID(), name: "Energizer AA Batteries", detail: "8 count", price: 10.99, badge: nil),
                    MenuItem(id: UUID(), name: "USB-C Charging Cable", detail: "3 ft braided", price: 14.99, badge: nil)
                ]),
                MenuSection(title: "Pantry", items: [
                    MenuItem(id: UUID(), name: "Barilla Penne", detail: "16 oz box", price: 2.49, badge: nil),
                    MenuItem(id: UUID(), name: "Rao's Marinara Sauce", detail: "24 oz jar", price: 8.99, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Cheerios", detail: "12 oz box", price: 5.49, badge: nil)
                ])
            ]
        )

        let totalWine = Restaurant(
            id: UUID(),
            name: "Total Wine & More",
            cuisine: "Bottle Shop",
            rating: 4.7,
            ratingCount: 870,
            deliveryFee: "$3.99 delivery fee",
            eta: "25-40 min",
            distanceMiles: 2.6,
            heroColor: UIColor(red: 0.55, green: 0.08, blue: 0.13, alpha: 1),
            imageName: "total_wine_hero",
            tags: ["Alcohol", "Drinks", "Offers", "Gifts", "Retail"],
            menu: [
                MenuSection(title: "Wine", items: [
                    MenuItem(id: UUID(), name: "Caymus Cabernet Sauvignon", detail: "750 ml, Napa Valley", price: 89.99, badge: "Staff Pick"),
                    MenuItem(id: UUID(), name: "La Marca Prosecco", detail: "750 ml, Italy", price: 14.99, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Whispering Angel Rosé", detail: "750 ml, Provence", price: 22.99, badge: nil)
                ]),
                MenuSection(title: "Beer", items: [
                    MenuItem(id: UUID(), name: "Modelo Especial 12-Pack", detail: "12 oz cans", price: 17.99, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Blue Moon Belgian White 6-Pack", detail: "12 oz bottles", price: 11.99, badge: nil),
                    MenuItem(id: UUID(), name: "Athletic Brewing Run Wild IPA 6-Pack", detail: "12 oz non-alcoholic", price: 10.99, badge: nil)
                ]),
                MenuSection(title: "Spirits", items: [
                    MenuItem(id: UUID(), name: "Tito's Handmade Vodka", detail: "750 ml", price: 24.99, badge: nil),
                    MenuItem(id: UUID(), name: "Don Julio Blanco Tequila", detail: "750 ml", price: 49.99, badge: nil)
                ])
            ]
        )

        let bouqs = Restaurant(
            id: UUID(),
            name: "The Bouqs Co.",
            cuisine: "Florist",
            rating: 4.8,
            ratingCount: 420,
            deliveryFee: "$4.99 delivery fee",
            eta: "35-50 min",
            distanceMiles: 3.1,
            heroColor: UIColor(red: 0.95, green: 0.80, blue: 0.89, alpha: 1),
            imageName: "bouqs_hero",
            tags: ["Flowers", "Gifts", "Premium", "Home Goods"],
            menu: [
                MenuSection(title: "Bouquets", items: [
                    MenuItem(id: UUID(), name: "The Brightest Day", detail: "Vibrant seasonal mix, eco-friendly farm sourced", price: 54.00, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Classic Red Roses", detail: "Dozen long-stem red roses", price: 65.00, badge: nil),
                    MenuItem(id: UUID(), name: "Wildflower Mix", detail: "Colorful field-inspired arrangement", price: 48.00, badge: nil)
                ]),
                MenuSection(title: "Arrangements", items: [
                    MenuItem(id: UUID(), name: "Modern White Orchid", detail: "Phalaenopsis orchid in ceramic pot", price: 72.00, badge: nil),
                    MenuItem(id: UUID(), name: "Succulent Garden", detail: "Assorted succulents in planter", price: 45.00, badge: "Giftable")
                ])
            ]
        )

        let cvs = Restaurant(
            id: UUID(),
            name: "CVS Pharmacy",
            cuisine: "Pharmacy",
            rating: 4.4,
            ratingCount: 1560,
            deliveryFee: "$2.99 delivery fee",
            eta: "20-30 min",
            distanceMiles: 1.7,
            heroColor: UIColor(red: 0.80, green: 0.09, blue: 0.16, alpha: 1),
            imageName: "cvs_hero",
            tags: ["Drugstore", "Beauty", "Home Goods", "Convenience", "Snacks"],
            menu: [
                MenuSection(title: "Health & Medicine", items: [
                    MenuItem(id: UUID(), name: "Advil Ibuprofen", detail: "24 count, 200mg tablets", price: 7.99, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Band-Aid Flexible Fabric", detail: "100 count assorted", price: 9.49, badge: nil),
                    MenuItem(id: UUID(), name: "NyQuil Cold & Flu", detail: "12 oz liquid, nighttime relief", price: 12.99, badge: nil)
                ]),
                MenuSection(title: "Beauty & Personal Care", items: [
                    MenuItem(id: UUID(), name: "CeraVe Hydrating Cleanser", detail: "12 oz, for normal to dry skin", price: 15.99, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Neutrogena SPF 50 Sunscreen", detail: "3 oz lotion", price: 12.49, badge: nil)
                ]),
                MenuSection(title: "Snacks & Beverages", items: [
                    MenuItem(id: UUID(), name: "KIND Dark Chocolate Nuts Bar", detail: "6 count box", price: 8.99, badge: nil),
                    MenuItem(id: UUID(), name: "Smartwater", detail: "1 liter bottle", price: 2.99, badge: nil)
                ])
            ]
        )

        let petsmart = Restaurant(
            id: UUID(),
            name: "PetSmart",
            cuisine: "Pets",
            rating: 4.7,
            ratingCount: 680,
            deliveryFee: "$1.99 delivery fee",
            eta: "25-35 min",
            distanceMiles: 2.3,
            heroColor: UIColor(red: 0.00, green: 0.30, blue: 0.65, alpha: 1),
            imageName: "petsmart_hero",
            tags: ["Pets", "Retail", "Convenience"],
            menu: [
                MenuSection(title: "Dog", items: [
                    MenuItem(id: UUID(), name: "Blue Buffalo Life Protection", detail: "6 lb bag, chicken & brown rice", price: 19.98, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Greenies Dental Treats", detail: "12 oz bag, regular size", price: 14.99, badge: nil),
                    MenuItem(id: UUID(), name: "KONG Classic Dog Toy", detail: "Medium, red rubber", price: 12.99, badge: nil)
                ]),
                MenuSection(title: "Cat", items: [
                    MenuItem(id: UUID(), name: "Fancy Feast Classic Paté", detail: "12 count variety pack, 3 oz cans", price: 12.48, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Catnip Mouse Toy", detail: "3 pack assorted", price: 5.99, badge: nil),
                    MenuItem(id: UUID(), name: "Tidy Cats Clumping Litter", detail: "20 lb jug, unscented", price: 14.99, badge: nil)
                ])
            ]
        )

        let dicks = Restaurant(
            id: UUID(),
            name: "Dick's Sporting Goods",
            cuisine: "Sporting Goods",
            rating: 4.6,
            ratingCount: 390,
            deliveryFee: "$3.49 delivery fee",
            eta: "30-45 min",
            distanceMiles: 3.8,
            heroColor: UIColor(red: 0.16, green: 0.44, blue: 0.22, alpha: 1),
            imageName: "dicks_hero",
            tags: ["Sporting", "Retail", "Packages"],
            menu: [
                MenuSection(title: "Training", items: [
                    MenuItem(id: UUID(), name: "GU Energy Gels 8-Pack", detail: "Mixed flavors, 32g carbs each", price: 14.99, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Nuun Sport Hydration Tabs", detail: "4 tube variety pack, 40 servings", price: 24.99, badge: nil),
                    MenuItem(id: UUID(), name: "SPRI Resistance Band Kit", detail: "3 bands, light/medium/heavy", price: 19.99, badge: nil)
                ]),
                MenuSection(title: "Recovery", items: [
                    MenuItem(id: UUID(), name: "Nike Dri-FIT Running Socks", detail: "3 pairs, cushioned", price: 22.00, badge: nil),
                    MenuItem(id: UUID(), name: "TriggerPoint GRID Foam Roller", detail: "13 inch, multi-density", price: 34.99, badge: nil)
                ])
            ]
        )

        let tacoBell = Restaurant(
            id: UUID(),
            name: "Taco Bell",
            cuisine: "Mexican",
            rating: 4.3,
            ratingCount: 3800,
            deliveryFee: "$0.00 delivery fee on $15+",
            eta: "15-25 min",
            distanceMiles: 1.8,
            heroColor: UIColor(red: 0.44, green: 0.16, blue: 0.66, alpha: 1),
            imageName: "taco_bell_hero",
            tags: ["Burrito", "Offers", "Catering"],
            menu: [
                MenuSection(title: "Tacos", items: [
                    MenuItem(id: UUID(), name: "Crunchy Taco Supreme", detail: "Seasoned beef, lettuce, tomatoes, sour cream, cheese", price: 3.49, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Doritos Locos Taco", detail: "Seasoned beef in a Nacho Cheese Doritos shell", price: 3.29, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Chalupa Supreme", detail: "Seasoned beef, lettuce, tomatoes, sour cream, cheese, chalupa shell", price: 4.99, badge: nil)
                ]),
                MenuSection(title: "Burritos", items: [
                    MenuItem(id: UUID(), name: "Beefy 5-Layer Burrito", detail: "Seasoned beef, beans, nacho cheese, sour cream, cheese", price: 4.49, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Chicken Burrito Supreme", detail: "Chicken, beans, rice, lettuce, tomatoes, sour cream, cheese", price: 5.99, badge: nil),
                    MenuItem(id: UUID(), name: "Bean Burrito", detail: "Refried beans, onions, red sauce, cheese", price: 2.49, badge: nil)
                ]),
                MenuSection(title: "Combos", items: [
                    MenuItem(id: UUID(), name: "Cravings Box", detail: "Chalupa Supreme, Beefy 5-Layer, crunchy taco, chips & nacho cheese, medium drink", price: 7.99, badge: nil),
                    MenuItem(id: UUID(), name: "Nachos BellGrande", detail: "Seasoned beef, refried beans, nacho cheese, tomatoes, sour cream", price: 5.99, badge: nil)
                ])
            ]
        )

        let wingstop = Restaurant(
            id: UUID(),
            name: "Wingstop",
            cuisine: "Chicken",
            rating: 4.5,
            ratingCount: 2340,
            deliveryFee: "$0.00 delivery fee on $15+",
            eta: "20-35 min",
            distanceMiles: 2.6,
            heroColor: UIColor(red: 0.00, green: 0.50, blue: 0.25, alpha: 1),
            imageName: "wingstop_hero",
            tags: ["Chicken", "Offers"],
            menu: [
                MenuSection(title: "Classic Wings", items: [
                    MenuItem(id: UUID(), name: "Lemon Pepper Wings", detail: "10 pc bone-in, tossed in lemon pepper seasoning", price: 15.99, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Garlic Parmesan Wings", detail: "10 pc bone-in, tossed in garlic parmesan", price: 15.99, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Original Hot Wings", detail: "10 pc bone-in, classic buffalo hot sauce", price: 15.99, badge: nil)
                ]),
                MenuSection(title: "Boneless Wings", items: [
                    MenuItem(id: UUID(), name: "Boneless Lemon Pepper", detail: "10 pc boneless, lemon pepper seasoning", price: 14.29, badge: nil),
                    MenuItem(id: UUID(), name: "Boneless Hawaiian", detail: "10 pc boneless, sweet Hawaiian glaze", price: 14.29, badge: nil)
                ]),
                MenuSection(title: "Sides", items: [
                    MenuItem(id: UUID(), name: "Cajun Fried Corn", detail: "Seasoned corn on the cob", price: 3.99, badge: nil),
                    MenuItem(id: UUID(), name: "Seasoned Fries", detail: "Crispy seasoned fries", price: 4.49, badge: "Popular")
                ])
            ]
        )

        let popeyes = Restaurant(
            id: UUID(),
            name: "Popeyes",
            cuisine: "Chicken",
            rating: 4.4,
            ratingCount: 2780,
            deliveryFee: "$1.99 delivery fee",
            eta: "20-30 min",
            distanceMiles: 2.3,
            heroColor: UIColor(red: 0.93, green: 0.46, blue: 0.13, alpha: 1),
            imageName: "popeyes_hero",
            tags: ["Chicken", "Offers", "Catering"],
            menu: [
                MenuSection(title: "Chicken", items: [
                    MenuItem(id: UUID(), name: "Chicken Sandwich", detail: "Buttermilk battered chicken, barrel cured pickles, mayo, brioche bun", price: 6.99, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Spicy Chicken Sandwich", detail: "Spicy buttermilk battered chicken, barrel cured pickles, spicy mayo", price: 6.99, badge: "Popular"),
                    MenuItem(id: UUID(), name: "3 Pc Tenders", detail: "Hand-battered chicken tenders, choice of sauce", price: 7.49, badge: nil),
                    MenuItem(id: UUID(), name: "3 Pc Mixed Chicken", detail: "Mild or spicy, bone-in chicken", price: 8.99, badge: nil)
                ]),
                MenuSection(title: "Sides", items: [
                    MenuItem(id: UUID(), name: "Cajun Fries", detail: "Regular, seasoned with Cajun spices", price: 3.49, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Red Beans & Rice", detail: "Regular, slow-cooked with Cajun spices", price: 3.49, badge: nil),
                    MenuItem(id: UUID(), name: "Coleslaw", detail: "Regular, creamy Southern-style", price: 3.49, badge: nil)
                ]),
                MenuSection(title: "Biscuits & Desserts", items: [
                    MenuItem(id: UUID(), name: "Buttermilk Biscuit", detail: "Freshly baked, flaky and buttery", price: 1.79, badge: nil),
                    MenuItem(id: UUID(), name: "Cinnamon Apple Pie", detail: "Hand-held fried pie", price: 2.49, badge: nil)
                ])
            ]
        )

        let peets = Restaurant(
            id: UUID(),
            name: "Peet's Coffee",
            cuisine: "Coffee",
            rating: 4.6,
            ratingCount: 1890,
            deliveryFee: "$0.00 delivery fee on $15+",
            eta: "15-25 min",
            distanceMiles: 1.1,
            heroColor: UIColor(red: 0.32, green: 0.18, blue: 0.10, alpha: 1),
            imageName: "peets_hero",
            tags: ["Coffee", "Bakery", "Convenience"],
            menu: [
                MenuSection(title: "Espresso Drinks", items: [
                    MenuItem(id: UUID(), name: "Caffe Latte", detail: "Medium, rich espresso with steamed milk", price: 5.95, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Caramel Macchiato", detail: "Medium, vanilla, steamed milk, espresso, caramel", price: 6.45, badge: nil),
                    MenuItem(id: UUID(), name: "Mocha", detail: "Medium, espresso, chocolate, steamed milk, whipped cream", price: 6.25, badge: nil)
                ]),
                MenuSection(title: "Cold Drinks", items: [
                    MenuItem(id: UUID(), name: "Cold Brew", detail: "Medium, smooth, slow-steeped for 12 hours", price: 5.45, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Iced Matcha Latte", detail: "Medium, stone-ground matcha with milk", price: 6.25, badge: nil),
                    MenuItem(id: UUID(), name: "Javiva Blended Coffee", detail: "Medium, frozen blended mocha or caramel", price: 6.75, badge: nil)
                ]),
                MenuSection(title: "Food", items: [
                    MenuItem(id: UUID(), name: "Everything Croissant", detail: "Flaky croissant with everything seasoning, cream cheese", price: 4.95, badge: nil),
                    MenuItem(id: UUID(), name: "Almond Croissant", detail: "Buttery layers with almond cream filling", price: 4.75, badge: nil)
                ])
            ]
        )

        let mcdonalds = Restaurant(
            id: UUID(),
            name: "McDonald's",
            cuisine: "Burgers",
            rating: 4.2,
            ratingCount: 5800,
            deliveryFee: "$0.00 delivery fee on $12+",
            eta: "10-20 min",
            distanceMiles: 1.3,
            heroColor: UIColor(red: 0.85, green: 0.14, blue: 0.15, alpha: 1),
            imageName: "mcdonalds_hero",
            tags: ["Burgers", "Chicken", "Coffee", "Offers", "Desserts"],
            menu: [
                MenuSection(title: "Burgers", items: [
                    MenuItem(id: UUID(), name: "Big Mac", detail: "Two 100% beef patties, special sauce, lettuce, cheese, pickles, onions", price: 7.49, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Quarter Pounder with Cheese", detail: "Fresh beef patty, two slices of cheese, onions, pickles, mustard, ketchup", price: 7.89, badge: "Popular"),
                    MenuItem(id: UUID(), name: "McDouble", detail: "Two beef patties, American cheese, pickles, onions, ketchup, mustard", price: 3.89, badge: nil),
                    MenuItem(id: UUID(), name: "McChicken", detail: "Breaded chicken patty, mayonnaise, shredded lettuce", price: 3.49, badge: nil)
                ]),
                MenuSection(title: "McNuggets & Fries", items: [
                    MenuItem(id: UUID(), name: "10 Pc Chicken McNuggets", detail: "Tender chicken in a crispy coating, choice of sauce", price: 6.49, badge: "Popular"),
                    MenuItem(id: UUID(), name: "World Famous Fries", detail: "Medium, golden crispy fries with salt", price: 4.19, badge: nil)
                ]),
                MenuSection(title: "Desserts & Drinks", items: [
                    MenuItem(id: UUID(), name: "McFlurry with OREO", detail: "Vanilla soft serve with OREO cookie pieces", price: 5.29, badge: nil),
                    MenuItem(id: UUID(), name: "McCafé Iced Coffee", detail: "Medium, premium roast coffee on ice", price: 3.49, badge: nil)
                ])
            ]
        )

        let subway = Restaurant(
            id: UUID(),
            name: "Subway",
            cuisine: "Deli",
            rating: 4.3,
            ratingCount: 3200,
            deliveryFee: "$0.00 delivery fee on $15+",
            eta: "15-25 min",
            distanceMiles: 1.4,
            heroColor: UIColor(red: 0.00, green: 0.60, blue: 0.30, alpha: 1),
            imageName: "subway_hero",
            tags: ["Sandwiches", "Deli", "Offers", "Catering"],
            menu: [
                MenuSection(title: "Footlong Subs", items: [
                    MenuItem(id: UUID(), name: "Italian B.M.T.", detail: "Footlong, Genoa salami, spicy pepperoni, Black Forest ham", price: 10.49, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Turkey Breast", detail: "Footlong, sliced turkey breast, your choice of veggies", price: 9.49, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Steak & Cheese", detail: "Footlong, shaved steak, melted cheese, peppers, onions", price: 11.49, badge: nil),
                    MenuItem(id: UUID(), name: "Veggie Delite", detail: "Footlong, fresh veggies on freshly baked bread", price: 7.99, badge: nil)
                ]),
                MenuSection(title: "Wraps", items: [
                    MenuItem(id: UUID(), name: "Turkey Bacon Ranch Wrap", detail: "Turkey, bacon, ranch, veggies in a spinach wrap", price: 10.99, badge: nil),
                    MenuItem(id: UUID(), name: "Chicken Caesar Wrap", detail: "Rotisserie chicken, Caesar dressing, parmesan", price: 10.99, badge: nil)
                ]),
                MenuSection(title: "Sides & Drinks", items: [
                    MenuItem(id: UUID(), name: "Chips", detail: "Miss Vickie's kettle cooked chips", price: 2.19, badge: nil),
                    MenuItem(id: UUID(), name: "Chocolate Chip Cookie", detail: "Freshly baked, 2 pack", price: 2.49, badge: nil)
                ])
            ]
        )

        let pandaExpress = Restaurant(
            id: UUID(),
            name: "Panda Express",
            cuisine: "Chinese",
            rating: 4.4,
            ratingCount: 3450,
            deliveryFee: "$0.00 delivery fee on $15+",
            eta: "15-25 min",
            distanceMiles: 1.7,
            heroColor: UIColor(red: 0.80, green: 0.12, blue: 0.12, alpha: 1),
            imageName: "panda_express_hero",
            tags: ["Bowls", "Offers", "Catering"],
            menu: [
                MenuSection(title: "Plates", items: [
                    MenuItem(id: UUID(), name: "Orange Chicken Plate", detail: "Orange chicken with fried rice and chow mein", price: 10.90, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Beijing Beef Plate", detail: "Beijing beef with white steamed rice and super greens", price: 11.40, badge: nil),
                    MenuItem(id: UUID(), name: "Kung Pao Chicken Plate", detail: "Kung Pao chicken with fried rice and chow mein", price: 10.90, badge: nil)
                ]),
                MenuSection(title: "Entrees", items: [
                    MenuItem(id: UUID(), name: "Orange Chicken", detail: "Crispy chicken wok-tossed in sweet and spicy orange sauce", price: 6.90, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Grilled Teriyaki Chicken", detail: "Grilled chicken thigh hand-sliced and served with teriyaki sauce", price: 6.90, badge: nil),
                    MenuItem(id: UUID(), name: "Honey Walnut Shrimp", detail: "Large tempura shrimp, wok-tossed with honey sauce and glazed walnuts", price: 7.90, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Broccoli Beef", detail: "Tender beef and fresh broccoli in ginger soy sauce", price: 6.90, badge: nil)
                ]),
                MenuSection(title: "Appetizers", items: [
                    MenuItem(id: UUID(), name: "Chicken Egg Roll", detail: "2 pc, crispy wrapper filled with chicken and vegetables", price: 3.20, badge: nil),
                    MenuItem(id: UUID(), name: "Cream Cheese Rangoon", detail: "3 pc, crispy wonton filled with cream cheese", price: 3.20, badge: nil)
                ])
            ]
        )

        let crumbl = Restaurant(
            id: UUID(),
            name: "Crumbl Cookies",
            cuisine: "Bakery",
            rating: 4.7,
            ratingCount: 1650,
            deliveryFee: "$2.99 delivery fee",
            eta: "25-35 min",
            distanceMiles: 2.4,
            heroColor: UIColor(red: 0.96, green: 0.74, blue: 0.80, alpha: 1),
            imageName: "crumbl_hero",
            tags: ["Bakery", "Desserts", "Gifts"],
            menu: [
                MenuSection(title: "Weekly Rotating", items: [
                    MenuItem(id: UUID(), name: "Classic Pink Sugar", detail: "Thick, soft almond sugar cookie with pink frosting", price: 4.68, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Chocolate Chip", detail: "Semi-sweet chocolate chips in a thick, gooey cookie", price: 4.68, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Biscoff Lava", detail: "Warm cookie filled with Biscoff cookie butter", price: 4.68, badge: nil),
                    MenuItem(id: UUID(), name: "Churro", detail: "Cinnamon sugar cookie with cream cheese frosting", price: 4.68, badge: nil)
                ]),
                MenuSection(title: "Packs", items: [
                    MenuItem(id: UUID(), name: "4-Pack Box", detail: "Choose any 4 cookies from the weekly menu", price: 17.48, badge: "Popular"),
                    MenuItem(id: UUID(), name: "6-Pack Party Box", detail: "Choose any 6 cookies, perfect for sharing", price: 25.48, badge: "Giftable"),
                    MenuItem(id: UUID(), name: "12-Pack Catering Box", detail: "Choose any 12 cookies for events", price: 48.48, badge: nil)
                ])
            ]
        )

        let laTaqueria = Restaurant(
            id: UUID(),
            name: "La Taqueria",
            cuisine: "Mexican",
            rating: 4.8,
            ratingCount: 2640,
            deliveryFee: "$1.99 delivery fee",
            eta: "20-30 min",
            distanceMiles: 1.5,
            heroColor: UIColor(red: 0.85, green: 0.20, blue: 0.10, alpha: 1),
            imageName: "la_taqueria_hero",
            tags: ["Burrito", "Offers"],
            menu: [
                MenuSection(title: "Burritos", items: [
                    MenuItem(id: UUID(), name: "Super Burrito", detail: "Carne asada, beans, cheese, sour cream, avocado, salsa", price: 14.50, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Super Chicken Burrito", detail: "Grilled chicken, beans, cheese, sour cream, avocado, salsa", price: 13.50, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Carnitas Burrito", detail: "Slow-roasted pork, beans, cheese, sour cream, avocado", price: 13.50, badge: nil)
                ]),
                MenuSection(title: "Tacos", items: [
                    MenuItem(id: UUID(), name: "Carne Asada Taco", detail: "Two tacos, grilled steak, cilantro, onion, salsa", price: 8.50, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Al Pastor Taco", detail: "Two tacos, marinated pork, pineapple, cilantro, onion", price: 8.50, badge: nil),
                    MenuItem(id: UUID(), name: "Carnitas Taco", detail: "Two tacos, slow-roasted pork, cilantro, onion, salsa", price: 8.50, badge: nil)
                ]),
                MenuSection(title: "Plates", items: [
                    MenuItem(id: UUID(), name: "Carnitas Plate", detail: "Slow-roasted pork with rice, beans, salad, tortillas", price: 16.50, badge: nil),
                    MenuItem(id: UUID(), name: "Horchata", detail: "Large, sweet cinnamon rice milk", price: 4.50, badge: nil)
                ])
            ]
        )

        let souvla = Restaurant(
            id: UUID(),
            name: "Souvla",
            cuisine: "Greek",
            rating: 4.7,
            ratingCount: 1890,
            deliveryFee: "$0.99 delivery fee",
            eta: "20-30 min",
            distanceMiles: 0.9,
            heroColor: UIColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1),
            imageName: "souvla_hero",
            tags: ["Salads", "Bowls", "Premium"],
            menu: [
                MenuSection(title: "Wraps", items: [
                    MenuItem(id: UUID(), name: "Lamb Wrap", detail: "Slow-roasted lamb shoulder, tomato, onion, tzatziki, feta mousse, warm pita", price: 16.95, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Chicken Wrap", detail: "Rotisserie white-meat chicken, tomato, onion, tzatziki, feta mousse", price: 15.95, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Pork Wrap", detail: "Slow-roasted pork shoulder, tomato, onion, tzatziki, warm pita", price: 15.95, badge: nil),
                    MenuItem(id: UUID(), name: "Veggie Wrap", detail: "Roasted sweet potatoes, greens, barrel-aged feta, harissa", price: 14.95, badge: nil)
                ]),
                MenuSection(title: "Salads", items: [
                    MenuItem(id: UUID(), name: "Chicken Salad", detail: "Rotisserie white-meat chicken, romaine, tomato, onion, barrel-aged feta vinaigrette", price: 16.95, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Lamb Salad", detail: "Slow-roasted lamb, romaine, tomato, onion, barrel-aged feta vinaigrette", price: 17.95, badge: nil),
                    MenuItem(id: UUID(), name: "Veggie Salad", detail: "Roasted sweet potatoes, greens, barrel-aged feta, harissa vinaigrette", price: 14.95, badge: nil)
                ]),
                MenuSection(title: "Sides & Dessert", items: [
                    MenuItem(id: UUID(), name: "Greek Fries", detail: "Hand-cut fries, feta mousse, lemon, oregano", price: 7.50, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Roasted Vegetables", detail: "Seasonal roasted vegetables, olive oil, herbs", price: 6.95, badge: nil),
                    MenuItem(id: UUID(), name: "Frozen Greek Yogurt", detail: "Straus organic, seasonal toppings, baklava crumble", price: 6.95, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Baklava", detail: "Walnut and pistachio, honey syrup, phyllo", price: 5.95, badge: nil)
                ]),
                MenuSection(title: "Drinks", items: [
                    MenuItem(id: UUID(), name: "Greek Lemonade", detail: "Fresh-squeezed, honey, sparkling water", price: 4.50, badge: nil),
                    MenuItem(id: UUID(), name: "Iced Tea", detail: "House-brewed, unsweetened", price: 3.50, badge: nil)
                ])
            ]
        )

        let zyRestaurant = Restaurant(
            id: UUID(),
            name: "Z & Y Restaurant",
            cuisine: "Chinese",
            rating: 4.6,
            ratingCount: 2150,
            deliveryFee: "$1.99 delivery fee",
            eta: "25-40 min",
            distanceMiles: 1.4,
            heroColor: UIColor(red: 0.80, green: 0.15, blue: 0.10, alpha: 1),
            imageName: "z_and_y_hero",
            tags: ["Bowls", "Offers"],
            menu: [
                MenuSection(title: "Specialties", items: [
                    MenuItem(id: UUID(), name: "Spicy Popcorn Chicken", detail: "Crispy fried chicken tossed with dried chilies and Sichuan peppercorn", price: 16.95, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Cumin Lamb", detail: "Wok-fried lamb with cumin, chili flakes, cilantro", price: 18.95, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Mapo Tofu", detail: "Silken tofu in spicy chili-bean sauce with ground pork", price: 14.95, badge: nil)
                ]),
                MenuSection(title: "Noodles & Rice", items: [
                    MenuItem(id: UUID(), name: "Dan Dan Noodles", detail: "Wheat noodles in sesame-chili sauce with ground pork", price: 13.95, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Kung Pao Shrimp", detail: "Wok-fried shrimp, peanuts, dried chilies, bell peppers", price: 17.95, badge: nil),
                    MenuItem(id: UUID(), name: "Fried Rice with XO Sauce", detail: "Wok-tossed rice with egg, scallions, XO sauce", price: 14.95, badge: nil)
                ]),
                MenuSection(title: "Appetizers", items: [
                    MenuItem(id: UUID(), name: "Wontons in Chili Oil", detail: "Pork and shrimp wontons in spicy chili oil", price: 11.95, badge: nil),
                    MenuItem(id: UUID(), name: "Scallion Pancake", detail: "Pan-fried crispy layers, served with soy dipping sauce", price: 8.95, badge: nil),
                    MenuItem(id: UUID(), name: "Dry-Fried Green Beans", detail: "Blistered green beans, ground pork, pickled vegetables", price: 12.95, badge: nil),
                    MenuItem(id: UUID(), name: "Cold Noodles with Sesame", detail: "Chilled wheat noodles, sesame paste, chili oil, cucumber", price: 11.95, badge: nil)
                ]),
                MenuSection(title: "Soups", items: [
                    MenuItem(id: UUID(), name: "Fish Fillet in Chili Broth", detail: "Sliced fish fillet, Sichuan peppercorn, dried chilies, bean sprouts", price: 22.95, badge: nil),
                    MenuItem(id: UUID(), name: "Hot & Sour Soup", detail: "Tofu, wood ear, bamboo, egg, white pepper", price: 10.95, badge: nil)
                ])
            ]
        )

        let dumplingHome = Restaurant(
            id: UUID(),
            name: "Dumpling Home",
            cuisine: "Chinese",
            rating: 4.7,
            ratingCount: 1420,
            deliveryFee: "$0.99 delivery fee",
            eta: "20-30 min",
            distanceMiles: 0.5,
            heroColor: UIColor(red: 0.92, green: 0.35, blue: 0.22, alpha: 1),
            imageName: "dumpling_home_hero",
            tags: ["Bowls", "Offers"],
            menu: [
                MenuSection(title: "Dumplings", items: [
                    MenuItem(id: UUID(), name: "Soup Dumplings (Xiao Long Bao)", detail: "8 pc, pork filling with rich broth inside", price: 13.95, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Pan-Fried Pork Buns", detail: "4 pc, crispy bottom, juicy pork filling", price: 10.95, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Shrimp & Pork Dumplings", detail: "8 pc, steamed, ginger-soy dipping sauce", price: 14.95, badge: nil),
                    MenuItem(id: UUID(), name: "Vegetable Dumplings", detail: "8 pc, steamed, cabbage, mushroom, chive filling", price: 12.95, badge: nil),
                    MenuItem(id: UUID(), name: "Crab XLB", detail: "6 pc, crab and pork soup dumplings, seasonal", price: 16.95, badge: "Popular")
                ]),
                MenuSection(title: "Noodles & Rice", items: [
                    MenuItem(id: UUID(), name: "Dan Dan Noodles", detail: "Wheat noodles, spicy sesame sauce, ground pork, pickled greens", price: 13.95, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Cold Sesame Noodles", detail: "Chilled noodles, sesame paste, cucumber, scallion", price: 12.95, badge: nil),
                    MenuItem(id: UUID(), name: "Braised Beef Noodle Soup", detail: "Slow-braised beef, hand-pulled noodles, bok choy, five-spice broth", price: 16.95, badge: nil),
                    MenuItem(id: UUID(), name: "Fried Rice", detail: "Egg, scallion, choice of pork, chicken, or shrimp", price: 13.95, badge: nil)
                ]),
                MenuSection(title: "Appetizers & Sides", items: [
                    MenuItem(id: UUID(), name: "Crispy Scallion Pancake", detail: "Layers of flaky, pan-fried dough with scallions", price: 8.95, badge: nil),
                    MenuItem(id: UUID(), name: "Cucumber Salad", detail: "Smashed cucumber, garlic, chili oil, sesame", price: 7.95, badge: nil),
                    MenuItem(id: UUID(), name: "Wontons in Chili Oil", detail: "8 pc, pork wontons, Sichuan chili oil, garlic", price: 11.95, badge: nil),
                    MenuItem(id: UUID(), name: "Hot & Sour Soup", detail: "Tofu, egg, bamboo, mushroom, white pepper", price: 8.95, badge: nil)
                ]),
                MenuSection(title: "Drinks", items: [
                    MenuItem(id: UUID(), name: "Jasmine Tea (Pot)", detail: "Traditional jasmine green tea, serves 2", price: 4.50, badge: nil),
                    MenuItem(id: UUID(), name: "Plum Juice", detail: "House-made Chinese plum juice, chilled", price: 3.95, badge: nil)
                ])
            ]
        )

        let marufuku = Restaurant(
            id: UUID(),
            name: "Marufuku Ramen",
            cuisine: "Japanese",
            rating: 4.8,
            ratingCount: 2890,
            deliveryFee: "$2.99 delivery fee",
            eta: "25-40 min",
            distanceMiles: 1.9,
            heroColor: UIColor(red: 0.15, green: 0.12, blue: 0.10, alpha: 1),
            imageName: "marufuku_hero",
            tags: ["Sushi", "Premium"],
            menu: [
                MenuSection(title: "Ramen", items: [
                    MenuItem(id: UUID(), name: "Hakata Tonkotsu", detail: "Rich pork bone broth, thin noodles, chashu, soft egg, nori, scallions", price: 17.50, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Chicken Paitan", detail: "Creamy chicken broth, thin noodles, chicken chashu, soft egg, fried garlic", price: 17.50, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Spicy Tonkotsu", detail: "Pork bone broth with spicy miso, ground pork, bean sprouts, scallions", price: 18.50, badge: nil),
                    MenuItem(id: UUID(), name: "Vegetarian Ramen", detail: "Mushroom-kombu broth, seasonal vegetables, tofu, thin noodles", price: 16.50, badge: nil),
                    MenuItem(id: UUID(), name: "Tsukemen (Dipping Ramen)", detail: "Thick noodles served cold, rich pork dipping broth, chashu, soft egg", price: 18.50, badge: "Popular")
                ]),
                MenuSection(title: "Appetizers", items: [
                    MenuItem(id: UUID(), name: "Gyoza", detail: "6 pc, pan-fried pork dumplings with ponzu", price: 8.50, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Karaage", detail: "Japanese fried chicken thigh, yuzu mayo, shredded cabbage", price: 9.50, badge: nil),
                    MenuItem(id: UUID(), name: "Takoyaki", detail: "6 pc, octopus fritters, bonito flakes, aonori, kewpie", price: 9.00, badge: nil),
                    MenuItem(id: UUID(), name: "Edamame", detail: "Steamed soybeans, sea salt", price: 5.50, badge: nil)
                ]),
                MenuSection(title: "Extras & Drinks", items: [
                    MenuItem(id: UUID(), name: "Extra Chashu", detail: "3 slices of braised pork belly", price: 4.50, badge: nil),
                    MenuItem(id: UUID(), name: "Ajitama (Soft Egg)", detail: "Marinated soft-boiled egg", price: 2.50, badge: nil),
                    MenuItem(id: UUID(), name: "Rice", detail: "Steamed Japanese short-grain rice", price: 2.50, badge: nil),
                    MenuItem(id: UUID(), name: "Ramune Soda", detail: "Japanese marble soda, original flavor", price: 3.50, badge: nil)
                ])
            ]
        )

        let burmaSuperstar = Restaurant(
            id: UUID(),
            name: "Burma Superstar",
            cuisine: "Burmese",
            rating: 4.7,
            ratingCount: 3120,
            deliveryFee: "$2.99 delivery fee",
            eta: "30-45 min",
            distanceMiles: 3.0,
            heroColor: UIColor(red: 0.72, green: 0.18, blue: 0.22, alpha: 1),
            imageName: "burma_superstar_hero",
            tags: ["Bowls", "Premium"],
            menu: [
                MenuSection(title: "Signature Salads", items: [
                    MenuItem(id: UUID(), name: "Tea Leaf Salad", detail: "Fermented tea leaves, peanuts, sesame, dried shrimp, tomato, jalapeño", price: 14.95, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Rainbow Salad", detail: "22-ingredient salad tossed tableside with lime dressing", price: 13.95, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Ginger Salad", detail: "Fresh ginger, peanuts, sesame, fried garlic, shredded cabbage, lime", price: 13.95, badge: nil)
                ]),
                MenuSection(title: "Curries & Mains", items: [
                    MenuItem(id: UUID(), name: "Coconut Chicken Noodle Soup", detail: "Khao swe, egg noodles in coconut-turmeric broth, crispy noodle topping", price: 16.95, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Mango Shrimp Curry", detail: "Tiger prawns in mango curry, basil, served with rice", price: 19.95, badge: nil),
                    MenuItem(id: UUID(), name: "Pork Belly Curry", detail: "Slow-braised pork belly, potato, coconut milk, turmeric, rice", price: 18.95, badge: nil),
                    MenuItem(id: UUID(), name: "Fiery Tofu", detail: "Crispy tofu, jalapeño, onion, tomato, spicy sauce, rice", price: 15.95, badge: nil)
                ]),
                MenuSection(title: "Noodles & Rice", items: [
                    MenuItem(id: UUID(), name: "Nan Gyi Thoke", detail: "Thick rice noodles, chicken, chickpea flour, onion, chili flakes", price: 15.95, badge: nil),
                    MenuItem(id: UUID(), name: "Garlic Noodles", detail: "Egg noodles, garlic, butter, parmesan, scallions", price: 13.95, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Samusa Soup", detail: "Samosa-stuffed soup with chicken, chickpeas, cilantro, lemon", price: 12.95, badge: nil)
                ]),
                MenuSection(title: "Appetizers", items: [
                    MenuItem(id: UUID(), name: "Platha with Potatoes", detail: "Flaky layered bread, curried potato dip", price: 9.95, badge: nil),
                    MenuItem(id: UUID(), name: "Samusa", detail: "2 pc, crispy fried pastry, curried potatoes, peas, onion", price: 7.95, badge: nil),
                    MenuItem(id: UUID(), name: "Fried Yellow Bean Tofu", detail: "Crispy chickpea tofu, tamarind dipping sauce", price: 8.95, badge: nil)
                ])
            ]
        )

        let tonys = Restaurant(
            id: UUID(),
            name: "Tony's Pizza Napoletana",
            cuisine: "Pizza",
            rating: 4.8,
            ratingCount: 2340,
            deliveryFee: "$2.99 delivery fee",
            eta: "30-45 min",
            distanceMiles: 1.6,
            heroColor: UIColor(red: 0.18, green: 0.45, blue: 0.20, alpha: 1),
            imageName: "tonys_pizza_hero",
            tags: ["Pizza", "Premium"],
            menu: [
                MenuSection(title: "Napoletana", items: [
                    MenuItem(id: UUID(), name: "Margherita", detail: "San Marzano tomatoes, fresh mozzarella, basil, EVOO", price: 19.95, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Diavola", detail: "Tomato, mozzarella, spicy salami, Calabrian chili, honey drizzle", price: 22.95, badge: nil),
                    MenuItem(id: UUID(), name: "Burrata e Prosciutto", detail: "Tomato, burrata, prosciutto di Parma, arugula", price: 24.95, badge: "Popular")
                ]),
                MenuSection(title: "NY & Detroit Style", items: [
                    MenuItem(id: UUID(), name: "Coal-Fired New Yorker", detail: "Large slice, classic NY-style, mozzarella, tomato sauce", price: 6.95, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Detroit Style", detail: "Square pan pizza, brick cheese, pepperoni, racing stripe sauce", price: 21.95, badge: nil)
                ]),
                MenuSection(title: "Starters", items: [
                    MenuItem(id: UUID(), name: "Fried Mozzarella", detail: "Mozzarella in carrozza with marinara", price: 12.95, badge: nil),
                    MenuItem(id: UUID(), name: "Caesar Salad", detail: "Romaine, garlic croutons, parmesan, anchovy dressing", price: 13.95, badge: nil)
                ])
            ]
        )

        let hogIsland = Restaurant(
            id: UUID(),
            name: "Hog Island Oyster Co.",
            cuisine: "Seafood",
            rating: 4.8,
            ratingCount: 1680,
            deliveryFee: "$3.99 delivery fee",
            eta: "30-45 min",
            distanceMiles: 1.0,
            heroColor: UIColor(red: 0.22, green: 0.42, blue: 0.55, alpha: 1),
            imageName: "hog_island_hero",
            tags: ["Premium"],
            menu: [
                MenuSection(title: "Oysters", items: [
                    MenuItem(id: UUID(), name: "Sweetwater Oysters", detail: "Half dozen, Tomales Bay, mignonette & cocktail sauce", price: 21.00, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Grilled Cheese & Oysters", detail: "3 oysters topped with garlic-herb butter, parmesan, grilled", price: 16.50, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Oyster Sampler", detail: "1 dozen mixed varietals from Tomales Bay", price: 38.00, badge: nil)
                ]),
                MenuSection(title: "Mains", items: [
                    MenuItem(id: UUID(), name: "Manila Clam Chowder", detail: "Creamy New England-style with potatoes, leeks, bacon", price: 14.50, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Grilled Fish Sandwich", detail: "Local catch, cabbage slaw, tartar sauce, brioche bun", price: 18.50, badge: nil),
                    MenuItem(id: UUID(), name: "Steamed Mussels", detail: "White wine, garlic, herbs, grilled bread", price: 19.00, badge: nil)
                ]),
                MenuSection(title: "Drinks", items: [
                    MenuItem(id: UUID(), name: "Bloody Mary", detail: "House-made mix with vodka and a Sweetwater oyster", price: 16.00, badge: nil),
                    MenuItem(id: UUID(), name: "Local White Wine", detail: "Glass, rotating winery selection", price: 14.00, badge: nil)
                ])
            ]
        )

        let nari = Restaurant(
            id: UUID(),
            name: "Nari",
            cuisine: "Thai",
            rating: 4.8,
            ratingCount: 980,
            deliveryFee: "$2.99 delivery fee",
            eta: "30-45 min",
            distanceMiles: 1.8,
            heroColor: UIColor(red: 0.58, green: 0.30, blue: 0.55, alpha: 1),
            imageName: "nari_hero",
            tags: ["Bowls", "Premium"],
            menu: [
                MenuSection(title: "Mains", items: [
                    MenuItem(id: UUID(), name: "Khao Soi", detail: "Northern Thai curry noodles, chicken leg, pickled mustard greens, crispy noodles", price: 24.00, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Coconut Curry", detail: "Rich red curry, seasonal vegetables, Thai basil, jasmine rice", price: 22.00, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Laab Muu", detail: "Spicy ground pork salad, toasted rice, herbs, sticky rice", price: 19.00, badge: nil)
                ]),
                MenuSection(title: "Small Plates", items: [
                    MenuItem(id: UUID(), name: "Papaya Salad", detail: "Green papaya, peanuts, dried shrimp, chili, lime", price: 15.00, badge: nil),
                    MenuItem(id: UUID(), name: "Fried Chicken Wings", detail: "Fish sauce marinated, served with tamarind sauce", price: 16.00, badge: "Popular")
                ]),
                MenuSection(title: "Desserts", items: [
                    MenuItem(id: UUID(), name: "Sticky Rice Dessert", detail: "Coconut sticky rice, mango, toasted coconut", price: 14.00, badge: nil),
                    MenuItem(id: UUID(), name: "Pandan Custard", detail: "Steamed pandan custard, coconut cream, palm sugar", price: 12.00, badge: nil)
                ])
            ]
        )

        let flourWater = Restaurant(
            id: UUID(),
            name: "Flour + Water",
            cuisine: "Italian",
            rating: 4.8,
            ratingCount: 2450,
            deliveryFee: "$2.99 delivery fee",
            eta: "30-45 min",
            distanceMiles: 1.4,
            heroColor: UIColor(red: 0.85, green: 0.75, blue: 0.60, alpha: 1),
            imageName: "flour_water_hero",
            tags: ["Pizza", "Premium"],
            menu: [
                MenuSection(title: "Pasta", items: [
                    MenuItem(id: UUID(), name: "Daily Pasta", detail: "Handmade, chef's choice of seasonal pasta and sauce", price: 24.00, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Spaghetti Pomodoro", detail: "San Marzano tomato sauce, basil, garlic, parmesan", price: 21.00, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Cacio e Pepe", detail: "Tonnarelli, pecorino Romano, black pepper", price: 22.00, badge: nil)
                ]),
                MenuSection(title: "Pizza & Starters", items: [
                    MenuItem(id: UUID(), name: "Margherita Pizza", detail: "Wood-fired, tomato, fior di latte, basil", price: 19.00, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Burrata", detail: "Pugliese burrata, seasonal accompaniment, grilled bread", price: 18.00, badge: nil)
                ]),
                MenuSection(title: "Desserts", items: [
                    MenuItem(id: UUID(), name: "Panna Cotta", detail: "Vanilla bean, seasonal fruit compote", price: 12.00, badge: nil),
                    MenuItem(id: UUID(), name: "Tiramisu", detail: "Espresso-soaked ladyfingers, mascarpone, cocoa", price: 14.00, badge: nil)
                ])
            ]
        )

        let sightglass = Restaurant(
            id: UUID(),
            name: "Sightglass Coffee",
            cuisine: "Coffee",
            rating: 4.7,
            ratingCount: 1340,
            deliveryFee: "$0.99 delivery fee",
            eta: "15-25 min",
            distanceMiles: 0.6,
            heroColor: UIColor(red: 0.25, green: 0.22, blue: 0.20, alpha: 1),
            imageName: "sightglass_hero",
            tags: ["Coffee", "Bakery"],
            menu: [
                MenuSection(title: "Espresso", items: [
                    MenuItem(id: UUID(), name: "Cortado", detail: "Double shot espresso, equal parts steamed milk", price: 5.50, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Cappuccino", detail: "Double shot espresso, velvety steamed milk foam", price: 5.75, badge: nil),
                    MenuItem(id: UUID(), name: "Latte", detail: "Double shot espresso, steamed milk", price: 6.00, badge: nil)
                ]),
                MenuSection(title: "Brewed & Cold", items: [
                    MenuItem(id: UUID(), name: "Pour Over", detail: "Single-origin, brewed to order", price: 6.50, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Cold Brew", detail: "12 oz, steeped overnight, smooth and bold", price: 5.50, badge: nil),
                    MenuItem(id: UUID(), name: "Affogato", detail: "Vanilla gelato, double shot espresso", price: 7.50, badge: nil)
                ]),
                MenuSection(title: "Food", items: [
                    MenuItem(id: UUID(), name: "Avocado Toast", detail: "Sourdough, smashed avocado, chili flake, lemon, radish", price: 12.50, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Morning Bun", detail: "Flaky pastry with orange zest and cinnamon sugar", price: 5.50, badge: nil)
                ])
            ]
        )

        let tartine = Restaurant(
            id: UUID(),
            name: "Tartine Manufactory",
            cuisine: "Bakery",
            rating: 4.8,
            ratingCount: 2180,
            deliveryFee: "$1.99 delivery fee",
            eta: "25-35 min",
            distanceMiles: 1.2,
            heroColor: UIColor(red: 0.92, green: 0.88, blue: 0.80, alpha: 1),
            imageName: "tartine_hero",
            tags: ["Bakery", "Coffee", "Sandwiches", "Premium"],
            menu: [
                MenuSection(title: "Bakery", items: [
                    MenuItem(id: UUID(), name: "Morning Bun", detail: "Orange-scented, sugar-crusted croissant pastry", price: 5.75, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Country Bread", detail: "Whole loaf, naturally leavened, crusty sourdough", price: 12.50, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Almond Croissant", detail: "Twice-baked with almond frangipane and sliced almonds", price: 6.50, badge: nil)
                ]),
                MenuSection(title: "Savory", items: [
                    MenuItem(id: UUID(), name: "Smoked Trout Tartine", detail: "Open-faced on country bread, crème fraîche, pickled onion, capers", price: 16.50, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Seasonal Galette", detail: "Savory pastry with seasonal vegetables and cheese", price: 14.50, badge: nil),
                    MenuItem(id: UUID(), name: "Egg Sandwich", detail: "Scrambled eggs, gruyère, arugula on country bread", price: 13.50, badge: nil)
                ]),
                MenuSection(title: "Drinks", items: [
                    MenuItem(id: UUID(), name: "Drip Coffee", detail: "House blend, 12 oz", price: 4.50, badge: nil),
                    MenuItem(id: UUID(), name: "Matcha Latte", detail: "Ceremonial grade matcha, steamed milk", price: 6.50, badge: nil)
                ])
            ]
        )

        // ── SF locals from Beli ────────────────────────────────────

        let elFarolito = Restaurant(
            id: UUID(),
            name: "El Farolito",
            cuisine: "Mexican",
            rating: 4.6,
            ratingCount: 4150,
            deliveryFee: "$1.99 delivery fee",
            eta: "15-25 min",
            distanceMiles: 1.8,
            heroColor: UIColor(red: 0.90, green: 0.22, blue: 0.15, alpha: 1),
            imageName: "el_farolito_hero",
            tags: ["Burrito", "Offers"],
            menu: [
                MenuSection(title: "Burritos", items: [
                    MenuItem(id: UUID(), name: "Super Burrito", detail: "Choice of meat, rice, beans, cheese, sour cream, guacamole, salsa", price: 13.95, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Regular Burrito", detail: "Choice of meat, rice, beans, salsa", price: 10.95, badge: nil),
                    MenuItem(id: UUID(), name: "Veggie Burrito", detail: "Rice, beans, cheese, sour cream, guacamole, lettuce, salsa", price: 10.50, badge: nil)
                ]),
                MenuSection(title: "Tacos & Quesadillas", items: [
                    MenuItem(id: UUID(), name: "Quesadilla Suiza", detail: "Flour tortilla, choice of meat, melted cheese, sour cream, guacamole", price: 12.95, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Tacos", detail: "Three soft corn tacos, choice of meat, cilantro, onion, salsa", price: 9.50, badge: nil)
                ]),
                MenuSection(title: "Plates & Drinks", items: [
                    MenuItem(id: UUID(), name: "Nachos", detail: "Chips, choice of meat, beans, cheese, sour cream, guacamole, jalapeños", price: 13.50, badge: nil),
                    MenuItem(id: UUID(), name: "Agua Fresca", detail: "Large, horchata or jamaica", price: 4.50, badge: nil)
                ])
            ]
        )

        let sanTung = Restaurant(
            id: UUID(),
            name: "San Tung",
            cuisine: "Chinese",
            rating: 4.7,
            ratingCount: 3580,
            deliveryFee: "$2.99 delivery fee",
            eta: "30-45 min",
            distanceMiles: 3.2,
            heroColor: UIColor(red: 0.75, green: 0.18, blue: 0.12, alpha: 1),
            imageName: "san_tung_hero",
            tags: ["Chicken", "Bowls"],
            menu: [
                MenuSection(title: "House Specialties", items: [
                    MenuItem(id: UUID(), name: "Dry-Fried Chicken Wings", detail: "Crispy fried wings in sweet-spicy glaze, sesame seeds", price: 15.95, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Salt & Pepper Calamari", detail: "Lightly battered, fried with jalapeños, onions, and scallions", price: 14.95, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Kung Pao Chicken", detail: "Diced chicken, peanuts, dried chilies, bell peppers, celery", price: 15.95, badge: nil),
                    MenuItem(id: UUID(), name: "Honey Walnut Prawns", detail: "Crispy prawns, candied walnuts, creamy mayo sauce", price: 18.95, badge: nil)
                ]),
                MenuSection(title: "Noodles", items: [
                    MenuItem(id: UUID(), name: "Dan Dan Noodles", detail: "Wheat noodles, spicy peanut-sesame sauce, ground pork, bok choy", price: 13.95, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Chow Mein", detail: "Pan-fried egg noodles, vegetables, choice of chicken, pork, or shrimp", price: 14.95, badge: nil),
                    MenuItem(id: UUID(), name: "Beef Chow Fun", detail: "Wide rice noodles, beef, bean sprouts, scallions, soy sauce", price: 15.95, badge: nil)
                ]),
                MenuSection(title: "Rice Plates", items: [
                    MenuItem(id: UUID(), name: "Fried Rice", detail: "Egg, scallions, choice of chicken, pork, or shrimp", price: 13.95, badge: nil),
                    MenuItem(id: UUID(), name: "Orange Chicken Rice", detail: "Crispy chicken, orange glaze, steamed rice, broccoli", price: 14.95, badge: nil)
                ]),
                MenuSection(title: "Appetizers & Soup", items: [
                    MenuItem(id: UUID(), name: "Wontons in Chili Oil", detail: "Pork wontons, spicy chili oil, garlic, Sichuan peppercorn", price: 12.95, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Pot Stickers", detail: "8 pc, pan-fried pork dumplings, soy-vinegar dipping sauce", price: 10.95, badge: nil),
                    MenuItem(id: UUID(), name: "Hot & Sour Soup", detail: "Tofu, mushrooms, bamboo shoots, egg, white pepper", price: 9.95, badge: nil),
                    MenuItem(id: UUID(), name: "Egg Flower Soup", detail: "Light broth, egg ribbons, scallions", price: 8.95, badge: nil)
                ])
            ]
        )

        let zuniCafe = Restaurant(
            id: UUID(),
            name: "Zuni Cafe",
            cuisine: "American",
            rating: 4.8,
            ratingCount: 1920,
            deliveryFee: "$3.99 delivery fee",
            eta: "35-50 min",
            distanceMiles: 0.7,
            heroColor: UIColor(red: 0.88, green: 0.82, blue: 0.72, alpha: 1),
            imageName: "zuni_cafe_hero",
            tags: ["Chicken", "Salads", "Premium"],
            menu: [
                MenuSection(title: "Mains", items: [
                    MenuItem(id: UUID(), name: "Roast Chicken for Two", detail: "Brick-oven roasted with warm bread salad, currants, pine nuts (allow 1 hour)", price: 72.00, badge: "Signature"),
                    MenuItem(id: UUID(), name: "Burger", detail: "Niman Ranch beef, pickled zucchini relish, aioli, house focaccia", price: 22.50, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Grilled Fish", detail: "Market fish, seasonal vegetables, herb vinaigrette", price: 34.00, badge: nil),
                    MenuItem(id: UUID(), name: "Ribollita", detail: "Tuscan bread soup, cannellini beans, kale, parmesan, olive oil", price: 18.00, badge: nil),
                    MenuItem(id: UUID(), name: "Handmade Pappardelle", detail: "Fresh pasta, braised rabbit, wild mushrooms, parmesan", price: 28.00, badge: nil)
                ]),
                MenuSection(title: "Starters & Salads", items: [
                    MenuItem(id: UUID(), name: "Caesar Salad", detail: "Little gem lettuce, anchovy dressing, parmesan, garlic croutons", price: 18.00, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Shoestring Fries", detail: "Crispy thin-cut, served with aioli", price: 12.00, badge: "Popular"),
                    MenuItem(id: UUID(), name: "House-Cured Anchovies", detail: "White anchovies, celery, parmesan, lemon, olive oil", price: 16.00, badge: nil),
                    MenuItem(id: UUID(), name: "Beet Salad", detail: "Roasted beets, goat cheese, walnuts, frisée, sherry vinaigrette", price: 17.00, badge: nil)
                ]),
                MenuSection(title: "Desserts", items: [
                    MenuItem(id: UUID(), name: "Espresso Granita", detail: "Frozen espresso, whipped cream", price: 10.00, badge: nil),
                    MenuItem(id: UUID(), name: "Seasonal Fruit Crostata", detail: "Rustic tart, crème fraîche, seasonal fruit", price: 14.00, badge: nil),
                    MenuItem(id: UUID(), name: "Chocolate Pots de Crème", detail: "Rich chocolate custard, whipped cream, cocoa nib", price: 12.00, badge: nil)
                ])
            ]
        )

        let nopalito = Restaurant(
            id: UUID(),
            name: "Nopalito",
            cuisine: "Mexican",
            rating: 4.7,
            ratingCount: 1870,
            deliveryFee: "$1.99 delivery fee",
            eta: "25-35 min",
            distanceMiles: 1.6,
            heroColor: UIColor(red: 0.25, green: 0.55, blue: 0.35, alpha: 1),
            imageName: "nopalito_hero",
            tags: ["Burrito", "Premium"],
            menu: [
                MenuSection(title: "Platos Fuertes", items: [
                    MenuItem(id: UUID(), name: "Carnitas", detail: "Slow-braised heritage pork, handmade tortillas, salsa verde, beans, rice", price: 19.50, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Pozole Rojo", detail: "Hominy stew, pork, dried chili broth, radish, cabbage, oregano", price: 16.50, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Enchiladas Suizas", detail: "Chicken, tomatillo cream, Oaxacan cheese, crema, rice, beans", price: 18.50, badge: nil),
                    MenuItem(id: UUID(), name: "Mole Negro Chicken", detail: "Free-range chicken, house-made mole negro, rice, handmade tortillas", price: 21.00, badge: nil)
                ]),
                MenuSection(title: "Tacos & Antojitos", items: [
                    MenuItem(id: UUID(), name: "Fish Taco", detail: "Beer-battered rock cod, cabbage, crema, pickled jalapeño", price: 8.50, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Quesadilla de Hongos", detail: "Wild mushrooms, Oaxacan cheese, handmade corn tortilla, salsa roja", price: 15.50, badge: nil),
                    MenuItem(id: UUID(), name: "Tamale", detail: "Seasonal filling, masa, banana leaf, salsa", price: 9.00, badge: nil),
                    MenuItem(id: UUID(), name: "Elote", detail: "Grilled corn, mayo, cotija cheese, chili powder, lime", price: 7.50, badge: "Popular")
                ]),
                MenuSection(title: "Sopas & Ensaladas", items: [
                    MenuItem(id: UUID(), name: "Tortilla Soup", detail: "Pasilla broth, avocado, crema, queso fresco, tortilla strips", price: 12.00, badge: nil),
                    MenuItem(id: UUID(), name: "Ensalada de Nopales", detail: "Grilled cactus, tomato, onion, cilantro, queso fresco, lime", price: 11.50, badge: nil)
                ]),
                MenuSection(title: "Postres & Bebidas", items: [
                    MenuItem(id: UUID(), name: "Churros", detail: "Fried dough, cinnamon sugar, chocolate dipping sauce", price: 9.50, badge: nil),
                    MenuItem(id: UUID(), name: "Flan", detail: "Classic caramel custard, seasonal fruit", price: 10.00, badge: nil),
                    MenuItem(id: UUID(), name: "Horchata", detail: "House-made rice milk, cinnamon, vanilla", price: 5.00, badge: nil),
                    MenuItem(id: UUID(), name: "Agua Fresca", detail: "Seasonal fruit water, rotating flavors", price: 4.50, badge: nil)
                ])
            ]
        )

        let kinKhao = Restaurant(
            id: UUID(),
            name: "Kin Khao",
            cuisine: "Thai",
            rating: 4.8,
            ratingCount: 1340,
            deliveryFee: "$2.99 delivery fee",
            eta: "25-40 min",
            distanceMiles: 0.9,
            heroColor: UIColor(red: 0.95, green: 0.80, blue: 0.20, alpha: 1),
            imageName: "kin_khao_hero",
            tags: ["Bowls", "Premium"],
            menu: [
                MenuSection(title: "Curries", items: [
                    MenuItem(id: UUID(), name: "Crab Curry", detail: "Dungeness crab, coconut curry, betel leaves, Thai basil, jasmine rice", price: 32.00, badge: "Signature"),
                    MenuItem(id: UUID(), name: "Khao Soi", detail: "Northern Thai curry, egg noodles, chicken leg, pickled mustard, crispy shallots", price: 22.00, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Massaman Curry", detail: "Slow-braised short rib, potato, peanut, tamarind, jasmine rice", price: 26.00, badge: nil),
                    MenuItem(id: UUID(), name: "Green Curry", detail: "Seasonal vegetables, Thai eggplant, basil, coconut milk, jasmine rice", price: 19.00, badge: nil)
                ]),
                MenuSection(title: "Mains", items: [
                    MenuItem(id: UUID(), name: "Pad Kra Pao", detail: "Stir-fried ground pork, holy basil, chili, fried egg, jasmine rice", price: 19.00, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Grilled Pork Collar", detail: "Marinated pork collar, jaew dipping sauce, sticky rice, herbs", price: 24.00, badge: nil),
                    MenuItem(id: UUID(), name: "Whole Fried Fish", detail: "Market fish, three-flavor sauce, herbs, crispy shallots", price: 34.00, badge: nil)
                ]),
                MenuSection(title: "Small Plates", items: [
                    MenuItem(id: UUID(), name: "Papaya Salad", detail: "Green papaya, dried shrimp, peanuts, tomato, long bean, chili-lime", price: 14.00, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Miang Kham", detail: "Betel leaf wraps, peanuts, dried shrimp, ginger, lime, chili, toasted coconut", price: 15.00, badge: nil),
                    MenuItem(id: UUID(), name: "Crispy Rice Salad", detail: "Puffed rice, sour sausage, peanuts, herbs, lime dressing", price: 16.00, badge: nil)
                ]),
                MenuSection(title: "Desserts", items: [
                    MenuItem(id: UUID(), name: "Coconut Cake", detail: "Pandan coconut sponge, coconut cream, toasted coconut", price: 12.00, badge: nil),
                    MenuItem(id: UUID(), name: "Sticky Rice with Mango", detail: "Sweet sticky rice, ripe mango, coconut cream", price: 13.00, badge: "Popular")
                ])
            ]
        )

        let stateBird = Restaurant(
            id: UUID(),
            name: "State Bird Provisions",
            cuisine: "American",
            rating: 4.9,
            ratingCount: 1150,
            deliveryFee: "$3.99 delivery fee",
            eta: "35-50 min",
            distanceMiles: 1.5,
            heroColor: UIColor(red: 0.30, green: 0.35, blue: 0.45, alpha: 1),
            imageName: "state_bird_hero",
            tags: ["Premium"],
            menu: [
                MenuSection(title: "Provisions (Dim Sum Style)", items: [
                    MenuItem(id: UUID(), name: "State Bird with Provisions", detail: "Quail, sunchoke purée, stewed onions, spiced garum", price: 18.00, badge: "Signature"),
                    MenuItem(id: UUID(), name: "Garlic Bread with Burrata", detail: "Wood-fired garlic bread, burrata, seasonal jam", price: 16.00, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Duck Liver Mousse", detail: "Silky mousse, grilled bread, pickled shallots, herbs", price: 15.00, badge: nil),
                    MenuItem(id: UUID(), name: "Yellowtail Collar", detail: "Grilled hamachi collar, citrus ponzu, pickled daikon", price: 19.00, badge: nil),
                    MenuItem(id: UUID(), name: "Sesame Ball", detail: "Crispy mochi, black sesame, seasonal filling", price: 8.00, badge: nil)
                ]),
                MenuSection(title: "From the Kitchen", items: [
                    MenuItem(id: UUID(), name: "Seasonal Pancake", detail: "Savory pancake with market vegetables and herbs", price: 14.00, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Wood-Grilled Steak", detail: "Grass-fed bavette, chimichurri, grilled alliums", price: 36.00, badge: nil),
                    MenuItem(id: UUID(), name: "Blistered Beans", detail: "Charred green beans, sesame, chili vinaigrette", price: 12.00, badge: nil),
                    MenuItem(id: UUID(), name: "Roasted Half Chicken", detail: "Herb-marinated, seasonal sides", price: 28.00, badge: nil)
                ]),
                MenuSection(title: "Desserts", items: [
                    MenuItem(id: UUID(), name: "Meyer Lemon Cream Puff", detail: "Choux pastry, lemon curd, whipped cream", price: 10.00, badge: nil),
                    MenuItem(id: UUID(), name: "Chocolate Pot de Crème", detail: "Dark chocolate, sea salt, shortbread", price: 12.00, badge: nil)
                ])
            ]
        )

        // ── Gap-filling chains & stores ──────────────────────────────

        let traderJoes = Restaurant(
            id: UUID(),
            name: "Trader Joe's",
            cuisine: "Grocery",
            rating: 4.8,
            ratingCount: 3200,
            deliveryFee: "$0.00 delivery fee on $35+",
            eta: "35-50 min",
            distanceMiles: 1.8,
            heroColor: UIColor(red: 0.80, green: 0.15, blue: 0.15, alpha: 1),
            imageName: "trader_joes_hero",
            tags: ["Grocery", "Pantry", "Frozen", "Snacks", "Drinks"],
            menu: [
                MenuSection(title: "Favorites", items: [
                    MenuItem(id: UUID(), name: "Mandarin Orange Chicken", detail: "Frozen, 22 oz bag", price: 5.49, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Cauliflower Gnocchi", detail: "Frozen, 12 oz bag", price: 3.49, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Everything But the Bagel Seasoning", detail: "2.3 oz jar", price: 2.49, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Unexpected Cheddar", detail: "8 oz block, aged cheddar with parmesan notes", price: 3.99, badge: nil)
                ]),
                MenuSection(title: "Snacks", items: [
                    MenuItem(id: UUID(), name: "Peanut Butter Cups", detail: "Dark chocolate, 16 oz bag", price: 4.99, badge: nil),
                    MenuItem(id: UUID(), name: "Elote Corn Chip Dippers", detail: "9.75 oz bag", price: 3.49, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Chocolate Lava Cakes", detail: "Frozen, 2 pack", price: 3.99, badge: nil)
                ]),
                MenuSection(title: "Drinks", items: [
                    MenuItem(id: UUID(), name: "Cold Brew Coffee Concentrate", detail: "32 oz bottle", price: 7.99, badge: nil),
                    MenuItem(id: UUID(), name: "Sparkling Mineral Water", detail: "1 liter glass bottle", price: 1.29, badge: nil)
                ])
            ]
        )

        let safeway = Restaurant(
            id: UUID(),
            name: "Safeway",
            cuisine: "Grocery",
            rating: 4.4,
            ratingCount: 2680,
            deliveryFee: "$0.00 delivery fee on $35+",
            eta: "40-55 min",
            distanceMiles: 1.2,
            heroColor: UIColor(red: 0.80, green: 0.10, blue: 0.15, alpha: 1),
            imageName: "safeway_hero",
            tags: ["Grocery", "Pantry", "Bakery", "Frozen", "Drugstore"],
            menu: [
                MenuSection(title: "Deli & Prepared", items: [
                    MenuItem(id: UUID(), name: "Rotisserie Chicken", detail: "Whole, seasoned and roasted", price: 8.99, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Signature Caesar Salad Kit", detail: "Complete kit with dressing, croutons, parmesan", price: 5.99, badge: nil),
                    MenuItem(id: UUID(), name: "Fresh Sushi Combo", detail: "12 piece assortment", price: 11.99, badge: nil)
                ]),
                MenuSection(title: "Bakery", items: [
                    MenuItem(id: UUID(), name: "French Bread", detail: "Fresh baked loaf", price: 3.49, badge: nil),
                    MenuItem(id: UUID(), name: "Chocolate Chip Cookies", detail: "12 count, bakery fresh", price: 6.99, badge: "Popular")
                ]),
                MenuSection(title: "Essentials", items: [
                    MenuItem(id: UUID(), name: "Lucerne Whole Milk", detail: "Gallon", price: 5.49, badge: nil),
                    MenuItem(id: UUID(), name: "Signature SELECT Eggs", detail: "Dozen, cage-free", price: 5.99, badge: nil),
                    MenuItem(id: UUID(), name: "Signature SELECT Pasta Sauce", detail: "24 oz jar, marinara", price: 3.49, badge: nil)
                ])
            ]
        )

        let target = Restaurant(
            id: UUID(),
            name: "Target",
            cuisine: "Retail",
            rating: 4.6,
            ratingCount: 2100,
            deliveryFee: "$0.00 delivery fee on $35+",
            eta: "35-50 min",
            distanceMiles: 2.5,
            heroColor: UIColor(red: 0.80, green: 0.10, blue: 0.10, alpha: 1),
            imageName: "target_hero",
            tags: ["Retail", "Baby & Toys", "Electronics", "Home Goods", "Beauty", "Snacks", "Packages"],
            menu: [
                MenuSection(title: "Baby & Kids", items: [
                    MenuItem(id: UUID(), name: "Pampers Swaddlers Diapers", detail: "Size 3, 78 count", price: 29.99, badge: "Popular"),
                    MenuItem(id: UUID(), name: "LEGO Classic Bricks Box", detail: "484 pieces, creative play set", price: 34.99, badge: nil),
                    MenuItem(id: UUID(), name: "Enfamil NeuroPro Formula", detail: "20.7 oz powder tub", price: 39.99, badge: nil)
                ]),
                MenuSection(title: "Electronics", items: [
                    MenuItem(id: UUID(), name: "Apple AirPods Pro", detail: "2nd generation, USB-C", price: 189.99, badge: "Popular"),
                    MenuItem(id: UUID(), name: "JBL Flip 6 Speaker", detail: "Portable Bluetooth, waterproof", price: 99.99, badge: nil),
                    MenuItem(id: UUID(), name: "Anker USB-C Hub", detail: "7-in-1, HDMI, USB 3.0, SD card", price: 35.99, badge: nil)
                ]),
                MenuSection(title: "Home & Beauty", items: [
                    MenuItem(id: UUID(), name: "Threshold Candle", detail: "Warm Vanilla, 11 oz glass jar", price: 9.99, badge: nil),
                    MenuItem(id: UUID(), name: "CeraVe Moisturizing Cream", detail: "16 oz tub, daily face & body", price: 17.99, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Room Essentials Bath Towels", detail: "2 pack, white, quick-dry", price: 12.99, badge: nil)
                ])
            ]
        )

        let tropicalSmoothie = Restaurant(
            id: UUID(),
            name: "Tropical Smoothie Cafe",
            cuisine: "Drinks",
            rating: 4.5,
            ratingCount: 1680,
            deliveryFee: "$0.00 delivery fee on $15+",
            eta: "15-25 min",
            distanceMiles: 1.9,
            heroColor: UIColor(red: 0.96, green: 0.65, blue: 0.15, alpha: 1),
            imageName: "tropical_smoothie_hero",
            tags: ["Smoothie", "Sandwiches", "Bowls", "Offers"],
            menu: [
                MenuSection(title: "Smoothies", items: [
                    MenuItem(id: UUID(), name: "Bahama Mama", detail: "24 oz, strawberries, white chocolate, coconut, banana", price: 7.99, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Detox Island Green", detail: "24 oz, spinach, kale, mango, pineapple, banana, ginger", price: 7.99, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Peanut Butter Cup", detail: "24 oz, peanut butter, banana, chocolate, milk", price: 7.99, badge: nil),
                    MenuItem(id: UUID(), name: "Açaí Berry Boost", detail: "24 oz, açaí, blueberry, strawberry, banana", price: 7.99, badge: nil)
                ]),
                MenuSection(title: "Wraps & Flatbreads", items: [
                    MenuItem(id: UUID(), name: "Thai Chicken Wrap", detail: "Grilled chicken, Thai peanut sauce, lettuce, carrots, wonton strips", price: 10.99, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Avocado BLT Flatbread", detail: "Bacon, avocado, lettuce, tomato, ranch on toasted flatbread", price: 10.99, badge: nil)
                ]),
                MenuSection(title: "Bowls", items: [
                    MenuItem(id: UUID(), name: "Açaí Bowl", detail: "Açaí blend, granola, banana, strawberry, blueberry, honey", price: 10.49, badge: nil),
                    MenuItem(id: UUID(), name: "Island Green Bowl", detail: "Spinach, kale, mango, pineapple, granola, coconut", price: 10.49, badge: nil)
                ])
            ]
        )

        let bevmo = Restaurant(
            id: UUID(),
            name: "BevMo!",
            cuisine: "Bottle Shop",
            rating: 4.5,
            ratingCount: 920,
            deliveryFee: "$2.99 delivery fee",
            eta: "30-45 min",
            distanceMiles: 2.8,
            heroColor: UIColor(red: 0.92, green: 0.72, blue: 0.10, alpha: 1),
            imageName: "bevmo_hero",
            tags: ["Alcohol", "Drinks", "Gifts", "Retail"],
            menu: [
                MenuSection(title: "Wine", items: [
                    MenuItem(id: UUID(), name: "Josh Cabernet Sauvignon", detail: "750 ml, California", price: 14.99, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Kim Crawford Sauvignon Blanc", detail: "750 ml, Marlborough", price: 13.99, badge: nil),
                    MenuItem(id: UUID(), name: "Veuve Clicquot Yellow Label", detail: "750 ml, Champagne", price: 54.99, badge: nil)
                ]),
                MenuSection(title: "Beer & Seltzer", items: [
                    MenuItem(id: UUID(), name: "Lagunitas IPA 6-Pack", detail: "12 oz bottles", price: 10.99, badge: "Popular"),
                    MenuItem(id: UUID(), name: "White Claw Variety 12-Pack", detail: "12 oz cans, assorted flavors", price: 17.99, badge: nil),
                    MenuItem(id: UUID(), name: "Pliny the Elder 4-Pack", detail: "16 oz cans, Russian River Brewing", price: 19.99, badge: nil)
                ]),
                MenuSection(title: "Spirits", items: [
                    MenuItem(id: UUID(), name: "Bulleit Bourbon", detail: "750 ml", price: 29.99, badge: nil),
                    MenuItem(id: UUID(), name: "Casamigos Reposado", detail: "750 ml", price: 44.99, badge: "Popular")
                ])
            ]
        )

        let walgreens = Restaurant(
            id: UUID(),
            name: "Walgreens",
            cuisine: "Pharmacy",
            rating: 4.3,
            ratingCount: 1890,
            deliveryFee: "$1.99 delivery fee",
            eta: "20-30 min",
            distanceMiles: 0.8,
            heroColor: UIColor(red: 0.00, green: 0.42, blue: 0.22, alpha: 1),
            imageName: "walgreens_hero",
            tags: ["Drugstore", "Beauty", "Snacks", "Convenience"],
            menu: [
                MenuSection(title: "Health & Wellness", items: [
                    MenuItem(id: UUID(), name: "Tylenol Extra Strength", detail: "100 count, 500mg caplets", price: 11.99, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Zyrtec Allergy", detail: "30 count, 10mg tablets", price: 22.99, badge: nil),
                    MenuItem(id: UUID(), name: "Emergen-C Vitamin C", detail: "30 count packets, orange flavor", price: 13.49, badge: nil)
                ]),
                MenuSection(title: "Beauty & Personal Care", items: [
                    MenuItem(id: UUID(), name: "Dove Body Wash", detail: "22 oz, deep moisture", price: 8.99, badge: nil),
                    MenuItem(id: UUID(), name: "Maybelline Lash Sensational Mascara", detail: "Blackest black, washable", price: 10.99, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Oral-B Pro 1000 Toothbrush", detail: "Rechargeable electric toothbrush", price: 49.99, badge: nil)
                ]),
                MenuSection(title: "Snacks", items: [
                    MenuItem(id: UUID(), name: "Häagen-Dazs Vanilla", detail: "Pint", price: 6.49, badge: nil),
                    MenuItem(id: UUID(), name: "Coca-Cola 6-Pack", detail: "12 oz cans", price: 5.99, badge: nil)
                ])
            ]
        )

        // ── More food variety ────────────────────────────────────────

        let curryUpNow = Restaurant(
            id: UUID(),
            name: "Curry Up Now",
            cuisine: "Indian",
            rating: 4.6,
            ratingCount: 1560,
            deliveryFee: "$0.99 delivery fee",
            eta: "20-30 min",
            distanceMiles: 1.6,
            heroColor: UIColor(red: 0.90, green: 0.55, blue: 0.10, alpha: 1),
            imageName: "curry_up_now_hero",
            tags: ["Bowls", "Burrito", "Catering", "Offers"],
            menu: [
                MenuSection(title: "Burritos & Bowls", items: [
                    MenuItem(id: UUID(), name: "Tikka Masala Burrito", detail: "Chicken tikka masala, basmati rice, naan strips, chutney, wrapped in flour tortilla", price: 14.95, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Deconstructed Samosa Bowl", detail: "Spiced potatoes, chickpeas, tamarind chutney, yogurt, sev, basmati rice", price: 13.95, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Paneer Tikka Bowl", detail: "Grilled paneer, bell peppers, onions, mint chutney, basmati rice", price: 14.95, badge: nil)
                ]),
                MenuSection(title: "Street Eats", items: [
                    MenuItem(id: UUID(), name: "Sexy Fries", detail: "Masala fries, chutneys, paneer tikka, chaat spices", price: 9.95, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Samosa Sliders", detail: "3 mini samosas, tamarind, cilantro chutney", price: 8.95, badge: nil),
                    MenuItem(id: UUID(), name: "Naan Pizza", detail: "Garlic naan, chicken tikka, mozzarella, cilantro, red onion", price: 12.95, badge: nil)
                ]),
                MenuSection(title: "Drinks", items: [
                    MenuItem(id: UUID(), name: "Mango Lassi", detail: "16 oz, fresh mango, yogurt, cardamom", price: 5.95, badge: nil),
                    MenuItem(id: UUID(), name: "Masala Chai", detail: "12 oz, spiced black tea with steamed milk", price: 4.95, badge: nil)
                ])
            ]
        )

        let phoTai = Restaurant(
            id: UUID(),
            name: "Pho Tai",
            cuisine: "Vietnamese",
            rating: 4.6,
            ratingCount: 1340,
            deliveryFee: "$1.99 delivery fee",
            eta: "20-35 min",
            distanceMiles: 2.0,
            heroColor: UIColor(red: 0.78, green: 0.25, blue: 0.20, alpha: 1),
            imageName: "pho_tai_hero",
            tags: ["Bowls", "Offers"],
            menu: [
                MenuSection(title: "Pho", items: [
                    MenuItem(id: UUID(), name: "Pho Dac Biet", detail: "Large, rare steak, well-done brisket, tendon, tripe, rice noodles", price: 16.95, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Pho Ga", detail: "Large, chicken noodle soup, white meat chicken, rice noodles", price: 15.95, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Pho Chay", detail: "Large, vegetable broth, tofu, mushrooms, bok choy, rice noodles", price: 14.95, badge: nil)
                ]),
                MenuSection(title: "Rice & Vermicelli", items: [
                    MenuItem(id: UUID(), name: "Banh Mi Dac Biet", detail: "Vietnamese baguette, pâté, ham, pork, pickled daikon, cilantro, jalapeño", price: 12.95, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Bun Thit Nuong", detail: "Vermicelli noodles, grilled pork, egg roll, fresh herbs, fish sauce", price: 15.95, badge: nil),
                    MenuItem(id: UUID(), name: "Com Tam Suon", detail: "Broken rice, grilled pork chop, fried egg, pickled vegetables", price: 16.95, badge: nil)
                ]),
                MenuSection(title: "Appetizers & Drinks", items: [
                    MenuItem(id: UUID(), name: "Goi Cuon", detail: "2 fresh spring rolls, shrimp, pork, vermicelli, lettuce, peanut sauce", price: 8.95, badge: nil),
                    MenuItem(id: UUID(), name: "Ca Phe Sua Da", detail: "Vietnamese iced coffee, sweetened condensed milk", price: 5.95, badge: "Popular")
                ])
            ]
        )

        let inNOut = Restaurant(
            id: UUID(),
            name: "In-N-Out Burger",
            cuisine: "Burgers",
            rating: 4.8,
            ratingCount: 6200,
            deliveryFee: "$2.99 delivery fee",
            eta: "20-35 min",
            distanceMiles: 3.5,
            heroColor: UIColor(red: 0.85, green: 0.12, blue: 0.15, alpha: 1),
            imageName: "in_n_out_hero",
            tags: ["Burgers", "Offers"],
            menu: [
                MenuSection(title: "Burgers", items: [
                    MenuItem(id: UUID(), name: "Double-Double", detail: "Two beef patties, two slices American cheese, lettuce, tomato, spread, onion", price: 5.95, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Cheeseburger", detail: "Beef patty, American cheese, lettuce, tomato, spread, onion", price: 4.25, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Hamburger", detail: "Beef patty, lettuce, tomato, spread, onion", price: 3.75, badge: nil),
                    MenuItem(id: UUID(), name: "Animal Style Burger", detail: "Mustard grilled patty, extra spread, grilled onions, pickles", price: 5.95, badge: "Popular")
                ]),
                MenuSection(title: "Sides & Drinks", items: [
                    MenuItem(id: UUID(), name: "French Fries", detail: "Fresh-cut, cooked in sunflower oil", price: 2.65, badge: nil),
                    MenuItem(id: UUID(), name: "Animal Style Fries", detail: "Fries with cheese, spread, grilled onions", price: 4.60, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Neapolitan Shake", detail: "Chocolate, vanilla, and strawberry hand-scooped milkshake", price: 3.45, badge: nil)
                ])
            ]
        )

        let philz = Restaurant(
            id: UUID(),
            name: "Philz Coffee",
            cuisine: "Coffee",
            rating: 4.7,
            ratingCount: 2450,
            deliveryFee: "$0.99 delivery fee",
            eta: "15-25 min",
            distanceMiles: 0.7,
            heroColor: UIColor(red: 0.42, green: 0.30, blue: 0.18, alpha: 1),
            imageName: "philz_hero",
            tags: ["Coffee", "Bakery"],
            menu: [
                MenuSection(title: "Signature Blends", items: [
                    MenuItem(id: UUID(), name: "Mint Mojito Iced Coffee", detail: "Large, fresh mint, coffee, cream, honey", price: 7.50, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Tesora", detail: "Large, caramel, honey, cream — Philz #1 blend", price: 6.75, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Ether", detail: "Large, bold dark roast, hint of cocoa, served black or with cream", price: 6.50, badge: nil),
                    MenuItem(id: UUID(), name: "Silken Splendor", detail: "Large, nutty, smooth, medium roast, cream and sugar", price: 6.50, badge: nil)
                ]),
                MenuSection(title: "Non-Coffee", items: [
                    MenuItem(id: UUID(), name: "Matcha Latte", detail: "Large, ceremonial matcha, steamed milk", price: 6.75, badge: nil),
                    MenuItem(id: UUID(), name: "Chai Latte", detail: "Large, spiced chai concentrate, steamed milk", price: 6.25, badge: nil)
                ]),
                MenuSection(title: "Food", items: [
                    MenuItem(id: UUID(), name: "Almond Croissant", detail: "Buttery, flaky, almond cream filling", price: 4.95, badge: nil),
                    MenuItem(id: UUID(), name: "Banana Bread", detail: "Thick slice, moist, walnuts", price: 4.50, badge: nil)
                ])
            ]
        )

        let koreanBBQ = Restaurant(
            id: UUID(),
            name: "KBBQ To Go",
            cuisine: "Korean",
            rating: 4.5,
            ratingCount: 1120,
            deliveryFee: "$1.99 delivery fee",
            eta: "25-35 min",
            distanceMiles: 2.2,
            heroColor: UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1),
            imageName: "kbbq_hero",
            tags: ["Bowls", "Catering"],
            menu: [
                MenuSection(title: "BBQ Plates", items: [
                    MenuItem(id: UUID(), name: "Bulgogi Plate", detail: "Marinated beef, steamed rice, kimchi, japchae, pickled radish", price: 17.95, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Spicy Pork Plate", detail: "Gochujang marinated pork, steamed rice, kimchi, bean sprouts", price: 16.95, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Galbi Plate", detail: "Soy-marinated short ribs, steamed rice, kimchi, japchae", price: 21.95, badge: nil)
                ]),
                MenuSection(title: "Bowls & Stews", items: [
                    MenuItem(id: UUID(), name: "Bibimbap", detail: "Mixed rice bowl, beef, vegetables, fried egg, gochujang", price: 15.95, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Kimchi Jjigae", detail: "Spicy kimchi stew, pork belly, tofu, rice", price: 14.95, badge: nil),
                    MenuItem(id: UUID(), name: "Japchae Bowl", detail: "Glass noodles, beef, mixed vegetables, sesame oil", price: 14.95, badge: nil)
                ]),
                MenuSection(title: "Sides", items: [
                    MenuItem(id: UUID(), name: "Kimbap Roll", detail: "8 pieces, beef, pickled radish, spinach, egg, rice, seaweed", price: 9.95, badge: nil),
                    MenuItem(id: UUID(), name: "Korean Fried Chicken Wings", detail: "8 pc, double-fried, choice of soy-garlic or spicy", price: 13.95, badge: "Popular")
                ])
            ]
        )

        let mendocino = Restaurant(
            id: UUID(),
            name: "Mendocino Farms",
            cuisine: "Deli",
            rating: 4.6,
            ratingCount: 1290,
            deliveryFee: "$0.99 delivery fee",
            eta: "20-30 min",
            distanceMiles: 1.3,
            heroColor: UIColor(red: 0.25, green: 0.55, blue: 0.30, alpha: 1),
            imageName: "mendocino_hero",
            tags: ["Sandwiches", "Salads", "Catering"],
            menu: [
                MenuSection(title: "Sandwiches", items: [
                    MenuItem(id: UUID(), name: "Not So Fried Chicken", detail: "Cornflake-crusted chicken, herb aioli, pickled onion, honey mustard, ciabatta", price: 14.29, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Impossible Taco", detail: "Seasoned Impossible meat, pico, guacamole, jalapeño ranch, crispy onions", price: 13.79, badge: nil),
                    MenuItem(id: UUID(), name: "Peruvian Steak", detail: "Chimichurri steak, sweet peppers, pickled red onion, garlic aioli, ciabatta", price: 15.29, badge: "Popular")
                ]),
                MenuSection(title: "Salads", items: [
                    MenuItem(id: UUID(), name: "Chinese Chicken Salad", detail: "Sesame chicken, napa cabbage, mandarins, wontons, toasted almonds, sesame-ginger vinaigrette", price: 14.29, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Kale & Quinoa Salad", detail: "Baby kale, quinoa, roasted beets, avocado, almonds, dried cranberries, lemon vinaigrette", price: 13.79, badge: nil)
                ]),
                MenuSection(title: "Sides", items: [
                    MenuItem(id: UUID(), name: "Mama Chen's Chinese Chicken Salad", detail: "Side portion", price: 6.99, badge: nil),
                    MenuItem(id: UUID(), name: "Seasonal Soup", detail: "Cup, rotating daily selection", price: 5.99, badge: nil)
                ])
            ]
        )

        // ── More SF locals & missing cuisines ────────────────────────

        let pokeworks = Restaurant(
            id: UUID(),
            name: "Pokeworks",
            cuisine: "Hawaiian",
            rating: 4.5,
            ratingCount: 1480,
            deliveryFee: "$0.99 delivery fee",
            eta: "15-25 min",
            distanceMiles: 1.1,
            heroColor: UIColor(red: 0.12, green: 0.40, blue: 0.60, alpha: 1),
            imageName: "pokeworks_hero",
            tags: ["Bowls", "Sushi", "Offers"],
            menu: [
                MenuSection(title: "Poke Bowls", items: [
                    MenuItem(id: UUID(), name: "Regular Poke Bowl", detail: "2 proteins, white rice, 4 mix-ins, 2 toppings, 1 sauce", price: 14.95, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Large Poke Bowl", detail: "3 proteins, white rice, 6 mix-ins, 3 toppings, 2 sauces", price: 17.95, badge: nil),
                    MenuItem(id: UUID(), name: "Umami Ahi Tuna Bowl", detail: "Ahi tuna, umami shoyu, edamame, cucumber, avocado, sesame, crispy onion", price: 15.95, badge: "Popular")
                ]),
                MenuSection(title: "Burritos & Wraps", items: [
                    MenuItem(id: UUID(), name: "Poke Burrito", detail: "2 proteins, sushi rice, mix-ins, seaweed wrap", price: 14.95, badge: nil),
                    MenuItem(id: UUID(), name: "Poke Tacos", detail: "3 wonton shell tacos, protein, toppings, sauce", price: 13.95, badge: nil)
                ]),
                MenuSection(title: "Sides", items: [
                    MenuItem(id: UUID(), name: "Miso Soup", detail: "Tofu, seaweed, scallions", price: 3.95, badge: nil),
                    MenuItem(id: UUID(), name: "Edamame", detail: "Steamed, sea salt", price: 4.50, badge: nil)
                ])
            ]
        )

        let yankSing = Restaurant(
            id: UUID(),
            name: "Yank Sing",
            cuisine: "Chinese",
            rating: 4.7,
            ratingCount: 2340,
            deliveryFee: "$2.99 delivery fee",
            eta: "30-45 min",
            distanceMiles: 0.8,
            heroColor: UIColor(red: 0.85, green: 0.18, blue: 0.15, alpha: 1),
            imageName: "yank_sing_hero",
            tags: ["Premium", "Catering"],
            menu: [
                MenuSection(title: "Dim Sum Classics", items: [
                    MenuItem(id: UUID(), name: "Har Gow", detail: "4 pc, crystal shrimp dumplings", price: 9.50, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Siu Mai", detail: "4 pc, pork and shrimp dumplings", price: 8.50, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Xiao Long Bao", detail: "4 pc, Shanghai soup dumplings", price: 10.50, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Char Siu Bao", detail: "3 pc, BBQ pork steamed buns", price: 8.50, badge: nil)
                ]),
                MenuSection(title: "Specialties", items: [
                    MenuItem(id: UUID(), name: "Peking Duck Spring Rolls", detail: "3 pc, duck, hoisin, scallion, crispy wrapper", price: 12.50, badge: "Signature"),
                    MenuItem(id: UUID(), name: "Sticky Rice in Lotus Leaf", detail: "Glutinous rice, pork, mushroom, egg yolk, steamed in leaf", price: 9.50, badge: nil),
                    MenuItem(id: UUID(), name: "Turnip Cake", detail: "3 pc, pan-fried daikon radish cake with XO sauce", price: 8.50, badge: nil)
                ]),
                MenuSection(title: "Rice & Noodles", items: [
                    MenuItem(id: UUID(), name: "Cheung Fun", detail: "Shrimp rice noodle rolls, soy sauce", price: 9.50, badge: nil),
                    MenuItem(id: UUID(), name: "Chow Fun", detail: "Wide rice noodles, beef, bean sprouts, scallions", price: 14.50, badge: nil)
                ])
            ]
        )

        let brendas = Restaurant(
            id: UUID(),
            name: "Brenda's French Soul Food",
            cuisine: "Southern",
            rating: 4.8,
            ratingCount: 3450,
            deliveryFee: "$2.99 delivery fee",
            eta: "25-40 min",
            distanceMiles: 0.9,
            heroColor: UIColor(red: 0.55, green: 0.15, blue: 0.25, alpha: 1),
            imageName: "brendas_hero",
            tags: ["Chicken", "Premium"],
            menu: [
                MenuSection(title: "Mains", items: [
                    MenuItem(id: UUID(), name: "Crawfish Beignets", detail: "3 pc, crawfish, cream cheese, Crystal hot sauce aioli", price: 14.50, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Fried Chicken & Waffle", detail: "Buttermilk fried chicken thigh, cornmeal waffle, maple syrup", price: 18.50, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Shrimp & Grits", detail: "Gulf shrimp, stone-ground grits, tasso ham, cream gravy", price: 19.50, badge: nil),
                    MenuItem(id: UUID(), name: "Hangtown Fry", detail: "Fried oysters, bacon, eggs, mixed greens", price: 20.50, badge: nil)
                ]),
                MenuSection(title: "Beignets", items: [
                    MenuItem(id: UUID(), name: "New Orleans Beignets", detail: "3 pc, powdered sugar, choice of dipping sauce", price: 8.50, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Ghirardelli Chocolate Beignets", detail: "3 pc, chocolate filled, powdered sugar", price: 10.50, badge: nil)
                ]),
                MenuSection(title: "Sides", items: [
                    MenuItem(id: UUID(), name: "Andouille Sausage", detail: "Smoked pork sausage, Creole mustard", price: 7.50, badge: nil),
                    MenuItem(id: UUID(), name: "Red Beans & Rice", detail: "Slow-simmered, andouille, holy trinity", price: 8.50, badge: nil)
                ])
            ]
        )

        let fourFiveOhFive = Restaurant(
            id: UUID(),
            name: "4505 Burgers & BBQ",
            cuisine: "BBQ",
            rating: 4.6,
            ratingCount: 1890,
            deliveryFee: "$1.99 delivery fee",
            eta: "25-35 min",
            distanceMiles: 1.8,
            heroColor: UIColor(red: 0.35, green: 0.20, blue: 0.12, alpha: 1),
            imageName: "4505_bbq_hero",
            tags: ["Burgers", "Catering"],
            menu: [
                MenuSection(title: "BBQ Plates", items: [
                    MenuItem(id: UUID(), name: "Brisket Plate", detail: "Smoked 14-hour brisket, two sides, pickles, white bread", price: 22.95, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Pulled Pork Plate", detail: "Smoked pork shoulder, two sides, pickles, white bread", price: 18.95, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Half Rack Ribs", detail: "St. Louis-style pork ribs, dry rub, two sides", price: 24.95, badge: nil)
                ]),
                MenuSection(title: "Sandwiches", items: [
                    MenuItem(id: UUID(), name: "Frankaroni", detail: "All-beef hot dog, mac & cheese, jalapeño relish", price: 12.95, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Brisket Sandwich", detail: "Sliced brisket, pickles, onions, BBQ sauce, brioche bun", price: 16.95, badge: nil)
                ]),
                MenuSection(title: "Sides", items: [
                    MenuItem(id: UUID(), name: "Mac & Cheese", detail: "Cheddar, Gruyère, breadcrumb topping", price: 6.95, badge: nil),
                    MenuItem(id: UUID(), name: "Coleslaw", detail: "Creamy, vinegar-based", price: 4.95, badge: nil),
                    MenuItem(id: UUID(), name: "Cornbread", detail: "Jalapeño cheddar, honey butter", price: 4.95, badge: nil)
                ])
            ]
        )

        let orensHummus = Restaurant(
            id: UUID(),
            name: "Oren's Hummus",
            cuisine: "Mediterranean",
            rating: 4.7,
            ratingCount: 1650,
            deliveryFee: "$1.99 delivery fee",
            eta: "20-30 min",
            distanceMiles: 1.4,
            heroColor: UIColor(red: 0.88, green: 0.78, blue: 0.55, alpha: 1),
            imageName: "orens_hummus_hero",
            tags: ["Bowls", "Salads", "Catering"],
            menu: [
                MenuSection(title: "Hummus Bowls", items: [
                    MenuItem(id: UUID(), name: "Classic Hummus", detail: "Chickpea hummus, tahini, olive oil, warm pita", price: 11.95, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Hummus with Shawarma Chicken", detail: "Hummus, spiced rotisserie chicken, pickled turnip, zhug", price: 16.95, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Hummus with Lamb", detail: "Hummus, spiced ground lamb, pine nuts, herbs", price: 17.95, badge: nil)
                ]),
                MenuSection(title: "Plates & Wraps", items: [
                    MenuItem(id: UUID(), name: "Chicken Shawarma Plate", detail: "Rotisserie chicken, Israeli salad, tahini, pickles, rice, pita", price: 18.95, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Falafel Wrap", detail: "Crispy falafel, hummus, tahini, Israeli salad, pickles, pita", price: 14.95, badge: nil),
                    MenuItem(id: UUID(), name: "Kebab Plate", detail: "Grilled beef & lamb kebab, rice, salad, tahini, pita", price: 19.95, badge: nil)
                ]),
                MenuSection(title: "Sides", items: [
                    MenuItem(id: UUID(), name: "Falafel", detail: "4 pc, crispy chickpea fritters, tahini", price: 7.95, badge: nil),
                    MenuItem(id: UUID(), name: "Israeli Salad", detail: "Diced cucumber, tomato, onion, lemon-olive oil dressing", price: 6.95, badge: nil)
                ])
            ]
        )

        let superDuper = Restaurant(
            id: UUID(),
            name: "Super Duper Burgers",
            cuisine: "Burgers",
            rating: 4.6,
            ratingCount: 2780,
            deliveryFee: "$0.99 delivery fee",
            eta: "15-25 min",
            distanceMiles: 0.8,
            heroColor: UIColor(red: 0.95, green: 0.82, blue: 0.15, alpha: 1),
            imageName: "super_duper_hero",
            tags: ["Burgers", "Offers"],
            menu: [
                MenuSection(title: "Burgers", items: [
                    MenuItem(id: UUID(), name: "Super Burger", detail: "Niman Ranch beef, lettuce, tomato, pickles, Super Sauce, toasted bun", price: 9.29, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Fried Chicken Sandwich", detail: "Buttermilk fried chicken, pickles, slaw, hot honey, potato bun", price: 10.49, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Veggie Burger", detail: "House-made veggie patty, lettuce, tomato, pickles, Super Sauce", price: 9.29, badge: nil),
                    MenuItem(id: UUID(), name: "Mini Burgers", detail: "3 mini Niman Ranch beef burgers, American cheese", price: 10.99, badge: nil)
                ]),
                MenuSection(title: "Sides & Shakes", items: [
                    MenuItem(id: UUID(), name: "Garlic Fries", detail: "Fresh-cut, tossed with garlic and parsley", price: 5.49, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Oreo Milkshake", detail: "Straus organic ice cream, Oreo cookies", price: 7.29, badge: nil),
                    MenuItem(id: UUID(), name: "Organic Salad", detail: "Mixed greens, cherry tomatoes, shaved parmesan, vinaigrette", price: 6.99, badge: nil)
                ])
            ]
        )

        let roosterRice = Restaurant(
            id: UUID(),
            name: "Rooster & Rice",
            cuisine: "Thai",
            rating: 4.6,
            ratingCount: 1920,
            deliveryFee: "$0.99 delivery fee",
            eta: "15-25 min",
            distanceMiles: 1.0,
            heroColor: UIColor(red: 0.88, green: 0.68, blue: 0.15, alpha: 1),
            imageName: "rooster_rice_hero",
            tags: ["Bowls", "Offers"],
            menu: [
                MenuSection(title: "Plates", items: [
                    MenuItem(id: UUID(), name: "Chicken & Rice", detail: "Poached chicken, garlic rice, house ginger sauce, cucumber, broth", price: 13.95, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Fried Chicken & Rice", detail: "Crispy fried chicken, garlic rice, sweet chili sauce, cucumber", price: 14.95, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Half & Half", detail: "Half poached, half fried chicken, garlic rice, both sauces", price: 15.95, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Chicken Skin & Rice", detail: "Crispy chicken skin, garlic rice, ginger sauce, scallion oil", price: 12.95, badge: nil)
                ]),
                MenuSection(title: "Soups & Salads", items: [
                    MenuItem(id: UUID(), name: "Chicken Soup", detail: "Chicken broth, rice, ginger, cilantro, fried garlic", price: 9.95, badge: nil),
                    MenuItem(id: UUID(), name: "Papaya Salad", detail: "Green papaya, peanuts, dried shrimp, chili-lime dressing", price: 10.95, badge: nil)
                ]),
                MenuSection(title: "Extras & Drinks", items: [
                    MenuItem(id: UUID(), name: "Extra Chicken", detail: "Additional portion of poached or fried chicken", price: 5.00, badge: nil),
                    MenuItem(id: UUID(), name: "Extra Rice", detail: "Garlic rice side", price: 3.00, badge: nil),
                    MenuItem(id: UUID(), name: "Side Broth", detail: "Chicken broth with ginger", price: 2.50, badge: nil),
                    MenuItem(id: UUID(), name: "Thai Iced Tea", detail: "Classic Thai tea with condensed milk", price: 4.50, badge: nil),
                    MenuItem(id: UUID(), name: "Coconut Water", detail: "Fresh coconut water, chilled", price: 3.50, badge: nil)
                ])
            ]
        )

        let chefico = Restaurant(
            id: UUID(),
            name: "Che Fico",
            cuisine: "Italian",
            rating: 4.8,
            ratingCount: 1560,
            deliveryFee: "$3.99 delivery fee",
            eta: "35-50 min",
            distanceMiles: 1.7,
            heroColor: UIColor(red: 0.15, green: 0.25, blue: 0.40, alpha: 1),
            imageName: "che_fico_hero",
            tags: ["Pizza", "Premium"],
            menu: [
                MenuSection(title: "Pizza", items: [
                    MenuItem(id: UUID(), name: "Focaccia di Recco", detail: "Crispy flatbread, stracchino cheese, sea salt, olive oil", price: 22.00, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Margherita", detail: "Wood-fired, San Marzano, fior di latte, basil", price: 20.00, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Funghi", detail: "Mixed wild mushrooms, fontina, thyme, truffle oil", price: 24.00, badge: nil)
                ]),
                MenuSection(title: "Pasta", items: [
                    MenuItem(id: UUID(), name: "Cacio e Pepe", detail: "Tonnarelli, pecorino Romano, Tellicherry black pepper", price: 24.00, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Pappardelle Bolognese", detail: "Hand-cut pasta, slow-braised beef and pork ragù", price: 26.00, badge: nil),
                    MenuItem(id: UUID(), name: "Wood-Fired Fish", detail: "Market fish, salsa verde, grilled lemon, seasonal vegetables", price: 34.00, badge: nil)
                ]),
                MenuSection(title: "Desserts", items: [
                    MenuItem(id: UUID(), name: "Tiramisu", detail: "Espresso-soaked ladyfingers, mascarpone, cocoa", price: 14.00, badge: nil),
                    MenuItem(id: UUID(), name: "Bomboloni", detail: "3 pc, Italian doughnuts, pastry cream, seasonal jam", price: 12.00, badge: nil)
                ])
            ]
        )

        let delfina = Restaurant(
            id: UUID(),
            name: "Delfina",
            cuisine: "Italian",
            rating: 4.8,
            ratingCount: 2120,
            deliveryFee: "$2.99 delivery fee",
            eta: "30-45 min",
            distanceMiles: 1.3,
            heroColor: UIColor(red: 0.75, green: 0.60, blue: 0.40, alpha: 1),
            imageName: "delfina_hero",
            tags: ["Pizza", "Premium"],
            menu: [
                MenuSection(title: "Pasta", items: [
                    MenuItem(id: UUID(), name: "Spaghetti", detail: "House-made pasta, plum tomato sauce, basil, parmesan", price: 22.00, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Pappardelle with Ragù", detail: "Hand-cut pasta, braised pork shoulder ragù, pecorino", price: 26.00, badge: nil),
                    MenuItem(id: UUID(), name: "Risotto", detail: "Carnaroli rice, seasonal vegetables, parmesan broth", price: 24.00, badge: nil)
                ]),
                MenuSection(title: "Mains", items: [
                    MenuItem(id: UUID(), name: "Grilled Pork Chop", detail: "Berkshire pork, roasted potatoes, salsa verde, greens", price: 34.00, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Bruschetta", detail: "Grilled country bread, seasonal toppings, olive oil", price: 14.00, badge: nil)
                ]),
                MenuSection(title: "Desserts", items: [
                    MenuItem(id: UUID(), name: "Panna Cotta", detail: "Buttermilk panna cotta, seasonal fruit, biscotti", price: 12.00, badge: nil),
                    MenuItem(id: UUID(), name: "Affogato", detail: "Vanilla gelato, double espresso", price: 10.00, badge: nil)
                ])
            ]
        )

        let senorSisig = Restaurant(
            id: UUID(),
            name: "Señor Sisig",
            cuisine: "Filipino",
            rating: 4.7,
            ratingCount: 2680,
            deliveryFee: "$0.99 delivery fee",
            eta: "15-25 min",
            distanceMiles: 1.5,
            heroColor: UIColor(red: 0.90, green: 0.30, blue: 0.15, alpha: 1),
            imageName: "senor_sisig_hero",
            tags: ["Burrito", "Bowls", "Offers"],
            menu: [
                MenuSection(title: "Burritos & Bowls", items: [
                    MenuItem(id: UUID(), name: "Sisig Burrito", detail: "Sizzling pork sisig, garlic rice, onions, peppers, chipotle crema, flour tortilla", price: 13.95, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Chicken Adobo Bowl", detail: "Braised chicken adobo, garlic rice, pickled vegetables, egg", price: 14.95, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Tofu Sisig Bowl", detail: "Crispy tofu, garlic rice, onions, peppers, vegan chipotle crema", price: 12.95, badge: nil)
                ]),
                MenuSection(title: "Tacos & Nachos", items: [
                    MenuItem(id: UUID(), name: "Sisig Tacos", detail: "3 tacos, pork sisig, cilantro-onion relish, sriracha mayo", price: 11.95, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Nachos", detail: "Tortilla chips, sisig, cheese, jalapeños, crema, salsa", price: 12.95, badge: nil)
                ]),
                MenuSection(title: "Sides", items: [
                    MenuItem(id: UUID(), name: "Lumpia Shanghai", detail: "6 pc, crispy fried pork spring rolls, sweet chili sauce", price: 7.95, badge: nil),
                    MenuItem(id: UUID(), name: "Garlic Rice", detail: "Side of toasted garlic fried rice", price: 3.95, badge: nil)
                ])
            ]
        )

        let kitava = Restaurant(
            id: UUID(),
            name: "Kitava",
            cuisine: "Healthy",
            rating: 4.6,
            ratingCount: 1120,
            deliveryFee: "$0.99 delivery fee",
            eta: "20-30 min",
            distanceMiles: 1.2,
            heroColor: UIColor(red: 0.40, green: 0.65, blue: 0.50, alpha: 1),
            imageName: "kitava_hero",
            tags: ["Bowls", "Salads", "Offers"],
            menu: [
                MenuSection(title: "Bowls", items: [
                    MenuItem(id: UUID(), name: "Steak Bowl", detail: "Grass-fed steak, sweet potato, kale, pickled onion, chimichurri, cauliflower rice", price: 17.95, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Chicken Bowl", detail: "Free-range chicken, roasted vegetables, avocado, turmeric rice", price: 15.95, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Salmon Bowl", detail: "Wild salmon, beet, greens, avocado, lemon-dill dressing, cauliflower rice", price: 18.95, badge: nil)
                ]),
                MenuSection(title: "Salads", items: [
                    MenuItem(id: UUID(), name: "Mission Salad", detail: "Greens, chicken, avocado, plantain chips, cilantro-lime vinaigrette", price: 15.95, badge: nil),
                    MenuItem(id: UUID(), name: "Beet & Citrus Salad", detail: "Roasted beets, citrus, arugula, toasted almonds, honey vinaigrette", price: 14.95, badge: nil)
                ]),
                MenuSection(title: "Sides", items: [
                    MenuItem(id: UUID(), name: "Sweet Potato Fries", detail: "Baked, served with chipotle aioli", price: 6.95, badge: nil),
                    MenuItem(id: UUID(), name: "Bone Broth", detail: "8 oz, grass-fed, turmeric, ginger", price: 5.95, badge: nil)
                ])
            ]
        )

        let sourdoughCo = Restaurant(
            id: UUID(),
            name: "Boudin Bakery",
            cuisine: "Bakery",
            rating: 4.5,
            ratingCount: 2340,
            deliveryFee: "$1.99 delivery fee",
            eta: "25-35 min",
            distanceMiles: 1.6,
            heroColor: UIColor(red: 0.82, green: 0.68, blue: 0.45, alpha: 1),
            imageName: "boudin_hero",
            tags: ["Bakery", "Sandwiches", "Deli"],
            menu: [
                MenuSection(title: "Bread Bowls", items: [
                    MenuItem(id: UUID(), name: "Clam Chowder Bread Bowl", detail: "Creamy New England chowder in a sourdough bread bowl", price: 14.95, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Broccoli Cheddar Bread Bowl", detail: "Broccoli cheddar soup in a sourdough bread bowl", price: 13.95, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Chili Bread Bowl", detail: "Beef chili in a sourdough bread bowl, sour cream, cheese", price: 14.95, badge: nil)
                ]),
                MenuSection(title: "Sandwiches", items: [
                    MenuItem(id: UUID(), name: "Turkey Avocado", detail: "Roasted turkey, avocado, bacon, swiss, sourdough", price: 13.95, badge: nil),
                    MenuItem(id: UUID(), name: "Sourdough Grilled Cheese", detail: "Cheddar, swiss, gruyère on sourdough bread", price: 11.95, badge: "Popular")
                ]),
                MenuSection(title: "Bakery", items: [
                    MenuItem(id: UUID(), name: "Sourdough Round", detail: "Whole 1 lb loaf, San Francisco sourdough", price: 7.95, badge: nil),
                    MenuItem(id: UUID(), name: "Sourdough Bread Sampler", detail: "Assorted mini loaves: round, baguette, batard", price: 14.95, badge: nil)
                ])
            ]
        )

        // ── BELI CROSS-REF RESTAURANTS ──────────────────────────────

        let richTable = Restaurant(
            id: UUID(),
            name: "Rich Table",
            cuisine: "American",
            rating: 4.8,
            ratingCount: 1890,
            deliveryFee: "$3.99 delivery fee",
            eta: "35-45 min",
            distanceMiles: 0.8,
            heroColor: UIColor(red: 0.35, green: 0.30, blue: 0.25, alpha: 1),
            imageName: "rich_table_hero",
            tags: ["Premium", "Offers"],
            menu: [
                MenuSection(title: "Starters", items: [
                    MenuItem(id: UUID(), name: "Sardine Chips", detail: "Crispy sardine fillets, horseradish crème fraîche", price: 18.00, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Porcini Doughnuts", detail: "Savory porcini mushroom doughnuts, raclette dip", price: 16.00, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Burrata", detail: "Burrata, stone fruit, pistachio, basil oil", price: 19.00, badge: nil)
                ]),
                MenuSection(title: "Mains", items: [
                    MenuItem(id: UUID(), name: "Dry-Aged Duck", detail: "Dry-aged duck breast, seasonal vegetables, jus", price: 42.00, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Seasonal Pasta", detail: "Hand-rolled pasta, rotating seasonal preparation", price: 28.00, badge: nil),
                    MenuItem(id: UUID(), name: "Pan-Roasted Halibut", detail: "Halibut, fennel, citrus, olive tapenade", price: 38.00, badge: nil)
                ]),
                MenuSection(title: "Desserts", items: [
                    MenuItem(id: UUID(), name: "Miso Butterscotch Pudding", detail: "White miso, butterscotch, sesame brittle", price: 14.00, badge: nil),
                    MenuItem(id: UUID(), name: "Chocolate Souffle", detail: "Dark chocolate, crème anglaise", price: 16.00, badge: nil)
                ])
            ]
        )

        let mamaSF = Restaurant(
            id: UUID(),
            name: "Mama",
            cuisine: "Italian",
            rating: 4.6,
            ratingCount: 2450,
            deliveryFee: "$1.99 delivery fee",
            eta: "25-35 min",
            distanceMiles: 2.1,
            heroColor: UIColor(red: 0.85, green: 0.55, blue: 0.35, alpha: 1),
            imageName: "mama_hero",
            tags: ["Pizza", "Premium", "Offers"],
            menu: [
                MenuSection(title: "Brunch Favorites", items: [
                    MenuItem(id: UUID(), name: "Egg Pizza", detail: "Runny egg, fontina, arugula, chili flakes, olive oil", price: 19.00, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Rigatoni Bolognese", detail: "Slow-cooked beef and pork ragù, parmesan", price: 22.00, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Burrata Salad", detail: "Burrata, roasted peppers, sourdough croutons, basil", price: 18.00, badge: nil)
                ]),
                MenuSection(title: "Pasta & Pizza", items: [
                    MenuItem(id: UUID(), name: "Cacio e Pepe", detail: "Tonnarelli, pecorino romano, black pepper", price: 20.00, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Margherita Pizza", detail: "San Marzano, fior di latte, basil, olive oil", price: 18.00, badge: nil)
                ]),
                MenuSection(title: "Desserts", items: [
                    MenuItem(id: UUID(), name: "Affogato", detail: "Vanilla gelato, double espresso", price: 10.00, badge: nil),
                    MenuItem(id: UUID(), name: "Tiramisu", detail: "Espresso-soaked ladyfingers, mascarpone, cocoa", price: 14.00, badge: nil)
                ])
            ]
        )

        let misterJius = Restaurant(
            id: UUID(),
            name: "Mister Jiu's",
            cuisine: "Chinese",
            rating: 4.8,
            ratingCount: 1650,
            deliveryFee: "$3.99 delivery fee",
            eta: "35-45 min",
            distanceMiles: 1.4,
            heroColor: UIColor(red: 0.80, green: 0.25, blue: 0.20, alpha: 1),
            imageName: "mister_jius_hero",
            tags: ["Premium"],
            menu: [
                MenuSection(title: "Starters", items: [
                    MenuItem(id: UUID(), name: "Cheung Fun", detail: "Rice noodle rolls, XO sauce, scallion oil", price: 18.00, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Smoked Quail", detail: "Tea-smoked quail, plum sauce, pickled mustard greens", price: 22.00, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Hot & Sour Soup", detail: "Black vinegar, tofu, wood ear mushroom, egg drop", price: 14.00, badge: nil)
                ]),
                MenuSection(title: "Mains", items: [
                    MenuItem(id: UUID(), name: "Sesame Ball Stuffed Duck", detail: "Roasted half duck, sesame stuffing, plum glaze", price: 48.00, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Dai Pai Dong Noodles", detail: "Wok-tossed egg noodles, shiitake, bok choy, chili crisp", price: 24.00, badge: nil),
                    MenuItem(id: UUID(), name: "Whole Steamed Fish", detail: "Market fish, ginger, scallion, soy, cilantro", price: 52.00, badge: nil)
                ]),
                MenuSection(title: "Desserts", items: [
                    MenuItem(id: UUID(), name: "Coconut Custard Bun", detail: "Steamed bun, coconut custard, sesame", price: 12.00, badge: nil),
                    MenuItem(id: UUID(), name: "Black Sesame Sundae", detail: "Black sesame ice cream, mochi, peanut brittle", price: 14.00, badge: nil)
                ])
            ]
        )

        let lazyBear = Restaurant(
            id: UUID(),
            name: "Lazy Bear",
            cuisine: "American",
            rating: 4.9,
            ratingCount: 1280,
            deliveryFee: "$4.99 delivery fee",
            eta: "40-50 min",
            distanceMiles: 1.7,
            heroColor: UIColor(red: 0.30, green: 0.25, blue: 0.20, alpha: 1),
            imageName: "lazy_bear_hero",
            tags: ["Premium"],
            menu: [
                MenuSection(title: "Tasting Menu Selections", items: [
                    MenuItem(id: UUID(), name: "Tasting Menu for Two", detail: "Multi-course prix fixe, seasonal California ingredients, communal dining", price: 195.00, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Wine Pairing Add-On", detail: "Sommelier-selected pairings for each course", price: 125.00, badge: "Popular")
                ]),
                MenuSection(title: "À La Carte (When Available)", items: [
                    MenuItem(id: UUID(), name: "Duck Liver Mousse", detail: "Toasted brioche, pickled cherries, pistachios", price: 22.00, badge: nil),
                    MenuItem(id: UUID(), name: "Dry-Aged Beef", detail: "Grass-fed strip, seasonal accompaniments, bone marrow jus", price: 48.00, badge: nil),
                    MenuItem(id: UUID(), name: "Charred Cabbage", detail: "Miso butter, toasted nori, smoked trout roe", price: 18.00, badge: nil)
                ]),
                MenuSection(title: "Desserts", items: [
                    MenuItem(id: UUID(), name: "Chocolate & Olive Oil", detail: "Valrhona chocolate, olive oil cake, fleur de sel", price: 16.00, badge: nil),
                    MenuItem(id: UUID(), name: "Seasonal Sorbet Trio", detail: "Three rotating flavors, fresh herbs", price: 14.00, badge: nil)
                ])
            ]
        )

        let swanOyster = Restaurant(
            id: UUID(),
            name: "Swan Oyster Depot",
            cuisine: "Seafood",
            rating: 4.8,
            ratingCount: 3450,
            deliveryFee: "$2.99 delivery fee",
            eta: "30-40 min",
            distanceMiles: 1.3,
            heroColor: UIColor(red: 0.25, green: 0.50, blue: 0.60, alpha: 1),
            imageName: "swan_oyster_hero",
            tags: ["Premium", "Seafood"],
            menu: [
                MenuSection(title: "Raw Bar", items: [
                    MenuItem(id: UUID(), name: "Oysters on the Half Shell", detail: "6 pc, daily selection, mignonette, cocktail sauce, lemon", price: 24.00, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Crab Back", detail: "Whole Dungeness crab back, Louis dressing", price: 28.00, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Shrimp Louie", detail: "Bay shrimp, louie dressing, egg, tomato, avocado", price: 22.00, badge: nil)
                ]),
                MenuSection(title: "Seafood", items: [
                    MenuItem(id: UUID(), name: "Clam Chowder", detail: "New England style, sourdough bread", price: 14.00, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Smoked Trout", detail: "House-smoked, crème fraîche, capers, red onion", price: 18.00, badge: nil),
                    MenuItem(id: UUID(), name: "Lobster Tail", detail: "Half Maine lobster tail, drawn butter, lemon", price: 38.00, badge: nil)
                ]),
                MenuSection(title: "Extras", items: [
                    MenuItem(id: UUID(), name: "Sicilian Sashimi", detail: "Ahi tuna, olive oil, capers, lemon, sea salt", price: 19.00, badge: nil),
                    MenuItem(id: UUID(), name: "Sourdough Bread", detail: "Sliced, served with butter", price: 4.00, badge: nil)
                ])
            ]
        )

        let commis = Restaurant(
            id: UUID(),
            name: "Commis",
            cuisine: "American",
            rating: 4.9,
            ratingCount: 980,
            deliveryFee: "$4.99 delivery fee",
            eta: "45-55 min",
            distanceMiles: 8.5,
            heroColor: UIColor(red: 0.28, green: 0.28, blue: 0.32, alpha: 1),
            imageName: "commis_hero",
            tags: ["Premium"],
            menu: [
                MenuSection(title: "Tasting Menu", items: [
                    MenuItem(id: UUID(), name: "Tasting Menu for Two", detail: "Multi-course prix fixe, hyper-seasonal East Bay ingredients, open kitchen", price: 175.00, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Wine Pairing", detail: "Sommelier-curated wines for each course", price: 110.00, badge: "Popular")
                ]),
                MenuSection(title: "Select Courses", items: [
                    MenuItem(id: UUID(), name: "Abalone & Kelp", detail: "Local abalone, kombu butter, sea beans", price: 28.00, badge: nil),
                    MenuItem(id: UUID(), name: "Sonoma Duck", detail: "Dry-aged breast, turnip, black garlic, jus", price: 36.00, badge: nil)
                ]),
                MenuSection(title: "Desserts", items: [
                    MenuItem(id: UUID(), name: "Meyer Lemon Curd", detail: "Lemon curd, meringue, herbs, olive oil", price: 16.00, badge: nil),
                    MenuItem(id: UUID(), name: "Chocolate & Bay Laurel", detail: "Dark chocolate, bay laurel cream, almond", price: 16.00, badge: nil)
                ])
            ]
        )

        let chezPanisse = Restaurant(
            id: UUID(),
            name: "Chez Panisse",
            cuisine: "American",
            rating: 4.8,
            ratingCount: 2890,
            deliveryFee: "$4.99 delivery fee",
            eta: "45-55 min",
            distanceMiles: 10.2,
            heroColor: UIColor(red: 0.55, green: 0.40, blue: 0.30, alpha: 1),
            imageName: "chez_panisse_hero",
            tags: ["Premium"],
            menu: [
                MenuSection(title: "Prix Fixe", items: [
                    MenuItem(id: UUID(), name: "Monday Night Dinner", detail: "Three-course seasonal menu, changes weekly", price: 85.00, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Saturday Night Dinner", detail: "Four-course menu, peak seasonal ingredients", price: 125.00, badge: "Popular")
                ]),
                MenuSection(title: "Café Menu", items: [
                    MenuItem(id: UUID(), name: "Garden Salad", detail: "Local greens, sherry vinaigrette, edible flowers", price: 16.00, badge: nil),
                    MenuItem(id: UUID(), name: "Wood-Oven Pizza", detail: "Seasonal toppings, house-made mozzarella, olive oil", price: 22.00, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Grilled Fish", detail: "Market fish, herb salsa verde, roasted vegetables", price: 32.00, badge: nil)
                ]),
                MenuSection(title: "Desserts", items: [
                    MenuItem(id: UUID(), name: "Fruit Galette", detail: "Seasonal fruit, butter pastry, crème fraîche", price: 14.00, badge: nil),
                    MenuItem(id: UUID(), name: "Sherbet Trio", detail: "Three seasonal flavors, house-made wafer", price: 12.00, badge: nil)
                ])
            ]
        )

        let cholitaLinda = Restaurant(
            id: UUID(),
            name: "Cholita Linda",
            cuisine: "Caribbean",
            rating: 4.7,
            ratingCount: 2120,
            deliveryFee: "$1.99 delivery fee",
            eta: "35-45 min",
            distanceMiles: 7.8,
            heroColor: UIColor(red: 0.90, green: 0.65, blue: 0.20, alpha: 1),
            imageName: "cholita_linda_hero",
            tags: ["Bowls", "Offers"],
            menu: [
                MenuSection(title: "Tacos & Burritos", items: [
                    MenuItem(id: UUID(), name: "Fish Tacos", detail: "Battered white fish, cabbage slaw, chipotle crema, corn tortillas", price: 15.95, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Jerk Chicken Burrito", detail: "Jerk-spiced chicken, black beans, rice, plantains, mango salsa", price: 14.95, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Carnitas Tacos", detail: "Slow-roasted pork, pickled onion, cilantro, salsa verde", price: 14.95, badge: nil)
                ]),
                MenuSection(title: "Plates", items: [
                    MenuItem(id: UUID(), name: "Plantain Bowl", detail: "Fried plantains, black beans, rice, avocado, pico de gallo", price: 13.95, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Cuban Sandwich", detail: "Roasted pork, ham, swiss, pickles, mustard, pressed roll", price: 13.95, badge: nil)
                ]),
                MenuSection(title: "Sides & Drinks", items: [
                    MenuItem(id: UUID(), name: "Fried Plantains", detail: "Sweet plantains, crema dip", price: 6.95, badge: nil),
                    MenuItem(id: UUID(), name: "Jamaica", detail: "House-made hibiscus agua fresca", price: 4.95, badge: nil)
                ])
            ]
        )

        let ippuku = Restaurant(
            id: UUID(),
            name: "Ippuku",
            cuisine: "Japanese",
            rating: 4.7,
            ratingCount: 1560,
            deliveryFee: "$2.99 delivery fee",
            eta: "40-50 min",
            distanceMiles: 9.6,
            heroColor: UIColor(red: 0.25, green: 0.22, blue: 0.20, alpha: 1),
            imageName: "ippuku_hero",
            tags: ["Premium"],
            menu: [
                MenuSection(title: "Yakitori", items: [
                    MenuItem(id: UUID(), name: "Chicken Thigh Skewer", detail: "Tare-glazed, charcoal grilled, sea salt", price: 6.50, badge: "Most Popular"),
                    MenuItem(id: UUID(), name: "Tsukune", detail: "Chicken meatball skewer, egg yolk dip, tare sauce", price: 7.50, badge: "Popular"),
                    MenuItem(id: UUID(), name: "Negima", detail: "Chicken and scallion skewer, shio salt", price: 6.50, badge: nil),
                    MenuItem(id: UUID(), name: "Yakitori Omakase (8 pc)", detail: "Chef's selection of 8 grilled skewers", price: 36.00, badge: "Popular")
                ]),
                MenuSection(title: "Small Plates", items: [
                    MenuItem(id: UUID(), name: "Agedashi Tofu", detail: "Crispy tofu, dashi broth, bonito, grated daikon", price: 12.00, badge: nil),
                    MenuItem(id: UUID(), name: "Takoyaki", detail: "Octopus fritters, bonito flakes, kewpie, aonori", price: 11.00, badge: nil)
                ]),
                MenuSection(title: "Rice & Noodles", items: [
                    MenuItem(id: UUID(), name: "Oyakodon", detail: "Chicken and egg rice bowl, mitsuba, dashi", price: 16.00, badge: nil),
                    MenuItem(id: UUID(), name: "Cold Soba", detail: "Buckwheat noodles, tsuyu dipping sauce, wasabi, nori", price: 14.00, badge: nil)
                ])
            ]
        )

        restaurants = [
            wholefoods,
            chipotle,
            dominos,
            pizzaHut,
            sweetgreen,
            chickFilA,
            sugarfish,
            nobu,
            fiveGuys,
            shakeShack,
            levain,
            starbucks,
            jamba,
            kungFuTea,
            jerseyMikes,
            panera,
            cava,
            dashMart,
            totalWine,
            bouqs,
            cvs,
            petsmart,
            dicks,
            tacoBell,
            wingstop,
            popeyes,
            peets,
            mcdonalds,
            subway,
            pandaExpress,
            crumbl,
            laTaqueria,
            souvla,
            zyRestaurant,
            dumplingHome,
            marufuku,
            burmaSuperstar,
            tonys,
            hogIsland,
            nari,
            flourWater,
            sightglass,
            tartine,
            elFarolito,
            sanTung,
            zuniCafe,
            nopalito,
            kinKhao,
            stateBird,
            traderJoes,
            safeway,
            target,
            tropicalSmoothie,
            bevmo,
            walgreens,
            curryUpNow,
            phoTai,
            inNOut,
            philz,
            koreanBBQ,
            mendocino,
            pokeworks,
            yankSing,
            brendas,
            fourFiveOhFive,
            orensHummus,
            superDuper,
            roosterRice,
            chefico,
            delfina,
            senorSisig,
            kitava,
            sourdoughCo,
            richTable,
            mamaSF,
            misterJius,
            lazyBear,
            swanOyster,
            commis,
            chezPanisse,
            cholitaLinda,
            ippuku
        ]

        // ── Pickup availability & ETAs ────────────────────────────────
        let noPickup: Set<String> = ["Lazy Bear", "Commis", "The Bouqs Co."]
        let fastPickup: Set<String> = [
            "McDonald's", "Chick-fil-A", "Taco Bell", "Five Guys", "In-N-Out Burger",
            "Shake Shack", "Starbucks", "Philz Coffee", "Peet's Coffee",
            "Sightglass Coffee", "Kung Fu Tea", "Jamba", "Crumbl Cookies"
        ]
        let quickPickup: Set<String> = [
            "Chipotle Mexican Grill", "Sweetgreen", "CAVA", "Panera Bread",
            "Subway", "Jersey Mike's Subs", "Panda Express", "Wingstop", "Popeyes",
            "Señor Sisig", "Curry Up Now", "Pokeworks", "Super Duper Burgers",
            "Tropical Smoothie Cafe", "Mendocino Farms", "Rooster & Rice",
            "La Taqueria", "El Farolito", "Cholita Linda"
        ]
        let slowPickup: Set<String> = [
            "Whole Foods Market", "Trader Joe's", "Safeway", "Target",
            "CVS Pharmacy", "Walgreens", "BevMo!", "Total Wine & More",
            "PetSmart", "Dick's Sporting Goods", "DashMart"
        ]
        for i in restaurants.indices {
            let name = restaurants[i].name
            if noPickup.contains(name) {
                restaurants[i].pickupAvailable = false
            } else if fastPickup.contains(name) {
                restaurants[i].pickupEta = "5-10 min"
            } else if quickPickup.contains(name) {
                restaurants[i].pickupEta = "10-15 min"
            } else if slowPickup.contains(name) {
                restaurants[i].pickupEta = "20-30 min"
            }
        }

        addresses = [
            Address(id: UUID(), label: "Home", detail: "410 Brannan St, Unit 12B"),
            Address(id: UUID(), label: "Office", detail: "525 Market St, Suite 900"),
            Address(id: UUID(), label: "Studio", detail: "1234 Folsom St, Unit 4A"),
            Address(id: UUID(), label: "Friend", detail: "2847 Diamond St")
        ]

        selectedAddressID = addresses.first?.id ?? UUID()
        selectedPaymentAccountId = preferredCheckoutAccount()?.id
        pastOrders = loadPastOrders()
        loadPersistedCart()
    }

    private func loadPastOrders() -> [ActiveOrder] {
        func daysAgo(_ d: Int, hour: Int = 12, minute: Int = 30) -> Date {
            Calendar.current.date(byAdding: .day, value: -d, to: Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()) ?? Date()
        }
        let home = addresses[0]
        let office = addresses[1]

        return [
            ActiveOrder(
                id: UUID(), restaurant: restaurants[1], // Chipotle
                items: [
                    CartItem(item: restaurants[1].menu[0].items[0], quantity: 1, restaurantID: restaurants[1].id),
                    CartItem(item: restaurants[1].menu[0].items[2], quantity: 1, restaurantID: restaurants[1].id)
                ],
                startDate: daysAgo(1, hour: 12, minute: 45), etaMinutes: 22, distanceMiles: 2.1,
                scheduledFor: nil, statusIndex: 4, orderType: .delivery, destinationAddress: office
            ),
            ActiveOrder(
                id: UUID(), restaurant: restaurants[4], // Sweetgreen
                items: [
                    CartItem(item: restaurants[4].menu[0].items[0], quantity: 1, restaurantID: restaurants[4].id)
                ],
                startDate: daysAgo(3, hour: 12, minute: 15), etaMinutes: 18, distanceMiles: 1.3,
                scheduledFor: nil, statusIndex: 4, orderType: .delivery, destinationAddress: office
            ),
            ActiveOrder(
                id: UUID(), restaurant: restaurants[9], // Shake Shack
                items: [
                    CartItem(item: restaurants[9].menu[0].items[0], quantity: 2, restaurantID: restaurants[9].id),
                    CartItem(item: restaurants[9].menu[0].items[1], quantity: 1, restaurantID: restaurants[9].id)
                ],
                startDate: daysAgo(5, hour: 19, minute: 10), etaMinutes: 28, distanceMiles: 2.4,
                scheduledFor: nil, statusIndex: 4, orderType: .delivery, destinationAddress: home
            ),
            ActiveOrder(
                id: UUID(), restaurant: restaurants[11], // Starbucks
                items: [
                    CartItem(item: restaurants[11].menu[0].items[0], quantity: 2, restaurantID: restaurants[11].id),
                    CartItem(item: restaurants[11].menu[0].items[1], quantity: 1, restaurantID: restaurants[11].id)
                ],
                startDate: daysAgo(6, hour: 8, minute: 20), etaMinutes: 15, distanceMiles: 0.8,
                scheduledFor: nil, statusIndex: 4, orderType: .delivery, destinationAddress: home
            ),
            ActiveOrder(
                id: UUID(), restaurant: restaurants[0], // Whole Foods
                items: [
                    CartItem(item: restaurants[0].menu[0].items[0], quantity: 1, restaurantID: restaurants[0].id),
                    CartItem(item: restaurants[0].menu[0].items[2], quantity: 2, restaurantID: restaurants[0].id),
                    CartItem(item: restaurants[0].menu[2].items[0], quantity: 1, restaurantID: restaurants[0].id)
                ],
                startDate: daysAgo(8, hour: 17, minute: 30), etaMinutes: 55, distanceMiles: 1.6,
                scheduledFor: nil, statusIndex: 4, orderType: .delivery, destinationAddress: home
            ),
            ActiveOrder(
                id: UUID(), restaurant: restaurants[6], // Sugarfish
                items: [
                    CartItem(item: restaurants[6].menu[0].items[0], quantity: 1, restaurantID: restaurants[6].id),
                    CartItem(item: restaurants[6].menu[0].items[1], quantity: 1, restaurantID: restaurants[6].id)
                ],
                startDate: daysAgo(10, hour: 19, minute: 45), etaMinutes: 35, distanceMiles: 3.2,
                scheduledFor: nil, statusIndex: 4, orderType: .delivery, destinationAddress: home
            ),
            ActiveOrder(
                id: UUID(), restaurant: restaurants[15], // Panera
                items: [
                    CartItem(item: restaurants[15].menu[0].items[0], quantity: 1, restaurantID: restaurants[15].id),
                    CartItem(item: restaurants[15].menu[0].items[1], quantity: 1, restaurantID: restaurants[15].id)
                ],
                startDate: daysAgo(12, hour: 12, minute: 0), etaMinutes: 20, distanceMiles: 1.8,
                scheduledFor: nil, statusIndex: 4, orderType: .pickup, destinationAddress: office
            ),
            ActiveOrder(
                id: UUID(), restaurant: restaurants[5], // Chick-fil-A
                items: [
                    CartItem(item: restaurants[5].menu[0].items[0], quantity: 1, restaurantID: restaurants[5].id),
                    CartItem(item: restaurants[5].menu[0].items[1], quantity: 1, restaurantID: restaurants[5].id)
                ],
                startDate: daysAgo(15, hour: 13, minute: 10), etaMinutes: 25, distanceMiles: 2.9,
                scheduledFor: nil, statusIndex: 4, orderType: .delivery, destinationAddress: office
            ),
            ActiveOrder(
                id: UUID(), restaurant: restaurants[14], // Jersey Mike's
                items: [
                    CartItem(item: restaurants[14].menu[0].items[0], quantity: 1, restaurantID: restaurants[14].id)
                ],
                startDate: daysAgo(18, hour: 12, minute: 30), etaMinutes: 22, distanceMiles: 1.5,
                scheduledFor: nil, statusIndex: 4, orderType: .delivery, destinationAddress: office
            ),
            ActiveOrder(
                id: UUID(), restaurant: restaurants[3], // Pizza Hut
                items: [
                    CartItem(item: restaurants[3].menu[0].items[0], quantity: 1, restaurantID: restaurants[3].id),
                    CartItem(item: restaurants[3].menu[0].items[1], quantity: 1, restaurantID: restaurants[3].id)
                ],
                startDate: daysAgo(22, hour: 20, minute: 15), etaMinutes: 30, distanceMiles: 3.1,
                scheduledFor: nil, statusIndex: 4, orderType: .delivery, destinationAddress: home
            ),
            ActiveOrder(
                id: UUID(), restaurant: restaurants[16], // Cava
                items: [
                    CartItem(item: restaurants[16].menu[0].items[0], quantity: 1, restaurantID: restaurants[16].id)
                ],
                startDate: daysAgo(25, hour: 12, minute: 45), etaMinutes: 18, distanceMiles: 1.2,
                scheduledFor: nil, statusIndex: 4, orderType: .delivery, destinationAddress: office
            ),
            ActiveOrder(
                id: UUID(), restaurant: restaurants[2], // Domino's
                items: [
                    CartItem(item: restaurants[2].menu[0].items[0], quantity: 2, restaurantID: restaurants[2].id),
                    CartItem(item: restaurants[2].menu[0].items[1], quantity: 1, restaurantID: restaurants[2].id)
                ],
                startDate: daysAgo(30, hour: 19, minute: 0), etaMinutes: 32, distanceMiles: 2.7,
                scheduledFor: nil, statusIndex: 4, orderType: .delivery, destinationAddress: home
            ),

            ActiveOrder(
                id: UUID(), restaurant: restaurants[1], // Chipotle
                items: [
                    CartItem(item: restaurants[1].menu[0].items[0], quantity: 1, restaurantID: restaurants[1].id),
                    CartItem(item: restaurants[1].menu[2].items[0], quantity: 1, restaurantID: restaurants[1].id)
                ],
                startDate: daysAgo(33, hour: 12, minute: 20), etaMinutes: 20, distanceMiles: 2.1,
                scheduledFor: nil, statusIndex: 4, orderType: .delivery, destinationAddress: office
            ),
            ActiveOrder(
                id: UUID(), restaurant: restaurants[8], // Five Guys
                items: [
                    CartItem(item: restaurants[8].menu[0].items[2], quantity: 1, restaurantID: restaurants[8].id),
                    CartItem(item: restaurants[8].menu[1].items[0], quantity: 1, restaurantID: restaurants[8].id)
                ],
                startDate: daysAgo(36, hour: 18, minute: 45), etaMinutes: 28, distanceMiles: 2.8,
                scheduledFor: nil, statusIndex: 4, orderType: .delivery, destinationAddress: home
            ),
            ActiveOrder(
                id: UUID(), restaurant: restaurants[11], // Starbucks
                items: [
                    CartItem(item: restaurants[11].menu[0].items[0], quantity: 1, restaurantID: restaurants[11].id),
                    CartItem(item: restaurants[11].menu[2].items[0], quantity: 1, restaurantID: restaurants[11].id)
                ],
                startDate: daysAgo(39, hour: 8, minute: 10), etaMinutes: 14, distanceMiles: 0.8,
                scheduledFor: nil, statusIndex: 4, orderType: .delivery, destinationAddress: home
            ),
            ActiveOrder(
                id: UUID(), restaurant: restaurants[4], // Sweetgreen
                items: [
                    CartItem(item: restaurants[4].menu[0].items[2], quantity: 1, restaurantID: restaurants[4].id),
                    CartItem(item: restaurants[4].menu[2].items[0], quantity: 1, restaurantID: restaurants[4].id)
                ],
                startDate: daysAgo(41, hour: 12, minute: 40), etaMinutes: 22, distanceMiles: 1.3,
                scheduledFor: nil, statusIndex: 4, orderType: .delivery, destinationAddress: office
            ),
            ActiveOrder(
                id: UUID(), restaurant: restaurants[17], // DashMart
                items: [
                    CartItem(item: restaurants[17].menu[0].items[0], quantity: 2, restaurantID: restaurants[17].id),
                    CartItem(item: restaurants[17].menu[0].items[1], quantity: 1, restaurantID: restaurants[17].id),
                    CartItem(item: restaurants[17].menu[0].items[2], quantity: 1, restaurantID: restaurants[17].id)
                ],
                startDate: daysAgo(44, hour: 21, minute: 15), etaMinutes: 18, distanceMiles: 1.0,
                scheduledFor: nil, statusIndex: 4, orderType: .delivery, destinationAddress: home
            ),
            ActiveOrder(
                id: UUID(), restaurant: restaurants[3], // Pizza Hut
                items: [
                    CartItem(item: restaurants[3].menu[0].items[2], quantity: 1, restaurantID: restaurants[3].id),
                    CartItem(item: restaurants[3].menu[1].items[0], quantity: 1, restaurantID: restaurants[3].id),
                    CartItem(item: restaurants[3].menu[2].items[0], quantity: 1, restaurantID: restaurants[3].id)
                ],
                startDate: daysAgo(50, hour: 19, minute: 30), etaMinutes: 35, distanceMiles: 3.1,
                scheduledFor: nil, statusIndex: 4, orderType: .delivery, destinationAddress: home
            ),
            ActiveOrder(
                id: UUID(), restaurant: restaurants[1], // Chipotle
                items: [
                    CartItem(item: restaurants[1].menu[1].items[0], quantity: 1, restaurantID: restaurants[1].id)
                ],
                startDate: daysAgo(53, hour: 11, minute: 50), etaMinutes: 18, distanceMiles: 2.1,
                scheduledFor: nil, statusIndex: 4, orderType: .pickup, destinationAddress: office
            ),
            ActiveOrder(
                id: UUID(), restaurant: restaurants[16], // CAVA
                items: [
                    CartItem(item: restaurants[16].menu[0].items[0], quantity: 1, restaurantID: restaurants[16].id),
                    CartItem(item: restaurants[16].menu[2].items[0], quantity: 1, restaurantID: restaurants[16].id)
                ],
                startDate: daysAgo(55, hour: 12, minute: 10), etaMinutes: 22, distanceMiles: 1.2,
                scheduledFor: nil, statusIndex: 4, orderType: .delivery, destinationAddress: office
            ),
            ActiveOrder(
                id: UUID(), restaurant: restaurants[20], // CVS Pharmacy
                items: [
                    CartItem(item: restaurants[20].menu[0].items[2], quantity: 1, restaurantID: restaurants[20].id),
                    CartItem(item: restaurants[20].menu[0].items[0], quantity: 1, restaurantID: restaurants[20].id),
                    CartItem(item: restaurants[20].menu[2].items[1], quantity: 2, restaurantID: restaurants[20].id)
                ],
                startDate: daysAgo(58, hour: 20, minute: 5), etaMinutes: 24, distanceMiles: 1.7,
                scheduledFor: nil, statusIndex: 4, orderType: .delivery, destinationAddress: home
            ),
            ActiveOrder(
                id: UUID(), restaurant: restaurants[15], // Panera Bread
                items: [
                    CartItem(item: restaurants[15].menu[0].items[0], quantity: 2, restaurantID: restaurants[15].id),
                    CartItem(item: restaurants[15].menu[1].items[0], quantity: 1, restaurantID: restaurants[15].id)
                ],
                startDate: daysAgo(62, hour: 11, minute: 30), etaMinutes: 20, distanceMiles: 1.8,
                scheduledFor: nil, statusIndex: 4, orderType: .pickup, destinationAddress: home
            ),
            ActiveOrder(
                id: UUID(), restaurant: restaurants[13], // Kung Fu Tea
                items: [
                    CartItem(item: restaurants[13].menu[0].items[0], quantity: 1, restaurantID: restaurants[13].id),
                    CartItem(item: restaurants[13].menu[0].items[1], quantity: 1, restaurantID: restaurants[13].id)
                ],
                startDate: daysAgo(64, hour: 14, minute: 30), etaMinutes: 16, distanceMiles: 1.2,
                scheduledFor: nil, statusIndex: 4, orderType: .delivery, destinationAddress: office
            ),
            ActiveOrder(
                id: UUID(), restaurant: restaurants[7], // Nobu
                items: [
                    CartItem(item: restaurants[7].menu[0].items[0], quantity: 1, restaurantID: restaurants[7].id),
                    CartItem(item: restaurants[7].menu[0].items[1], quantity: 1, restaurantID: restaurants[7].id),
                    CartItem(item: restaurants[7].menu[2].items[2], quantity: 1, restaurantID: restaurants[7].id)
                ],
                startDate: daysAgo(71, hour: 19, minute: 15), etaMinutes: 45, distanceMiles: 3.6,
                scheduledFor: nil, statusIndex: 4, orderType: .delivery, destinationAddress: home
            ),
            ActiveOrder(
                id: UUID(), restaurant: restaurants[5], // Chick-fil-A
                items: [
                    CartItem(item: restaurants[5].menu[0].items[1], quantity: 1, restaurantID: restaurants[5].id),
                    CartItem(item: restaurants[5].menu[1].items[0], quantity: 1, restaurantID: restaurants[5].id),
                    CartItem(item: restaurants[5].menu[2].items[0], quantity: 1, restaurantID: restaurants[5].id)
                ],
                startDate: daysAgo(76, hour: 12, minute: 55), etaMinutes: 20, distanceMiles: 2.4,
                scheduledFor: nil, statusIndex: 4, orderType: .delivery, destinationAddress: office
            ),
            ActiveOrder(
                id: UUID(), restaurant: restaurants[2], // Domino's
                items: [
                    CartItem(item: restaurants[2].menu[0].items[0], quantity: 2, restaurantID: restaurants[2].id),
                    CartItem(item: restaurants[2].menu[0].items[1], quantity: 1, restaurantID: restaurants[2].id),
                    CartItem(item: restaurants[2].menu[1].items[0], quantity: 2, restaurantID: restaurants[2].id)
                ],
                startDate: daysAgo(80, hour: 20, minute: 0), etaMinutes: 35, distanceMiles: 2.7,
                scheduledFor: nil, statusIndex: 4, orderType: .delivery, destinationAddress: home
            ),
            ActiveOrder(
                id: UUID(), restaurant: restaurants[11], // Starbucks
                items: [
                    CartItem(item: restaurants[11].menu[1].items[0], quantity: 2, restaurantID: restaurants[11].id),
                    CartItem(item: restaurants[11].menu[2].items[1], quantity: 2, restaurantID: restaurants[11].id)
                ],
                startDate: daysAgo(81, hour: 9, minute: 15), etaMinutes: 15, distanceMiles: 0.8,
                scheduledFor: nil, statusIndex: 4, orderType: .delivery, destinationAddress: home
            ),
            ActiveOrder(
                id: UUID(), restaurant: restaurants[18], // Total Wine & More
                items: [
                    CartItem(item: restaurants[18].menu[0].items[1], quantity: 2, restaurantID: restaurants[18].id),
                    CartItem(item: restaurants[18].menu[1].items[0], quantity: 1, restaurantID: restaurants[18].id)
                ],
                startDate: daysAgo(78, hour: 16, minute: 30), etaMinutes: 30, distanceMiles: 2.6,
                scheduledFor: nil, statusIndex: 4, orderType: .delivery, destinationAddress: home
            ),
            ActiveOrder(
                id: UUID(), restaurant: restaurants[10], // Levain Bakery
                items: [
                    CartItem(item: restaurants[10].menu[2].items[0], quantity: 1, restaurantID: restaurants[10].id),
                    CartItem(item: restaurants[10].menu[1].items[0], quantity: 1, restaurantID: restaurants[10].id)
                ],
                startDate: daysAgo(83, hour: 14, minute: 0), etaMinutes: 28, distanceMiles: 1.4,
                scheduledFor: nil, statusIndex: 4, orderType: .delivery, destinationAddress: home
            ),
            ActiveOrder(
                id: UUID(), restaurant: restaurants[9], // Shake Shack
                items: [
                    CartItem(item: restaurants[9].menu[0].items[1], quantity: 2, restaurantID: restaurants[9].id),
                    CartItem(item: restaurants[9].menu[1].items[1], quantity: 1, restaurantID: restaurants[9].id),
                    CartItem(item: restaurants[9].menu[2].items[0], quantity: 2, restaurantID: restaurants[9].id)
                ],
                startDate: daysAgo(86, hour: 18, minute: 30), etaMinutes: 25, distanceMiles: 2.0,
                scheduledFor: nil, statusIndex: 4, orderType: .delivery, destinationAddress: home
            ),
            ActiveOrder(
                id: UUID(), restaurant: restaurants[17], // DashMart
                items: [
                    CartItem(item: restaurants[17].menu[1].items[0], quantity: 1, restaurantID: restaurants[17].id),
                    CartItem(item: restaurants[17].menu[2].items[1], quantity: 1, restaurantID: restaurants[17].id)
                ],
                startDate: daysAgo(89, hour: 17, minute: 45), etaMinutes: 16, distanceMiles: 1.0,
                scheduledFor: nil, statusIndex: 4, orderType: .delivery, destinationAddress: home
            ),
            ActiveOrder(
                id: UUID(), restaurant: restaurants[14], // Jersey Mike's
                items: [
                    CartItem(item: restaurants[14].menu[0].items[0], quantity: 1, restaurantID: restaurants[14].id),
                    CartItem(item: restaurants[14].menu[2].items[0], quantity: 1, restaurantID: restaurants[14].id)
                ],
                startDate: daysAgo(92, hour: 11, minute: 45), etaMinutes: 22, distanceMiles: 1.5,
                scheduledFor: nil, statusIndex: 4, orderType: .delivery, destinationAddress: office
            ),
            ActiveOrder(
                id: UUID(), restaurant: restaurants[15], // Panera Bread
                items: [
                    CartItem(item: restaurants[15].menu[1].items[2], quantity: 1, restaurantID: restaurants[15].id),
                    CartItem(item: restaurants[15].menu[0].items[0], quantity: 1, restaurantID: restaurants[15].id)
                ],
                startDate: daysAgo(94, hour: 11, minute: 15), etaMinutes: 25, distanceMiles: 1.3,
                scheduledFor: nil, statusIndex: 4, orderType: .pickup, destinationAddress: home
            ),
            ActiveOrder(
                id: UUID(), restaurant: restaurants[1], // Chipotle
                items: [
                    CartItem(item: restaurants[1].menu[0].items[1], quantity: 1, restaurantID: restaurants[1].id),
                    CartItem(item: restaurants[1].menu[1].items[2], quantity: 1, restaurantID: restaurants[1].id),
                    CartItem(item: restaurants[1].menu[2].items[1], quantity: 1, restaurantID: restaurants[1].id)
                ],
                startDate: daysAgo(95, hour: 19, minute: 40), etaMinutes: 24, distanceMiles: 2.1,
                scheduledFor: nil, statusIndex: 4, orderType: .delivery, destinationAddress: home
            )
        ]
    }

    var selectedAddress: Address {
        addresses.first { $0.id == selectedAddressID } ?? addresses[0]
    }

    var cartRestaurant: Restaurant? {
        guard let restaurantID = cartItems.first?.restaurantID else { return nil }
        return restaurants.first { $0.id == restaurantID }
    }

    var cartItemCount: Int {
        cartItems.reduce(0) { $0 + $1.quantity }
    }

    var cartTotal: Double {
        cartItems.reduce(0) { $0 + (Double($1.quantity) * $1.item.price) }
    }

    var selectedPaymentAccount: PaymentAccount? {
        guard let id = selectedPaymentAccountId else { return nil }
        return paymentAccounts.first(where: { $0.id == id })
    }

    private func preferredCheckoutAccount() -> PaymentAccount? {
        paymentAccounts.first(where: { $0.type == .credit }) ?? paymentAccounts.first
    }

    var orderTotals: OrderTotals {
        let subtotal = cartTotal
        let deliveryFee = subtotal > 0 && selectedOrderType == .delivery ? 1.99 : 0
        let serviceFee = subtotal > 0 ? 2.99 : 0
        let tax = subtotal * 0.0825
        let tipAmounts: [Double] = [0, 2, 3, 4]
        let tip = selectedTipIndex < tipAmounts.count ? tipAmounts[selectedTipIndex] : subtotal * 0.15
        return OrderTotals(subtotal: subtotal, deliveryFee: deliveryFee, serviceFee: serviceFee, tax: tax, tip: tip)
    }

    func refreshPaymentAccounts() {
        paymentAccounts = accountsService.loadAccounts()
        if selectedPaymentAccountId == nil || !paymentAccounts.contains(where: { $0.id == selectedPaymentAccountId }) {
            selectedPaymentAccountId = preferredCheckoutAccount()?.id
        }
        notify()
    }

    func setPaymentAccount(_ account: PaymentAccount) {
        selectedPaymentAccountId = account.id
        notify()
    }

    func addPaymentAccount(_ account: PaymentAccount) {
        paymentAccounts.append(account)
        if selectedPaymentAccountId == nil {
            selectedPaymentAccountId = account.id
        }
        notify()
    }

    func removePaymentAccount(at index: Int) {
        guard index < paymentAccounts.count else { return }
        let removed = paymentAccounts.remove(at: index)
        if selectedPaymentAccountId == removed.id {
            selectedPaymentAccountId = paymentAccounts.first?.id
        }
        notify()
    }

    func validateCheckout() -> Result<Void, OrderPlacementError> {
        guard cartRestaurant != nil, !cartItems.isEmpty else {
            return .failure(.emptyCart)
        }

        let paymentAccount = selectedPaymentAccount ?? preferredCheckoutAccount()
        if let fallback = paymentAccount, selectedPaymentAccountId == nil {
            selectedPaymentAccountId = fallback.id
        }
        guard let paymentAccount else {
            return .failure(.missingPaymentMethod)
        }

        let total = orderTotals.total
        guard paymentAccount.availableForSpending >= total else {
            return .failure(.insufficientFunds(required: total, available: paymentAccount.availableForSpending))
        }

        return .success(())
    }

    func restaurants(for category: DashCategory) -> [Restaurant] {
        restaurants.filter { $0.tags.contains(category.title) || $0.cuisine == category.title }
    }

    func selectAddress(_ address: Address) {
        selectedAddressID = address.id
        notify()
    }

    func addAddress(_ address: Address) {
        addresses.append(address)
        selectedAddressID = address.id
        notify()
    }

    func setScheduledDelivery(_ date: Date?) {
        scheduledDelivery = date
        notify()
    }

    func setOrderType(_ orderType: OrderType) {
        selectedOrderType = orderType
        notify()
    }

    func add(item: MenuItem, from restaurant: Restaurant) {
        if let existingRestaurant = cartItems.first?.restaurantID, existingRestaurant != restaurant.id {
            cartItems.removeAll()
        }

        if let index = cartItems.firstIndex(where: { $0.item.id == item.id && $0.restaurantID == restaurant.id }) {
            cartItems[index].quantity += 1
        } else {
            cartItems.append(CartItem(item: item, quantity: 1, restaurantID: restaurant.id))
        }
        notify()
    }

    func updateQuantity(for item: MenuItem, restaurantID: UUID, delta: Int) {
        guard let index = cartItems.firstIndex(where: { $0.item.id == item.id && $0.restaurantID == restaurantID }) else { return }
        cartItems[index].quantity += delta
        if cartItems[index].quantity <= 0 {
            cartItems.remove(at: index)
        }
        notify()
    }

    func clearCart() {
        cartItems.removeAll()
        scheduledDelivery = nil
        notify()
    }

    func placeOrder() -> Result<ActiveOrder, OrderPlacementError> {
        guard let restaurant = cartRestaurant, !cartItems.isEmpty else {
            return .failure(.emptyCart)
        }
        let paymentAccount = selectedPaymentAccount ?? preferredCheckoutAccount()
        if let fallback = paymentAccount, selectedPaymentAccountId == nil {
            selectedPaymentAccountId = fallback.id
        }
        guard let paymentAccount else {
            return .failure(.missingPaymentMethod)
        }
        let total = orderTotals.total
        if paymentAccount.availableForSpending < total {
            return .failure(.insufficientFunds(required: total, available: paymentAccount.availableForSpending))
        }
        let eta: Int
        if selectedOrderType == .pickup {
            let parts = restaurant.pickupEta.components(separatedBy: "-")
            let low = Int(parts.first?.trimmingCharacters(in: .letters.union(.whitespaces)) ?? "15") ?? 15
            let high = Int(parts.last?.trimmingCharacters(in: .letters.union(.whitespaces)) ?? "25") ?? 25
            eta = Int.random(in: low...max(low, high))
        } else {
            eta = Int.random(in: 18...35)
        }
        let distance = max(1.0, restaurant.distanceMiles)
        let order = ActiveOrder(
            id: UUID(),
            restaurant: restaurant,
            items: cartItems,
            startDate: Date(),
            etaMinutes: eta,
            distanceMiles: distance,
            scheduledFor: scheduledDelivery,
            statusIndex: 0,
            orderType: selectedOrderType,
            destinationAddress: selectedAddress
        )
        activeOrder = order
        scheduleAutoCompletion(orderID: order.id)
        clearCart()
        notify()
        return .success(order)
    }

    func completeActiveOrder() {
        guard let order = activeOrder else { return }
        pastOrders.insert(order, at: 0)
        activeOrder = nil
        autoCompleteWorkItem?.cancel()
        autoCompleteWorkItem = nil
        notify()
    }

    private func scheduleAutoCompletion(orderID: UUID) {
        autoCompleteWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self, self.activeOrder?.id == orderID else { return }
            self.completeActiveOrder()
        }
        autoCompleteWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + autoCompleteInterval, execute: workItem)
    }

    private func notify() {
        persistCart()
        NotificationCenter.default.post(name: .dashStoreDidChange, object: nil)
    }

    private func persistCart() {
        let entries = cartItems.map { PersistedCartEntry(itemID: $0.item.id, restaurantID: $0.restaurantID, quantity: $0.quantity) }
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: cartPersistenceKey)
        }
    }

    private func loadPersistedCart() {
        guard let data = UserDefaults.standard.data(forKey: cartPersistenceKey),
              let entries = try? JSONDecoder().decode([PersistedCartEntry].self, from: data) else { return }
        var restored: [CartItem] = []
        for entry in entries {
            guard let restaurant = restaurants.first(where: { $0.id == entry.restaurantID }) else { continue }
            var menuItem: MenuItem?
            for section in restaurant.menu {
                if let match = section.items.first(where: { $0.id == entry.itemID }) {
                    menuItem = match
                    break
                }
            }
            if let item = menuItem {
                restored.append(CartItem(item: item, quantity: entry.quantity, restaurantID: entry.restaurantID))
            }
        }
        cartItems = restored
    }
}

// MARK: - Style

enum DashStyle {
    static let red = UIColor(red: 1.0, green: 0.19, blue: 0.03, alpha: 1) // #FF3008 QuickBite red
    static let darkRed = UIColor(red: 0.80, green: 0.14, blue: 0.02, alpha: 1)
    static let lightGray = UIColor(white: 0.96, alpha: 1)
    static let cardShadow = UIColor(white: 0, alpha: 0.08)
    static let separator = UIColor(white: 0.92, alpha: 1)
    static let greenBadge = UIColor(red: 0.0, green: 0.65, blue: 0.31, alpha: 1) // DashPass green
    static let ratingGray = UIColor(white: 0.35, alpha: 1)
    static let subtextGray = UIColor(white: 0.45, alpha: 1)
}

// MARK: - Home

final class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let cartBar = CartBarView()
    private let headerView = HomeHeaderView()
    private var restaurants: [Restaurant] = []
    private var sortOption: RestaurantSortOption = .featured

    enum Section: Int, CaseIterable {
        case categories
        case promo
        case fastestNearYou
        case nationalFavorites
        case popular

        var title: String {
            switch self {
            case .categories:
                return ""
            case .promo:
                return ""
            case .fastestNearYou:
                return "Fastest Near You"
            case .nationalFavorites:
                return "National Favorites"
            case .popular:
                return "All Restaurants"
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = ""
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = false
        configureNav()
        configureTable()
        applySort()
        configureCartBar()
        NotificationCenter.default.addObserver(self, selector: #selector(handleStoreChange), name: .dashStoreDidChange, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateAddressTitle()
        updateCartBar()
    }

    private func configureNav() {
        let cartButton = UIButton(type: .system)
        cartButton.setImage(UIImage(systemName: "cart"), for: .normal)
        cartButton.tintColor = .label
        cartButton.addTarget(self, action: #selector(openCart), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cartButton)
        updateAddressTitle()
    }

    private func updateAddressTitle() {
        let address = DashStore.shared.selectedAddress
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let topLabel = UILabel()
        topLabel.translatesAutoresizingMaskIntoConstraints = false
        topLabel.text = DashStore.shared.selectedOrderType == .pickup ? "Pickup" : "Deliver now"
        topLabel.font = .systemFont(ofSize: 12, weight: .regular)
        topLabel.textColor = .secondaryLabel

        let bottomStack = UIStackView()
        bottomStack.translatesAutoresizingMaskIntoConstraints = false
        bottomStack.axis = .horizontal
        bottomStack.spacing = 4
        bottomStack.alignment = .center

        let addressLabel = UILabel()
        addressLabel.text = address.detail
        addressLabel.font = .systemFont(ofSize: 15, weight: .bold)
        addressLabel.textColor = .label

        let chevron = UIImageView(image: UIImage(systemName: "chevron.down"))
        chevron.tintColor = .label
        chevron.contentMode = .scaleAspectFit
        chevron.widthAnchor.constraint(equalToConstant: 12).isActive = true
        chevron.heightAnchor.constraint(equalToConstant: 12).isActive = true

        bottomStack.addArrangedSubview(addressLabel)
        bottomStack.addArrangedSubview(chevron)

        let stack = UIStackView(arrangedSubviews: [topLabel, bottomStack])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 1

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(openAddresses))
        container.addGestureRecognizer(tap)
        container.isUserInteractionEnabled = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: container)
    }

    private func configureTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .none
        tableView.register(CategoryChipsCell.self, forCellReuseIdentifier: "CategoryChipsCell")
        tableView.register(HorizontalRestaurantsCell.self, forCellReuseIdentifier: "HorizontalRestaurantsCell")
        tableView.register(RestaurantListCell.self, forCellReuseIdentifier: "RestaurantListCell")
        tableView.register(PromoBannerCell.self, forCellReuseIdentifier: "PromoBannerCell")
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 44
        tableView.sectionFooterHeight = 4
        headerView.onSortTap = { [weak self] in
            self?.presentSortSheet()
        }
        headerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 48)
        tableView.tableHeaderView = headerView
        tableView.contentInset.bottom = 70

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureCartBar() {
        cartBar.translatesAutoresizingMaskIntoConstraints = false
        cartBar.isHidden = true
        cartBar.onTap = { [weak self] in
            self?.openCart()
        }
        view.addSubview(cartBar)

        NSLayoutConstraint.activate([
            cartBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            cartBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            cartBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            cartBar.heightAnchor.constraint(equalToConstant: 54)
        ])
    }

    @objc private func handleStoreChange() {
        updateAddressTitle()
        updateCartBar()
    }

    private func applySort() {
        restaurants = sortRestaurants(DashStore.shared.restaurants, by: sortOption)
        tableView.reloadData()
    }

    private func presentSortSheet() {
        let alert = UIAlertController(title: "Sort", message: nil, preferredStyle: .actionSheet)
        RestaurantSortOption.allCases.forEach { option in
            let action = UIAlertAction(title: option.title, style: .default) { [weak self] _ in
                self?.sortOption = option
                self?.applySort()
            }
            if option == sortOption {
                action.setValue(true, forKey: "checked")
            }
            alert.addAction(action)
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let popover = alert.popoverPresentationController {
            popover.sourceView = headerView
            popover.sourceRect = CGRect(x: headerView.bounds.midX, y: headerView.bounds.maxY, width: 1, height: 1)
        }
        present(alert, animated: true)
    }

    private func updateCartBar() {
        cartBar.update()
        cartBar.isHidden = DashStore.shared.cartItemCount == 0
    }

    @objc private func openCart() {
        let cart = CartViewController()
        navigationController?.pushViewController(cart, animated: true)
    }

    @objc private func openAddresses() {
        let list = AddressListViewController()
        navigationController?.pushViewController(list, animated: true)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .categories, .promo:
            return 1
        case .fastestNearYou, .nationalFavorites:
            return 1
        case .popular:
            return restaurants.count
        case .none:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let sectionType = Section(rawValue: section), !sectionType.title.isEmpty else { return nil }
        let header = SectionHeaderView()
        header.configure(title: sectionType.title)
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let sectionType = Section(rawValue: section), !sectionType.title.isEmpty else { return 0 }
        _ = sectionType
        return 44
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else { return UITableViewCell() }
        switch section {
        case .categories:
            let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryChipsCell", for: indexPath) as? CategoryChipsCell
            cell?.configure(categories: DashStore.shared.categories) { [weak self] category in
                self?.openCategory(category)
            }
            return cell ?? UITableViewCell()
        case .promo:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PromoBannerCell", for: indexPath) as? PromoBannerCell
            return cell ?? UITableViewCell()
        case .fastestNearYou:
            let cell = tableView.dequeueReusableCell(withIdentifier: "HorizontalRestaurantsCell", for: indexPath) as? HorizontalRestaurantsCell
            let fastest = restaurants.sorted { $0.distanceMiles < $1.distanceMiles }.prefix(6)
            cell?.configure(restaurants: Array(fastest)) { [weak self] restaurant in
                self?.openRestaurant(restaurant)
            }
            return cell ?? UITableViewCell()
        case .nationalFavorites:
            let cell = tableView.dequeueReusableCell(withIdentifier: "HorizontalRestaurantsCell", for: indexPath) as? HorizontalRestaurantsCell
            let favorites = restaurants.sorted { $0.ratingCount > $1.ratingCount }.prefix(6)
            cell?.configure(restaurants: Array(favorites)) { [weak self] restaurant in
                self?.openRestaurant(restaurant)
            }
            return cell ?? UITableViewCell()
        case .popular:
            let cell = tableView.dequeueReusableCell(withIdentifier: "RestaurantListCell", for: indexPath) as? RestaurantListCell
            let restaurant = restaurants[indexPath.row]
            cell?.configure(with: restaurant)
            return cell ?? UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard Section(rawValue: indexPath.section) == .popular else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        let restaurant = restaurants[indexPath.row]
        openRestaurant(restaurant)
    }

    private func openRestaurant(_ restaurant: Restaurant) {
        let detail = RestaurantDetailViewController(restaurant: restaurant)
        navigationController?.pushViewController(detail, animated: true)
    }

    private func openCategory(_ category: DashCategory) {
        let results = CategoryResultsViewController(category: category)
        navigationController?.pushViewController(results, animated: true)
    }
}

// MARK: - Promo Banner

final class PromoBannerCell: UITableViewCell {
    private let bannerView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let iconView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .systemBackground
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        bannerView.backgroundColor = UIColor(red: 0.0, green: 0.28, blue: 0.15, alpha: 1)
        bannerView.layer.cornerRadius = 14
        bannerView.clipsToBounds = true
        contentView.addSubview(bannerView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Try DashPass for free"
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .white

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "$0 delivery fee and reduced service fees on eligible orders"
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        subtitleLabel.numberOfLines = 2

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = UIImage(systemName: "bolt.fill")
        iconView.tintColor = DashStyle.greenBadge
        iconView.contentMode = .scaleAspectFit

        bannerView.addSubview(titleLabel)
        bannerView.addSubview(subtitleLabel)
        bannerView.addSubview(iconView)

        NSLayoutConstraint.activate([
            bannerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bannerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            bannerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bannerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            bannerView.heightAnchor.constraint(equalToConstant: 90),

            iconView.trailingAnchor.constraint(equalTo: bannerView.trailingAnchor, constant: -16),
            iconView.centerYAnchor.constraint(equalTo: bannerView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 36),
            iconView.heightAnchor.constraint(equalToConstant: 36),

            titleLabel.leadingAnchor.constraint(equalTo: bannerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: iconView.leadingAnchor, constant: -12),
            titleLabel.topAnchor.constraint(equalTo: bannerView.topAnchor, constant: 18),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6)
        ])
    }

}

final class HomeHeaderView: UIView {
    private let chipsScroll = UIScrollView()
    private let chipsStack = UIStackView()
    var onSortTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        chipsScroll.translatesAutoresizingMaskIntoConstraints = false
        chipsScroll.showsHorizontalScrollIndicator = false
        addSubview(chipsScroll)

        chipsStack.translatesAutoresizingMaskIntoConstraints = false
        chipsStack.axis = .horizontal
        chipsStack.spacing = 8
        chipsScroll.addSubview(chipsStack)

        let dashPassChip = FilterChip(title: "DashPass", icon: "bolt.fill", highlighted: true)
        chipsStack.addArrangedSubview(dashPassChip)
        chipsStack.addArrangedSubview(FilterChip(title: "Pickup", icon: "bag.fill", highlighted: false))
        chipsStack.addArrangedSubview(FilterChip(title: "Offers", icon: "tag.fill", highlighted: false))
        chipsStack.addArrangedSubview(FilterChip(title: "Under 30 min", icon: "clock.fill", highlighted: false))
        let sortChip = FilterChip(title: "Sort", icon: "arrow.up.arrow.down", highlighted: false)
        sortChip.addTarget(self, action: #selector(sortTapped), for: .touchUpInside)
        chipsStack.addArrangedSubview(sortChip)
        chipsStack.addArrangedSubview(FilterChip(title: "Price", icon: "dollarsign.circle.fill", highlighted: false))
        chipsStack.addArrangedSubview(FilterChip(title: "Rating", icon: "star.fill", highlighted: false))

        NSLayoutConstraint.activate([
            chipsScroll.leadingAnchor.constraint(equalTo: leadingAnchor),
            chipsScroll.trailingAnchor.constraint(equalTo: trailingAnchor),
            chipsScroll.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            chipsScroll.heightAnchor.constraint(equalToConstant: 36),

            chipsStack.leadingAnchor.constraint(equalTo: chipsScroll.leadingAnchor, constant: 16),
            chipsStack.trailingAnchor.constraint(equalTo: chipsScroll.trailingAnchor, constant: -16),
            chipsStack.topAnchor.constraint(equalTo: chipsScroll.topAnchor),
            chipsStack.bottomAnchor.constraint(equalTo: chipsScroll.bottomAnchor),
            chipsStack.heightAnchor.constraint(equalTo: chipsScroll.heightAnchor)
        ])
    }

    @objc private func sortTapped() {
        onSortTap?()
    }
}

final class FilterChip: UIButton {
    init(title: String, icon: String, highlighted: Bool = false) {
        super.init(frame: .zero)
        var config = UIButton.Configuration.filled()
        config.title = title
        config.image = UIImage(systemName: icon)?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 11, weight: .medium))
        config.imagePadding = 4
        config.contentInsets = NSDirectionalEdgeInsets(top: 7, leading: 12, bottom: 7, trailing: 12)
        config.cornerStyle = .capsule
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 13, weight: .medium)
            return outgoing
        }
        if highlighted {
            config.baseBackgroundColor = DashStyle.red
            config.baseForegroundColor = .white
        } else {
            config.baseBackgroundColor = DashStyle.lightGray
            config.baseForegroundColor = .label
        }
        configuration = config
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class SectionHeaderView: UIView {
    private let titleLabel = UILabel()
    private let seeAllButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .label

        seeAllButton.translatesAutoresizingMaskIntoConstraints = false
        seeAllButton.setTitle("See All", for: .normal)
        seeAllButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        seeAllButton.setTitleColor(DashStyle.red, for: .normal)

        addSubview(titleLabel)
        addSubview(seeAllButton)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            seeAllButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            seeAllButton.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    func configure(title: String) {
        titleLabel.text = title
    }
}

final class CategoryChipsCell: UITableViewCell {
    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .systemBackground
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        contentView.addSubview(scrollView)

        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 12
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stack.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
    }

    func configure(categories: [DashCategory], selectedTitle: String? = nil, onSelect: @escaping (DashCategory) -> Void) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for category in categories {
            let view = CategoryChipView()
            view.configure(category: category, isSelected: category.title == selectedTitle) {
                onSelect(category)
            }
            stack.addArrangedSubview(view)
        }
    }
}

final class CategoryChipView: UIControl {
    private let iconView = UIImageView()
    private let iconContainer = UIView()
    private let label = UILabel()
    private var onTap: (() -> Void)?

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.15) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.92, y: 0.92) : .identity
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        translatesAutoresizingMaskIntoConstraints = false
        accessibilityTraits = .button
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit

        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        label.textColor = .label

        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.layer.cornerRadius = 26
        iconContainer.addSubview(iconView)

        addSubview(iconContainer)
        addSubview(label)
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 64),

            iconContainer.topAnchor.constraint(equalTo: topAnchor),
            iconContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 52),
            iconContainer.heightAnchor.constraint(equalToConstant: 52),

            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),

            label.topAnchor.constraint(equalTo: iconContainer.bottomAnchor, constant: 6),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func configure(category: DashCategory, isSelected: Bool = false, onTap: @escaping () -> Void) {
        self.onTap = onTap
        iconView.image = UIImage(systemName: category.symbol)?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)) ?? UIImage(systemName: "circle.fill")
        label.text = category.title
        iconContainer.backgroundColor = category.color
        accessibilityLabel = category.title

        if isSelected {
            iconContainer.layer.borderWidth = 3
            iconContainer.layer.borderColor = UIColor.label.cgColor
            label.font = .systemFont(ofSize: 12, weight: .bold)
        } else {
            iconContainer.layer.borderWidth = 0
            label.font = .systemFont(ofSize: 12, weight: .medium)
        }
    }

    @objc private func handleTap() {
        onTap?()
    }
}

final class HorizontalRestaurantsCell: UITableViewCell {
    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private var onSelect: ((Restaurant) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .systemBackground
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        contentView.addSubview(scrollView)

        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 14
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stack.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
    }

    func configure(restaurants: [Restaurant], onSelect: @escaping (Restaurant) -> Void) {
        self.onSelect = onSelect
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for restaurant in restaurants {
            let card = RestaurantCardView()
            card.configure(with: restaurant)
            card.onTap = { [weak self] in
                self?.onSelect?(restaurant)
            }
            stack.addArrangedSubview(card)
        }
    }
}

final class RestaurantCardView: UIView {
    private let heroImageView = UIImageView()
    private let nameLabel = UILabel()
    private let detailLabel = UILabel()
    private let ratingBadge = UILabel()
    private let deliveryLabel = UILabel()
    var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .systemBackground

        heroImageView.translatesAutoresizingMaskIntoConstraints = false
        heroImageView.layer.cornerRadius = 10
        heroImageView.clipsToBounds = true
        heroImageView.contentMode = .scaleAspectFill

        ratingBadge.translatesAutoresizingMaskIntoConstraints = false
        ratingBadge.font = .systemFont(ofSize: 12, weight: .bold)
        ratingBadge.textColor = .white
        ratingBadge.backgroundColor = UIColor(white: 0.15, alpha: 0.85)
        ratingBadge.layer.cornerRadius = 12
        ratingBadge.clipsToBounds = true
        ratingBadge.textAlignment = .center

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.lineBreakMode = .byTruncatingTail

        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.font = .systemFont(ofSize: 12, weight: .regular)
        detailLabel.textColor = DashStyle.subtextGray

        deliveryLabel.translatesAutoresizingMaskIntoConstraints = false
        deliveryLabel.font = .systemFont(ofSize: 12, weight: .regular)
        deliveryLabel.textColor = DashStyle.subtextGray

        addSubview(heroImageView)
        heroImageView.addSubview(ratingBadge)
        addSubview(nameLabel)
        addSubview(detailLabel)
        addSubview(deliveryLabel)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 200),

            heroImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            heroImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            heroImageView.topAnchor.constraint(equalTo: topAnchor),
            heroImageView.heightAnchor.constraint(equalToConstant: 130),

            ratingBadge.leadingAnchor.constraint(equalTo: heroImageView.leadingAnchor, constant: 8),
            ratingBadge.bottomAnchor.constraint(equalTo: heroImageView.bottomAnchor, constant: -8),
            ratingBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 36),
            ratingBadge.heightAnchor.constraint(equalToConstant: 24),

            nameLabel.topAnchor.constraint(equalTo: heroImageView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            detailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            detailLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            deliveryLabel.topAnchor.constraint(equalTo: detailLabel.bottomAnchor, constant: 2),
            deliveryLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            deliveryLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            deliveryLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    func configure(with restaurant: Restaurant) {
        configureHeroImageView(heroImageView, with: restaurant, symbolPointSize: 38)
        nameLabel.text = restaurant.name
        ratingBadge.text = " \(restaurant.rating) ★ "
        detailLabel.text = "\(restaurant.eta) · \(String(format: "%.1f", restaurant.distanceMiles)) mi"
        deliveryLabel.text = restaurant.deliveryFee
    }

    @objc private func handleTap() {
        onTap?()
    }
}

final class RestaurantListCell: UITableViewCell {
    private let heroImageView = UIImageView()
    private let nameLabel = UILabel()
    private let detailLabel = UILabel()
    private let metaLabel = UILabel()
    private let ratingBadge = UIView()
    private let ratingLabel = UILabel()
    private let freeDeliveryBadge = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .systemBackground
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        heroImageView.translatesAutoresizingMaskIntoConstraints = false
        heroImageView.layer.cornerRadius = 12
        heroImageView.clipsToBounds = true
        heroImageView.contentMode = .scaleAspectFill

        ratingBadge.translatesAutoresizingMaskIntoConstraints = false
        ratingBadge.backgroundColor = UIColor(white: 0.15, alpha: 0.85)
        ratingBadge.layer.cornerRadius = 14
        ratingBadge.clipsToBounds = true

        ratingLabel.translatesAutoresizingMaskIntoConstraints = false
        ratingLabel.font = .systemFont(ofSize: 12, weight: .bold)
        ratingLabel.textColor = .white
        ratingLabel.textAlignment = .center
        ratingBadge.addSubview(ratingLabel)

        freeDeliveryBadge.translatesAutoresizingMaskIntoConstraints = false
        freeDeliveryBadge.font = .systemFont(ofSize: 11, weight: .bold)
        freeDeliveryBadge.textColor = .white
        freeDeliveryBadge.backgroundColor = DashStyle.greenBadge
        freeDeliveryBadge.layer.cornerRadius = 4
        freeDeliveryBadge.clipsToBounds = true
        freeDeliveryBadge.textAlignment = .center

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .systemFont(ofSize: 16, weight: .bold)
        nameLabel.textColor = .label

        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.font = .systemFont(ofSize: 13, weight: .regular)
        detailLabel.textColor = DashStyle.subtextGray

        metaLabel.translatesAutoresizingMaskIntoConstraints = false
        metaLabel.font = .systemFont(ofSize: 13, weight: .regular)
        metaLabel.textColor = DashStyle.subtextGray

        contentView.addSubview(heroImageView)
        heroImageView.addSubview(ratingBadge)
        heroImageView.addSubview(freeDeliveryBadge)
        contentView.addSubview(nameLabel)
        contentView.addSubview(detailLabel)
        contentView.addSubview(metaLabel)

        NSLayoutConstraint.activate([
            heroImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            heroImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            heroImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            heroImageView.heightAnchor.constraint(equalToConstant: 160),

            ratingBadge.leadingAnchor.constraint(equalTo: heroImageView.leadingAnchor, constant: 10),
            ratingBadge.bottomAnchor.constraint(equalTo: heroImageView.bottomAnchor, constant: -10),
            ratingBadge.heightAnchor.constraint(equalToConstant: 28),
            ratingBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),

            ratingLabel.leadingAnchor.constraint(equalTo: ratingBadge.leadingAnchor, constant: 8),
            ratingLabel.trailingAnchor.constraint(equalTo: ratingBadge.trailingAnchor, constant: -8),
            ratingLabel.centerYAnchor.constraint(equalTo: ratingBadge.centerYAnchor),

            freeDeliveryBadge.trailingAnchor.constraint(equalTo: heroImageView.trailingAnchor, constant: -10),
            freeDeliveryBadge.topAnchor.constraint(equalTo: heroImageView.topAnchor, constant: 10),
            freeDeliveryBadge.heightAnchor.constraint(equalToConstant: 22),

            nameLabel.leadingAnchor.constraint(equalTo: heroImageView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: heroImageView.trailingAnchor),
            nameLabel.topAnchor.constraint(equalTo: heroImageView.bottomAnchor, constant: 10),

            detailLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            detailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 3),

            metaLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            metaLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            metaLabel.topAnchor.constraint(equalTo: detailLabel.bottomAnchor, constant: 3),
            metaLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14)
        ])
    }

    func configure(with restaurant: Restaurant) {
        configureHeroImageView(heroImageView, with: restaurant, symbolPointSize: 44)
        nameLabel.text = restaurant.name
        ratingLabel.text = "\(restaurant.rating) ★"
        detailLabel.text = "\(restaurant.eta) · \(restaurant.cuisine) · \(String(format: "%.1f", restaurant.distanceMiles)) mi"
        metaLabel.text = restaurant.deliveryFee

        if restaurant.deliveryFee.contains("$0.00") {
            freeDeliveryBadge.text = " $0 delivery "
            freeDeliveryBadge.isHidden = false
        } else {
            freeDeliveryBadge.isHidden = true
        }

        // Stable accessibility id derived from the restaurant name so MCP
        // tooling can tap a specific restaurant row via
        // `tap_id("restaurant_row_<slug>")`.
        let slug = MenuItem.slug(from: restaurant.name)
        self.accessibilityIdentifier = "restaurant_row_\(slug)"
    }
}

// MARK: - Restaurant Detail

final class RestaurantDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let restaurant: Restaurant
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let cartBar = CartBarView()
    private lazy var headerView = RestaurantHeaderView(restaurant: restaurant)

    init(restaurant: Restaurant) {
        self.restaurant = restaurant
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureHeader()
        configureTable()
        configureCartBar()
        NotificationCenter.default.addObserver(self, selector: #selector(handleStoreChange), name: .dashStoreDidChange, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateHeaderLayout()
    }

    private func configureHeader() {
        tableView.tableHeaderView = headerView
        updateHeaderLayout()
    }

    private func configureTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .none
        tableView.register(MenuItemCell.self, forCellReuseIdentifier: "MenuItemCell")
        tableView.sectionHeaderHeight = 32
        tableView.contentInset.bottom = 88
        tableView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 88, right: 0)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureCartBar() {
        cartBar.translatesAutoresizingMaskIntoConstraints = false
        cartBar.isHidden = true
        cartBar.onTap = { [weak self] in
            self?.openCart()
        }
        view.addSubview(cartBar)

        NSLayoutConstraint.activate([
            cartBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            cartBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            cartBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            cartBar.heightAnchor.constraint(equalToConstant: 54)
        ])
    }

    @objc private func handleStoreChange() {
        cartBar.update()
        cartBar.isHidden = DashStore.shared.cartItemCount == 0
    }

    private func updateHeaderLayout() {
        guard tableView.bounds.width > 0 else { return }

        let targetSize = CGSize(width: tableView.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        let fittingHeight = headerView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        let height = max(1, ceil(fittingHeight))

        if headerView.frame.width != tableView.bounds.width || headerView.frame.height != height {
            headerView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: height)
            tableView.tableHeaderView = headerView
        }
    }

    private func openCart() {
        let cart = CartViewController()
        navigationController?.pushViewController(cart, animated: true)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        restaurant.menu.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        restaurant.menu[section].items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        restaurant.menu[section].title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MenuItemCell", for: indexPath) as? MenuItemCell else {
            return UITableViewCell()
        }
        let item = restaurant.menu[indexPath.section].items[indexPath.row]
        cell.configure(item: item)
        let currentRestaurant = restaurant
        cell.onAdd = {
            DashStore.shared.add(item: item, from: currentRestaurant)
        }
        return cell
    }

    // Tapping a menu row opens the item's detail screen (the + button on the
    // row still does a one-tap quick-add, unchanged).
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = restaurant.menu[indexPath.section].items[indexPath.row]
        let detail = MenuItemDetailViewController(item: item, restaurant: restaurant)
        navigationController?.pushViewController(detail, animated: true)
    }
}

// MARK: - Menu Item Detail

/// Full-screen detail for a single menu item — tapped from a menu row.
/// Shows the item's art, price, and description, with a prominent
/// "Add to Cart" button that drops it into the order.
final class MenuItemDetailViewController: UIViewController {
    private let item: MenuItem
    private let restaurant: Restaurant
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let addButton = UIButton(type: .system)

    init(item: MenuItem, restaurant: Restaurant) {
        self.item = item
        self.restaurant = restaurant
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = item.name
        view.accessibilityIdentifier = "menu_item_detail_\(item.slug)"
        configureContent()
        configureAddButton()
    }

    private func configureContent() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.alignment = .fill
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 24, right: 20)
        scrollView.addSubview(contentStack)

        // Hero panel — the item's appearance icon on a tinted card.
        let appearance = MenuItemAppearance.lookup(name: item.name, detail: item.detail)
        let hero = UIView()
        hero.backgroundColor = appearance.tint.withAlphaComponent(0.18)
        hero.layer.cornerRadius = 18
        let heroIcon = UIImageView()
        heroIcon.translatesAutoresizingMaskIntoConstraints = false
        heroIcon.contentMode = .scaleAspectFit
        heroIcon.tintColor = appearance.tint
        heroIcon.image = UIImage(systemName: appearance.symbol)?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 68, weight: .semibold))
        hero.addSubview(heroIcon)
        NSLayoutConstraint.activate([
            hero.heightAnchor.constraint(equalToConstant: 200),
            heroIcon.centerXAnchor.constraint(equalTo: hero.centerXAnchor),
            heroIcon.centerYAnchor.constraint(equalTo: hero.centerYAnchor)
        ])

        let nameLabel = UILabel()
        nameLabel.font = .systemFont(ofSize: 24, weight: .bold)
        nameLabel.numberOfLines = 0
        nameLabel.text = item.name
        nameLabel.accessibilityIdentifier = "menu_item_detail_name"

        let fromLabel = UILabel()
        fromLabel.font = .systemFont(ofSize: 14, weight: .regular)
        fromLabel.textColor = DashStyle.subtextGray
        fromLabel.text = "from \(restaurant.name)"

        let priceLabel = UILabel()
        priceLabel.font = .systemFont(ofSize: 19, weight: .semibold)
        priceLabel.text = String(format: "$%.2f", item.price)
        priceLabel.accessibilityIdentifier = "menu_item_detail_price"
        priceLabel.setContentHuggingPriority(.required, for: .horizontal)

        let priceRow = UIStackView()
        priceRow.axis = .horizontal
        priceRow.spacing = 10
        priceRow.alignment = .firstBaseline
        priceRow.addArrangedSubview(priceLabel)
        if let badge = item.badge {
            let badgeLabel = UILabel()
            badgeLabel.font = .systemFont(ofSize: 12, weight: .bold)
            badgeLabel.textColor = DashStyle.red
            badgeLabel.text = badge
            priceRow.addArrangedSubview(badgeLabel)
        }
        priceRow.addArrangedSubview(UIView())  // trailing spacer

        let detailLabel = UILabel()
        detailLabel.font = .systemFont(ofSize: 15, weight: .regular)
        detailLabel.textColor = DashStyle.subtextGray
        detailLabel.numberOfLines = 0
        detailLabel.text = item.detail

        contentStack.addArrangedSubview(hero)
        contentStack.setCustomSpacing(18, after: hero)
        contentStack.addArrangedSubview(nameLabel)
        contentStack.setCustomSpacing(2, after: nameLabel)
        contentStack.addArrangedSubview(fromLabel)
        contentStack.addArrangedSubview(priceRow)
        contentStack.addArrangedSubview(detailLabel)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -92),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    private func configureAddButton() {
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.setTitle(String(format: "Add to Cart  ·  $%.2f", item.price), for: .normal)
        addButton.setTitleColor(.white, for: .normal)
        addButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        addButton.backgroundColor = DashStyle.red
        addButton.layer.cornerRadius = 27
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        // Stable id so MCP / agent tooling can drive the detail → cart step.
        addButton.accessibilityIdentifier = "menu_item_detail_add_\(item.slug)"
        addButton.accessibilityLabel = "Add \(item.name) to cart"
        view.addSubview(addButton)

        NSLayoutConstraint.activate([
            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            addButton.heightAnchor.constraint(equalToConstant: 54)
        ])
    }

    @objc private func addTapped() {
        DashStore.shared.add(item: item, from: restaurant)
        navigationController?.popViewController(animated: true)
    }
}

final class RestaurantHeaderView: UIView {
    private let orderSegment = UISegmentedControl(items: ["Delivery", "Pickup"])

    init(restaurant: Restaurant) {
        super.init(frame: .zero)
        configure(restaurant: restaurant)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure(restaurant: Restaurant) {
        backgroundColor = .systemBackground

        let hero = UIImageView()
        hero.translatesAutoresizingMaskIntoConstraints = false
        configureHeroImageView(hero, with: restaurant, symbolPointSize: 60)
        hero.clipsToBounds = true

        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .systemFont(ofSize: 26, weight: .bold)
        nameLabel.text = restaurant.name
        nameLabel.numberOfLines = 0

        // Rating row with gray badge
        let ratingContainer = UIView()
        ratingContainer.translatesAutoresizingMaskIntoConstraints = false

        let starIcon = UIImageView(image: UIImage(systemName: "star.fill"))
        starIcon.translatesAutoresizingMaskIntoConstraints = false
        starIcon.tintColor = DashStyle.ratingGray
        starIcon.contentMode = .scaleAspectFit

        let ratingText = UILabel()
        ratingText.translatesAutoresizingMaskIntoConstraints = false
        ratingText.font = .systemFont(ofSize: 14, weight: .semibold)
        ratingText.textColor = DashStyle.ratingGray
        ratingText.text = "\(restaurant.rating) (\(restaurant.ratingCount)+)"

        let dotLabel = UILabel()
        dotLabel.translatesAutoresizingMaskIntoConstraints = false
        dotLabel.font = .systemFont(ofSize: 14, weight: .regular)
        dotLabel.textColor = DashStyle.subtextGray
        dotLabel.text = " · "

        let cuisineLabel = UILabel()
        cuisineLabel.translatesAutoresizingMaskIntoConstraints = false
        cuisineLabel.font = .systemFont(ofSize: 14, weight: .regular)
        cuisineLabel.textColor = DashStyle.subtextGray
        cuisineLabel.text = "\(restaurant.cuisine) · \(String(format: "%.1f", restaurant.distanceMiles)) mi"

        let ratingRow = UIStackView(arrangedSubviews: [starIcon, ratingText, dotLabel, cuisineLabel])
        ratingRow.translatesAutoresizingMaskIntoConstraints = false
        ratingRow.axis = .horizontal
        ratingRow.spacing = 2
        ratingRow.alignment = .center
        starIcon.widthAnchor.constraint(equalToConstant: 14).isActive = true
        starIcon.heightAnchor.constraint(equalToConstant: 14).isActive = true

        // Delivery info pills
        let infoPill1 = makeInfoPill(icon: "clock", text: restaurant.eta)
        let infoPill2 = makeInfoPill(icon: "dollarsign.circle", text: restaurant.deliveryFee.replacingOccurrences(of: " delivery fee", with: "").replacingOccurrences(of: " on $", with: "\nMin $").components(separatedBy: "\n").first ?? restaurant.deliveryFee)

        let pillRow = UIStackView(arrangedSubviews: [infoPill1, infoPill2])
        pillRow.translatesAutoresizingMaskIntoConstraints = false
        pillRow.axis = .horizontal
        pillRow.spacing = 10
        pillRow.distribution = .fillEqually

        // Delivery fee banner
        let feeBanner = UIView()
        feeBanner.translatesAutoresizingMaskIntoConstraints = false
        feeBanner.backgroundColor = UIColor(red: 0.98, green: 0.95, blue: 0.90, alpha: 1)
        feeBanner.layer.cornerRadius = 10

        let feeIcon = UIImageView(image: UIImage(systemName: "tag.fill"))
        feeIcon.translatesAutoresizingMaskIntoConstraints = false
        feeIcon.tintColor = DashStyle.red
        feeIcon.contentMode = .scaleAspectFit

        let feeLabel = UILabel()
        feeLabel.translatesAutoresizingMaskIntoConstraints = false
        feeLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        feeLabel.textColor = .label
        feeLabel.text = restaurant.deliveryFee
        feeLabel.numberOfLines = 1

        feeBanner.addSubview(feeIcon)
        feeBanner.addSubview(feeLabel)

        NSLayoutConstraint.activate([
            feeIcon.leadingAnchor.constraint(equalTo: feeBanner.leadingAnchor, constant: 12),
            feeIcon.centerYAnchor.constraint(equalTo: feeBanner.centerYAnchor),
            feeIcon.widthAnchor.constraint(equalToConstant: 16),
            feeIcon.heightAnchor.constraint(equalToConstant: 16),
            feeLabel.leadingAnchor.constraint(equalTo: feeIcon.trailingAnchor, constant: 6),
            feeLabel.trailingAnchor.constraint(equalTo: feeBanner.trailingAnchor, constant: -12),
            feeLabel.centerYAnchor.constraint(equalTo: feeBanner.centerYAnchor),
            feeBanner.heightAnchor.constraint(equalToConstant: 36)
        ])

        orderSegment.translatesAutoresizingMaskIntoConstraints = false
        if restaurant.pickupAvailable {
            orderSegment.selectedSegmentIndex = DashStore.shared.selectedOrderType == .pickup ? 1 : 0
        } else {
            orderSegment.selectedSegmentIndex = 0
            orderSegment.setEnabled(false, forSegmentAt: 1)
            if DashStore.shared.selectedOrderType == .pickup {
                DashStore.shared.setOrderType(.delivery)
            }
        }
        orderSegment.selectedSegmentTintColor = .white
        orderSegment.backgroundColor = DashStyle.lightGray
        orderSegment.setTitleTextAttributes([.foregroundColor: UIColor.label, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)], for: .selected)
        orderSegment.setTitleTextAttributes([.foregroundColor: DashStyle.subtextGray, .font: UIFont.systemFont(ofSize: 14, weight: .medium)], for: .normal)
        orderSegment.addTarget(self, action: #selector(orderTypeChanged), for: .valueChanged)
        orderSegment.heightAnchor.constraint(equalToConstant: 40).isActive = true

        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = DashStyle.separator
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true

        let contentStack = UIStackView(arrangedSubviews: [nameLabel, ratingRow, feeBanner, orderSegment, separator])
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 10

        addSubview(hero)
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            hero.leadingAnchor.constraint(equalTo: leadingAnchor),
            hero.trailingAnchor.constraint(equalTo: trailingAnchor),
            hero.topAnchor.constraint(equalTo: topAnchor),
            hero.heightAnchor.constraint(equalToConstant: 200),

            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            contentStack.topAnchor.constraint(equalTo: hero.bottomAnchor, constant: 16),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }

    private func makeInfoPill(icon: String, text: String) -> UIView {
        let container = UIView()
        container.backgroundColor = DashStyle.lightGray
        container.layer.cornerRadius = 10

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.tintColor = .label
        iconView.contentMode = .scaleAspectFit

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .label
        label.text = text

        container.addSubview(iconView)
        container.addSubview(label)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 16),
            iconView.heightAnchor.constraint(equalToConstant: 16),
            label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 6),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            container.heightAnchor.constraint(equalToConstant: 36)
        ])

        return container
    }

    @objc private func orderTypeChanged() {
        let type: OrderType = orderSegment.selectedSegmentIndex == 1 ? .pickup : .delivery
        DashStore.shared.setOrderType(type)
    }
}

final class MenuItemCell: UITableViewCell {
    private let nameLabel = UILabel()
    private let detailLabel = UILabel()
    private let priceLabel = UILabel()
    private let badgeLabel = UILabel()
    private let thumbnailView = UIView()
    private let thumbnailIcon = UIImageView()
    private let addButton = UIButton(type: .system)
    var onAdd: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        // .default gives the row a tap highlight — it now opens an item
        // detail screen (see RestaurantDetailViewController.didSelectRowAt).
        selectionStyle = .default
        backgroundColor = .systemBackground
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)

        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.font = .systemFont(ofSize: 13, weight: .regular)
        detailLabel.textColor = DashStyle.subtextGray
        detailLabel.numberOfLines = 2

        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.font = .systemFont(ofSize: 14, weight: .medium)
        priceLabel.textColor = .label

        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.font = .systemFont(ofSize: 11, weight: .bold)
        badgeLabel.textColor = DashStyle.red
        badgeLabel.isHidden = true

        thumbnailView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailView.backgroundColor = DashStyle.lightGray
        thumbnailView.layer.cornerRadius = 10
        thumbnailView.clipsToBounds = true

        thumbnailIcon.translatesAutoresizingMaskIntoConstraints = false
        thumbnailIcon.contentMode = .scaleAspectFit
        thumbnailView.addSubview(thumbnailIcon)

        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.setImage(UIImage(systemName: "plus")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)), for: .normal)
        addButton.tintColor = .label
        addButton.backgroundColor = .clear
        addButton.layer.cornerRadius = 16
        addButton.layer.borderWidth = 1.5
        addButton.layer.borderColor = UIColor(white: 0.82, alpha: 1).cgColor
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)

        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = DashStyle.separator

        contentView.addSubview(nameLabel)
        contentView.addSubview(detailLabel)
        contentView.addSubview(priceLabel)
        contentView.addSubview(badgeLabel)
        contentView.addSubview(thumbnailView)
        contentView.addSubview(addButton)
        contentView.addSubview(separator)

        NSLayoutConstraint.activate([
            thumbnailView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            thumbnailView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            thumbnailView.widthAnchor.constraint(equalToConstant: 80),
            thumbnailView.heightAnchor.constraint(equalToConstant: 80),

            thumbnailIcon.centerXAnchor.constraint(equalTo: thumbnailView.centerXAnchor),
            thumbnailIcon.centerYAnchor.constraint(equalTo: thumbnailView.centerYAnchor),

            addButton.centerXAnchor.constraint(equalTo: thumbnailView.trailingAnchor, constant: -4),
            addButton.centerYAnchor.constraint(equalTo: thumbnailView.bottomAnchor, constant: -4),
            addButton.widthAnchor.constraint(equalToConstant: 32),
            addButton.heightAnchor.constraint(equalToConstant: 32),

            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: thumbnailView.leadingAnchor, constant: -12),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),

            detailLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            detailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),

            priceLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            priceLabel.topAnchor.constraint(equalTo: detailLabel.bottomAnchor, constant: 6),

            badgeLabel.leadingAnchor.constraint(equalTo: priceLabel.trailingAnchor, constant: 8),
            badgeLabel.centerYAnchor.constraint(equalTo: priceLabel.centerYAnchor),

            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5),

            contentView.bottomAnchor.constraint(greaterThanOrEqualTo: thumbnailView.bottomAnchor, constant: 14),
            contentView.bottomAnchor.constraint(greaterThanOrEqualTo: priceLabel.bottomAnchor, constant: 14)
        ])
    }

    func configure(item: MenuItem) {
        nameLabel.text = item.name
        detailLabel.text = item.detail
        priceLabel.text = String(format: "$%.2f", item.price)
        if let badge = item.badge {
            badgeLabel.text = badge
            badgeLabel.isHidden = false
        } else {
            badgeLabel.isHidden = true
        }
        let appearance = MenuItemAppearance.lookup(name: item.name, detail: item.detail)
        thumbnailView.backgroundColor = appearance.tint.withAlphaComponent(0.18)
        thumbnailIcon.tintColor = appearance.tint
        thumbnailIcon.image = UIImage(systemName: appearance.symbol)?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 32, weight: .semibold))

        // Expose stable accessibility identifiers so MCP tooling
        // (e.g. quickbite.add_to_order) can target specific menu rows.
        // The cell itself uses `menu_item_<slug>`; the add (+) button
        // uses `menu_item_add_<slug>` to allow either to be tapped.
        let slug = item.slug
        self.accessibilityIdentifier = "menu_item_\(slug)"
        self.isAccessibilityElement = false
        addButton.accessibilityIdentifier = "menu_item_add_\(slug)"
        addButton.accessibilityLabel = "Add \(item.name)"
    }

    @objc private func addTapped() {
        onAdd?()
    }
}

// MARK: - Cart

final class CartViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let footerView = CartFooterView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Cart"
        view.backgroundColor = .systemBackground
        configureTable()
        configureFooter()
        DashStore.shared.refreshPaymentAccounts()
        NotificationCenter.default.addObserver(self, selector: #selector(handleStoreChange), name: .dashStoreDidChange, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DashStore.shared.refreshPaymentAccounts()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func configureTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .systemBackground
        tableView.register(CartItemCell.self, forCellReuseIdentifier: "CartItemCell")
        tableView.rowHeight = 68
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureFooter() {
        footerView.onSchedule = { [weak self] in
            let schedule = ScheduleViewController()
            self?.navigationController?.pushViewController(schedule, animated: true)
        }
        footerView.onPlaceOrder = { [weak self] in
            self?.startCheckout()
        }
    }

    @objc private func handleStoreChange() {
        tableView.reloadData()
        footerView.update()
    }

    private func startCheckout() {
        switch DashStore.shared.validateCheckout() {
        case .success:
            let checkout = MyBankCheckoutConfirmationViewController(
                totals: DashStore.shared.orderTotals,
                paymentAccount: DashStore.shared.selectedPaymentAccount
            )
            checkout.onConfirm = { [weak self, weak checkout] in
                self?.placeOrder(from: checkout)
            }
            navigationController?.pushViewController(checkout, animated: true)
        case .failure(let error):
            presentOrderError(error, from: self)
        }
    }

    private func placeOrder(from presenter: UIViewController?) {
        let totals = DashStore.shared.orderTotals
        switch DashStore.shared.placeOrder() {
        case .success(let order):
            MyBankLedgerWriter.recordOrder(order, total: totals.total, paymentAccountId: DashStore.shared.selectedPaymentAccountId)
            MailOutboxWriter.recordOrderEmail(order, total: totals.total, etaMinutes: 20)
            let tracking = OrderTrackingViewController(order: order)
            let host = presenter?.navigationController ?? navigationController
            host?.pushViewController(tracking, animated: true)
        case .failure(let error):
            presentOrderError(error, from: presenter ?? self)
        }
    }

    private func presentOrderError(_ error: OrderPlacementError, from presenter: UIViewController) {
        let alert = UIAlertController(title: "Unable to Place Order", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        presenter.present(alert, animated: true)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        DashStore.shared.cartItems.isEmpty ? 1 : 3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if DashStore.shared.cartItems.isEmpty { return 1 }
        switch section {
        case 0:
            return DashStore.shared.cartItems.count
        case 1:
            return 1
        case 2:
            return DashStore.shared.paymentAccounts.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard !DashStore.shared.cartItems.isEmpty else { return nil }
        switch section {
        case 0:
            return DashStore.shared.cartRestaurant?.name
        case 1:
            return DashStore.shared.selectedOrderType == .pickup ? "Pickup" : "Delivery"
        case 2:
            return "Payment Methods"
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if DashStore.shared.cartItems.isEmpty {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            cell.textLabel?.text = "Your cart is empty"
            cell.detailTextLabel?.text = "Add items from a restaurant"
            cell.selectionStyle = .none
            return cell
        }

        if indexPath.section == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "CartItemCell", for: indexPath) as? CartItemCell else {
                return UITableViewCell()
            }
            let cartItem = DashStore.shared.cartItems[indexPath.row]
            cell.configure(item: cartItem)
            cell.onAdd = { DashStore.shared.updateQuantity(for: cartItem.item, restaurantID: cartItem.restaurantID, delta: 1) }
            cell.onRemove = { DashStore.shared.updateQuantity(for: cartItem.item, restaurantID: cartItem.restaurantID, delta: -1) }
            return cell
        }

        if indexPath.section == 1 {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            if DashStore.shared.selectedOrderType == .pickup {
                cell.textLabel?.text = "Pick up at restaurant"
                cell.detailTextLabel?.text = DashStore.shared.cartRestaurant?.name
                cell.selectionStyle = .none
            } else {
                let address = DashStore.shared.selectedAddress
                cell.textLabel?.text = "Deliver to \(address.label)"
                cell.detailTextLabel?.text = address.detail
                cell.accessoryType = .disclosureIndicator
            }
            return cell
        }

        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        let account = DashStore.shared.paymentAccounts[indexPath.row]
        cell.textLabel?.text = account.name
        cell.detailTextLabel?.text = account.network
        cell.accessoryType = account.id == DashStore.shared.selectedPaymentAccountId ? .checkmark : .none
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 && DashStore.shared.selectedOrderType == .delivery {
            let list = AddressListViewController()
            navigationController?.pushViewController(list, animated: true)
        } else if indexPath.section == 2 {
            let account = DashStore.shared.paymentAccounts[indexPath.row]
            DashStore.shared.setPaymentAccount(account)
            tableView.reloadSections(IndexSet(integer: 2), with: .automatic)
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard !DashStore.shared.cartItems.isEmpty, section == 2 else { return nil }
        footerView.update()
        return footerView
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard !DashStore.shared.cartItems.isEmpty, section == 2 else { return 0 }
        return 380
    }
}

final class CartItemCell: UITableViewCell {
    private let nameLabel = UILabel()
    private let priceLabel = UILabel()
    private let stepperView = StepperView()
    var onAdd: (() -> Void)?
    var onRemove: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)

        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.font = .systemFont(ofSize: 13, weight: .regular)
        priceLabel.textColor = .secondaryLabel

        stepperView.translatesAutoresizingMaskIntoConstraints = false
        stepperView.onAdd = { [weak self] in self?.onAdd?() }
        stepperView.onRemove = { [weak self] in self?.onRemove?() }

        contentView.addSubview(nameLabel)
        contentView.addSubview(priceLabel)
        contentView.addSubview(stepperView)

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),

            priceLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            priceLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),

            stepperView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stepperView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func configure(item: CartItem) {
        nameLabel.text = item.item.name
        let lineTotal = item.item.price * Double(item.quantity)
        priceLabel.text = String(format: "$%.2f", lineTotal)
        stepperView.setValue(item.quantity)
    }
}

final class StepperView: UIView {
    private let valueLabel = UILabel()
    var onAdd: (() -> Void)?
    var onRemove: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        layer.cornerRadius = 14
        layer.borderColor = DashStyle.red.cgColor
        layer.borderWidth = 1

        let minus = UIButton(type: .system)
        minus.setTitle("-", for: .normal)
        minus.setTitleColor(DashStyle.red, for: .normal)
        minus.addTarget(self, action: #selector(removeTapped), for: .touchUpInside)

        let plus = UIButton(type: .system)
        plus.setTitle("+", for: .normal)
        plus.setTitleColor(DashStyle.red, for: .normal)
        plus.addTarget(self, action: #selector(addTapped), for: .touchUpInside)

        valueLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        valueLabel.textAlignment = .center
        valueLabel.text = "1"

        let stack = UIStackView(arrangedSubviews: [minus, valueLabel, plus])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            widthAnchor.constraint(equalToConstant: 90),
            heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    func setValue(_ value: Int) {
        valueLabel.text = "\(value)"
    }

    @objc private func addTapped() {
        onAdd?()
    }

    @objc private func removeTapped() {
        onRemove?()
    }
}

final class MyBankCheckoutConfirmationViewController: UIViewController {
    private let totals: OrderTotals
    private let paymentAccount: PaymentAccount?

    private let cardLabel = UILabel()
    private let summaryLabel = UILabel()
    private let confirmSwitch = UISwitch()
    private let confirmButton = UIButton(type: .system)

    var onConfirm: (() -> Void)?

    init(totals: OrderTotals, paymentAccount: PaymentAccount?) {
        self.totals = totals
        self.paymentAccount = paymentAccount
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "MyBank Checkout"
        view.backgroundColor = .systemBackground
        configureLayout()
        updateConfirmState()
    }

    private func configureLayout() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])

        let badge = UILabel()
        badge.text = "Payment routed through MyBank"
        badge.font = .systemFont(ofSize: 13, weight: .semibold)
        badge.textColor = DashStyle.red
        badge.accessibilityIdentifier = "mybank.checkout.badge"
        stack.addArrangedSubview(badge)

        let titleLabel = UILabel()
        titleLabel.text = "Saved Card"
        titleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        titleLabel.textColor = .secondaryLabel
        stack.addArrangedSubview(titleLabel)

        cardLabel.font = .systemFont(ofSize: 15, weight: .medium)
        cardLabel.numberOfLines = 0
        cardLabel.textColor = .label
        cardLabel.accessibilityIdentifier = "mybank.checkout.card"
        if let paymentAccount {
            cardLabel.text = "\(paymentAccount.network) • \(paymentAccount.maskedNumber)\n\(paymentAccount.name)"
        } else {
            cardLabel.text = "No autosaved MyBank card found."
            cardLabel.textColor = .systemRed
        }
        stack.addArrangedSubview(cardLabel)

        let summaryTitleLabel = UILabel()
        summaryTitleLabel.text = "Order Summary"
        summaryTitleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        summaryTitleLabel.textColor = .secondaryLabel
        stack.addArrangedSubview(summaryTitleLabel)

        summaryLabel.font = .monospacedDigitSystemFont(ofSize: 14, weight: .regular)
        summaryLabel.numberOfLines = 0
        summaryLabel.textColor = .label
        summaryLabel.accessibilityIdentifier = "mybank.checkout.summary"
        summaryLabel.text = String(
            format: "Subtotal: $%.2f\nDelivery fee: $%.2f\nService fee: $%.2f\nTaxes: $%.2f\nTip: $%.2f\nTotal: $%.2f",
            totals.subtotal,
            totals.deliveryFee,
            totals.serviceFee,
            totals.tax,
            totals.tip,
            totals.total
        )
        stack.addArrangedSubview(summaryLabel)

        let confirmRow = UIView()
        confirmRow.translatesAutoresizingMaskIntoConstraints = false

        let confirmLabel = UILabel()
        confirmLabel.translatesAutoresizingMaskIntoConstraints = false
        confirmLabel.text = "I confirm this charge on my saved MyBank card."
        confirmLabel.numberOfLines = 0
        confirmLabel.font = .systemFont(ofSize: 14, weight: .regular)
        confirmLabel.accessibilityIdentifier = "mybank.checkout.confirmLabel"
        confirmLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        confirmSwitch.addTarget(self, action: #selector(confirmToggled), for: .valueChanged)
        confirmSwitch.translatesAutoresizingMaskIntoConstraints = false
        confirmSwitch.accessibilityIdentifier = "mybank.checkout.confirmToggle"
        confirmSwitch.setContentCompressionResistancePriority(.required, for: .horizontal)
        confirmSwitch.setContentHuggingPriority(.required, for: .horizontal)

        confirmRow.addSubview(confirmLabel)
        confirmRow.addSubview(confirmSwitch)

        NSLayoutConstraint.activate([
            confirmLabel.leadingAnchor.constraint(equalTo: confirmRow.leadingAnchor),
            confirmLabel.topAnchor.constraint(equalTo: confirmRow.topAnchor),
            confirmLabel.bottomAnchor.constraint(equalTo: confirmRow.bottomAnchor),
            confirmLabel.trailingAnchor.constraint(lessThanOrEqualTo: confirmSwitch.leadingAnchor, constant: -12),

            confirmSwitch.trailingAnchor.constraint(equalTo: confirmRow.trailingAnchor),
            confirmSwitch.centerYAnchor.constraint(equalTo: confirmRow.centerYAnchor),
            confirmSwitch.topAnchor.constraint(greaterThanOrEqualTo: confirmRow.topAnchor),
            confirmSwitch.bottomAnchor.constraint(lessThanOrEqualTo: confirmRow.bottomAnchor)
        ])

        stack.addArrangedSubview(confirmRow)

        confirmButton.setTitle("Confirm & Place Order", for: .normal)
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        confirmButton.backgroundColor = DashStyle.red
        confirmButton.layer.cornerRadius = 12
        confirmButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        confirmButton.accessibilityIdentifier = "mybank.checkout.confirmButton"
        stack.addArrangedSubview(confirmButton)
    }

    private func updateConfirmState() {
        let canConfirm = confirmSwitch.isOn && paymentAccount != nil
        confirmButton.isEnabled = canConfirm
        confirmButton.alpha = canConfirm ? 1.0 : 0.5
    }

    @objc private func confirmToggled() {
        updateConfirmState()
    }

    @objc private func confirmTapped() {
        guard confirmButton.isEnabled else { return }
        onConfirm?()
    }
}

final class CartFooterView: UIView {
    private let summaryStack = UIStackView()
    private let tipStack = UIStackView()
    private let asapButton = UIButton(type: .system)
    private let scheduleButton = UIButton(type: .system)
    private let addressLabel = UILabel()
    private let placeButton = UIButton(type: .system)
    private var selectedTipIndex: Int { DashStore.shared.selectedTipIndex }

    var onSchedule: (() -> Void)?
    var onPlaceOrder: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        summaryStack.translatesAutoresizingMaskIntoConstraints = false
        summaryStack.axis = .vertical
        summaryStack.spacing = 6

        // Tip section
        let tipTitle = UILabel()
        tipTitle.text = "Dasher tip"
        tipTitle.font = .systemFont(ofSize: 15, weight: .bold)
        tipTitle.textColor = .label

        tipStack.translatesAutoresizingMaskIntoConstraints = false
        tipStack.axis = .horizontal
        tipStack.spacing = 8
        tipStack.distribution = .fillEqually

        let tipAmounts = ["$0", "$2", "$3", "$4", "Other"]
        for (index, amount) in tipAmounts.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(amount, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
            btn.layer.cornerRadius = 18
            btn.layer.borderWidth = 1.5
            btn.tag = index
            btn.accessibilityIdentifier = "tip_button_\(index)"
            btn.addTarget(self, action: #selector(tipTapped(_:)), for: .touchUpInside)
            btn.heightAnchor.constraint(equalToConstant: 36).isActive = true
            if index == selectedTipIndex {
                btn.backgroundColor = DashStyle.red
                btn.setTitleColor(.white, for: .normal)
                btn.layer.borderColor = DashStyle.red.cgColor
            } else {
                btn.backgroundColor = .systemBackground
                btn.setTitleColor(.label, for: .normal)
                btn.layer.borderColor = UIColor(white: 0.8, alpha: 1).cgColor
            }
            tipStack.addArrangedSubview(btn)
        }

        let buttonRow = UIStackView(arrangedSubviews: [asapButton, scheduleButton])
        buttonRow.translatesAutoresizingMaskIntoConstraints = false
        buttonRow.axis = .horizontal
        buttonRow.spacing = 10
        buttonRow.distribution = .fillEqually

        asapButton.translatesAutoresizingMaskIntoConstraints = false
        asapButton.setTitle("⏱ ASAP", for: .normal)
        asapButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        asapButton.layer.cornerRadius = 12
        asapButton.addTarget(self, action: #selector(asapTapped), for: .touchUpInside)

        scheduleButton.translatesAutoresizingMaskIntoConstraints = false
        scheduleButton.setTitle("📅 Schedule", for: .normal)
        scheduleButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        scheduleButton.setTitleColor(.label, for: .normal)
        scheduleButton.backgroundColor = DashStyle.lightGray
        scheduleButton.layer.cornerRadius = 12
        scheduleButton.addTarget(self, action: #selector(scheduleTapped), for: .touchUpInside)

        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        addressLabel.font = .systemFont(ofSize: 13, weight: .regular)
        addressLabel.textColor = .secondaryLabel
        addressLabel.textAlignment = .center

        placeButton.translatesAutoresizingMaskIntoConstraints = false
        placeButton.setTitle("Place Order", for: .normal)
        placeButton.setTitleColor(.white, for: .normal)
        placeButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        placeButton.backgroundColor = DashStyle.red
        placeButton.layer.cornerRadius = 27
        placeButton.addTarget(self, action: #selector(placeTapped), for: .touchUpInside)
        // Stable accessibility id so MCP tooling can drive the cart →
        // MyBank-checkout transition without a coordinate search.
        placeButton.accessibilityIdentifier = "cart_place_order_button"

        addSubview(summaryStack)
        addSubview(tipTitle)
        addSubview(tipStack)
        addSubview(buttonRow)
        addSubview(addressLabel)
        addSubview(placeButton)

        tipTitle.translatesAutoresizingMaskIntoConstraints = false
        buttonRow.heightAnchor.constraint(equalToConstant: 44).isActive = true

        NSLayoutConstraint.activate([
            summaryStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            summaryStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            summaryStack.topAnchor.constraint(equalTo: topAnchor, constant: 8),

            tipTitle.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            tipTitle.topAnchor.constraint(equalTo: summaryStack.bottomAnchor, constant: 16),

            tipStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            tipStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            tipStack.topAnchor.constraint(equalTo: tipTitle.bottomAnchor, constant: 8),

            buttonRow.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            buttonRow.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            buttonRow.topAnchor.constraint(equalTo: tipStack.bottomAnchor, constant: 16),

            addressLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            addressLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            addressLabel.topAnchor.constraint(equalTo: buttonRow.bottomAnchor, constant: 10),

            placeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            placeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            placeButton.topAnchor.constraint(equalTo: addressLabel.bottomAnchor, constant: 12),
            placeButton.heightAnchor.constraint(equalToConstant: 54)
        ])
    }

    @objc private func tipTapped(_ sender: UIButton) {
        DashStore.shared.setTipIndex(sender.tag)
        for case let btn as UIButton in tipStack.arrangedSubviews {
            if btn.tag == selectedTipIndex {
                btn.backgroundColor = DashStyle.red
                btn.setTitleColor(.white, for: .normal)
                btn.layer.borderColor = DashStyle.red.cgColor
            } else {
                btn.backgroundColor = .systemBackground
                btn.setTitleColor(.label, for: .normal)
                btn.layer.borderColor = UIColor(white: 0.8, alpha: 1).cgColor
            }
        }
        update()
    }

    func update() {
        summaryStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let totals = DashStore.shared.orderTotals

        func addRow(_ label: String, _ value: String, bold: Bool = false, color: UIColor = .label) {
            let row = UIStackView()
            row.axis = .horizontal

            let left = UILabel()
            left.text = label
            left.font = .systemFont(ofSize: 14, weight: bold ? .bold : .regular)
            left.textColor = bold ? .label : DashStyle.subtextGray

            let right = UILabel()
            right.text = value
            right.font = .monospacedDigitSystemFont(ofSize: 14, weight: bold ? .bold : .regular)
            right.textColor = color
            right.textAlignment = .right

            row.addArrangedSubview(left)
            row.addArrangedSubview(right)
            summaryStack.addArrangedSubview(row)
        }

        addRow("Subtotal", String(format: "$%.2f", totals.subtotal))
        addRow("Delivery Fee", totals.deliveryFee > 0 ? String(format: "$%.2f", totals.deliveryFee) : "Free", color: totals.deliveryFee > 0 ? .label : DashStyle.greenBadge)
        addRow("Service Fee", String(format: "$%.2f", totals.serviceFee))
        addRow("Tax", String(format: "$%.2f", totals.tax))
        addRow("Dasher Tip", String(format: "$%.2f", totals.tip))

        let sep = UIView()
        sep.heightAnchor.constraint(equalToConstant: 1).isActive = true
        sep.backgroundColor = DashStyle.separator
        summaryStack.addArrangedSubview(sep)

        addRow("Total", String(format: "$%.2f", totals.total), bold: true)

        let isASAP = DashStore.shared.scheduledDelivery == nil
        if isASAP {
            asapButton.backgroundColor = DashStyle.red
            asapButton.setTitleColor(.white, for: .normal)
            scheduleButton.backgroundColor = DashStyle.lightGray
            scheduleButton.setTitleColor(.label, for: .normal)
        } else {
            asapButton.backgroundColor = DashStyle.lightGray
            asapButton.setTitleColor(.label, for: .normal)
            scheduleButton.backgroundColor = DashStyle.red
            scheduleButton.setTitleColor(.white, for: .normal)
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            let timeText = formatter.string(from: DashStore.shared.scheduledDelivery!)
            scheduleButton.setTitle("📅 \(timeText)", for: .normal)
        }

        let addr = DashStore.shared.selectedAddress
        addressLabel.text = "📍 \(addr.label) · \(addr.detail)"
    }

    @objc private func asapTapped() {
        DashStore.shared.setScheduledDelivery(nil)
    }

    @objc private func scheduleTapped() {
        onSchedule?()
    }

    @objc private func placeTapped() {
        onPlaceOrder?()
    }
}

final class CartBarView: UIView {
    private let label = UILabel()
    private let countLabel = UILabel()
    private let totalLabel = UILabel()
    var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        backgroundColor = DashStyle.red
        layer.cornerRadius = 27
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 12
        layer.shadowOffset = CGSize(width: 0, height: 4)
        // Stable accessibility id so MCP tooling can tap the cart-bar
        // floating button to push the Cart view from a restaurant detail.
        self.accessibilityIdentifier = "view_cart_button"
        self.isAccessibilityElement = true

        countLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.font = .systemFont(ofSize: 14, weight: .bold)
        countLabel.textColor = DashStyle.red
        countLabel.backgroundColor = .white
        countLabel.layer.cornerRadius = 13
        countLabel.textAlignment = .center
        countLabel.clipsToBounds = true

        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .white
        label.text = "View Cart"

        totalLabel.translatesAutoresizingMaskIntoConstraints = false
        totalLabel.font = .systemFont(ofSize: 16, weight: .bold)
        totalLabel.textColor = .white
        totalLabel.textAlignment = .right

        addSubview(countLabel)
        addSubview(label)
        addSubview(totalLabel)

        NSLayoutConstraint.activate([
            countLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            countLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            countLabel.widthAnchor.constraint(equalToConstant: 26),
            countLabel.heightAnchor.constraint(equalToConstant: 26),

            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),

            totalLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            totalLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    func update() {
        let count = DashStore.shared.cartItemCount
        let total = DashStore.shared.cartTotal
        label.text = "View Cart"
        countLabel.text = "\(count)"
        totalLabel.text = String(format: "$%.2f", total)
    }

    @objc private func handleTap() {
        onTap?()
    }
}

// MARK: - Address & Schedule

final class AddressListViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Address"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 2 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? DashStore.shared.addresses.count : 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if indexPath.section == 0 {
            let address = DashStore.shared.addresses[indexPath.row]
            cell.textLabel?.text = "\(address.label) · \(address.detail)"
            cell.textLabel?.textColor = .label
            cell.accessoryType = address.id == DashStore.shared.selectedAddressID ? .checkmark : .none
        } else {
            cell.textLabel?.text = "+ Add New Address"
            cell.textLabel?.textColor = DashStyle.red
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let address = DashStore.shared.addresses[indexPath.row]
            DashStore.shared.selectAddress(address)
            navigationController?.popViewController(animated: true)
        } else {
            let addVC = AddNewAddressViewController()
            addVC.onSave = { [weak self] in
                self?.tableView.reloadData()
            }
            navigationController?.pushViewController(addVC, animated: true)
        }
    }
}

final class AddNewAddressViewController: UIViewController {
    private let labelField = UITextField()
    private let addressField = UITextField()
    var onSave: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "New Address"
        view.backgroundColor = .systemBackground

        labelField.translatesAutoresizingMaskIntoConstraints = false
        labelField.placeholder = "Label (e.g. Home, Work)"
        labelField.font = .systemFont(ofSize: 16)
        labelField.borderStyle = .roundedRect
        labelField.accessibilityIdentifier = "doordash.newAddress.label"

        addressField.translatesAutoresizingMaskIntoConstraints = false
        addressField.placeholder = "Street address"
        addressField.font = .systemFont(ofSize: 16)
        addressField.borderStyle = .roundedRect
        addressField.accessibilityIdentifier = "doordash.newAddress.detail"

        let saveButton = UIButton(type: .system)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.setTitle("Save Address", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        saveButton.backgroundColor = DashStyle.red
        saveButton.layer.cornerRadius = 12
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        saveButton.accessibilityIdentifier = "doordash.newAddress.save"

        view.addSubview(labelField)
        view.addSubview(addressField)
        view.addSubview(saveButton)

        NSLayoutConstraint.activate([
            labelField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            labelField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            labelField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            labelField.heightAnchor.constraint(equalToConstant: 44),

            addressField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            addressField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            addressField.topAnchor.constraint(equalTo: labelField.bottomAnchor, constant: 12),
            addressField.heightAnchor.constraint(equalToConstant: 44),

            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            saveButton.topAnchor.constraint(equalTo: addressField.bottomAnchor, constant: 24),
            saveButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    @objc private func saveTapped() {
        let label = (labelField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let detail = (addressField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !label.isEmpty, !detail.isEmpty else { return }
        let address = Address(id: UUID(), label: label, detail: detail)
        DashStore.shared.addAddress(address)
        onSave?()
        navigationController?.popViewController(animated: true)
    }
}

final class ScheduleViewController: UIViewController {
    private let picker = UIDatePicker()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Schedule"
        view.backgroundColor = .systemBackground
        configure()
    }

    private func configure() {
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.datePickerMode = .dateAndTime
        if #available(iOS 13.4, *) {
            picker.preferredDatePickerStyle = .wheels
        }
        view.addSubview(picker)

        let save = UIButton(type: .system)
        save.translatesAutoresizingMaskIntoConstraints = false
        save.setTitle("Save", for: .normal)
        save.setTitleColor(.white, for: .normal)
        save.backgroundColor = DashStyle.red
        save.layer.cornerRadius = 12
        save.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        view.addSubview(save)

        NSLayoutConstraint.activate([
            picker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            picker.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            save.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            save.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            save.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            save.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    @objc private func saveTapped() {
        DashStore.shared.setScheduledDelivery(picker.date)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Orders & Tracking

final class OrdersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let segment = UISegmentedControl(items: ["Active", "Past"])

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Orders"
        view.backgroundColor = .systemBackground
        configureSegment()
        configureTable()
        NotificationCenter.default.addObserver(self, selector: #selector(handleStoreChange), name: .dashStoreDidChange, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func configureSegment() {
        segment.selectedSegmentIndex = 0
        segment.addTarget(self, action: #selector(handleSegment), for: .valueChanged)
        navigationItem.titleView = segment
    }

    private func configureTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(OrderCardCell.self, forCellReuseIdentifier: "OrderCardCell")
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func handleSegment() {
        tableView.reloadData()
    }

    @objc private func handleStoreChange() {
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if segment.selectedSegmentIndex == 0 {
            return DashStore.shared.activeOrder == nil ? 1 : 1
        }
        return max(1, DashStore.shared.pastOrders.count)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if segment.selectedSegmentIndex == 0 {
            guard let order = DashStore.shared.activeOrder else {
                let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
                cell.textLabel?.text = "No active orders"
                cell.detailTextLabel?.text = "Place an order to see tracking"
                cell.selectionStyle = .none
                return cell
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: "OrderCardCell", for: indexPath) as? OrderCardCell
            let status = order.orderType == .pickup ? "Preparing pickup" : "On the way"
            cell?.configure(order: order, status: status, showsTrack: true)
            cell?.onTrack = { [weak self] in
                let tracking = OrderTrackingViewController(order: order)
                self?.navigationController?.pushViewController(tracking, animated: true)
            }
            return cell ?? UITableViewCell()
        }

        if DashStore.shared.pastOrders.isEmpty {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            cell.textLabel?.text = "No past orders"
            cell.detailTextLabel?.text = "Your completed orders show here"
            cell.selectionStyle = .none
            return cell
        }

        let order = DashStore.shared.pastOrders[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "OrderCardCell", for: indexPath) as? OrderCardCell
        cell?.configure(order: order, status: "Delivered", showsTrack: false)
        cell?.onTrack = nil
        return cell ?? UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if segment.selectedSegmentIndex == 1, !DashStore.shared.pastOrders.isEmpty {
            let order = DashStore.shared.pastOrders[indexPath.row]
            let detail = OrderDetailViewController(order: order)
            navigationController?.pushViewController(detail, animated: true)
        }
    }
}

final class OrderDetailViewController: UIViewController, UITableViewDataSource {
    private let order: ActiveOrder
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    init(order: ActiveOrder) {
        self.order = order
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = order.restaurant.name
        view.backgroundColor = .systemGroupedBackground
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func numberOfSections(in tableView: UITableView) -> Int { 3 }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Order Details"
        case 1: return "Items"
        case 2: return "Summary"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 3
        case 1: return order.items.count
        case 2: return 4
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.selectionStyle = .none
        var config = cell.defaultContentConfiguration()

        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                config.text = "Status"
                config.secondaryText = "Delivered"
            case 1:
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .short
                config.text = "Date"
                config.secondaryText = dateFormatter.string(from: order.startDate)
            case 2:
                config.text = order.orderType == .pickup ? "Pickup" : "Delivered to"
                config.secondaryText = order.orderType == .pickup ? order.restaurant.name : "\(order.destinationAddress.label) · \(order.destinationAddress.detail)"
            default: break
            }
        case 1:
            let cartItem = order.items[indexPath.row]
            let itemTotal = cartItem.item.price * Double(cartItem.quantity)
            config.text = cartItem.quantity > 1 ? "\(cartItem.quantity)x \(cartItem.item.name)" : cartItem.item.name
            config.secondaryText = String(format: "$%.2f", itemTotal)
        case 2:
            let subtotal = order.items.reduce(0.0) { $0 + $1.item.price * Double($1.quantity) }
            let fees = 2.99
            let tax = subtotal * 0.0875
            let total = subtotal + fees + tax
            switch indexPath.row {
            case 0:
                config.text = "Subtotal"
                config.secondaryText = String(format: "$%.2f", subtotal)
            case 1:
                config.text = "Fees & Delivery"
                config.secondaryText = String(format: "$%.2f", fees)
            case 2:
                config.text = "Tax"
                config.secondaryText = String(format: "$%.2f", tax)
            case 3:
                config.text = "Total"
                config.textProperties.font = .systemFont(ofSize: 16, weight: .bold)
                config.secondaryText = String(format: "$%.2f", total)
                config.secondaryTextProperties.font = .systemFont(ofSize: 16, weight: .bold)
            default: break
            }
        default: break
        }

        cell.contentConfiguration = config
        return cell
    }
}

final class OrderCardCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let statusLabel = UILabel()
    private let trackButton = UIButton(type: .system)
    var onTrack: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)

        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.font = .systemFont(ofSize: 13, weight: .regular)
        detailLabel.textColor = .secondaryLabel
        detailLabel.numberOfLines = 0

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        statusLabel.textColor = DashStyle.red

        trackButton.translatesAutoresizingMaskIntoConstraints = false
        var btnConfig = UIButton.Configuration.filled()
        btnConfig.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16)
        btnConfig.baseBackgroundColor = DashStyle.red
        btnConfig.baseForegroundColor = .white
        btnConfig.title = "Track"
        btnConfig.cornerStyle = .medium
        trackButton.configuration = btnConfig
        trackButton.addTarget(self, action: #selector(trackTapped), for: .touchUpInside)

        contentView.addSubview(titleLabel)
        contentView.addSubview(detailLabel)
        contentView.addSubview(statusLabel)
        contentView.addSubview(trackButton)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),

            detailLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),

            statusLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            statusLabel.topAnchor.constraint(equalTo: detailLabel.bottomAnchor, constant: 4),
            statusLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14),

            trackButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            trackButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func configure(order: ActiveOrder, status: String, showsTrack: Bool) {
        titleLabel.text = order.restaurant.name
        let summary = summaryText(for: order)
        let subtotal = order.items.reduce(0.0) { $0 + $1.item.price * Double($1.quantity) }
        let orderTotal = subtotal + 2.99 + subtotal * 0.0875
        let totalStr = String(format: "$%.2f", orderTotal)
        if showsTrack {
            if order.orderType == .pickup {
                detailLabel.text = "\(order.items.count) items · Ready in \(order.etaMinutes) min\n\(summary)"
            } else {
                detailLabel.text = "\(order.items.count) items · ETA \(order.etaMinutes) min\n\(summary)"
            }
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let dateStr = dateFormatter.string(from: order.startDate)
            detailLabel.text = "\(order.items.count) items · \(totalStr) · \(dateStr)\n\(summary)"
        }
        statusLabel.text = status
        trackButton.isHidden = !showsTrack
    }

    private func summaryText(for order: ActiveOrder) -> String {
        let items = order.items.map { item in
            item.quantity > 1 ? "\(item.quantity)x \(item.item.name)" : item.item.name
        }
        let preview = items.prefix(2)
        var summary = preview.joined(separator: ", ")
        if items.count > 2 {
            summary += " +\(items.count - 2) more"
        }
        return summary
    }

    @objc private func trackTapped() {
        onTrack?()
    }
}

final class OrderTrackingViewController: UIViewController {
    private let order: ActiveOrder
    private let mapView = TrackingMapView()
    private let etaLabel = UILabel()
    private let distanceLabel = UILabel()
    private let statusLabel = UILabel()
    private var timer: Timer?

    init(order: ActiveOrder) {
        self.order = order
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Tracking"
        view.backgroundColor = .systemBackground
        configure()
        startTimer()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
    }

    private func configure() {
        mapView.translatesAutoresizingMaskIntoConstraints = false

        // Progress bar
        let progressBar = UIView()
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.backgroundColor = DashStyle.lightGray
        progressBar.layer.cornerRadius = 3

        let progressFill = UIView()
        progressFill.translatesAutoresizingMaskIntoConstraints = false
        progressFill.backgroundColor = DashStyle.red
        progressFill.layer.cornerRadius = 3
        progressBar.addSubview(progressFill)

        etaLabel.translatesAutoresizingMaskIntoConstraints = false
        etaLabel.font = .systemFont(ofSize: 28, weight: .bold)

        distanceLabel.translatesAutoresizingMaskIntoConstraints = false
        distanceLabel.font = .systemFont(ofSize: 14, weight: .regular)
        distanceLabel.textColor = DashStyle.subtextGray

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        statusLabel.textColor = DashStyle.red

        let restaurantCard = UIView()
        restaurantCard.translatesAutoresizingMaskIntoConstraints = false
        restaurantCard.backgroundColor = DashStyle.lightGray
        restaurantCard.layer.cornerRadius = 12

        let restIcon = UIImageView(image: UIImage(systemName: "bag.fill"))
        restIcon.translatesAutoresizingMaskIntoConstraints = false
        restIcon.tintColor = DashStyle.red
        restIcon.contentMode = .scaleAspectFit

        let restLabel = UILabel()
        restLabel.translatesAutoresizingMaskIntoConstraints = false
        restLabel.text = order.restaurant.name
        restLabel.font = .systemFont(ofSize: 14, weight: .semibold)

        let itemCount = UILabel()
        itemCount.translatesAutoresizingMaskIntoConstraints = false
        itemCount.text = "\(order.items.count) item\(order.items.count == 1 ? "" : "s")"
        itemCount.font = .systemFont(ofSize: 12, weight: .regular)
        itemCount.textColor = DashStyle.subtextGray

        restaurantCard.addSubview(restIcon)
        restaurantCard.addSubview(restLabel)
        restaurantCard.addSubview(itemCount)

        NSLayoutConstraint.activate([
            restIcon.leadingAnchor.constraint(equalTo: restaurantCard.leadingAnchor, constant: 12),
            restIcon.centerYAnchor.constraint(equalTo: restaurantCard.centerYAnchor),
            restIcon.widthAnchor.constraint(equalToConstant: 20),
            restLabel.leadingAnchor.constraint(equalTo: restIcon.trailingAnchor, constant: 8),
            restLabel.topAnchor.constraint(equalTo: restaurantCard.topAnchor, constant: 10),
            itemCount.leadingAnchor.constraint(equalTo: restLabel.leadingAnchor),
            itemCount.topAnchor.constraint(equalTo: restLabel.bottomAnchor, constant: 2),
            restaurantCard.heightAnchor.constraint(equalToConstant: 52)
        ])

        mapView.configure(order: order)

        view.addSubview(etaLabel)
        view.addSubview(statusLabel)
        view.addSubview(progressBar)
        view.addSubview(mapView)
        view.addSubview(distanceLabel)
        view.addSubview(restaurantCard)

        NSLayoutConstraint.activate([
            etaLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            etaLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),

            statusLabel.leadingAnchor.constraint(equalTo: etaLabel.leadingAnchor),
            statusLabel.topAnchor.constraint(equalTo: etaLabel.bottomAnchor, constant: 4),

            progressBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            progressBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            progressBar.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 12),
            progressBar.heightAnchor.constraint(equalToConstant: 6),

            progressFill.leadingAnchor.constraint(equalTo: progressBar.leadingAnchor),
            progressFill.topAnchor.constraint(equalTo: progressBar.topAnchor),
            progressFill.bottomAnchor.constraint(equalTo: progressBar.bottomAnchor),
            progressFill.widthAnchor.constraint(equalTo: progressBar.widthAnchor, multiplier: 0.3),

            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            mapView.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 16),
            mapView.heightAnchor.constraint(equalToConstant: 240),

            distanceLabel.leadingAnchor.constraint(equalTo: mapView.leadingAnchor),
            distanceLabel.topAnchor.constraint(equalTo: mapView.bottomAnchor, constant: 12),

            restaurantCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            restaurantCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            restaurantCard.topAnchor.constraint(equalTo: distanceLabel.bottomAnchor, constant: 16)
        ])
    }

    private func startTimer() {
        updateStatus()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateStatus()
        }
    }

    private func updateStatus() {
        let elapsed = Date().timeIntervalSince(order.startDate)
        let total = Double(order.etaMinutes * 60)
        let progress = total > 0 ? min(1.0, elapsed / total) : 1.0
        let remainingMinutes = progress >= 1.0 ? 0 : max(1, Int(ceil((total - elapsed) / 60)))
        if order.orderType == .pickup {
            etaLabel.text = "Ready in \(remainingMinutes) min"
            distanceLabel.text = "Pickup at \(order.restaurant.name)"
            let statusMessages = ["Order received", "Preparing", "Almost ready", "Ready for pickup"]
            let statusIndex = min(statusMessages.count - 1, Int(progress * Double(statusMessages.count - 1)))
            statusLabel.text = statusMessages[statusIndex]
        } else {
            let remainingDistance = max(0.2, order.distanceMiles * (1 - progress))
            etaLabel.text = "ETA \(remainingMinutes) min"
            distanceLabel.text = String(format: "Driver %.1f mi away to %@", remainingDistance, order.destinationAddress.label)
            let statusMessages = ["Order confirmed", "Preparing", "Picking up", "On the way", "Arriving soon"]
            let statusIndex = min(statusMessages.count - 1, Int(progress * Double(statusMessages.count - 1)))
            statusLabel.text = statusMessages[statusIndex]
        }

        mapView.progress = progress

        if progress >= 1.0 {
            timer?.invalidate()
            DashStore.shared.completeActiveOrder()
            etaLabel.text = order.orderType == .pickup ? "Ready now" : "Delivered"
            statusLabel.text = order.orderType == .pickup ? "Ready for pickup" : "Delivered"
        }
    }
}

private func offsetCoordinate(_ coordinate: CLLocationCoordinate2D, latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: coordinate.latitude + latitude, longitude: coordinate.longitude + longitude)
}

private func blendCoordinates(
    _ start: CLLocationCoordinate2D,
    _ end: CLLocationCoordinate2D,
    fraction: Double,
    latitudeOffset: CLLocationDegrees = 0,
    longitudeOffset: CLLocationDegrees = 0
) -> CLLocationCoordinate2D {
    CLLocationCoordinate2D(
        latitude: start.latitude + ((end.latitude - start.latitude) * fraction) + latitudeOffset,
        longitude: start.longitude + ((end.longitude - start.longitude) * fraction) + longitudeOffset
    )
}

private struct TrackingRoutePath {
    let coordinates: [CLLocationCoordinate2D]

    init(order: ActiveOrder) {
        if order.orderType == .pickup {
            coordinates = Self.pickupRoute(from: order.destinationAddress.coordinate, to: order.restaurant.coordinate)
        } else {
            coordinates = Self.deliveryRoute(from: order.restaurant.coordinate, to: order.destinationAddress.coordinate)
        }
    }

    private static func pickupRoute(from start: CLLocationCoordinate2D, to restaurant: CLLocationCoordinate2D) -> [CLLocationCoordinate2D] {
        let latSign = restaurant.latitude >= start.latitude ? 1.0 : -1.0
        let lonSign = restaurant.longitude >= start.longitude ? 1.0 : -1.0
        let firstTurn = blendCoordinates(start, restaurant, fraction: 0.38, latitudeOffset: 0.0025 * latSign, longitudeOffset: -0.0030 * lonSign)
        let finalTurn = blendCoordinates(start, restaurant, fraction: 0.78, latitudeOffset: -0.0012 * latSign, longitudeOffset: 0.0018 * lonSign)
        return [start, firstTurn, finalTurn, restaurant]
    }

    private static func deliveryRoute(from restaurant: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> [CLLocationCoordinate2D] {
        let latSign = destination.latitude >= restaurant.latitude ? 1.0 : -1.0
        let lonSign = destination.longitude >= restaurant.longitude ? 1.0 : -1.0
        let driverStart = offsetCoordinate(restaurant, latitude: 0.009 * latSign, longitude: -0.010 * lonSign)
        let pickupApproach = blendCoordinates(driverStart, restaurant, fraction: 0.68, latitudeOffset: -0.0012 * latSign, longitudeOffset: 0.0012 * lonSign)
        let downtownTurn = blendCoordinates(restaurant, destination, fraction: 0.34, latitudeOffset: 0.0040 * latSign, longitudeOffset: -0.0030 * lonSign)
        let neighborhoodTurn = blendCoordinates(restaurant, destination, fraction: 0.74, latitudeOffset: -0.0020 * latSign, longitudeOffset: 0.0020 * lonSign)
        return [driverStart, pickupApproach, restaurant, downtownTurn, neighborhoodTurn, destination]
    }

    func coordinate(at progress: Double) -> CLLocationCoordinate2D {
        guard coordinates.count > 1 else { return coordinates.first ?? CLLocationCoordinate2D() }

        let clamped = min(max(progress, 0), 1)
        let points = coordinates.map(MKMapPoint.init)
        let segments = zip(points, points.dropFirst()).map { $0.distance(to: $1) }
        let totalDistance = segments.reduce(0, +)
        guard totalDistance > 0 else { return coordinates.last ?? coordinates[0] }

        var remainingDistance = totalDistance * clamped
        for index in 0..<segments.count {
            let segmentDistance = segments[index]
            if remainingDistance <= segmentDistance {
                let fraction = segmentDistance == 0 ? 0 : remainingDistance / segmentDistance
                return blendCoordinates(coordinates[index], coordinates[index + 1], fraction: fraction)
            }
            remainingDistance -= segmentDistance
        }
        return coordinates.last ?? coordinates[0]
    }

    func prefixCoordinates(upTo progress: Double) -> [CLLocationCoordinate2D] {
        guard coordinates.count > 1 else { return coordinates }

        let clamped = min(max(progress, 0), 1)
        if clamped <= 0 { return [coordinates[0]] }
        if clamped >= 1 { return coordinates }

        let points = coordinates.map(MKMapPoint.init)
        let segments = zip(points, points.dropFirst()).map { $0.distance(to: $1) }
        let totalDistance = segments.reduce(0, +)
        guard totalDistance > 0 else { return coordinates }

        var remainingDistance = totalDistance * clamped
        var results = [coordinates[0]]
        for index in 0..<segments.count {
            let segmentDistance = segments[index]
            if remainingDistance >= segmentDistance {
                results.append(coordinates[index + 1])
                remainingDistance -= segmentDistance
            } else {
                let fraction = segmentDistance == 0 ? 0 : remainingDistance / segmentDistance
                results.append(blendCoordinates(coordinates[index], coordinates[index + 1], fraction: fraction))
                break
            }
        }
        return results
    }
}

private enum TrackingAnnotationKind {
    case restaurant
    case destination
    case courier
}

private final class TrackingPointAnnotation: NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    let kind: TrackingAnnotationKind

    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?, kind: TrackingAnnotationKind) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.kind = kind
    }
}

final class TrackingMapView: UIView, MKMapViewDelegate {
    private let mapView = MKMapView()
    private var routePath: TrackingRoutePath?
    private var orderType: OrderType = .delivery
    private var baseRouteOverlay: MKPolyline?
    private var progressOverlay: MKPolyline?
    private var courierAnnotation: TrackingPointAnnotation?

    var progress: Double = 0 {
        didSet { updateProgress(animated: true) }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        layer.cornerRadius = 18
        clipsToBounds = true

        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.delegate = self
        mapView.showsCompass = false
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        addSubview(mapView)

        NSLayoutConstraint.activate([
            mapView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: trailingAnchor),
            mapView.topAnchor.constraint(equalTo: topAnchor),
            mapView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func configure(order: ActiveOrder) {
        orderType = order.orderType
        routePath = TrackingRoutePath(order: order)
        progress = 0

        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        baseRouteOverlay = nil
        progressOverlay = nil
        courierAnnotation = nil

        let restaurantAnnotation = TrackingPointAnnotation(
            coordinate: order.restaurant.coordinate,
            title: order.restaurant.name,
            subtitle: order.orderType == .pickup ? "Pickup spot" : "Restaurant",
            kind: .restaurant
        )
        let destinationAnnotation = TrackingPointAnnotation(
            coordinate: order.destinationAddress.coordinate,
            title: order.orderType == .pickup ? order.destinationAddress.label : "Drop-off",
            subtitle: order.destinationAddress.detail,
            kind: .destination
        )
        mapView.addAnnotations([restaurantAnnotation, destinationAnnotation])

        if order.orderType == .delivery, let routePath {
            let courier = TrackingPointAnnotation(
                coordinate: routePath.coordinate(at: 0),
                title: "Dasher",
                subtitle: "En route",
                kind: .courier
            )
            courierAnnotation = courier
            mapView.addAnnotation(courier)
        }

        drawBaseRoute()
        updateProgress(animated: false)
        fitRoute(animated: false)
    }

    private func drawBaseRoute() {
        guard let routePath else { return }
        if let baseRouteOverlay {
            mapView.removeOverlay(baseRouteOverlay)
        }
        let polyline = MKPolyline(coordinates: routePath.coordinates, count: routePath.coordinates.count)
        baseRouteOverlay = polyline
        mapView.addOverlay(polyline)
    }

    private func updateProgress(animated: Bool) {
        guard let routePath else { return }

        if orderType == .delivery {
            courierAnnotation?.coordinate = routePath.coordinate(at: progress)
        }

        if let progressOverlay {
            mapView.removeOverlay(progressOverlay)
        }

        let path = orderType == .delivery ? routePath.prefixCoordinates(upTo: progress) : []
        guard path.count > 1 else {
            progressOverlay = nil
            return
        }

        let polyline = MKPolyline(coordinates: path, count: path.count)
        progressOverlay = polyline
        mapView.addOverlay(polyline)

        if animated, let courierAnnotation {
            UIView.animate(withDuration: 0.25) {
                courierAnnotation.coordinate = routePath.coordinate(at: self.progress)
            }
        }
    }

    private func fitRoute(animated: Bool) {
        guard let routePath, !routePath.coordinates.isEmpty else { return }
        let polyline = MKPolyline(coordinates: routePath.coordinates, count: routePath.coordinates.count)
        mapView.setVisibleMapRect(
            polyline.boundingMapRect,
            edgePadding: UIEdgeInsets(top: 42, left: 30, bottom: 42, right: 30),
            animated: animated
        )
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let polyline = overlay as? MKPolyline else { return MKOverlayRenderer(overlay: overlay) }
        let renderer = MKPolylineRenderer(polyline: polyline)
        renderer.lineCap = .round
        renderer.lineJoin = .round
        if overlay === progressOverlay {
            renderer.strokeColor = DashStyle.red
            renderer.lineWidth = 5
        } else {
            renderer.strokeColor = UIColor(white: 0.80, alpha: 0.9)
            renderer.lineWidth = 4
        }
        return renderer
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? TrackingPointAnnotation else { return nil }

        switch annotation.kind {
        case .restaurant:
            let identifier = "restaurant-pin"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.annotation = annotation
            view.canShowCallout = true
            view.markerTintColor = DashStyle.red
            view.glyphImage = UIImage(systemName: "fork.knife")
            return view
        case .destination:
            let identifier = "destination-pin"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.annotation = annotation
            view.canShowCallout = true
            view.markerTintColor = UIColor(white: 0.22, alpha: 1)
            view.glyphImage = UIImage(systemName: orderType == .pickup ? "house.fill" : "mappin.circle.fill")
            return view
        case .courier:
            let identifier = "courier-pin"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) ?? MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.annotation = annotation
            view.canShowCallout = false
            view.image = courierBadgeImage()
            view.centerOffset = CGPoint(x: 0, y: -2)
            return view
        }
    }

    private func courierBadgeImage() -> UIImage {
        let size = CGSize(width: 34, height: 34)
        let symbolRect = CGRect(x: 8, y: 8, width: 18, height: 18)
        let configuration = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        let symbol = UIImage(systemName: "car.fill", withConfiguration: configuration)?
            .withTintColor(.white, renderingMode: .alwaysOriginal)

        return UIGraphicsImageRenderer(size: size).image { _ in
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).addClip()
            DashStyle.red.setFill()
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).fill()
            UIColor.white.withAlphaComponent(0.18).setStroke()
            UIBezierPath(ovalIn: CGRect(x: 1, y: 1, width: 32, height: 32)).stroke()
            symbol?.draw(in: symbolRect)
        }
    }
}

// MARK: - Browse

final class BrowseViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let searchBar = UISearchBar()
    private var searchResults: [Restaurant] = []
    private var isSearching = false

    private enum BrowseSection: Int, CaseIterable {
        case recentSearches
        case categories
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Browse"
        view.backgroundColor = .systemBackground
        configureTable()
    }

    private func configureTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(BrowseGridCell.self, forCellReuseIdentifier: "BrowseGridCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "RecentCell")
        tableView.register(RestaurantListCell.self, forCellReuseIdentifier: "RestaurantListCell")
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive

        let headerContainer = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 56))
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = "Search QuickBite"
        searchBar.searchBarStyle = .minimal
        searchBar.searchTextField.backgroundColor = DashStyle.lightGray
        searchBar.searchTextField.layer.cornerRadius = 20
        searchBar.searchTextField.clipsToBounds = true
        searchBar.delegate = self
        searchBar.accessibilityIdentifier = "browse_search_bar"
        headerContainer.addSubview(searchBar)
        NSLayoutConstraint.activate([
            searchBar.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -8),
            searchBar.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor)
        ])
        tableView.tableHeaderView = headerContainer

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Search

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        if query.isEmpty {
            isSearching = false
            searchResults = []
        } else {
            isSearching = true
            let lower = query.lowercased()
            searchResults = DashStore.shared.restaurants.filter {
                $0.name.lowercased().contains(lower) ||
                $0.cuisine.lowercased().contains(lower) ||
                $0.tags.contains(where: { $0.lowercased().contains(lower) })
            }
        }
        tableView.reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        isSearching = false
        searchResults = []
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
        tableView.reloadData()
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }

    // MARK: - Table

    func numberOfSections(in tableView: UITableView) -> Int {
        isSearching ? 1 : BrowseSection.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching { return max(1, searchResults.count) }
        switch BrowseSection(rawValue: section) {
        case .recentSearches: return 5
        case .categories: return 1
        case .none: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if isSearching { return "Results" }
        switch BrowseSection(rawValue: section) {
        case .recentSearches: return "Recent Searches"
        case .categories: return "All Categories"
        case .none: return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isSearching {
            if searchResults.isEmpty {
                let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
                cell.textLabel?.text = "No results found"
                cell.detailTextLabel?.text = "Try a different search term"
                cell.selectionStyle = .none
                return cell
            }
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "RestaurantListCell", for: indexPath) as? RestaurantListCell else {
                return UITableViewCell()
            }
            cell.configure(with: searchResults[indexPath.row])
            return cell
        }

        switch BrowseSection(rawValue: indexPath.section) {
        case .recentSearches:
            let cell = tableView.dequeueReusableCell(withIdentifier: "RecentCell", for: indexPath)
            let recentItems = ["Pizza", "Sushi", "Coffee", "Burgers", "Boba"]
            var config = cell.defaultContentConfiguration()
            config.text = recentItems[indexPath.row]
            config.textProperties.font = .systemFont(ofSize: 15, weight: .regular)
            config.image = UIImage(systemName: "clock")
            config.imageProperties.tintColor = .secondaryLabel
            cell.contentConfiguration = config
            cell.selectionStyle = .default
            return cell
        case .categories:
            let cell = tableView.dequeueReusableCell(withIdentifier: "BrowseGridCell", for: indexPath) as? BrowseGridCell
            cell?.configure(categories: DashStore.shared.browseCategories, onSelect: { [weak self] category in
                let results = CategoryResultsViewController(category: category)
                self?.navigationController?.pushViewController(results, animated: true)
            })
            return cell ?? UITableViewCell()
        case .none:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if isSearching {
            guard !searchResults.isEmpty else { return }
            let restaurant = searchResults[indexPath.row]
            let detail = RestaurantDetailViewController(restaurant: restaurant)
            navigationController?.pushViewController(detail, animated: true)
        } else if BrowseSection(rawValue: indexPath.section) == .recentSearches {
            let recentItems = ["Pizza", "Sushi", "Coffee", "Burgers", "Boba"]
            searchBar.text = recentItems[indexPath.row]
            searchBar(searchBar, textDidChange: recentItems[indexPath.row])
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if isSearching { return UITableView.automaticDimension }
        switch BrowseSection(rawValue: indexPath.section) {
        case .recentSearches: return 44
        case .categories: return 620
        case .none: return 0
        }
    }
}

final class CategoryResultsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let category: DashCategory
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private var restaurants: [Restaurant] = []
    private var sortOption: RestaurantSortOption = .featured

    init(category: DashCategory) {
        self.category = category
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = category.title
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Sort", style: .plain, target: self, action: #selector(sortTapped))
        configureTable()
        applySort()
    }

    private func configureTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.register(RestaurantListCell.self, forCellReuseIdentifier: "RestaurantListCell")
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func applySort() {
        let matches = DashStore.shared.restaurants(for: category)
        restaurants = sortRestaurants(matches, by: sortOption)
        tableView.reloadData()
    }

    @objc private func sortTapped() {
        let alert = UIAlertController(title: "Sort", message: nil, preferredStyle: .actionSheet)
        RestaurantSortOption.allCases.forEach { option in
            let action = UIAlertAction(title: option.title, style: .default) { [weak self] _ in
                self?.sortOption = option
                self?.applySort()
            }
            if option == sortOption {
                action.setValue(true, forKey: "checked")
            }
            alert.addAction(action)
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        present(alert, animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        max(1, restaurants.count)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if restaurants.isEmpty {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            cell.textLabel?.text = "No restaurants yet"
            cell.detailTextLabel?.text = "Check back soon for \(category.title.lowercased())"
            cell.selectionStyle = .none
            return cell
        }

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "RestaurantListCell", for: indexPath) as? RestaurantListCell else {
            return UITableViewCell()
        }
        let restaurant = restaurants[indexPath.row]
        cell.configure(with: restaurant)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !restaurants.isEmpty else { return }
        let restaurant = restaurants[indexPath.row]
        let detail = RestaurantDetailViewController(restaurant: restaurant)
        navigationController?.pushViewController(detail, animated: true)
    }
}

final class BrowseGridCell: UITableViewCell {
    private let gridStack = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        gridStack.translatesAutoresizingMaskIntoConstraints = false
        gridStack.axis = .vertical
        gridStack.spacing = 16
        contentView.addSubview(gridStack)

        NSLayoutConstraint.activate([
            gridStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            gridStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            gridStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            gridStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -16)
        ])
    }

    func configure(categories: [DashCategory], onSelect: @escaping (DashCategory) -> Void) {
        gridStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        var index = 0
        let columns = 4
        while index < categories.count {
            let row = UIStackView()
            row.axis = .horizontal
            row.distribution = .fillEqually
            row.spacing = 12

            for _ in 0..<columns {
                if index < categories.count {
                    let item = CategoryGridItemView()
                    let category = categories[index]
                    item.configure(category: category, onTap: {
                        onSelect(category)
                    })
                    row.addArrangedSubview(item)
                } else {
                    row.addArrangedSubview(UIView())
                }
                index += 1
            }

            gridStack.addArrangedSubview(row)
        }
    }
}

final class CategoryGridItemView: UIView {
    private let iconView = UIImageView()
    private let iconContainer = UIView()
    private let label = UILabel()
    private var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit

        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.layer.cornerRadius = 22
        iconContainer.addSubview(iconView)

        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 2

        addSubview(iconContainer)
        addSubview(label)

        NSLayoutConstraint.activate([
            iconContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconContainer.topAnchor.constraint(equalTo: topAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 44),
            iconContainer.heightAnchor.constraint(equalToConstant: 44),

            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            label.topAnchor.constraint(equalTo: iconContainer.bottomAnchor, constant: 6),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }

    func configure(category: DashCategory, onTap: @escaping () -> Void) {
        self.onTap = onTap
        iconView.image = UIImage(systemName: category.symbol)?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)) ?? UIImage(systemName: "circle.fill")
        label.text = category.title
        iconContainer.backgroundColor = category.color
    }

    @objc private func handleTap() {
        onTap?()
    }
}

// MARK: - Account

final class AccountViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let store = DashStore.shared
    private let headerNameLabel = UILabel()
    private let headerEmailLabel = UILabel()

    private struct AccountItem {
        let icon: String
        let title: String
        let subtitle: String?
        let tintColor: UIColor
    }

    private var sections: [[AccountItem]] {
        let savedCount = store.restaurants.prefix(3).count
        let addressCount = store.addresses.count
        let paymentCount = store.paymentAccounts.count
        let orderCount = store.pastOrders.count

        return [
            [
                AccountItem(icon: "heart.fill", title: "Saved Stores", subtitle: "\(savedCount) stores", tintColor: DashStyle.red),
                AccountItem(icon: "gift.fill", title: "Gift Cards", subtitle: "Balance: $25.00", tintColor: .systemPurple),
                AccountItem(icon: "tag.fill", title: "Promos", subtitle: "3 available", tintColor: DashStyle.greenBadge)
            ],
            [
                AccountItem(icon: "creditcard.fill", title: "Payment Methods", subtitle: "\(paymentCount) cards", tintColor: .systemBlue),
                AccountItem(icon: "mappin.circle.fill", title: "Manage Addresses", subtitle: "\(addressCount) saved", tintColor: .systemOrange),
                AccountItem(icon: "person.2.fill", title: "Family Sharing", subtitle: "Not set up", tintColor: .systemTeal)
            ],
            [
                AccountItem(icon: "bolt.fill", title: "DashPass", subtitle: "Active member", tintColor: DashStyle.greenBadge),
                AccountItem(icon: "medal.fill", title: "Rewards", subtitle: "142 points", tintColor: .systemYellow),
                AccountItem(icon: "clock.fill", title: "Order History", subtitle: "\(orderCount) orders", tintColor: DashStyle.subtextGray)
            ],
            [
                AccountItem(icon: "questionmark.circle.fill", title: "Help", subtitle: nil, tintColor: .systemGray),
                AccountItem(icon: "gearshape.fill", title: "Settings", subtitle: nil, tintColor: .systemGray),
                AccountItem(icon: "info.circle.fill", title: "About", subtitle: "v24.12.1", tintColor: .systemGray)
            ]
        ]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Account"
        view.backgroundColor = .systemGroupedBackground
        navigationController?.navigationBar.prefersLargeTitles = false
        configureTable()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        headerNameLabel.text = store.profileName
        headerEmailLabel.text = store.profileEmail
        tableView.reloadData()
    }

    private func configureTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)

        // Profile header
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 148))
        headerView.backgroundColor = .systemGroupedBackground

        let avatarView = UIView()
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.backgroundColor = DashStyle.red
        avatarView.layer.cornerRadius = 30

        let initialsLabel = UILabel()
        initialsLabel.translatesAutoresizingMaskIntoConstraints = false
        initialsLabel.text = "JA"
        initialsLabel.font = .systemFont(ofSize: 20, weight: .bold)
        initialsLabel.textColor = .white
        avatarView.addSubview(initialsLabel)

        let nameLabel = headerNameLabel
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.text = store.profileName
        nameLabel.font = .systemFont(ofSize: 22, weight: .bold)
        nameLabel.textColor = .label

        let emailLabel = headerEmailLabel
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        emailLabel.text = store.profileEmail
        emailLabel.font = .systemFont(ofSize: 14, weight: .regular)
        emailLabel.textColor = .secondaryLabel

        let editButton = UIButton(type: .system)
        editButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.setTitle("Edit", for: .normal)
        editButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        editButton.setTitleColor(DashStyle.red, for: .normal)
        editButton.accessibilityIdentifier = "profile_edit_button"
        editButton.addTarget(self, action: #selector(editProfileTapped), for: .touchUpInside)

        headerView.addSubview(avatarView)
        headerView.addSubview(nameLabel)
        headerView.addSubview(emailLabel)
        headerView.addSubview(editButton)

        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            avatarView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 20),
            avatarView.widthAnchor.constraint(equalToConstant: 60),
            avatarView.heightAnchor.constraint(equalToConstant: 60),

            initialsLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            initialsLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),

            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 14),
            nameLabel.topAnchor.constraint(equalTo: avatarView.topAnchor, constant: 6),

            emailLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),

            editButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            editButton.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor)
        ])

        // DashPass banner in header
        let dashPassBanner = UIView()
        dashPassBanner.translatesAutoresizingMaskIntoConstraints = false
        dashPassBanner.backgroundColor = UIColor(red: 0.0, green: 0.28, blue: 0.15, alpha: 1)
        dashPassBanner.layer.cornerRadius = 12

        let boltIcon = UIImageView(image: UIImage(systemName: "bolt.fill"))
        boltIcon.translatesAutoresizingMaskIntoConstraints = false
        boltIcon.tintColor = DashStyle.greenBadge
        boltIcon.contentMode = .scaleAspectFit

        let dpLabel = UILabel()
        dpLabel.translatesAutoresizingMaskIntoConstraints = false
        dpLabel.text = "DashPass Member"
        dpLabel.font = .systemFont(ofSize: 14, weight: .bold)
        dpLabel.textColor = .white

        let dpDetail = UILabel()
        dpDetail.translatesAutoresizingMaskIntoConstraints = false
        dpDetail.text = "$0 delivery fees on eligible orders"
        dpDetail.font = .systemFont(ofSize: 12, weight: .regular)
        dpDetail.textColor = UIColor.white.withAlphaComponent(0.8)

        dashPassBanner.addSubview(boltIcon)
        dashPassBanner.addSubview(dpLabel)
        dashPassBanner.addSubview(dpDetail)
        headerView.addSubview(dashPassBanner)

        NSLayoutConstraint.activate([
            dashPassBanner.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            dashPassBanner.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            dashPassBanner.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 14),
            dashPassBanner.heightAnchor.constraint(equalToConstant: 44),

            boltIcon.leadingAnchor.constraint(equalTo: dashPassBanner.leadingAnchor, constant: 12),
            boltIcon.centerYAnchor.constraint(equalTo: dashPassBanner.centerYAnchor),
            boltIcon.widthAnchor.constraint(equalToConstant: 16),
            boltIcon.heightAnchor.constraint(equalToConstant: 16),

            dpLabel.leadingAnchor.constraint(equalTo: boltIcon.trailingAnchor, constant: 6),
            dpLabel.centerYAnchor.constraint(equalTo: dashPassBanner.centerYAnchor, constant: -8),

            dpDetail.leadingAnchor.constraint(equalTo: dpLabel.leadingAnchor),
            dpDetail.topAnchor.constraint(equalTo: dpLabel.bottomAnchor, constant: 1)
        ])

        tableView.tableHeaderView = headerView

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func editProfileTapped() {
        let editVC = EditProfileViewController()
        navigationController?.pushViewController(editVC, animated: true)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let item = sections[indexPath.section][indexPath.row]

        var config = cell.defaultContentConfiguration()
        config.text = item.title
        config.textProperties.font = .systemFont(ofSize: 16, weight: .medium)
        config.secondaryText = item.subtitle
        config.secondaryTextProperties.font = .systemFont(ofSize: 13, weight: .regular)
        config.secondaryTextProperties.color = .secondaryLabel
        config.image = UIImage(systemName: item.icon)
        config.imageProperties.tintColor = item.tintColor
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        // Expose a stable accessibility id derived from the row's title so
        // MCP tooling can tap rows via `tap_id("account_row_<slug>")`
        // (e.g. `account_row_help`, `account_row_manage_addresses`).
        let slug = MenuItem.slug(from: item.title)
        cell.accessibilityIdentifier = "account_row_\(slug)"
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = sections[indexPath.section][indexPath.row]

        switch item.title {
        case "Payment Methods":
            let vc = PaymentMethodsViewController()
            navigationController?.pushViewController(vc, animated: true)

        case "Manage Addresses":
            let list = AddressListViewController()
            navigationController?.pushViewController(list, animated: true)

        case "Order History":
            let vc = AccountDetailListViewController(style: .insetGrouped)
            vc.title = "Order History"
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            vc.items = store.pastOrders.map { order in
                let subtotal = order.items.reduce(0.0) { $0 + $1.item.price * Double($1.quantity) }
                let orderTotal = subtotal + 2.99 + subtotal * 0.0875
                let totalStr = String(format: "$%.2f", orderTotal)
                return AccountDetailListViewController.DetailItem(
                    icon: "bag.fill",
                    iconColor: DashStyle.red,
                    title: order.restaurant.name,
                    subtitle: "\(order.items.count) item\(order.items.count == 1 ? "" : "s") · \(totalStr) · \(dateFormatter.string(from: order.startDate))"
                )
            }
            if vc.items.isEmpty {
                vc.items = [
                    AccountDetailListViewController.DetailItem(
                        icon: "clock",
                        iconColor: .secondaryLabel,
                        title: "No past orders",
                        subtitle: "Your order history will appear here"
                    )
                ]
            }
            navigationController?.pushViewController(vc, animated: true)

        case "Saved Stores":
            let vc = SavedStoresViewController()
            navigationController?.pushViewController(vc, animated: true)

        case "DashPass":
            let vc = AccountDetailListViewController(style: .insetGrouped)
            vc.title = "DashPass"
            vc.items = [
                AccountDetailListViewController.DetailItem(
                    icon: "checkmark.circle.fill",
                    iconColor: DashStyle.greenBadge,
                    title: "Status: Active",
                    subtitle: "Member since October 2023"
                ),
                AccountDetailListViewController.DetailItem(
                    icon: "truck.box.fill",
                    iconColor: DashStyle.greenBadge,
                    title: "$0 delivery fee",
                    subtitle: "On orders over $12 from eligible stores"
                ),
                AccountDetailListViewController.DetailItem(
                    icon: "percent",
                    iconColor: DashStyle.greenBadge,
                    title: "Reduced service fees",
                    subtitle: "Save on every eligible order"
                ),
                AccountDetailListViewController.DetailItem(
                    icon: "star.fill",
                    iconColor: DashStyle.greenBadge,
                    title: "Exclusive offers",
                    subtitle: "Members-only deals and promotions"
                )
            ]
            navigationController?.pushViewController(vc, animated: true)

        case "Rewards":
            let vc = AccountDetailListViewController(style: .insetGrouped)
            vc.title = "Rewards"
            vc.items = [
                AccountDetailListViewController.DetailItem(
                    icon: "medal.fill",
                    iconColor: .systemYellow,
                    title: "142 Points",
                    subtitle: "Earn 1 point per $1 spent"
                ),
                AccountDetailListViewController.DetailItem(
                    icon: "gift.fill",
                    iconColor: .systemPurple,
                    title: "Available Rewards",
                    subtitle: "$5 off next order at 200 points"
                )
            ]
            navigationController?.pushViewController(vc, animated: true)

        case "Promos":
            let vc = PromosViewController()
            navigationController?.pushViewController(vc, animated: true)

        case "Gift Cards":
            let vc = AccountDetailListViewController(style: .insetGrouped)
            vc.title = "Gift Cards"
            vc.items = [
                AccountDetailListViewController.DetailItem(icon: "gift.fill", iconColor: .systemPurple, title: "Gift Card Balance", subtitle: "$25.00"),
                AccountDetailListViewController.DetailItem(icon: "plus.circle.fill", iconColor: .systemBlue, title: "Redeem a Gift Card", subtitle: "Enter code to add balance")
            ]
            navigationController?.pushViewController(vc, animated: true)

        case "Help":
            let vc = AccountDetailListViewController(style: .insetGrouped)
            vc.title = "Help"
            vc.items = [
                AccountDetailListViewController.DetailItem(icon: "questionmark.circle", iconColor: .systemBlue, title: "FAQ", subtitle: "Common questions and answers"),
                AccountDetailListViewController.DetailItem(icon: "bubble.left.fill", iconColor: .systemGreen, title: "Chat Support", subtitle: "Avg. wait: 2 minutes"),
                AccountDetailListViewController.DetailItem(icon: "phone.fill", iconColor: .systemOrange, title: "Phone Support", subtitle: "1-855-431-0459"),
                AccountDetailListViewController.DetailItem(icon: "doc.text", iconColor: .systemGray, title: "Terms of Service", subtitle: nil),
                AccountDetailListViewController.DetailItem(icon: "hand.raised.fill", iconColor: .systemGray, title: "Privacy Policy", subtitle: nil)
            ]
            vc.onItemTap = { [weak self] title in
                switch title {
                case "Chat Support":
                    let chat = DashChatSupportViewController()
                    self?.navigationController?.pushViewController(chat, animated: true)
                case "FAQ":
                    let detail = AccountDetailListViewController(style: .insetGrouped)
                    detail.title = "FAQ"
                    detail.items = [
                        AccountDetailListViewController.DetailItem(icon: "questionmark.circle", iconColor: .systemBlue, title: "How do I track my order?", subtitle: "Go to Orders tab and tap Track on your active order"),
                        AccountDetailListViewController.DetailItem(icon: "questionmark.circle", iconColor: .systemBlue, title: "How do I get a refund?", subtitle: "Contact Chat Support for refund requests"),
                        AccountDetailListViewController.DetailItem(icon: "questionmark.circle", iconColor: .systemBlue, title: "How do I change my address?", subtitle: "Go to Account > Manage Addresses"),
                        AccountDetailListViewController.DetailItem(icon: "questionmark.circle", iconColor: .systemBlue, title: "What is DashPass?", subtitle: "$0 delivery fees and reduced service fees on eligible orders")
                    ]
                    self?.navigationController?.pushViewController(detail, animated: true)
                case "Phone Support":
                    let detail = AccountDetailListViewController(style: .insetGrouped)
                    detail.title = "Phone Support"
                    detail.items = [
                        AccountDetailListViewController.DetailItem(icon: "phone.fill", iconColor: .systemOrange, title: "1-855-431-0459", subtitle: "Available 24/7")
                    ]
                    self?.navigationController?.pushViewController(detail, animated: true)
                case "Terms of Service":
                    let detail = AccountDetailListViewController(style: .insetGrouped)
                    detail.title = "Terms of Service"
                    detail.items = [
                        AccountDetailListViewController.DetailItem(icon: "doc.text", iconColor: .systemGray, title: "QuickBite Terms of Service", subtitle: "Last updated: January 2025. By using QuickBite you agree to these terms.")
                    ]
                    self?.navigationController?.pushViewController(detail, animated: true)
                case "Privacy Policy":
                    let detail = AccountDetailListViewController(style: .insetGrouped)
                    detail.title = "Privacy Policy"
                    detail.items = [
                        AccountDetailListViewController.DetailItem(icon: "hand.raised.fill", iconColor: .systemGray, title: "Privacy Policy", subtitle: "QuickBite collects data to provide and improve our services. We do not sell your personal information.")
                    ]
                    self?.navigationController?.pushViewController(detail, animated: true)
                default:
                    break
                }
            }
            navigationController?.pushViewController(vc, animated: true)

        case "Settings":
            let vc = AccountDetailListViewController(style: .insetGrouped)
            vc.title = "Settings"
            vc.items = [
                AccountDetailListViewController.DetailItem(icon: "bell.fill", iconColor: DashStyle.red, title: "Notifications", subtitle: "Push, email, and SMS"),
                AccountDetailListViewController.DetailItem(icon: "globe", iconColor: .systemBlue, title: "Language", subtitle: "English"),
                AccountDetailListViewController.DetailItem(icon: "accessibility", iconColor: .systemPurple, title: "Accessibility", subtitle: nil),
                AccountDetailListViewController.DetailItem(icon: "trash", iconColor: .systemRed, title: "Delete Account", subtitle: nil)
            ]
            vc.onItemTap = { [weak self] title in
                let detail = AccountDetailListViewController(style: .insetGrouped)
                switch title {
                case "Notifications":
                    detail.title = "Notifications"
                    detail.items = [
                        AccountDetailListViewController.DetailItem(icon: "bell.fill", iconColor: DashStyle.red, title: "Push Notifications", subtitle: "Enabled"),
                        AccountDetailListViewController.DetailItem(icon: "envelope.fill", iconColor: .systemBlue, title: "Email Notifications", subtitle: "Enabled"),
                        AccountDetailListViewController.DetailItem(icon: "message.fill", iconColor: .systemGreen, title: "SMS Notifications", subtitle: "Enabled")
                    ]
                case "Language":
                    detail.title = "Language"
                    detail.items = [
                        AccountDetailListViewController.DetailItem(icon: "checkmark.circle.fill", iconColor: .systemBlue, title: "English", subtitle: "Currently selected"),
                        AccountDetailListViewController.DetailItem(icon: "globe", iconColor: .systemGray, title: "Español", subtitle: nil),
                        AccountDetailListViewController.DetailItem(icon: "globe", iconColor: .systemGray, title: "Français", subtitle: nil)
                    ]
                case "Accessibility":
                    detail.title = "Accessibility"
                    detail.items = [
                        AccountDetailListViewController.DetailItem(icon: "textformat.size", iconColor: .systemPurple, title: "Large Text", subtitle: "Uses system setting"),
                        AccountDetailListViewController.DetailItem(icon: "hand.tap.fill", iconColor: .systemPurple, title: "Reduce Motion", subtitle: "Uses system setting")
                    ]
                case "Delete Account":
                    detail.title = "Delete Account"
                    detail.items = [
                        AccountDetailListViewController.DetailItem(icon: "exclamationmark.triangle.fill", iconColor: .systemRed, title: "Delete Account", subtitle: "This action is permanent and cannot be undone. Contact support to proceed.")
                    ]
                default:
                    return
                }
                self?.navigationController?.pushViewController(detail, animated: true)
            }
            navigationController?.pushViewController(vc, animated: true)

        default:
            break
        }
    }
}

// MARK: - Account Detail List

final class AccountDetailListViewController: UITableViewController {
    struct DetailItem {
        let icon: String
        let iconColor: UIColor
        let title: String
        let subtitle: String?
    }

    var items: [DetailItem] = []
    var onItemTap: ((String) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DetailCell")
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell", for: indexPath)
        let item = items[indexPath.row]

        var config = cell.defaultContentConfiguration()
        config.text = item.title
        config.textProperties.font = .systemFont(ofSize: 16, weight: .medium)
        config.secondaryText = item.subtitle
        config.secondaryTextProperties.font = .systemFont(ofSize: 13, weight: .regular)
        config.secondaryTextProperties.color = .secondaryLabel
        config.image = UIImage(systemName: item.icon)
        config.imageProperties.tintColor = item.iconColor
        cell.contentConfiguration = config
        cell.accessoryType = onItemTap != nil ? .disclosureIndicator : .none
        // Expose a stable accessibility id derived from the row's title so
        // MCP tooling can tap rows via `tap_id("account_detail_row_<slug>")`
        // (e.g. `account_detail_row_chat_support`, `account_detail_row_help`).
        let slug = MenuItem.slug(from: item.title)
        cell.accessibilityIdentifier = "account_detail_row_\(slug)"
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        onItemTap?(items[indexPath.row].title)
    }
}

// MARK: - Edit Profile

final class EditProfileViewController: UIViewController {
    private let nameField = UITextField()
    private let emailField = UITextField()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Edit Profile"
        view.backgroundColor = .systemGroupedBackground
        configure()
    }

    private func configure() {
        nameField.translatesAutoresizingMaskIntoConstraints = false
        nameField.text = DashStore.shared.profileName
        nameField.font = .systemFont(ofSize: 16)
        nameField.borderStyle = .roundedRect
        nameField.placeholder = "Name"
        nameField.accessibilityIdentifier = "doordash.editProfile.name"

        emailField.translatesAutoresizingMaskIntoConstraints = false
        emailField.text = DashStore.shared.profileEmail
        emailField.font = .systemFont(ofSize: 16)
        emailField.borderStyle = .roundedRect
        emailField.placeholder = "Email"
        emailField.keyboardType = .emailAddress
        emailField.accessibilityIdentifier = "doordash.editProfile.email"

        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.text = "Name"
        nameLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        nameLabel.textColor = .secondaryLabel

        let emailLabel = UILabel()
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        emailLabel.text = "Email"
        emailLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        emailLabel.textColor = .secondaryLabel

        let saveButton = UIButton(type: .system)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.setTitle("Save Changes", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        saveButton.backgroundColor = DashStyle.red
        saveButton.layer.cornerRadius = 12
        saveButton.accessibilityIdentifier = "doordash.editProfile.save"
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        view.addSubview(nameLabel)
        view.addSubview(nameField)
        view.addSubview(emailLabel)
        view.addSubview(emailField)
        view.addSubview(saveButton)

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            nameLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),

            nameField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            nameField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            nameField.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),
            nameField.heightAnchor.constraint(equalToConstant: 44),

            emailLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            emailLabel.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 16),

            emailField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            emailField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            emailField.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 6),
            emailField.heightAnchor.constraint(equalToConstant: 44),

            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            saveButton.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 24),
            saveButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    @objc private func saveTapped() {
        DashStore.shared.updateProfile(name: nameField.text, email: emailField.text)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Saved Stores

final class SavedStoresViewController: UITableViewController {
    private var savedRestaurants: [Restaurant] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Saved Stores"
        view.backgroundColor = .systemGroupedBackground
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        savedRestaurants = Array(DashStore.shared.restaurants.prefix(3))
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        max(1, savedRestaurants.count)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if savedRestaurants.isEmpty {
            var config = cell.defaultContentConfiguration()
            config.text = "No saved stores"
            config.secondaryText = "Heart a restaurant to save it"
            config.secondaryTextProperties.color = .secondaryLabel
            cell.contentConfiguration = config
            cell.selectionStyle = .none
            return cell
        }
        let restaurant = savedRestaurants[indexPath.row]
        var config = cell.defaultContentConfiguration()
        config.text = restaurant.name
        config.secondaryText = "\(restaurant.cuisine) · \(restaurant.eta)"
        config.secondaryTextProperties.color = .secondaryLabel
        config.image = UIImage(systemName: "heart.fill")
        config.imageProperties.tintColor = DashStyle.red
        cell.contentConfiguration = config
        cell.selectionStyle = .none
        return cell
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !savedRestaurants.isEmpty else { return nil }
        let unsave = UIContextualAction(style: .destructive, title: "Unsave") { [weak self] _, _, completion in
            self?.savedRestaurants.remove(at: indexPath.row)
            if self?.savedRestaurants.isEmpty == true {
                tableView.reloadData()
            } else {
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
            completion(true)
        }
        unsave.image = UIImage(systemName: "heart.slash.fill")
        return UISwipeActionsConfiguration(actions: [unsave])
    }
}

// MARK: - Promos

final class PromosViewController: UITableViewController {
    private struct Promo {
        let title: String
        let detail: String
        let code: String
        let storeName: String?
    }

    private let promos: [Promo] = [
        Promo(title: "20% off Sweetgreen", detail: "Get 20% off your next Sweetgreen order over $15. Valid through next week.", code: "SWEET20", storeName: "Sweetgreen"),
        Promo(title: "$5 off DashMart", detail: "Save $5 on your next DashMart order of $20 or more.", code: "MART5OFF", storeName: "DashMart"),
        Promo(title: "Free Delivery", detail: "Free delivery on your next 3 orders from any restaurant. No minimum.", code: "FREEDEL3", storeName: nil)
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Promos"
        view.backgroundColor = .systemGroupedBackground
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        promos.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let promo = promos[indexPath.row]
        var config = cell.defaultContentConfiguration()
        config.text = promo.title
        config.textProperties.font = .systemFont(ofSize: 16, weight: .semibold)
        config.secondaryText = "\(promo.detail)\nCode: \(promo.code)"
        config.secondaryTextProperties.font = .systemFont(ofSize: 13, weight: .regular)
        config.secondaryTextProperties.color = .secondaryLabel
        config.secondaryTextProperties.numberOfLines = 3
        config.image = UIImage(systemName: "tag.fill")
        config.imageProperties.tintColor = DashStyle.greenBadge
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let promo = promos[indexPath.row]
        let detail = AccountDetailListViewController(style: .insetGrouped)
        detail.title = promo.title
        var items = [
            AccountDetailListViewController.DetailItem(icon: "tag.fill", iconColor: DashStyle.greenBadge, title: promo.title, subtitle: promo.detail),
            AccountDetailListViewController.DetailItem(icon: "doc.on.doc", iconColor: .systemBlue, title: "Promo Code", subtitle: promo.code)
        ]
        if let store = promo.storeName {
            items.append(AccountDetailListViewController.DetailItem(icon: "storefront.fill", iconColor: DashStyle.red, title: "Valid at", subtitle: store))
        }
        detail.items = items
        navigationController?.pushViewController(detail, animated: true)
    }
}

// MARK: - Payment Methods

final class PaymentMethodsViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Payment Methods"
        view.backgroundColor = .systemGroupedBackground
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 2 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? DashStore.shared.paymentAccounts.count : 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if indexPath.section == 0 {
            let account = DashStore.shared.paymentAccounts[indexPath.row]
            var config = cell.defaultContentConfiguration()
            config.text = account.name
            config.textProperties.font = .systemFont(ofSize: 16, weight: .medium)
            config.secondaryText = account.network
            config.secondaryTextProperties.font = .systemFont(ofSize: 13, weight: .regular)
            config.secondaryTextProperties.color = .secondaryLabel
            config.image = UIImage(systemName: account.type == .credit ? "creditcard.fill" : "banknote.fill")
            config.imageProperties.tintColor = account.type == .credit ? .systemBlue : .systemGreen
            cell.contentConfiguration = config
            cell.accessoryType = account.id == DashStore.shared.selectedPaymentAccountId ? .checkmark : .none
            cell.selectionStyle = .default
        } else {
            var config = cell.defaultContentConfiguration()
            config.text = "+ Add Payment Method"
            config.textProperties.color = DashStyle.red
            config.textProperties.font = .systemFont(ofSize: 16, weight: .semibold)
            config.image = UIImage(systemName: "plus.circle.fill")
            config.imageProperties.tintColor = DashStyle.red
            cell.contentConfiguration = config
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            let account = DashStore.shared.paymentAccounts[indexPath.row]
            DashStore.shared.setPaymentAccount(account)
            tableView.reloadData()
        } else {
            let addVC = AddPaymentMethodViewController()
            addVC.onSave = { [weak self] in
                self?.tableView.reloadData()
            }
            navigationController?.pushViewController(addVC, animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.section == 0 else { return nil }
        let remove = UIContextualAction(style: .destructive, title: "Remove") { [weak self] _, _, completion in
            DashStore.shared.removePaymentAccount(at: indexPath.row)
            self?.tableView.reloadData()
            completion(true)
        }
        remove.image = UIImage(systemName: "trash.fill")
        return UISwipeActionsConfiguration(actions: [remove])
    }
}

final class AddPaymentMethodViewController: UIViewController {
    private let cardNumberField = UITextField()
    private let nameField = UITextField()
    var onSave: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Add Card"
        view.backgroundColor = .systemGroupedBackground
        configure()
    }

    private func configure() {
        nameField.translatesAutoresizingMaskIntoConstraints = false
        nameField.placeholder = "Cardholder Name"
        nameField.font = .systemFont(ofSize: 16)
        nameField.borderStyle = .roundedRect
        nameField.accessibilityIdentifier = "doordash.addCard.name"

        cardNumberField.translatesAutoresizingMaskIntoConstraints = false
        cardNumberField.placeholder = "Card Number (last 4 digits)"
        cardNumberField.font = .systemFont(ofSize: 16)
        cardNumberField.borderStyle = .roundedRect
        cardNumberField.keyboardType = .numberPad
        cardNumberField.accessibilityIdentifier = "doordash.addCard.number"

        let saveButton = UIButton(type: .system)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.setTitle("Add Card", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        saveButton.backgroundColor = DashStyle.red
        saveButton.layer.cornerRadius = 12
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        saveButton.accessibilityIdentifier = "doordash.addCard.save"

        view.addSubview(nameField)
        view.addSubview(cardNumberField)
        view.addSubview(saveButton)

        NSLayoutConstraint.activate([
            nameField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            nameField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            nameField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            nameField.heightAnchor.constraint(equalToConstant: 44),

            cardNumberField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            cardNumberField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            cardNumberField.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 12),
            cardNumberField.heightAnchor.constraint(equalToConstant: 44),

            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            saveButton.topAnchor.constraint(equalTo: cardNumberField.bottomAnchor, constant: 24),
            saveButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    @objc private func saveTapped() {
        let name = (nameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let number = (cardNumberField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !number.isEmpty else { return }
        let account = PaymentAccount(
            id: UUID(), name: "\(name) (...\(number.suffix(4)))",
            type: .credit, balance: 0, availableBalance: 5000.00,
            currency: "USD", lastUpdated: Date(), creditLimit: 5000.00
        )
        DashStore.shared.addPaymentAccount(account)
        onSave?()
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - LLM Chat Support

private struct DashChatMessage {
    let id: String
    let text: String
    let isSupport: Bool
    let timestamp: Date
}

final class DashLLMService {
    static let shared = DashLLMService()

    private let session = URLSession.shared
    private var apiKey: String? {
        if let env = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !env.isEmpty { return env }
        if let plist = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
           !plist.isEmpty, !plist.contains("$(") { return plist }
        if let key = keyFromEnvFile() { return key }
        if let ud = UserDefaults.standard.string(forKey: "openai_api_key"), !ud.isEmpty { return ud }
        return nil
    }

    var isAvailable: Bool { apiKey != nil && !(apiKey ?? "").isEmpty }

    private func keyFromEnvFile() -> String? {
        var dir = Bundle.main.bundleURL.deletingLastPathComponent()
        for _ in 0..<10 {
            let envFile = dir.appendingPathComponent(".env")
            if let contents = try? String(contentsOf: envFile, encoding: .utf8) {
                for line in contents.components(separatedBy: .newlines) {
                    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard trimmed.hasPrefix("OPENAI_API_KEY"), let eqIdx = trimmed.firstIndex(of: "=") else { continue }
                    var val = String(trimmed[trimmed.index(after: eqIdx)...]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if (val.hasPrefix("\"") && val.hasSuffix("\"")) || (val.hasPrefix("'") && val.hasSuffix("'")) {
                        val = String(val.dropFirst().dropLast())
                    }
                    if !val.isEmpty { return val }
                }
            }
            let parent = dir.deletingLastPathComponent()
            if parent.path == dir.path { break }
            dir = parent
        }
        return nil
    }

    private struct ChatResponse: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable {
                let content: String
            }
            let message: Message
        }
        let choices: [Choice]
    }

    func generateSupportReply(
        customerName: String,
        orderHistory: String,
        conversationHistory: [(role: String, text: String)],
        customerMessage: String,
        completion: @escaping (String?) -> Void
    ) {
        guard let apiKey = apiKey else {
            completion(nil)
            return
        }

        let systemPrompt = """
        You are a friendly QuickBite customer support agent. Your name is Alex. \
        The customer's name is \(customerName). \(orderHistory) \
        Reply in 1-3 short, helpful sentences. Be concise and solution-oriented. \
        Do not use emojis. Do not break character. Do not mention AI or being an assistant.
        """

        var messages: [[String: Any]] = []
        for entry in conversationHistory.suffix(10) {
            messages.append(["role": entry.role == "support" ? "assistant" : "user", "content": entry.text])
        }
        messages.append(["role": "user", "content": customerMessage])

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [["role": "system", "content": systemPrompt]] + messages,
            "temperature": 0.8,
            "max_tokens": 256
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body),
              let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        request.timeoutInterval = 15

        session.dataTask(with: request) { data, _, error in
            guard error == nil, let data = data,
                  let decoded = try? JSONDecoder().decode(ChatResponse.self, from: data),
                  let text = decoded.choices.first?.message.content else {
                completion(nil)
                return
            }
            completion(text.trimmingCharacters(in: .whitespacesAndNewlines))
        }.resume()
    }
}

final class DashChatSupportViewController: UIViewController, UITableViewDataSource, UITextFieldDelegate {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let inputField = UITextField()
    private let sendButton = UIButton(type: .system)
    private let inputBar = UIView()
    private var messages: [DashChatMessage] = []
    private var inputBarBottom: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Chat Support"
        view.backgroundColor = .systemBackground
        view.accessibilityIdentifier = "doordash.chatSupport"
        configureLayout()
        registerForKeyboard()
        addGreeting()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollToBottom(animated: false)
    }

    private func configureLayout() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemBackground
        tableView.allowsSelection = false
        tableView.keyboardDismissMode = .interactive
        view.addSubview(tableView)

        inputBar.translatesAutoresizingMaskIntoConstraints = false
        inputBar.backgroundColor = .systemBackground

        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = DashStyle.separator
        inputBar.addSubview(separator)

        inputField.translatesAutoresizingMaskIntoConstraints = false
        inputField.placeholder = "Type a message..."
        inputField.font = .systemFont(ofSize: 16)
        inputField.borderStyle = .none
        inputField.backgroundColor = UIColor(white: 0.95, alpha: 1)
        inputField.layer.cornerRadius = 20
        inputField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        inputField.leftViewMode = .always
        inputField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        inputField.rightViewMode = .always
        inputField.delegate = self
        inputField.returnKeyType = .send
        inputField.accessibilityIdentifier = "doordash.chat.input"
        inputBar.addSubview(inputField)

        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        sendButton.tintColor = DashStyle.red
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        sendButton.accessibilityIdentifier = "doordash.chat.send"
        inputBar.addSubview(sendButton)

        view.addSubview(inputBar)

        inputBarBottom = inputBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputBar.topAnchor),

            inputBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputBarBottom!,

            separator.leadingAnchor.constraint(equalTo: inputBar.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: inputBar.trailingAnchor),
            separator.topAnchor.constraint(equalTo: inputBar.topAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1),

            inputField.leadingAnchor.constraint(equalTo: inputBar.leadingAnchor, constant: 12),
            inputField.topAnchor.constraint(equalTo: inputBar.topAnchor, constant: 8),
            inputField.bottomAnchor.constraint(equalTo: inputBar.bottomAnchor, constant: -8),
            inputField.heightAnchor.constraint(equalToConstant: 40),

            sendButton.leadingAnchor.constraint(equalTo: inputField.trailingAnchor, constant: 8),
            sendButton.trailingAnchor.constraint(equalTo: inputBar.trailingAnchor, constant: -12),
            sendButton.centerYAnchor.constraint(equalTo: inputField.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 32),
            sendButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    private func addGreeting() {
        let name = "Jordan"
        let greeting = DashChatMessage(
            id: UUID().uuidString,
            text: "Hi \(name)! I'm Alex from QuickBite Support. How can I help you today?",
            isSupport: true,
            timestamp: Date()
        )
        messages.append(greeting)
        tableView.reloadData()
    }

    @objc private func sendTapped() {
        let text = (inputField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let msg = DashChatMessage(id: UUID().uuidString, text: text, isSupport: false, timestamp: Date())
        messages.append(msg)
        inputField.text = ""
        tableView.reloadData()
        scrollToBottom(animated: false)
        respondFromSupport(to: text)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendTapped()
        return false
    }

    private func respondFromSupport(to customerMessage: String) {
        let typingID = "__typing__"
        let typing = DashChatMessage(id: typingID, text: "···", isSupport: true, timestamp: Date())
        messages.append(typing)
        tableView.reloadData()
        scrollToBottom(animated: true)

        let llm = DashLLMService.shared
        let store = DashStore.shared

        var orderContext = "The customer has no recent orders."
        if let lastOrder = store.pastOrders.first {
            let itemTotal = lastOrder.items.reduce(0.0) { $0 + $1.item.price * Double($1.quantity) }
            orderContext = "The customer's most recent order was from \(lastOrder.restaurant.name) for $\(String(format: "%.2f", itemTotal))."
        }

        guard llm.isAvailable else {
            deliverFallback(typingID: typingID, customerMessage: customerMessage)
            return
        }

        let history = messages
            .filter { $0.id != typingID }
            .map { (role: $0.isSupport ? "support" : "customer", text: $0.text) }

        llm.generateSupportReply(
            customerName: "Jordan",
            orderHistory: orderContext,
            conversationHistory: history,
            customerMessage: customerMessage
        ) { [weak self] reply in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let reply = reply {
                    self.replaceTyping(typingID: typingID, text: reply)
                } else {
                    self.deliverFallback(typingID: typingID, customerMessage: customerMessage)
                }
            }
        }
    }

    private func deliverFallback(typingID: String, customerMessage: String) {
        let lower = customerMessage.lowercased()
        let reply: String
        if lower.contains("refund") || lower.contains("charge") || lower.contains("money") {
            reply = "I understand your concern about the charge. Let me look into this for you. Could you share the order number so I can review the details?"
        } else if lower.contains("late") || lower.contains("where") || lower.contains("delivery") || lower.contains("driver") {
            reply = "I'm sorry about the delay. Let me check the status of your delivery and get you an updated ETA right away."
        } else if lower.contains("cancel") {
            reply = "I can help you with that cancellation. Could you confirm which order you'd like to cancel?"
        } else if lower.contains("missing") || lower.contains("wrong") || lower.contains("incorrect") {
            reply = "I'm sorry to hear that. I can help resolve this. Could you let me know what was missing or incorrect in your order?"
        } else if lower.contains("dasher") || lower.contains("tip") {
            reply = "I appreciate you reaching out about this. Let me look into the details and see how I can assist you."
        } else {
            reply = "Thanks for reaching out! I'd be happy to help. Could you give me a few more details so I can assist you better?"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.replaceTyping(typingID: typingID, text: reply)
        }
    }

    private func replaceTyping(typingID: String, text: String) {
        if let idx = messages.firstIndex(where: { $0.id == typingID }) {
            messages[idx] = DashChatMessage(id: UUID().uuidString, text: text, isSupport: true, timestamp: Date())
        } else {
            messages.append(DashChatMessage(id: UUID().uuidString, text: text, isSupport: true, timestamp: Date()))
        }
        tableView.reloadData()
        scrollToBottom(animated: true)
    }

    private func scrollToBottom(animated: Bool) {
        guard !messages.isEmpty else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }

    // MARK: - TableView

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let msg = messages[indexPath.row]
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.selectionStyle = .none
        cell.backgroundColor = .systemBackground

        let bubble = UIView()
        bubble.translatesAutoresizingMaskIntoConstraints = false
        bubble.layer.cornerRadius = 16
        bubble.backgroundColor = msg.isSupport ? UIColor(white: 0.93, alpha: 1) : DashStyle.red

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = msg.text
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = msg.isSupport ? .label : .white
        label.numberOfLines = 0

        bubble.addSubview(label)
        cell.contentView.addSubview(bubble)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -12),
            label.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -8),

            bubble.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 4),
            bubble.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -4),
            bubble.widthAnchor.constraint(lessThanOrEqualTo: cell.contentView.widthAnchor, multiplier: 0.75)
        ])

        if msg.isSupport {
            bubble.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 12).isActive = true
        } else {
            bubble.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -12).isActive = true
        }

        return cell
    }

    // MARK: - Keyboard

    private func registerForKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let frameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let endFrame = view.convert(frameValue.cgRectValue, from: nil)
        let overlap = max(0, view.bounds.maxY - endFrame.minY - view.safeAreaInsets.bottom)
        inputBarBottom?.constant = -overlap

        let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }
}

// MARK: - Helpers

struct MyBankLedgerWriter {
    private static let appGroupID = "group.com.iosworld.benchmark.personalsuite"
    private static let ledgerFileName = "mybank_ledger.json"
    private static let ioQueue = DispatchQueue(label: "quickbite.ledger.io", qos: .utility)

    private struct LedgerTransaction: Codable {
        let id: UUID
        let externalId: String
        let accountId: UUID
        let vendor: String
        let amount: Double
        let currency: String
        let category: String
        let note: String?
        let timestamp: Date
        let status: String
        let sourceApp: String
        let rawSource: String

        enum CodingKeys: String, CodingKey {
            case id
            case externalId = "external_id"
            case accountId = "account_id"
            case vendor
            case amount
            case currency
            case category
            case note
            case timestamp
            case status
            case sourceApp = "source_app"
            case rawSource = "raw_source"
        }
    }

    static func recordOrder(_ order: ActiveOrder, total: Double, paymentAccountId: UUID?) {
        guard let accountId = paymentAccountId else {
            print("[MyBank] Missing payment account id; skipping ledger write.")
            return
        }
        guard let ledgerURL = ledgerFileURL() else {
            print("[MyBank] App Group unavailable; ledger not written.")
            return
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let itemSummary = order.items.map { "\($0.quantity)x \($0.item.name)" }.joined(separator: ", ")
        let note = "\(order.restaurant.name) • \(itemSummary)"

        let record = LedgerTransaction(
            id: UUID(),
            externalId: order.id.uuidString,
            accountId: accountId,
            vendor: order.restaurant.name,
            amount: -abs(total),
            currency: "USD",
            category: "Food",
            note: note,
            timestamp: Date(),
            status: "pending",
            sourceApp: "QuickBite",
            rawSource: "quickbite_ledger"
        )

        ioQueue.async {
            var ledger = loadLedger(from: ledgerURL)
            if ledger.contains(where: { $0.externalId == record.externalId }) {
                return
            }
            ledger.append(record)
            saveLedger(ledger, to: ledgerURL)
        }
    }

    private static func ledgerFileURL() -> URL? {
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return appGroupURL.appendingPathComponent(ledgerFileName)
        }
        return nil
    }

    private static func loadLedger(from url: URL) -> [LedgerTransaction] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([LedgerTransaction].self, from: data)) ?? []
    }

    private static func saveLedger(_ ledger: [LedgerTransaction], to url: URL) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(ledger)
            try data.write(to: url, options: [.atomic])
        } catch {
            print("[MyBank] Failed to write ledger: \(error)")
        }
    }
}

struct MailOutboxWriter {
    private static let appGroupID = "group.com.iosworld.benchmark.personalsuite"
    private static let fileName = "mail_inbox.json"
    private static let ioQueue = DispatchQueue(label: "quickbite.outbox.io", qos: .utility)

    private struct MailRecord: Codable {
        let id: UUID
        let from: String
        let subject: String
        let body: String
        let category: Int
        let date: Date
    }

    static func recordOrderEmail(_ order: ActiveOrder, total: Double, etaMinutes: Int) {
        guard let url = inboxURL() else {
            print("[Mail] App Group unavailable; mail not written.")
            return
        }

        let itemSummary = order.items.map { "\($0.quantity)x \($0.item.name)" }.joined(separator: ", ")
        let totalText = String(format: "$%.2f", total)
        let subject = "Your QuickBite order is on the way"
        let body = """
        Hi Jordan,

        Your QuickBite order is on the way.

        Vendor: \(order.restaurant.name)
        Total: \(totalText)
        ETA: ~\(etaMinutes) min
        Items: \(itemSummary)

        Order ID: \(order.id.uuidString)

        Thanks,
        QuickBite
        """

        let record = MailRecord(
            id: order.id,
            from: "QuickBite",
            subject: subject,
            body: body,
            category: 1,
            date: Date()
        )

        ioQueue.async {
            var records = loadRecords(from: url)
            if records.contains(where: { $0.id == record.id }) {
                return
            }
            records.append(record)
            saveRecords(records, to: url)
        }
    }

    private static func inboxURL() -> URL? {
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return appGroupURL.appendingPathComponent(fileName)
        }
        return nil
    }

    private static func loadRecords(from url: URL) -> [MailRecord] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([MailRecord].self, from: data)) ?? []
    }

    private static func saveRecords(_ records: [MailRecord], to url: URL) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(records)
            try data.write(to: url, options: [.atomic])
        } catch {
            print("[Mail] Failed to write mail outbox: \(error)")
        }
    }
}

extension Double {
    func rounded(to places: Int) -> Double {
        let multiplier = pow(10.0, Double(places))
        return (self * multiplier).rounded() / multiplier
    }
}
