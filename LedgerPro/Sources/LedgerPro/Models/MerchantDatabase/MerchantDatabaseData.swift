import Foundation

/// Static merchant database with comprehensive merchant definitions
struct MerchantDatabaseData {
    
    static let allMerchants: [String: Merchant] = {
        var merchants: [String: Merchant] = [:]
        
        // Add all merchant categories
        merchants.merge(foodAndDining) { _, new in new }
        merchants.merge(shopping) { _, new in new }
        merchants.merge(transportation) { _, new in new }
        merchants.merge(entertainment) { _, new in new }
        merchants.merge(utilities) { _, new in new }
        merchants.merge(financial) { _, new in new }
        merchants.merge(healthcare) { _, new in new }
        merchants.merge(grocery) { _, new in new }
        merchants.merge(subscriptions) { _, new in new }
        merchants.merge(travel) { _, new in new }
        
        return merchants
    }()
    
    // MARK: - Food & Dining
    
    private static let foodAndDining: [String: Merchant] = [
        "mcdonalds": Merchant(
            id: "mcdonalds",
            canonicalName: "McDonald's",
            category: Category.systemCategory(id: Category.systemCategoryIds.foodDining)!,
            subcategory: "Fast Food",
            aliases: ["MCD", "MCDONALD", "MC DONALDS", "MCDONALDS"],
            patterns: ["(?i)mc\\s?donald['']?s?", "(?i)mcd\\s+\\d+"],
            isSubscription: false,
            merchantType: .restaurant,
            commonAmounts: [4.99, 7.99, 9.99, 12.99],
            metadata: MerchantMetadata(
                website: "mcdonalds.com",
                logo: "mcdonalds_logo",
                color: "#FFC72C",
                countryOrigin: "US",
                tags: ["fast-food", "breakfast", "drive-thru"]
            )
        ),
        
        "starbucks": Merchant(
            id: "starbucks",
            canonicalName: "Starbucks",
            category: Category.systemCategory(id: Category.systemCategoryIds.foodDining)!,
            subcategory: "Coffee",
            aliases: ["SBUX", "STARBUCK", "STAR BUCKS"],
            patterns: ["(?i)starbucks?", "(?i)sbux"],
            isSubscription: false,
            merchantType: .restaurant,
            commonAmounts: [3.99, 4.99, 5.99, 6.99],
            metadata: MerchantMetadata(
                website: "starbucks.com",
                logo: "starbucks_logo",
                color: "#00704A",
                countryOrigin: "US",
                tags: ["coffee", "breakfast", "cafe"]
            )
        ),
        
        "chipotle": Merchant(
            id: "chipotle",
            canonicalName: "Chipotle",
            category: Category.systemCategory(id: Category.systemCategoryIds.foodDining)!,
            subcategory: "Fast Casual",
            aliases: ["CHIPOTLE MEXICAN GRILL", "CMG"],
            patterns: ["(?i)chipotle"],
            isSubscription: false,
            merchantType: .restaurant,
            commonAmounts: [8.99, 10.99, 12.99],
            metadata: MerchantMetadata(
                website: "chipotle.com",
                logo: "chipotle_logo",
                color: "#A81612",
                countryOrigin: "US",
                tags: ["mexican", "fast-casual", "burrito"]
            )
        ),
        
        // === MAJOR FAST FOOD CHAINS ===
        
        "subway": Merchant(
            id: "subway",
            canonicalName: "Subway",
            category: Category.systemCategory(id: Category.systemCategoryIds.foodDining)!,
            subcategory: "Fast Food",
            aliases: ["SUBWAY SANDWICHES", "SUBWAY REST"],
            patterns: ["(?i)subway(?:\\s+(?:sandwiches?|rest))?"],
            isSubscription: false,
            merchantType: .restaurant,
            commonAmounts: [6.99, 8.99, 10.99],
            metadata: MerchantMetadata(
                website: "subway.com",
                logo: "subway_logo",
                color: "#00543C",
                countryOrigin: "US",
                tags: ["fast-food", "sandwiches", "subs"]
            )
        ),
        
        "burgerking": Merchant(
            id: "burgerking",
            canonicalName: "Burger King",
            category: Category.systemCategory(id: Category.systemCategoryIds.foodDining)!,
            subcategory: "Fast Food",
            aliases: ["BK", "BURGER KING CORP", "BKC"],
            patterns: ["(?i)burger\\s*king", "(?i)\\bbk\\b(?:\\s|$)"],
            isSubscription: false,
            merchantType: .restaurant,
            commonAmounts: [5.99, 7.99, 9.99],
            metadata: MerchantMetadata(
                website: "bk.com",
                logo: "bk_logo",
                color: "#EC1C24",
                countryOrigin: "US",
                tags: ["fast-food", "burgers", "flame-grilled"]
            )
        ),
        
        "wendys": Merchant(
            id: "wendys",
            canonicalName: "Wendy's",
            category: Category.systemCategory(id: Category.systemCategoryIds.foodDining)!,
            subcategory: "Fast Food",
            aliases: ["WENDY", "WENDYS OLD FASHIONED"],
            patterns: ["(?i)wendy'?s?(?:\\s+old\\s+fashioned)?"],
            isSubscription: false,
            merchantType: .restaurant,
            commonAmounts: [6.99, 8.99, 10.99],
            metadata: MerchantMetadata(
                website: "wendys.com",
                logo: "wendys_logo",
                color: "#E31837",
                countryOrigin: "US",
                tags: ["fast-food", "burgers", "fresh"]
            )
        ),
        
        "kfc": Merchant(
            id: "kfc",
            canonicalName: "KFC",
            category: Category.systemCategory(id: Category.systemCategoryIds.foodDining)!,
            subcategory: "Fast Food",
            aliases: ["KENTUCKY FRIED CHICKEN", "YUM"],
            patterns: ["(?i)kfc", "(?i)kentucky\\s+fried\\s+chicken"],
            isSubscription: false,
            merchantType: .restaurant,
            commonAmounts: [7.99, 9.99, 12.99],
            metadata: MerchantMetadata(
                website: "kfc.com",
                logo: "kfc_logo",
                color: "#F40027",
                countryOrigin: "US",
                tags: ["fast-food", "chicken", "fried"]
            )
        ),
        
        "tacobell": Merchant(
            id: "tacobell",
            canonicalName: "Taco Bell",
            category: Category.systemCategory(id: Category.systemCategoryIds.foodDining)!,
            subcategory: "Fast Food",
            aliases: ["TACO BELL CORP", "TB"],
            patterns: ["(?i)taco\\s*bell"],
            isSubscription: false,
            merchantType: .restaurant,
            commonAmounts: [4.99, 6.99, 8.99],
            metadata: MerchantMetadata(
                website: "tacobell.com",
                logo: "tacobell_logo",
                color: "#702F8A",
                countryOrigin: "US",
                tags: ["fast-food", "mexican", "tacos"]
            )
        ),
        
        "chickfila": Merchant(
            id: "chickfila",
            canonicalName: "Chick-fil-A",
            category: Category.systemCategory(id: Category.systemCategoryIds.foodDining)!,
            subcategory: "Fast Food",
            aliases: ["CHICK FIL A", "CFA", "CHICKFILA"],
            patterns: ["(?i)chick\\s*fil\\s*a", "(?i)cfa\\s"],
            isSubscription: false,
            merchantType: .restaurant,
            commonAmounts: [7.99, 9.99, 11.99],
            metadata: MerchantMetadata(
                website: "chick-fil-a.com",
                logo: "cfa_logo",
                color: "#E31837",
                countryOrigin: "US",
                tags: ["fast-food", "chicken", "christian"]
            )
        ),
        
        "panera": Merchant(
            id: "panera",
            canonicalName: "Panera Bread",
            category: Category.systemCategory(id: Category.systemCategoryIds.foodDining)!,
            subcategory: "Fast Casual",
            aliases: ["PANERA BREAD", "PANERA LLC"],
            patterns: ["(?i)panera(?:\\s+bread)?"],
            isSubscription: false,
            merchantType: .restaurant,
            commonAmounts: [8.99, 10.99, 12.99],
            metadata: MerchantMetadata(
                website: "panera.com",
                logo: "panera_logo",
                color: "#5C7A37",
                countryOrigin: "US",
                tags: ["fast-casual", "bread", "cafe"]
            )
        ),
        
        "dunkindonuts": Merchant(
            id: "dunkindonuts",
            canonicalName: "Dunkin'",
            category: Category.systemCategory(id: Category.systemCategoryIds.foodDining)!,
            subcategory: "Coffee",
            aliases: ["DUNKIN DONUTS", "DD", "DUNKIN"],
            patterns: ["(?i)dunkin(?:'?\\s*donuts?)?", "(?i)\\bdd\\b(?:\\s|$)"],
            isSubscription: false,
            merchantType: .restaurant,
            commonAmounts: [2.99, 4.99, 6.99],
            metadata: MerchantMetadata(
                website: "dunkindonuts.com",
                logo: "dunkin_logo",
                color: "#FF6600",
                countryOrigin: "US",
                tags: ["coffee", "donuts", "breakfast"]
            )
        ),
        
        "timhortons": Merchant(
            id: "timhortons",
            canonicalName: "Tim Hortons",
            category: Category.systemCategory(id: Category.systemCategoryIds.foodDining)!,
            subcategory: "Coffee",
            aliases: ["TIM HORTON", "TIMS"],
            patterns: ["(?i)tim\\s*hortons?", "(?i)tims\\b"],
            isSubscription: false,
            merchantType: .restaurant,
            commonAmounts: [2.99, 4.99, 6.99],
            metadata: MerchantMetadata(
                website: "timhortons.com",
                logo: "timhortons_logo",
                color: "#C8102E",
                countryOrigin: "CA",
                tags: ["coffee", "donuts", "canadian"]
            )
        ),
        
        // === PIZZA CHAINS ===
        
        "dominos": Merchant(
            id: "dominos",
            canonicalName: "Domino's Pizza",
            category: Category.systemCategory(id: Category.systemCategoryIds.foodDining)!,
            subcategory: "Pizza",
            aliases: ["DOMINOS PIZZA", "DPZ"],
            patterns: ["(?i)domino'?s?(?:\\s+pizza)?"],
            isSubscription: false,
            merchantType: .restaurant,
            commonAmounts: [12.99, 16.99, 22.99],
            metadata: MerchantMetadata(
                website: "dominos.com",
                logo: "dominos_logo",
                color: "#0078AE",
                countryOrigin: "US",
                tags: ["pizza", "delivery", "fast-food"]
            )
        ),
        
        "pizzahut": Merchant(
            id: "pizzahut",
            canonicalName: "Pizza Hut",
            category: Category.systemCategory(id: Category.systemCategoryIds.foodDining)!,
            subcategory: "Pizza",
            aliases: ["PIZZA HUT INC", "PHI"],
            patterns: ["(?i)pizza\\s*hut"],
            isSubscription: false,
            merchantType: .restaurant,
            commonAmounts: [14.99, 18.99, 24.99],
            metadata: MerchantMetadata(
                website: "pizzahut.com",
                logo: "pizzahut_logo",
                color: "#00A650",
                countryOrigin: "US",
                tags: ["pizza", "delivery", "dine-in"]
            )
        ),
        
        "papajohns": Merchant(
            id: "papajohns",
            canonicalName: "Papa John's",
            category: Category.systemCategory(id: Category.systemCategoryIds.foodDining)!,
            subcategory: "Pizza",
            aliases: ["PAPA JOHNS PIZZA", "PZZA"],
            patterns: ["(?i)papa\\s*john'?s?"],
            isSubscription: false,
            merchantType: .restaurant,
            commonAmounts: [13.99, 17.99, 23.99],
            metadata: MerchantMetadata(
                website: "papajohns.com",
                logo: "papajohns_logo",
                color: "#C41E3A",
                countryOrigin: "US",
                tags: ["pizza", "delivery", "better-ingredients"]
            )
        ),
        
        // === CASUAL DINING ===
        
        "applebees": Merchant(
            id: "applebees",
            canonicalName: "Applebee's",
            category: Category.systemCategory(id: Category.systemCategoryIds.foodDining)!,
            subcategory: "Casual Dining",
            aliases: ["APPLEBEES INTL", "APPLEBEE"],
            patterns: ["(?i)applebee'?s?"],
            isSubscription: false,
            merchantType: .restaurant,
            commonAmounts: [15.99, 19.99, 24.99],
            metadata: MerchantMetadata(
                website: "applebees.com",
                logo: "applebees_logo",
                color: "#C41E3A",
                countryOrigin: "US",
                tags: ["casual-dining", "sports-bar", "family"]
            )
        ),
        
        "olivegarden": Merchant(
            id: "olivegarden",
            canonicalName: "Olive Garden",
            category: Category.systemCategory(id: Category.systemCategoryIds.foodDining)!,
            subcategory: "Casual Dining",
            aliases: ["OLIVE GARDEN ITALIAN"],
            patterns: ["(?i)olive\\s*garden"],
            isSubscription: false,
            merchantType: .restaurant,
            commonAmounts: [18.99, 22.99, 28.99],
            metadata: MerchantMetadata(
                website: "olivegarden.com",
                logo: "olivegarden_logo",
                color: "#8B4513",
                countryOrigin: "US",
                tags: ["casual-dining", "italian", "unlimited-breadsticks"]
            )
        ),
        
        "chillis": Merchant(
            id: "chillis",
            canonicalName: "Chili's",
            category: Category.systemCategory(id: Category.systemCategoryIds.foodDining)!,
            subcategory: "Casual Dining",
            aliases: ["CHILIS GRILL", "CHILI"],
            patterns: ["(?i)chili'?s?"],
            isSubscription: false,
            merchantType: .restaurant,
            commonAmounts: [16.99, 20.99, 25.99],
            metadata: MerchantMetadata(
                website: "chilis.com",
                logo: "chilis_logo",
                color: "#C41E3A",
                countryOrigin: "US",
                tags: ["casual-dining", "tex-mex", "family"]
            )
        )
    ]
    
