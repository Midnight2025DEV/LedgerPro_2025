import Foundation

extension CategoryRule {
    /// Comprehensive system rules for merchant categorization
    static var systemRules: [CategoryRule] {
        var rules: [CategoryRule] = []
        
        // MARK: - Income Rules (Highest Priority)
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.salary,
            ruleName: "Direct Deposit - Payroll",
            priority: 150
        ).with {
            $0.merchantContains = "DIRECT DEP"
            $0.amountSign = .positive
            $0.isRecurring = true
            $0.confidence = 0.95
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.salary,
            ruleName: "Payroll Deposits",
            priority: 140
        ).with {
            $0.merchantContains = "PAYROLL"
            $0.amountSign = .positive
            $0.confidence = 0.9
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.salary,
            ruleName: "ACH Credit - Salary",
            priority: 130
        ).with {
            $0.merchantContains = "ACH CREDIT"
            $0.amountSign = .positive
            $0.confidence = 0.8
        })
        
        // MARK: - Transportation Rules
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.transportation,
            ruleName: "Uber Rides",
            priority: 120
        ).with {
            $0.merchantContains = "UBER"
            $0.confidence = 0.95
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.transportation,
            ruleName: "Lyft Rides",
            priority: 120
        ).with {
            $0.merchantContains = "LYFT"
            $0.confidence = 0.95
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.transportation,
            ruleName: "Taxi Services",
            priority: 110
        ).with {
            $0.regexPattern = "(?i)(taxi|cab|yellow cab)"
            $0.confidence = 0.85
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.transportation,
            ruleName: "Public Transit",
            priority: 115
        ).with {
            $0.regexPattern = "(?i)(metro|mta|bart|cta|transit|subway)"
            $0.confidence = 0.9
        })
        
        // MARK: - Gasoline Rules
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.gasoline,
            ruleName: "Shell Gas Stations",
            priority: 100
        ).with {
            $0.merchantContains = "SHELL"
            $0.confidence = 0.95
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.gasoline,
            ruleName: "Chevron Gas Stations",
            priority: 100
        ).with {
            $0.merchantContains = "CHEVRON"
            $0.confidence = 0.95
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.gasoline,
            ruleName: "Exxon Mobil Gas",
            priority: 100
        ).with {
            $0.regexPattern = "(?i)(exxon|mobil|exxonmobil)"
            $0.confidence = 0.95
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.gasoline,
            ruleName: "BP Gas Stations",
            priority: 100
        ).with {
            $0.merchantContains = "BP "
            $0.confidence = 0.9
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.gasoline,
            ruleName: "Citgo Gas",
            priority: 100
        ).with {
            $0.merchantContains = "CITGO"
            $0.confidence = 0.95
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.gasoline,
            ruleName: "Sunoco Gas",
            priority: 100
        ).with {
            $0.merchantContains = "SUNOCO"
            $0.confidence = 0.95
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.gasoline,
            ruleName: "Texaco Gas",
            priority: 100
        ).with {
            $0.merchantContains = "TEXACO"
            $0.confidence = 0.95
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.gasoline,
            ruleName: "Generic Gas Stations",
            priority: 85
        ).with {
            $0.regexPattern = "(?i)(gas|fuel|petroleum|76|speedway|wawa)"
            $0.confidence = 0.8
        })
        
        // MARK: - Dining Rules
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.foodDining,
            ruleName: "McDonald's",
            priority: 100
        ).with {
            $0.regexPattern = "(?i)(mcdonald|mcdonalds)"
            $0.confidence = 0.95
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.foodDining,
            ruleName: "Burger King",
            priority: 100
        ).with {
            $0.merchantContains = "BURGER KING"
            $0.confidence = 0.95
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.foodDining,
            ruleName: "Wendy's",
            priority: 100
        ).with {
            $0.merchantContains = "WENDY"
            $0.confidence = 0.9
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.foodDining,
            ruleName: "Taco Bell",
            priority: 100
        ).with {
            $0.merchantContains = "TACO BELL"
            $0.confidence = 0.95
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.foodDining,
            ruleName: "Subway Sandwiches",
            priority: 95
        ).with {
            $0.merchantContains = "SUBWAY"
            $0.confidence = 0.9
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.foodDining,
            ruleName: "Chipotle",
            priority: 100
        ).with {
            $0.merchantContains = "CHIPOTLE"
            $0.confidence = 0.95
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.foodDining,
            ruleName: "Starbucks Coffee",
            priority: 100
        ).with {
            $0.merchantContains = "STARBUCKS"
            $0.confidence = 0.95
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.foodDining,
            ruleName: "Dunkin' Donuts",
            priority: 100
        ).with {
            $0.regexPattern = "(?i)(dunkin|dunkin'|dd)"
            $0.confidence = 0.9
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.foodDining,
            ruleName: "Generic Restaurants",
            priority: 80
        ).with {
            $0.regexPattern = "(?i)(restaurant|cafe|diner|bistro|grill|pizza|kfc|domino)"
            $0.confidence = 0.75
        })
        
        // MARK: - Grocery Rules
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.groceries,
            ruleName: "Walmart",
            priority: 90
        ).with {
            $0.merchantContains = "WALMART"
            $0.confidence = 0.85
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.groceries,
            ruleName: "Target",
            priority: 85
        ).with {
            $0.merchantContains = "TARGET"
            $0.confidence = 0.8
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.groceries,
            ruleName: "Kroger",
            priority: 100
        ).with {
            $0.merchantContains = "KROGER"
            $0.confidence = 0.95
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.groceries,
            ruleName: "Safeway",
            priority: 100
        ).with {
            $0.merchantContains = "SAFEWAY"
            $0.confidence = 0.95
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.groceries,
            ruleName: "Whole Foods",
            priority: 100
        ).with {
            $0.regexPattern = "(?i)(whole foods|wholefoods|wfm)"
            $0.confidence = 0.95
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.groceries,
            ruleName: "Trader Joe's",
            priority: 100
        ).with {
            $0.regexPattern = "(?i)(trader joe|traderjoe)"
            $0.confidence = 0.95
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.groceries,
            ruleName: "Costco Wholesale",
            priority: 95
        ).with {
            $0.merchantContains = "COSTCO"
            $0.confidence = 0.9
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.groceries,
            ruleName: "Sam's Club",
            priority: 95
        ).with {
            $0.regexPattern = "(?i)(sam's club|sams club)"
            $0.confidence = 0.9
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.groceries,
            ruleName: "Generic Supermarkets",
            priority: 80
        ).with {
            $0.regexPattern = "(?i)(supermarket|grocery|food market|iga|publix|harris teeter)"
            $0.confidence = 0.85
        })
        
        // MARK: - Shopping Rules
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.shopping,
            ruleName: "Amazon",
            priority: 100
        ).with {
            $0.regexPattern = "(?i)(amazon|amzn)"
            $0.confidence = 0.95
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.shopping,
            ruleName: "Best Buy",
            priority: 100
        ).with {
            $0.merchantContains = "BEST BUY"
            $0.confidence = 0.95
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.shopping,
            ruleName: "Home Depot",
            priority: 100
        ).with {
            $0.merchantContains = "HOME DEPOT"
            $0.confidence = 0.95
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.shopping,
            ruleName: "Lowe's",
            priority: 100
        ).with {
            $0.merchantContains = "LOWE"
            $0.confidence = 0.9
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.shopping,
            ruleName: "Nike",
            priority: 95
        ).with {
            $0.merchantContains = "NIKE"
            $0.confidence = 0.9
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.shopping,
            ruleName: "Clothing Stores",
            priority: 85
        ).with {
            $0.regexPattern = "(?i)(macy|nordstrom|gap|old navy|tj maxx|marshall|h&m|zara|uniqlo)"
            $0.confidence = 0.85
        })
        
        // MARK: - Utilities Rules
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.utilities,
            ruleName: "Electric Companies",
            priority: 110
        ).with {
            $0.regexPattern = "(?i)(electric|pge|edison|duke energy|con ed|xcel)"
            $0.confidence = 0.9
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.utilities,
            ruleName: "Gas Utilities",
            priority: 110
        ).with {
            $0.regexPattern = "(?i)(gas company|natural gas|gas utility)"
            $0.confidence = 0.9
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.utilities,
            ruleName: "Water Companies",
            priority: 110
        ).with {
            $0.regexPattern = "(?i)(water|sewer|municipal)"
            $0.confidence = 0.85
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.utilities,
            ruleName: "Internet/Cable",
            priority: 105
        ).with {
            $0.regexPattern = "(?i)(comcast|xfinity|verizon|at&t|spectrum|cox|charter)"
            $0.confidence = 0.9
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.utilities,
            ruleName: "Phone Bills",
            priority: 105
        ).with {
            $0.regexPattern = "(?i)(t-mobile|tmobile|sprint|wireless)"
            $0.confidence = 0.85
        })
        
        // MARK: - Entertainment Rules
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.entertainment,
            ruleName: "Netflix",
            priority: 100
        ).with {
            $0.merchantContains = "NETFLIX"
            $0.confidence = 0.95
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.entertainment,
            ruleName: "Spotify",
            priority: 100
        ).with {
            $0.merchantContains = "SPOTIFY"
            $0.confidence = 0.95
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.entertainment,
            ruleName: "Movie Theaters",
            priority: 95
        ).with {
            $0.regexPattern = "(?i)(amc|regal|cinemark|theater|cinema)"
            $0.confidence = 0.9
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.entertainment,
            ruleName: "Gaming Services",
            priority: 90
        ).with {
            $0.regexPattern = "(?i)(xbox|playstation|steam|nintendo|gaming)"
            $0.confidence = 0.85
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.entertainment,
            ruleName: "Streaming Services",
            priority: 95
        ).with {
            $0.regexPattern = "(?i)(hulu|disney|prime video|apple tv|hbo)"
            $0.confidence = 0.9
        })
        
        // MARK: - Healthcare Rules
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.healthcare,
            ruleName: "CVS Pharmacy",
            priority: 100
        ).with {
            $0.merchantContains = "CVS"
            $0.confidence = 0.9
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.healthcare,
            ruleName: "Walgreens",
            priority: 100
        ).with {
            $0.merchantContains = "WALGREENS"
            $0.confidence = 0.95
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.healthcare,
            ruleName: "Pharmacies",
            priority: 95
        ).with {
            $0.regexPattern = "(?i)(pharmacy|rite aid|duane reade)"
            $0.confidence = 0.9
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.healthcare,
            ruleName: "Medical Services",
            priority: 90
        ).with {
            $0.regexPattern = "(?i)(medical|doctor|dr\\.|hospital|clinic|urgent care)"
            $0.confidence = 0.85
        })
        
        return rules
    }
}

// MARK: - Helper Extension for Rule Building

extension CategoryRule {
    /// Helper method for fluent rule configuration
    func with(_ configure: (inout CategoryRule) -> Void) -> CategoryRule {
        var rule = self
        configure(&rule)
        return rule
    }
}