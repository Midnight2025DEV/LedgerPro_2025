import Foundation

extension CategoryRule {
    static let systemRules: [CategoryRule] = {
        var rules: [CategoryRule] = []
        
        // MARK: - Transportation Rules
        var uberRule = CategoryRule(categoryId: Category.systemCategoryIds.transportation, ruleName: "Uber Rides")
        uberRule.merchantContains = "UBER"
        uberRule.confidence = 0.9
        uberRule.priority = 100
        uberRule.isSystem = true
        uberRule.amountSign = .negative
        rules.append(uberRule)
        
        var lyftRule = CategoryRule(categoryId: Category.systemCategoryIds.transportation, ruleName: "Lyft Rides")
        lyftRule.merchantContains = "LYFT"
        lyftRule.confidence = 0.9
        lyftRule.priority = 100
        lyftRule.isSystem = true
        lyftRule.amountSign = .negative
        rules.append(lyftRule)
        
        var taxiRule = CategoryRule(categoryId: Category.systemCategoryIds.transportation, ruleName: "Taxi Services")
        taxiRule.regexPattern = "TAXI|CAB|YELLOW CAB"
        taxiRule.confidence = 0.8
        taxiRule.priority = 90
        taxiRule.isSystem = true
        taxiRule.amountSign = .negative
        rules.append(taxiRule)
        
        var gasRule = CategoryRule(categoryId: Category.systemCategoryIds.transportation, ruleName: "Gas Stations")
        gasRule.regexPattern = "SHELL|CHEVRON|EXXON|BP|CITGO|SUNOCO|TEXACO|76.*GAS|GAS STATION"
        gasRule.confidence = 0.85
        gasRule.priority = 95
        gasRule.isSystem = true
        gasRule.amountSign = .negative
        rules.append(gasRule)
        
        // NEW: Parking rule
        var parkingRule = CategoryRule(categoryId: Category.systemCategoryIds.transportation, ruleName: "Parking")
        parkingRule.regexPattern = "PARKING|PARK\\s*METER|METER\\s*PARKING|PARK\\s*&|PARKADE|PARKWHIZ"
        parkingRule.confidence = 0.85
        parkingRule.priority = 90
        parkingRule.isSystem = true
        parkingRule.amountSign = .negative
        rules.append(parkingRule)
        
        // MARK: - Food & Dining Rules
        var starbucksRule = CategoryRule(categoryId: Category.systemCategoryIds.foodDining, ruleName: "Starbucks")
        starbucksRule.merchantContains = "STARBUCKS"
        starbucksRule.confidence = 0.95
        starbucksRule.priority = 90
        starbucksRule.isSystem = true
        starbucksRule.amountSign = .negative
        rules.append(starbucksRule)
        
        var mcdonaldsRule = CategoryRule(categoryId: Category.systemCategoryIds.foodDining, ruleName: "McDonald's")
        mcdonaldsRule.merchantContains = "MCDONALD"
        mcdonaldsRule.confidence = 0.9
        mcdonaldsRule.priority = 85
        mcdonaldsRule.isSystem = true
        mcdonaldsRule.amountSign = .negative
        rules.append(mcdonaldsRule)
        
        // NEW: Coffee shops (Rifle Coffee)
        var coffeeRule = CategoryRule(categoryId: Category.systemCategoryIds.foodDining, ruleName: "Coffee Shops")
        coffeeRule.regexPattern = "COFFEE|CAFE|ESPRESSO|ROASTERY|BARISTA"
        coffeeRule.confidence = 0.85
        coffeeRule.priority = 80
        coffeeRule.isSystem = true
        coffeeRule.amountSign = .negative
        rules.append(coffeeRule)
        
        // NEW: Mexican food stores
        var mexicanFoodRule = CategoryRule(categoryId: Category.systemCategoryIds.foodDining, ruleName: "Mexican Food Stores")
        mexicanFoodRule.regexPattern = "CARNICERIA|FRUTERIA|PANADERIA|TAQUERIA|TORTILLERIA"
        mexicanFoodRule.confidence = 0.85
        mexicanFoodRule.priority = 80
        mexicanFoodRule.isSystem = true
        mexicanFoodRule.amountSign = .negative
        rules.append(mexicanFoodRule)
        
        // MARK: - Shopping Rules
        var amazonRule = CategoryRule(categoryId: Category.systemCategoryIds.shopping, ruleName: "Amazon")
        amazonRule.merchantContains = "AMAZON"
        amazonRule.confidence = 0.9
        amazonRule.priority = 85
        amazonRule.isSystem = true
        amazonRule.amountSign = .negative
        rules.append(amazonRule)
        
        var walmartRule = CategoryRule(categoryId: Category.systemCategoryIds.shopping, ruleName: "Walmart")
        walmartRule.merchantContains = "WALMART"
        walmartRule.confidence = 0.9
        walmartRule.priority = 85
        walmartRule.isSystem = true
        walmartRule.amountSign = .negative
        rules.append(walmartRule)
        
        // NEW: Convenience stores (OXXO)
        var convenienceRule = CategoryRule(categoryId: Category.systemCategoryIds.shopping, ruleName: "Convenience Stores")
        convenienceRule.regexPattern = "OXXO|7-ELEVEN|CIRCLE K|WAWA|CONVENIENCE|CVS(?!\\s*PHARMACY)"
        convenienceRule.confidence = 0.85
        convenienceRule.priority = 80
        convenienceRule.isSystem = true
        convenienceRule.amountSign = .negative
        rules.append(convenienceRule)
        
        var targetRule = CategoryRule(categoryId: Category.systemCategoryIds.shopping, ruleName: "Target")
        targetRule.merchantContains = "TARGET"
        targetRule.confidence = 0.9
        targetRule.priority = 85
        targetRule.isSystem = true
        targetRule.amountSign = .negative
        rules.append(targetRule)
        
        // MARK: - Entertainment Rules (NEW CATEGORY)
        // Assuming entertainment category exists, otherwise use a different category
        let entertainmentId = UUID(uuidString: "00000000-0000-0000-0000-000000000032") ?? Category.systemCategoryIds.other
        
        // NEW: Streaming services
        var netflixRule = CategoryRule(categoryId: entertainmentId, ruleName: "Netflix")
        netflixRule.merchantContains = "NETFLIX"
        netflixRule.confidence = 0.95
        netflixRule.priority = 90
        netflixRule.isSystem = true
        netflixRule.amountSign = .negative
        rules.append(netflixRule)
        
        var crunchyrollRule = CategoryRule(categoryId: entertainmentId, ruleName: "Crunchyroll")
        crunchyrollRule.merchantContains = "CRUNCHYROLL"
        crunchyrollRule.confidence = 0.95
        crunchyrollRule.priority = 90
        crunchyrollRule.isSystem = true
        crunchyrollRule.amountSign = .negative
        rules.append(crunchyrollRule)
        
        var youtubeRule = CategoryRule(categoryId: entertainmentId, ruleName: "YouTube")
        youtubeRule.merchantContains = "YOUTUBE"
        youtubeRule.confidence = 0.95
        youtubeRule.priority = 90
        youtubeRule.isSystem = true
        youtubeRule.amountSign = .negative
        rules.append(youtubeRule)
        
        var spotifyRule = CategoryRule(categoryId: entertainmentId, ruleName: "Spotify")
        spotifyRule.merchantContains = "SPOTIFY"
        spotifyRule.confidence = 0.95
        spotifyRule.priority = 90
        spotifyRule.isSystem = true
        spotifyRule.amountSign = .negative
        rules.append(spotifyRule)
        
        // MARK: - Technology/AI Services (Education or Other category)
        let educationId = UUID(uuidString: "00000000-0000-0000-0000-000000000034") ?? Category.systemCategoryIds.other
        
        // NEW: AI Services
        var claudeRule = CategoryRule(categoryId: educationId, ruleName: "Claude AI")
        claudeRule.regexPattern = "CLAUDE|ANTHROPIC"
        claudeRule.confidence = 0.95
        claudeRule.priority = 90
        claudeRule.isSystem = true
        claudeRule.amountSign = .negative
        rules.append(claudeRule)
        
        var openaiRule = CategoryRule(categoryId: educationId, ruleName: "OpenAI")
        openaiRule.regexPattern = "OPENAI|CHATGPT|GPT"
        openaiRule.confidence = 0.95
        openaiRule.priority = 90
        openaiRule.isSystem = true
        openaiRule.amountSign = .negative
        rules.append(openaiRule)
        
        // NEW: Online Education
        var courseraRule = CategoryRule(categoryId: educationId, ruleName: "Coursera")
        courseraRule.merchantContains = "COURSERA"
        courseraRule.confidence = 0.95
        courseraRule.priority = 90
        courseraRule.isSystem = true
        courseraRule.amountSign = .negative
        rules.append(courseraRule)
        
        // MARK: - Travel/Lodging Rules
        let travelId = UUID(uuidString: "00000000-0000-0000-0000-000000000033") ?? Category.systemCategoryIds.other
        
        // NEW: Hotels
        var hotelRule = CategoryRule(categoryId: travelId, ruleName: "Hotels")
        hotelRule.regexPattern = "HOTEL|MOTEL|INN|MARRIOTT|HILTON|HYATT|SHERATON|HOLIDAY\\s*INN"
        hotelRule.confidence = 0.9
        hotelRule.priority = 85
        hotelRule.isSystem = true
        hotelRule.amountSign = .negative
        rules.append(hotelRule)
        
        // MARK: - Income Rules
        var salaryRule = CategoryRule(categoryId: Category.systemCategoryIds.salary, ruleName: "Salary Deposits")
        salaryRule.descriptionContains = "PAYROLL"
        salaryRule.confidence = 0.95
        salaryRule.priority = 100
        salaryRule.isSystem = true
        salaryRule.amountSign = .positive
        rules.append(salaryRule)
        
        var incomeRule = CategoryRule(categoryId: Category.systemCategoryIds.income, ruleName: "General Income")
        incomeRule.descriptionContains = "DEPOSIT"
        incomeRule.confidence = 0.8
        incomeRule.priority = 90
        incomeRule.isSystem = true
        incomeRule.amountSign = .positive
        rules.append(incomeRule)
        
        // MARK: - Transfer Rules
        // NEW: Bank transfers
        var transferRule = CategoryRule(categoryId: Category.systemCategoryIds.other, ruleName: "Bank Transfers")
        transferRule.regexPattern = "TRANSFER|MOBILE\\s*TRANSFER|BANK\\s*TRANSFER|ACH|WIRE"
        transferRule.confidence = 0.85
        transferRule.priority = 85
        transferRule.isSystem = true
        transferRule.amountSign = .negative
        rules.append(transferRule)
        
        // NEW: Payment services
        var paypalRule = CategoryRule(categoryId: Category.systemCategoryIds.other, ruleName: "PayPal")
        paypalRule.merchantContains = "PAYPAL"
        paypalRule.confidence = 0.9
        paypalRule.priority = 85
        paypalRule.isSystem = true
        paypalRule.amountSign = .negative
        rules.append(paypalRule)
        
        // MARK: - Credit Card Payment Rules
        var genericCreditCardRule = CategoryRule(categoryId: Category.systemCategoryIds.creditCardPayment, ruleName: "Credit Card Payments")
        genericCreditCardRule.regexPattern = "CREDIT\\s*CARD\\s*PAYMENT|AUTOPAY|CC\\s*PAYMENT"
        genericCreditCardRule.confidence = 0.9
        genericCreditCardRule.priority = 90
        genericCreditCardRule.isSystem = true
        genericCreditCardRule.amountSign = .positive
        rules.append(genericCreditCardRule)
        
        var creditCardRule = CategoryRule(categoryId: Category.systemCategoryIds.creditCardPayment, ruleName: "Capital One Payments")
        creditCardRule.merchantContains = "CAPITAL ONE"
        creditCardRule.descriptionContains = "PAYMENT"
        creditCardRule.confidence = 0.95
        creditCardRule.priority = 95
        creditCardRule.isSystem = true
        creditCardRule.amountSign = .positive
        rules.append(creditCardRule)
        
        return rules
    }()
}

// MARK: - Helper Extension for Testing
extension CategoryRule {
    /// Find all rules that match a given transaction description
    static func findMatchingRules(for description: String, in rules: [CategoryRule] = systemRules) -> [CategoryRule] {
        let mockTransaction = Transaction(
            date: Date().ISO8601Format(),
            description: description,
            amount: -50.0,
            category: "Uncategorized"
        )
        
        return rules.filter { $0.matches(transaction: mockTransaction) }
    }
}