    // MARK: - Shopping
    
    private static let shopping: [String: Merchant] = [
        "amazon": Merchant(
            id: "amazon",
            canonicalName: "Amazon",
            category: Category.systemCategory(id: Category.systemCategoryIds.shopping)!,
            subcategory: "Online Retail",
            aliases: ["AMZN", "AMAZON.COM", "AMZ", "AMAZON MKTP", "AMAZON MARKETPLACE"],
            patterns: ["(?i)amazon\\s*(?:mktp|marketplace)?", "(?i)amzn"],
            isSubscription: false,
            merchantType: .retail,
            commonAmounts: nil, // Highly variable
            metadata: MerchantMetadata(
                website: "amazon.com",
                logo: "amazon_logo",
                color: "#FF9900",
                countryOrigin: "US",
                tags: ["online", "marketplace", "prime"]
            )
        ),
        
        "walmart": Merchant(
            id: "walmart",
            canonicalName: "Walmart",
            category: Category.systemCategory(id: Category.systemCategoryIds.shopping)!,
            subcategory: "Department Store",
            aliases: ["WAL-MART", "WMT", "WALMART SUPERCENTER"],
            patterns: ["(?i)wal-?mart", "(?i)wmt\\s"],
            isSubscription: false,
            merchantType: .retail,
            commonAmounts: nil,
            metadata: MerchantMetadata(
                website: "walmart.com",
                logo: "walmart_logo",
                color: "#004C91",
                countryOrigin: "US",
                tags: ["department-store", "grocery", "supercenter"]
            )
        ),
        
        "target": Merchant(
            id: "target",
            canonicalName: "Target",
            category: Category.systemCategory(id: Category.systemCategoryIds.shopping)!,
            subcategory: "Department Store",
            aliases: ["TGT", "TARGET CORP"],
            patterns: ["(?i)target(?:\\s+corp)?", "(?i)tgt\\s"],
            isSubscription: false,
            merchantType: .retail,
            commonAmounts: nil,
            metadata: MerchantMetadata(
                website: "target.com",
                logo: "target_logo",
                color: "#CC0000",
                countryOrigin: "US",
                tags: ["department-store", "clothing", "home"]
            )
        ),
        
        // === MAJOR RETAILERS ===
        
        "costco": Merchant(
            id: "costco",
            canonicalName: "Costco",
            category: Category.systemCategory(id: Category.systemCategoryIds.shopping)!,
            subcategory: "Warehouse Club",
            aliases: ["COSTCO WHOLESALE", "COST"],
            patterns: ["(?i)costco(?:\\s+wholesale)?"],
            isSubscription: false,
            merchantType: .retail,
            commonAmounts: [50.00, 100.00, 150.00, 200.00],
            metadata: MerchantMetadata(
                website: "costco.com",
                logo: "costco_logo",
                color: "#E31837",
                countryOrigin: "US",
                tags: ["warehouse", "bulk", "membership"]
            )
        ),
        
        "homedepot": Merchant(
            id: "homedepot",
            canonicalName: "The Home Depot",
            category: Category.systemCategory(id: Category.systemCategoryIds.shopping)!,
            subcategory: "Home Improvement",
            aliases: ["HOME DEPOT", "HD", "THD"],
            patterns: ["(?i)(?:the\\s+)?home\\s*depot"],
            isSubscription: false,
            merchantType: .retail,
            commonAmounts: [25.00, 50.00, 100.00, 200.00],
            metadata: MerchantMetadata(
                website: "homedepot.com",
                logo: "homedepot_logo",
                color: "#F96302",
                countryOrigin: "US",
                tags: ["home-improvement", "tools", "diy"]
            )
        ),
        
        "lowes": Merchant(
            id: "lowes",
            canonicalName: "Lowe's",
            category: Category.systemCategory(id: Category.systemCategoryIds.shopping)!,
            subcategory: "Home Improvement",
            aliases: ["LOWES HOME", "LOW"],
            patterns: ["(?i)lowe'?s?(?:\\s+home)?"],
            isSubscription: false,
            merchantType: .retail,
            commonAmounts: [25.00, 50.00, 100.00, 200.00],
            metadata: MerchantMetadata(
                website: "lowes.com",
                logo: "lowes_logo",
                color: "#004990",
                countryOrigin: "US",
                tags: ["home-improvement", "tools", "garden"]
            )
        ),
        
        "bestbuy": Merchant(
            id: "bestbuy",
            canonicalName: "Best Buy",
            category: Category.systemCategory(id: Category.systemCategoryIds.shopping)!,
            subcategory: "Electronics",
            aliases: ["BEST BUY CO", "BBY"],
            patterns: ["(?i)best\\s*buy"],
            isSubscription: false,
            merchantType: .retail,
            commonAmounts: [50.00, 100.00, 200.00, 500.00],
            metadata: MerchantMetadata(
                website: "bestbuy.com",
                logo: "bestbuy_logo",
                color: "#0046BE",
                countryOrigin: "US",
                tags: ["electronics", "computers", "appliances"]
            )
        ),
        
        "macys": Merchant(
            id: "macys",
            canonicalName: "Macy's",
            category: Category.systemCategory(id: Category.systemCategoryIds.shopping)!,
            subcategory: "Department Store",
            aliases: ["MACYS INC", "M"],
            patterns: ["(?i)macy'?s?"],
            isSubscription: false,
            merchantType: .retail,
            commonAmounts: [40.00, 80.00, 120.00],
            metadata: MerchantMetadata(
                website: "macys.com",
                logo: "macys_logo",
                color: "#E21837",
                countryOrigin: "US",
                tags: ["department-store", "fashion", "cosmetics"]
            )
        ),
        
        "kohls": Merchant(
            id: "kohls",
            canonicalName: "Kohl's",
            category: Category.systemCategory(id: Category.systemCategoryIds.shopping)!,
            subcategory: "Department Store",
            aliases: ["KOHLS CORP", "KSS"],
            patterns: ["(?i)kohl'?s?"],
            isSubscription: false,
            merchantType: .retail,
            commonAmounts: [30.00, 60.00, 90.00],
            metadata: MerchantMetadata(
                website: "kohls.com",
                logo: "kohls_logo",
                color: "#7B2D8E",
                countryOrigin: "US",
                tags: ["department-store", "clothing", "home"]
            )
        ),
        
        "jcpenney": Merchant(
            id: "jcpenney",
            canonicalName: "JCPenney",
            category: Category.systemCategory(id: Category.systemCategoryIds.shopping)!,
            subcategory: "Department Store",
            aliases: ["JCP", "J C PENNEY"],
            patterns: ["(?i)j\\s*c\\s*penney"],
            isSubscription: false,
            merchantType: .retail,
            commonAmounts: [25.00, 50.00, 75.00],
            metadata: MerchantMetadata(
                website: "jcpenney.com",
                logo: "jcpenney_logo",
                color: "#005EB8",
                countryOrigin: "US",
                tags: ["department-store", "clothing", "home"]
            )
        ),
        
        "nordstrom": Merchant(
            id: "nordstrom",
            canonicalName: "Nordstrom",
            category: Category.systemCategory(id: Category.systemCategoryIds.shopping)!,
            subcategory: "Department Store",
            aliases: ["NRDS", "NORDSTROM INC"],
            patterns: ["(?i)nordstrom"],
            isSubscription: false,
            merchantType: .retail,
            commonAmounts: [80.00, 150.00, 250.00],
            metadata: MerchantMetadata(
                website: "nordstrom.com",
                logo: "nordstrom_logo",
                color: "#000000",
                countryOrigin: "US",
                tags: ["luxury", "fashion", "designer"]
            )
        ),
        
        "tj_maxx": Merchant(
            id: "tj_maxx",
            canonicalName: "T.J. Maxx",
            category: Category.systemCategory(id: Category.systemCategoryIds.shopping)!,
            subcategory: "Discount Retail",
            aliases: ["TJMAXX", "TJX", "TJ MAXX"],
            patterns: ["(?i)t\\.?j\\.?\\s*maxx"],
            isSubscription: false,
            merchantType: .retail,
            commonAmounts: [20.00, 40.00, 60.00],
            metadata: MerchantMetadata(
                website: "tjmaxx.tjx.com",
                logo: "tjmaxx_logo",
                color: "#E31837",
                countryOrigin: "US",
                tags: ["discount", "fashion", "home"]
            )
        ),
        
        "marshalls": Merchant(
            id: "marshalls",
            canonicalName: "Marshalls",
            category: Category.systemCategory(id: Category.systemCategoryIds.shopping)!,
            subcategory: "Discount Retail",
            aliases: ["MARSHALL"],
            patterns: ["(?i)marshalls?"],
            isSubscription: false,
            merchantType: .retail,
            commonAmounts: [20.00, 40.00, 60.00],
            metadata: MerchantMetadata(
                website: "marshalls.com",
                logo: "marshalls_logo",
                color: "#E31837",
                countryOrigin: "US",
                tags: ["discount", "fashion", "home"]
            )
        ),
        
        "bed_bath_beyond": Merchant(
            id: "bed_bath_beyond",
            canonicalName: "Bed Bath & Beyond",
            category: Category.systemCategory(id: Category.systemCategoryIds.shopping)!,
            subcategory: "Home Goods",
            aliases: ["BBB", "BBBY"],
            patterns: ["(?i)bed\\s*bath\\s*(?:&|and)\\s*beyond"],
            isSubscription: false,
            merchantType: .retail,
            commonAmounts: [30.00, 60.00, 100.00],
            metadata: MerchantMetadata(
                website: "bedbathandbeyond.com",
                logo: "bbb_logo",
                color: "#0066CC",
                countryOrigin: "US",
                tags: ["home", "bedding", "kitchen"]
            )
        )
    ]
    
    // MARK: - Transportation
    
    private static let transportation: [String: Merchant] = [
        "uber": Merchant(
            id: "uber",
            canonicalName: "Uber",
            category: Category.systemCategory(id: Category.systemCategoryIds.transportation)!,
            subcategory: "Rideshare",
            aliases: ["UBER TRIP", "UBER RIDE", "UBER TECHNOLOGIES"],
            patterns: ["(?i)uber(?:\\s+(?:trip|ride|technologies))?"],
            isSubscription: false,
            merchantType: .transportation,
            commonAmounts: [8.99, 12.99, 15.99, 18.99],
            metadata: MerchantMetadata(
                website: "uber.com",
                logo: "uber_logo",
                color: "#000000",
                countryOrigin: "US",
                tags: ["rideshare", "taxi", "transportation"]
            )
        ),
        
        "lyft": Merchant(
            id: "lyft",
            canonicalName: "Lyft",
            category: Category.systemCategory(id: Category.systemCategoryIds.transportation)!,
            subcategory: "Rideshare",
            aliases: ["LYFT INC"],
            patterns: ["(?i)lyft(?:\\s+inc)?"],
            isSubscription: false,
            merchantType: .transportation,
            commonAmounts: [8.99, 12.99, 15.99, 18.99],
            metadata: MerchantMetadata(
                website: "lyft.com",
                logo: "lyft_logo",
                color: "#FF00BF",
                countryOrigin: "US",
                tags: ["rideshare", "taxi", "transportation"]
            )
        ),
        
        "shell": Merchant(
            id: "shell",
            canonicalName: "Shell",
            category: Category.systemCategory(id: Category.systemCategoryIds.transportation)!,
            subcategory: "Gas Station",
            aliases: ["SHELL OIL", "SHELL GAS"],
            patterns: ["(?i)shell(?:\\s+(?:oil|gas))?"],
            isSubscription: false,
            merchantType: .retail,
            commonAmounts: [25.00, 35.00, 45.00, 55.00],
            metadata: MerchantMetadata(
                website: "shell.com",
                logo: "shell_logo",
                color: "#FFCC00",
                countryOrigin: "NL",
                tags: ["gas", "fuel", "convenience"]
            )
        ),
        
        // === GAS STATIONS ===
        
        "chevron": Merchant(
            id: "chevron",
            canonicalName: "Chevron",
            category: Category.systemCategory(id: Category.systemCategoryIds.transportation)!,
            subcategory: "Gas Station",
            aliases: ["CHEVRON CORP", "CVX"],
            patterns: ["(?i)chevron"],
            isSubscription: false,
            merchantType: .retail,
            commonAmounts: [25.00, 35.00, 45.00, 55.00],
            metadata: MerchantMetadata(
                website: "chevron.com",
                logo: "chevron_logo",
                color: "#E31837",
                countryOrigin: "US",
                tags: ["gas", "fuel", "convenience"]
            )
        ),
        
        "exxonmobil": Merchant(
            id: "exxonmobil",
            canonicalName: "ExxonMobil",
            category: Category.systemCategory(id: Category.systemCategoryIds.transportation)!,
            subcategory: "Gas Station",
            aliases: ["EXXON", "MOBIL", "XOM"],
            patterns: ["(?i)exxon(?:mobil)?", "(?i)mobil(?!e)"],
            isSubscription: false,
            merchantType: .retail,
            commonAmounts: [25.00, 35.00, 45.00, 55.00],
            metadata: MerchantMetadata(
                website: "exxonmobil.com",
                logo: "exxon_logo",
                color: "#E31837",
                countryOrigin: "US",
                tags: ["gas", "fuel", "convenience"]
            )
        ),
        
        "bp": Merchant(
            id: "bp",
            canonicalName: "BP",
            category: Category.systemCategory(id: Category.systemCategoryIds.transportation)!,
            subcategory: "Gas Station",
            aliases: ["BRITISH PETROLEUM", "BP PLC"],
            patterns: ["(?i)\\bbp\\b", "(?i)british\\s+petroleum"],
            isSubscription: false,
            merchantType: .retail,
            commonAmounts: [25.00, 35.00, 45.00, 55.00],
            metadata: MerchantMetadata(
                website: "bp.com",
                logo: "bp_logo",
                color: "#00A651",
                countryOrigin: "GB",
                tags: ["gas", "fuel", "convenience"]
            )
        ),
        
        "citgo": Merchant(
            id: "citgo",
            canonicalName: "CITGO",
            category: Category.systemCategory(id: Category.systemCategoryIds.transportation)!,
            subcategory: "Gas Station",
            aliases: ["CITGO PETROLEUM"],
            patterns: ["(?i)citgo"],
            isSubscription: false,
            merchantType: .retail,
            commonAmounts: [25.00, 35.00, 45.00, 55.00],
            metadata: MerchantMetadata(
                website: "citgo.com",
                logo: "citgo_logo",
                color: "#E31837",
                countryOrigin: "US",
                tags: ["gas", "fuel", "convenience"]
            )
        ),
        
        "marathon": Merchant(
            id: "marathon",
            canonicalName: "Marathon",
            category: Category.systemCategory(id: Category.systemCategoryIds.transportation)!,
            subcategory: "Gas Station",
            aliases: ["MARATHON PETROLEUM", "MPC"],
            patterns: ["(?i)marathon(?:\\s+petroleum)?"],
            isSubscription: false,
            merchantType: .retail,
            commonAmounts: [25.00, 35.00, 45.00, 55.00],
            metadata: MerchantMetadata(
                website: "marathonpetroleum.com",
                logo: "marathon_logo",
                color: "#005EB8",
                countryOrigin: "US",
                tags: ["gas", "fuel", "convenience"]
            )
        ),
        
        "seven_eleven": Merchant(
            id: "seven_eleven",
            canonicalName: "7-Eleven",
            category: Category.systemCategory(id: Category.systemCategoryIds.transportation)!,
            subcategory: "Gas Station",
            aliases: ["7-11", "SEVEN ELEVEN", "711"],
            patterns: ["(?i)7\\s*-?\\s*eleven", "(?i)7\\s*-?\\s*11"],
            isSubscription: false,
            merchantType: .retail,
            commonAmounts: [25.00, 35.00, 45.00, 55.00],
            metadata: MerchantMetadata(
                website: "7-eleven.com",
                logo: "seven_eleven_logo",
                color: "#E31837",
                countryOrigin: "US",
                tags: ["gas", "fuel", "convenience", "store"]
            )
        ),
        
        // === RIDE SHARING & TRANSPORTATION ===
        
        "doordash": Merchant(
            id: "doordash",
            canonicalName: "DoorDash",
            category: Category.systemCategory(id: Category.systemCategoryIds.transportation)!,
            subcategory: "Food Delivery",
            aliases: ["DASH", "DOORDASH INC"],
            patterns: ["(?i)door\\s*dash"],
            isSubscription: false,
            merchantType: .transportation,
            commonAmounts: [15.99, 22.99, 28.99],
            metadata: MerchantMetadata(
                website: "doordash.com",
                logo: "doordash_logo",
                color: "#FF3008",
                countryOrigin: "US",
                tags: ["delivery", "food", "gig-economy"]
            )
        ),
        
        "grubhub": Merchant(
            id: "grubhub",
            canonicalName: "Grubhub",
            category: Category.systemCategory(id: Category.systemCategoryIds.transportation)!,
            subcategory: "Food Delivery",
            aliases: ["GRUB HUB", "GH"],
            patterns: ["(?i)grub\\s*hub"],
            isSubscription: false,
            merchantType: .transportation,
            commonAmounts: [16.99, 23.99, 29.99],
            metadata: MerchantMetadata(
                website: "grubhub.com",
                logo: "grubhub_logo",
                color: "#FF8000",
                countryOrigin: "US",
                tags: ["delivery", "food", "restaurant"]
            )
        ),
        
        "ubereats": Merchant(
            id: "ubereats",
            canonicalName: "Uber Eats",
            category: Category.systemCategory(id: Category.systemCategoryIds.transportation)!,
            subcategory: "Food Delivery",
            aliases: ["UBER EATS"],
            patterns: ["(?i)uber\\s*eats"],
            isSubscription: false,
            merchantType: .transportation,
            commonAmounts: [17.99, 24.99, 31.99],
            metadata: MerchantMetadata(
                website: "ubereats.com",
                logo: "ubereats_logo",
                color: "#06C167",
                countryOrigin: "US",
                tags: ["delivery", "food", "uber"]
            )
        )
    ]
    
    // MARK: - Entertainment
    
    private static let entertainment: [String: Merchant] = [
        "netflix": Merchant(
            id: "netflix",
            canonicalName: "Netflix",
            category: Category.systemCategory(id: Category.systemCategoryIds.entertainment)!,
            subcategory: "Streaming",
            aliases: ["NETFLIX.COM", "NFLX"],
            patterns: ["(?i)netflix(?:\\.com)?"],
            isSubscription: true,
            merchantType: .subscription,
            commonAmounts: [8.99, 13.99, 17.99],
            metadata: MerchantMetadata(
                website: "netflix.com",
                logo: "netflix_logo",
                color: "#E50914",
                countryOrigin: "US",
                tags: ["streaming", "movies", "tv"]
            )
        ),
        
        "spotify": Merchant(
            id: "spotify",
            canonicalName: "Spotify",
            category: Category.systemCategory(id: Category.systemCategoryIds.entertainment)!,
            subcategory: "Music Streaming",
            aliases: ["SPOTIFY USA", "SPOT"],
            patterns: ["(?i)spotify(?:\\s+usa)?"],
            isSubscription: true,
            merchantType: .subscription,
            commonAmounts: [4.99, 9.99, 14.99],
            metadata: MerchantMetadata(
                website: "spotify.com",
                logo: "spotify_logo",
                color: "#1DB954",
                countryOrigin: "SE",
                tags: ["music", "streaming", "podcasts"]
            )
        )
    ]
    
    // MARK: - Utilities
    
    private static let utilities: [String: Merchant] = [
        "att": Merchant(
            id: "att",
            canonicalName: "AT&T",
            category: Category.systemCategory(id: Category.systemCategoryIds.utilities)!,
            subcategory: "Telecommunications",
            aliases: ["AT&T", "ATT", "AT AND T", "AMERICAN TELEPHONE"],
            patterns: ["(?i)at&?t", "(?i)american\\s+telephone"],
            isSubscription: true,
            merchantType: .utility,
            commonAmounts: [55.00, 75.00, 85.00, 100.00],
            metadata: MerchantMetadata(
                website: "att.com",
                logo: "att_logo",
                color: "#00A8E0",
                countryOrigin: "US",
                tags: ["phone", "internet", "telecommunications"]
            )
        ),
        
        "verizon": Merchant(
            id: "verizon",
            canonicalName: "Verizon",
            category: Category.systemCategory(id: Category.systemCategoryIds.utilities)!,
            subcategory: "Telecommunications",
            aliases: ["VZW", "VERIZON WIRELESS", "VZ"],
            patterns: ["(?i)verizon(?:\\s+wireless)?", "(?i)vzw"],
            isSubscription: true,
            merchantType: .utility,
            commonAmounts: [60.00, 80.00, 90.00, 110.00],
            metadata: MerchantMetadata(
                website: "verizon.com",
                logo: "verizon_logo",
                color: "#CD040B",
                countryOrigin: "US",
                tags: ["phone", "internet", "telecommunications"]
            )
        )
    ]
    
    // MARK: - Financial
    
    private static let financial: [String: Merchant] = [
        "chase": Merchant(
            id: "chase",
            canonicalName: "Chase Bank",
            category: Category.systemCategory(id: Category.systemCategoryIds.other)!, // Use 'other' as there's no banking category
            subcategory: "Banking",
            aliases: ["JPM", "JPMORGAN CHASE", "CHASE BANK", "JP MORGAN"],
            patterns: ["(?i)chase(?:\\s+bank)?", "(?i)jp\\s?morgan"],
            isSubscription: false,
            merchantType: .financial,
            commonAmounts: [12.00, 25.00, 35.00], // Common fees
            metadata: MerchantMetadata(
                website: "chase.com",
                logo: "chase_logo",
                color: "#117ACA",
                countryOrigin: "US",
                tags: ["bank", "credit-card", "finance"]
            )
        ),
        
        "paypal": Merchant(
            id: "paypal",
            canonicalName: "PayPal",
            category: Category.systemCategory(id: Category.systemCategoryIds.other)!, // Use 'other' as there's no banking category
            subcategory: "Payment Processing",
            aliases: ["PYPL", "PAYPAL INC"],
            patterns: ["(?i)paypal(?:\\s+inc)?"],
            isSubscription: false,
            merchantType: .financial,
            commonAmounts: nil,
            metadata: MerchantMetadata(
                website: "paypal.com",
                logo: "paypal_logo",
                color: "#003087",
                countryOrigin: "US",
                tags: ["payment", "digital-wallet", "transfer"]
            )
        )
    ]
    
    // MARK: - Healthcare
    
    private static let healthcare: [String: Merchant] = [
        "cvs": Merchant(
            id: "cvs",
            canonicalName: "CVS Pharmacy",
            category: Category.systemCategory(id: Category.systemCategoryIds.healthcare)!,
            subcategory: "Pharmacy",
            aliases: ["CVS", "CVS HEALTH", "CVS/PHARMACY"],
            patterns: ["(?i)cvs(?:/pharmacy|\\s+health)?"],
            isSubscription: false,
            merchantType: .healthcare,
            commonAmounts: [10.00, 15.00, 25.00, 50.00],
            metadata: MerchantMetadata(
                website: "cvs.com",
                logo: "cvs_logo",
                color: "#CC0000",
                countryOrigin: "US",
                tags: ["pharmacy", "health", "convenience"]
            )
        ),
        
        "walgreens": Merchant(
            id: "walgreens",
            canonicalName: "Walgreens",
            category: Category.systemCategory(id: Category.systemCategoryIds.healthcare)!,
            subcategory: "Pharmacy",
            aliases: ["WAG", "WALGREEN"],
            patterns: ["(?i)walgreens?"],
            isSubscription: false,
            merchantType: .healthcare,
            commonAmounts: [10.00, 15.00, 25.00, 50.00],
            metadata: MerchantMetadata(
                website: "walgreens.com",
                logo: "walgreens_logo",
                color: "#E31837",
                countryOrigin: "US",
                tags: ["pharmacy", "health", "convenience"]
            )
        )
    ]
    
    // MARK: - Grocery
    
    private static let grocery: [String: Merchant] = [
        "kroger": Merchant(
            id: "kroger",
            canonicalName: "Kroger",
            category: Category.systemCategory(id: Category.systemCategoryIds.groceries)!,
            subcategory: "Supermarket",
            aliases: ["KR", "KROGER CO"],
            patterns: ["(?i)kroger(?:\\s+co)?"],
            isSubscription: false,
            merchantType: .grocery,
            commonAmounts: [25.00, 50.00, 75.00, 100.00],
            metadata: MerchantMetadata(
                website: "kroger.com",
                logo: "kroger_logo",
                color: "#004990",
                countryOrigin: "US",
                tags: ["grocery", "supermarket", "food"]
            )
        ),
        
        "safeway": Merchant(
            id: "safeway",
            canonicalName: "Safeway",
            category: Category.systemCategory(id: Category.systemCategoryIds.groceries)!,
            subcategory: "Supermarket",
            aliases: ["SAFEWAY INC", "SWY"],
            patterns: ["(?i)safeway(?:\\s+inc)?"],
            isSubscription: false,
            merchantType: .grocery,
            commonAmounts: [25.00, 50.00, 75.00, 100.00],
            metadata: MerchantMetadata(
                website: "safeway.com",
                logo: "safeway_logo",
                color: "#DA020E",
                countryOrigin: "US",
                tags: ["grocery", "supermarket", "food"]
            )
        ),
        
        // === MAJOR GROCERY CHAINS ===
        
        "publix": Merchant(
            id: "publix",
            canonicalName: "Publix",
            category: Category.systemCategory(id: Category.systemCategoryIds.groceries)!,
            subcategory: "Supermarket",
            aliases: ["PUBLIX SUPER MARKETS"],
            patterns: ["(?i)publix"],
            isSubscription: false,
            merchantType: .grocery,
            commonAmounts: [30.00, 60.00, 90.00, 120.00],
            metadata: MerchantMetadata(
                website: "publix.com",
                logo: "publix_logo",
                color: "#008000",
                countryOrigin: "US",
                tags: ["grocery", "supermarket", "southeast"]
            )
        ),
        
        "albertsons": Merchant(
            id: "albertsons",
            canonicalName: "Albertsons",
            category: Category.systemCategory(id: Category.systemCategoryIds.groceries)!,
            subcategory: "Supermarket",
            aliases: ["ALBERTSONS COS", "ABS"],
            patterns: ["(?i)albertsons"],
            isSubscription: false,
            merchantType: .grocery,
            commonAmounts: [25.00, 50.00, 75.00, 100.00],
            metadata: MerchantMetadata(
                website: "albertsons.com",
                logo: "albertsons_logo",
                color: "#0066CC",
                countryOrigin: "US",
                tags: ["grocery", "supermarket", "west"]
            )
        ),
        
        "wegmans": Merchant(
            id: "wegmans",
            canonicalName: "Wegmans",
            category: Category.systemCategory(id: Category.systemCategoryIds.groceries)!,
            subcategory: "Supermarket",
            aliases: ["WEGMANS FOOD MARKETS"],
            patterns: ["(?i)wegmans"],
            isSubscription: false,
            merchantType: .grocery,
            commonAmounts: [35.00, 70.00, 105.00, 140.00],
            metadata: MerchantMetadata(
                website: "wegmans.com",
                logo: "wegmans_logo",
                color: "#E31837",
                countryOrigin: "US",
                tags: ["grocery", "supermarket", "northeast", "premium"]
            )
        ),
        
        "harris_teeter": Merchant(
            id: "harris_teeter",
            canonicalName: "Harris Teeter",
            category: Category.systemCategory(id: Category.systemCategoryIds.groceries)!,
            subcategory: "Supermarket",
            aliases: ["HARRIS TEETER SUPERMARKETS"],
            patterns: ["(?i)harris\\s*teeter"],
            isSubscription: false,
            merchantType: .grocery,
            commonAmounts: [25.00, 50.00, 75.00, 100.00],
            metadata: MerchantMetadata(
                website: "harristeeter.com",
                logo: "harris_teeter_logo",
                color: "#004990",
                countryOrigin: "US",
                tags: ["grocery", "supermarket", "southeast"]
            )
        ),
        
        "whole_foods": Merchant(
            id: "whole_foods",
            canonicalName: "Whole Foods Market",
            category: Category.systemCategory(id: Category.systemCategoryIds.groceries)!,
            subcategory: "Organic Supermarket",
            aliases: ["WFM", "WHOLE FOODS", "AMAZON WHOLE FOODS"],
            patterns: ["(?i)whole\\s*foods?", "(?i)wfm\\s"],
            isSubscription: false,
            merchantType: .grocery,
            commonAmounts: [40.00, 80.00, 120.00, 160.00],
            metadata: MerchantMetadata(
                website: "wholefoodsmarket.com",
                logo: "whole_foods_logo",
                color: "#00674B",
                countryOrigin: "US",
                tags: ["grocery", "organic", "premium", "amazon"]
            )
        ),
        
        "traders_joes": Merchant(
            id: "traders_joes",
            canonicalName: "Trader Joe's",
            category: Category.systemCategory(id: Category.systemCategoryIds.groceries)!,
            subcategory: "Specialty Grocery",
            aliases: ["TRADER JOES", "TJS"],
            patterns: ["(?i)trader\\s*joe'?s?"],
            isSubscription: false,
            merchantType: .grocery,
            commonAmounts: [20.00, 40.00, 60.00, 80.00],
            metadata: MerchantMetadata(
                website: "traderjoes.com",
                logo: "trader_joes_logo",
                color: "#D50000",
                countryOrigin: "US",
                tags: ["grocery", "specialty", "affordable", "unique"]
            )
        ),
        
        "aldi": Merchant(
            id: "aldi",
            canonicalName: "ALDI",
            category: Category.systemCategory(id: Category.systemCategoryIds.groceries)!,
            subcategory: "Discount Grocery",
            aliases: ["ALDI INC"],
            patterns: ["(?i)aldi(?:\\s+inc)?"],
            isSubscription: false,
            merchantType: .grocery,
            commonAmounts: [15.00, 30.00, 45.00, 60.00],
            metadata: MerchantMetadata(
                website: "aldi.us",
                logo: "aldi_logo",
                color: "#FF6600",
                countryOrigin: "DE",
                tags: ["grocery", "discount", "german", "affordable"]
            )
        ),
        
        "stop_shop": Merchant(
            id: "stop_shop",
            canonicalName: "Stop & Shop",
            category: Category.systemCategory(id: Category.systemCategoryIds.groceries)!,
            subcategory: "Supermarket",
            aliases: ["STOP AND SHOP", "S&S"],
            patterns: ["(?i)stop\\s*(?:&|and)\\s*shop"],
            isSubscription: false,
            merchantType: .grocery,
            commonAmounts: [25.00, 50.00, 75.00, 100.00],
            metadata: MerchantMetadata(
                website: "stopandshop.com",
                logo: "stop_shop_logo",
                color: "#E31837",
                countryOrigin: "US",
                tags: ["grocery", "supermarket", "northeast"]
            )
        ),
        
        "giant_food": Merchant(
            id: "giant_food",
            canonicalName: "Giant Food",
            category: Category.systemCategory(id: Category.systemCategoryIds.groceries)!,
            subcategory: "Supermarket",
            aliases: ["GIANT", "GIANT FOOD STORES"],
            patterns: ["(?i)giant(?:\\s+food)?(?:\\s+stores)?"],
            isSubscription: false,
            merchantType: .grocery,
            commonAmounts: [25.00, 50.00, 75.00, 100.00],
            metadata: MerchantMetadata(
                website: "giantfood.com",
                logo: "giant_logo",
                color: "#E31837",
                countryOrigin: "US",
                tags: ["grocery", "supermarket", "mid-atlantic"]
            )
        ),
        
        "heb": Merchant(
            id: "heb",
            canonicalName: "H-E-B",
            category: Category.systemCategory(id: Category.systemCategoryIds.groceries)!,
            subcategory: "Supermarket",
            aliases: ["HEB", "H E B"],
            patterns: ["(?i)h\\s*-?\\s*e\\s*-?\\s*b"],
            isSubscription: false,
            merchantType: .grocery,
            commonAmounts: [30.00, 60.00, 90.00, 120.00],
            metadata: MerchantMetadata(
                website: "heb.com",
                logo: "heb_logo",
                color: "#E31837",
                countryOrigin: "US",
                tags: ["grocery", "supermarket", "texas", "regional"]
            )
        ),
        
        "meijer": Merchant(
            id: "meijer",
            canonicalName: "Meijer",
            category: Category.systemCategory(id: Category.systemCategoryIds.groceries)!,
            subcategory: "Supercenter",
            aliases: ["MEIJER INC"],
            patterns: ["(?i)meijer"],
            isSubscription: false,
            merchantType: .grocery,
            commonAmounts: [40.00, 80.00, 120.00, 160.00],
            metadata: MerchantMetadata(
                website: "meijer.com",
                logo: "meijer_logo",
                color: "#E31837",
                countryOrigin: "US",
                tags: ["grocery", "supercenter", "midwest"]
            )
        )
    ]
    
    // MARK: - Subscriptions
    
    private static let subscriptions: [String: Merchant] = [
        "adobe": Merchant(
            id: "adobe",
            canonicalName: "Adobe",
            category: Category.systemCategory(id: Category.systemCategoryIds.subscriptions)!,
            subcategory: "Creative Software",
            aliases: ["ADOBE INC", "ADBE", "ADOBE SYSTEMS"],
            patterns: ["(?i)adobe(?:\\s+(?:inc|systems))?"],
            isSubscription: true,
            merchantType: .subscription,
            commonAmounts: [9.99, 20.99, 52.99],
            metadata: MerchantMetadata(
                website: "adobe.com",
                logo: "adobe_logo",
                color: "#FF0000",
                countryOrigin: "US",
                tags: ["software", "creative", "design"]
            )
        ),
        
        "microsoft": Merchant(
            id: "microsoft",
            canonicalName: "Microsoft",
            category: Category.systemCategory(id: Category.systemCategoryIds.subscriptions)!,
            subcategory: "Software",
            aliases: ["MSFT", "MS", "MICROSOFT CORP"],
            patterns: ["(?i)microsoft(?:\\s+corp)?", "(?i)msft"],
            isSubscription: true,
            merchantType: .subscription,
            commonAmounts: [6.99, 9.99, 12.99],
            metadata: MerchantMetadata(
                website: "microsoft.com",
                logo: "microsoft_logo",
                color: "#0078D4",
                countryOrigin: "US",
                tags: ["software", "office", "cloud"]
            )
        ),
        
        // === STREAMING SERVICES ===
        
        "disney_plus": Merchant(
            id: "disney_plus",
            canonicalName: "Disney+",
            category: Category.systemCategory(id: Category.systemCategoryIds.subscriptions)!,
            subcategory: "Streaming",
            aliases: ["DISNEY PLUS", "DIS", "DISNEY+"],
            patterns: ["(?i)disney\\s*\\+?"],
            isSubscription: true,
            merchantType: .subscription,
            commonAmounts: [7.99, 10.99, 13.99],
            metadata: MerchantMetadata(
                website: "disneyplus.com",
                logo: "disney_plus_logo",
                color: "#113CCF",
                countryOrigin: "US",
                tags: ["streaming", "disney", "family", "movies"]
            )
        ),
        
        "hulu": Merchant(
            id: "hulu",
            canonicalName: "Hulu",
            category: Category.systemCategory(id: Category.systemCategoryIds.subscriptions)!,
            subcategory: "Streaming",
            aliases: ["HULU LLC"],
            patterns: ["(?i)hulu"],
            isSubscription: true,
            merchantType: .subscription,
            commonAmounts: [5.99, 11.99, 17.99],
            metadata: MerchantMetadata(
                website: "hulu.com",
                logo: "hulu_logo",
                color: "#1CE783",
                countryOrigin: "US",
                tags: ["streaming", "tv", "shows"]
            )
        ),
        
        "amazon_prime": Merchant(
            id: "amazon_prime",
            canonicalName: "Amazon Prime",
            category: Category.systemCategory(id: Category.systemCategoryIds.subscriptions)!,
            subcategory: "Streaming",
            aliases: ["PRIME VIDEO", "AMAZON PRIME VIDEO"],
            patterns: ["(?i)(?:amazon\\s+)?prime(?:\\s+video)?"],
            isSubscription: true,
            merchantType: .subscription,
            commonAmounts: [8.99, 14.99, 139.00], // Monthly and annual
            metadata: MerchantMetadata(
                website: "amazon.com/prime",
                logo: "amazon_prime_logo",
                color: "#00A8E1",
                countryOrigin: "US",
                tags: ["streaming", "shipping", "amazon", "prime"]
            )
        ),
        
        "hbo_max": Merchant(
            id: "hbo_max",
            canonicalName: "HBO Max",
            category: Category.systemCategory(id: Category.systemCategoryIds.subscriptions)!,
            subcategory: "Streaming",
            aliases: ["HBO", "MAX", "WARNER BROS"],
            patterns: ["(?i)hbo(?:\\s+max)?", "(?i)\\bmax\\b(?:\\s|$)"],
            isSubscription: true,
            merchantType: .subscription,
            commonAmounts: [9.99, 15.99],
            metadata: MerchantMetadata(
                website: "hbomax.com",
                logo: "hbo_max_logo",
                color: "#7B2CBF",
                countryOrigin: "US",
                tags: ["streaming", "hbo", "premium", "movies"]
            )
        ),
        
        "paramount_plus": Merchant(
            id: "paramount_plus",
            canonicalName: "Paramount+",
            category: Category.systemCategory(id: Category.systemCategoryIds.subscriptions)!,
            subcategory: "Streaming",
            aliases: ["PARAMOUNT PLUS", "CBS ALL ACCESS"],
            patterns: ["(?i)paramount\\s*\\+?", "(?i)cbs\\s+all\\s+access"],
            isSubscription: true,
            merchantType: .subscription,
            commonAmounts: [5.99, 9.99],
            metadata: MerchantMetadata(
                website: "paramountplus.com",
                logo: "paramount_plus_logo",
                color: "#0064FF",
                countryOrigin: "US",
                tags: ["streaming", "paramount", "cbs", "tv"]
            )
        ),
        
        "apple_services": Merchant(
            id: "apple_services",
            canonicalName: "Apple Services",
            category: Category.systemCategory(id: Category.systemCategoryIds.subscriptions)!,
            subcategory: "Technology",
            aliases: ["APPLE.COM/BILL", "APPLE TV+", "APPLE MUSIC", "ICLOUD"],
            patterns: ["(?i)apple\\.com", "(?i)apple\\s+(?:tv|music|icloud)", "(?i)itunes"],
            isSubscription: true,
            merchantType: .subscription,
            commonAmounts: [0.99, 4.99, 9.99, 14.95],
            metadata: MerchantMetadata(
                website: "apple.com",
                logo: "apple_logo",
                color: "#000000",
                countryOrigin: "US",
                tags: ["technology", "apple", "music", "cloud", "tv"]
            )
        ),
        
        "youtube_premium": Merchant(
            id: "youtube_premium",
            canonicalName: "YouTube Premium",
            category: Category.systemCategory(id: Category.systemCategoryIds.subscriptions)!,
            subcategory: "Streaming",
            aliases: ["GOOGLE YOUTUBE", "YT PREMIUM"],
            patterns: ["(?i)youtube(?:\\s+premium)?", "(?i)google\\s*youtube"],
            isSubscription: true,
            merchantType: .subscription,
            commonAmounts: [11.99, 17.99, 22.99],
            metadata: MerchantMetadata(
                website: "youtube.com/premium",
                logo: "youtube_logo",
                color: "#FF0000",
                countryOrigin: "US",
                tags: ["streaming", "youtube", "google", "video"]
            )
        ),
        
        // === SOFTWARE & PRODUCTIVITY ===
        
        "google_workspace": Merchant(
            id: "google_workspace",
            canonicalName: "Google Workspace",
            category: Category.systemCategory(id: Category.systemCategoryIds.subscriptions)!,
            subcategory: "Productivity",
            aliases: ["G SUITE", "GOOGLE APPS", "GOOGL"],
            patterns: ["(?i)google\\s+(?:workspace|apps)", "(?i)g\\s+suite"],
            isSubscription: true,
            merchantType: .subscription,
            commonAmounts: [6.00, 12.00, 18.00],
            metadata: MerchantMetadata(
                website: "workspace.google.com",
                logo: "google_workspace_logo",
                color: "#4285F4",
                countryOrigin: "US",
                tags: ["productivity", "google", "business", "cloud"]
            )
        ),
        
        "zoom": Merchant(
            id: "zoom",
            canonicalName: "Zoom",
            category: Category.systemCategory(id: Category.systemCategoryIds.subscriptions)!,
            subcategory: "Communication",
            aliases: ["ZOOM VIDEO", "ZM"],
            patterns: ["(?i)zoom(?:\\s+video)?"],
            isSubscription: true,
            merchantType: .subscription,
            commonAmounts: [14.99, 19.99, 39.99],
            metadata: MerchantMetadata(
                website: "zoom.us",
                logo: "zoom_logo",
                color: "#2D8CFF",
                countryOrigin: "US",
                tags: ["communication", "video", "conferencing", "business"]
            )
        ),
        
        "slack": Merchant(
            id: "slack",
            canonicalName: "Slack",
            category: Category.systemCategory(id: Category.systemCategoryIds.subscriptions)!,
            subcategory: "Communication",
            aliases: ["SLACK TECH"],
            patterns: ["(?i)slack"],
            isSubscription: true,
            merchantType: .subscription,
            commonAmounts: [6.67, 12.50],
            metadata: MerchantMetadata(
                website: "slack.com",
                logo: "slack_logo",
                color: "#4A154B",
                countryOrigin: "US",
                tags: ["communication", "team", "business", "productivity"]
            )
        ),
        
        "dropbox": Merchant(
            id: "dropbox",
            canonicalName: "Dropbox",
            category: Category.systemCategory(id: Category.systemCategoryIds.subscriptions)!,
            subcategory: "Cloud Storage",
            aliases: ["DBX"],
            patterns: ["(?i)dropbox"],
            isSubscription: true,
            merchantType: .subscription,
            commonAmounts: [9.99, 16.58],
            metadata: MerchantMetadata(
                website: "dropbox.com",
                logo: "dropbox_logo",
                color: "#0061FF",
                countryOrigin: "US",
                tags: ["cloud", "storage", "file-sharing", "backup"]
            )
        ),
        
        "canva": Merchant(
            id: "canva",
            canonicalName: "Canva",
            category: Category.systemCategory(id: Category.systemCategoryIds.subscriptions)!,
            subcategory: "Design",
            aliases: ["CANVA PTY"],
            patterns: ["(?i)canva"],
            isSubscription: true,
            merchantType: .subscription,
            commonAmounts: [12.99, 119.99], // Monthly and annual
            metadata: MerchantMetadata(
                website: "canva.com",
                logo: "canva_logo",
                color: "#00C4CC",
                countryOrigin: "AU",
                tags: ["design", "graphics", "creative", "templates"]
            )
        )
    ]
    
    // MARK: - Travel
    
    private static let travel: [String: Merchant] = [
        "delta": Merchant(
            id: "delta",
            canonicalName: "Delta Air Lines",
            category: Category.systemCategory(id: Category.systemCategoryIds.travel)!,
            subcategory: "Airlines",
            aliases: ["DAL", "DELTA AIRLINES", "DELTA AIR"],
            patterns: ["(?i)delta(?:\\s+(?:air|airlines?))?"],
            isSubscription: false,
            merchantType: .travel,
            commonAmounts: [200.00, 350.00, 500.00, 750.00],
            metadata: MerchantMetadata(
                website: "delta.com",
                logo: "delta_logo",
                color: "#003366",
                countryOrigin: "US",
                tags: ["airline", "travel", "flights"]
            )
        ),
        
        "marriott": Merchant(
            id: "marriott",
            canonicalName: "Marriott",
            category: Category.systemCategory(id: Category.systemCategoryIds.lodging)!,
            subcategory: "Hotels",
            aliases: ["MAR", "MARRIOTT INTL", "MARRIOTT INTERNATIONAL"],
            patterns: ["(?i)marriott(?:\\s+(?:intl|international))?"],
            isSubscription: false,
            merchantType: .travel,
            commonAmounts: [120.00, 180.00, 250.00, 350.00],
            metadata: MerchantMetadata(
                website: "marriott.com",
                logo: "marriott_logo",
                color: "#8B0000",
                countryOrigin: "US",
                tags: ["hotel", "travel", "accommodation"]
            )
        )
    ]
}