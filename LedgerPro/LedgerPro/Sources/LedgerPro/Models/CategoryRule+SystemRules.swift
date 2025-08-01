import Foundation

extension CategoryRule {
    static let systemRules: [CategoryRule] = {
        var rules: [CategoryRule] = []
        
        // Transportation Rules (using existing transportation ID)
        rules.append(contentsOf: [
            CategoryRule(
                categoryId: Category.systemCategoryIds.transportation,
                ruleName: "Uber Rides",
                priority: 100
            ).with {
                $0.merchantContains = "UBER"
                $0.confidence = 0.9
            },
            CategoryRule(
                categoryId: Category.systemCategoryIds.transportation,
                ruleName: "Lyft Rides",
                priority: 100
            ).with {
                $0.merchantContains = "LYFT"
                $0.confidence = 0.9
            },
            CategoryRule(
                categoryId: Category.systemCategoryIds.transportation,
                ruleName: "Taxi Services",
                priority: 90
            ).with {
                $0.regexPattern = "TAXI|CAB|YELLOW CAB"
                $0.confidence = 0.8
            },
            CategoryRule(
                categoryId: Category.systemCategoryIds.transportation,
                ruleName: "Gas Stations",
                priority: 95
            ).with {
                $0.regexPattern = "SHELL|CHEVRON|EXXON(?!.*MOBILE)|BP|CITGO|SUNOCO|TEXACO|76.*GAS|COMPANIA GAS|GAS STATION"
                $0.confidence = 0.85
            }
        ])
        
        // Food & Dining Rules (using existing foodDining ID)
        rules.append(contentsOf: [
            CategoryRule(
                categoryId: Category.systemCategoryIds.foodDining,
                ruleName: "Uber Eats",
                priority: 110  // Higher than Uber transportation
            ).with {
                $0.merchantContains = "UBER EATS"
                $0.confidence = 0.95
            },
            CategoryRule(
                categoryId: Category.systemCategoryIds.foodDining,
                ruleName: "Food Delivery Services",
                priority: 105
            ).with {
                $0.regexPattern = "DOORDASH|GRUBHUB|POSTMATES|SEAMLESS"
                $0.confidence = 0.9
            },
            CategoryRule(
                categoryId: Category.systemCategoryIds.foodDining,
                ruleName: "Starbucks",
                priority: 100
            ).with {
                $0.merchantContains = "STARBUCKS"
                $0.confidence = 0.95
            },
            CategoryRule(
                categoryId: Category.systemCategoryIds.foodDining,
                ruleName: "Fast Food Chains",
                priority: 90
            ).with {
                $0.regexPattern = "MCDONALD|BURGER KING|WENDY|TACO BELL|SUBWAY|CHIPOTLE|KFC|POPEYES"
                $0.confidence = 0.9
            },
            CategoryRule(
                categoryId: Category.systemCategoryIds.foodDining,
                ruleName: "Coffee Shops",
                priority: 85
            ).with {
                $0.regexPattern = "COFFEE|CAFE|DUNKIN|PEET'S|TIM HORTONS"
                $0.confidence = 0.85
            },
            CategoryRule(
                categoryId: Category.systemCategoryIds.foodDining,
                ruleName: "Restaurants",
                priority: 80
            ).with {
                $0.regexPattern = "RESTAURANT|GRILL|KITCHEN|BISTRO|DINER|PIZZA"
                $0.confidence = 0.8
            }
        ])
        
        // Shopping Rules (using existing shopping ID)
        rules.append(contentsOf: [
            CategoryRule(
                categoryId: Category.systemCategoryIds.shopping,
                ruleName: "Amazon",
                priority: 100
            ).with {
                $0.merchantContains = "AMAZON"
                $0.confidence = 0.95
            },
            CategoryRule(
                categoryId: Category.systemCategoryIds.shopping,
                ruleName: "Walmart",
                priority: 95
            ).with {
                $0.merchantContains = "WALMART"
                $0.confidence = 0.9
            },
            CategoryRule(
                categoryId: Category.systemCategoryIds.shopping,
                ruleName: "Target",
                priority: 95
            ).with {
                $0.merchantContains = "TARGET"
                $0.confidence = 0.9
            },
            CategoryRule(
                categoryId: Category.systemCategoryIds.shopping,
                ruleName: "Home Improvement",
                priority: 85
            ).with {
                $0.regexPattern = "HOME DEPOT|LOWE'S|LOWES|ACE HARDWARE"
                $0.confidence = 0.85
            },
            CategoryRule(
                categoryId: Category.systemCategoryIds.shopping,
                ruleName: "Grocery Stores",
                priority: 90
            ).with {
                $0.regexPattern = "KROGER|SAFEWAY|PUBLIX|WEGMANS|HARRIS TEETER|GIANT|STOP SHOP"
                $0.confidence = 0.85
            },
            CategoryRule(
                categoryId: Category.systemCategoryIds.shopping,
                ruleName: "Pharmacies",
                priority: 85
            ).with {
                $0.regexPattern = "CVS|WALGREENS|RITE AID|PHARMACY"
                $0.confidence = 0.85
            },
            CategoryRule(
                categoryId: Category.systemCategoryIds.shopping,
                ruleName: "Subscriptions & Streaming",
                priority: 80
            ).with {
                $0.regexPattern = "NETFLIX|HULU|SPOTIFY|APPLE|DISNEY|HBO|AMAZON PRIME"
                $0.confidence = 0.8
            }
        ])
        
        // Income Rules (using existing salary ID for payroll)
        rules.append(contentsOf: [
            CategoryRule(
                categoryId: Category.systemCategoryIds.salary,
                ruleName: "Direct Deposit Salary",
                priority: 100
            ).with {
                $0.regexPattern = "DIRECT DEP|PAYROLL|SALARY"
                $0.amountSign = .positive
                $0.isRecurring = true
                $0.confidence = 0.95
            },
            CategoryRule(
                categoryId: Category.systemCategoryIds.income,
                ruleName: "Deposit",
                priority: 80
            ).with {
                $0.descriptionContains = "DEPOSIT"
                $0.amountSign = .positive
                $0.confidence = 0.7
            }
        ])
        
        // Housing Rules (using existing housing ID)
        rules.append(contentsOf: [
            CategoryRule(
                categoryId: Category.systemCategoryIds.housing,
                ruleName: "Rent Payment",
                priority: 95
            ).with {
                $0.regexPattern = "RENT|LEASE|APARTMENT|PROPERTY MGMT"
                $0.amountMin = 500
                $0.confidence = 0.85
            },
            CategoryRule(
                categoryId: Category.systemCategoryIds.housing,
                ruleName: "Mortgage",
                priority: 95
            ).with {
                $0.regexPattern = "MORTGAGE|HOME LOAN"
                $0.amountMin = 500
                $0.confidence = 0.9
            },
            CategoryRule(
                categoryId: Category.systemCategoryIds.housing,
                ruleName: "Utilities",
                priority: 90
            ).with {
                $0.regexPattern = "ELECTRIC|GAS COMPANY|WATER|COMCAST|VERIZON|AT&T|SPECTRUM|INTERNET|CABLE|UTILITY"
                $0.confidence = 0.8
            },
            CategoryRule(
                categoryId: Category.systemCategoryIds.housing,
                ruleName: "Real Estate",
                priority: 85
            ).with {
                $0.regexPattern = "INMOBILIARIO|REAL ESTATE|PROPERTY|REALTY"
                $0.confidence = 0.8
            }
        ])
        
        // Credit Card Payment Rules
        rules.append(contentsOf: [
            CategoryRule(
                categoryId: Category.systemCategoryIds.creditCardPayment,
                ruleName: "Capital One Payments",
                priority: 100
            ).with {
                $0.merchantContains = "CAPITAL ONE"
                $0.confidence = 0.95
            },
            CategoryRule(
                categoryId: Category.systemCategoryIds.creditCardPayment,
                ruleName: "Credit Card Payments",
                priority: 90
            ).with {
                $0.regexPattern = "PAYMENT|CARD PYMT|CC PAYMENT|AUTOPAY"
                $0.amountSign = .positive
                $0.confidence = 0.8
            }
        ])
        
        // Transfer Rules
        rules.append(contentsOf: [
            CategoryRule(
                categoryId: Category.systemCategoryIds.transfers,
                ruleName: "Bank Transfers",
                priority: 85
            ).with {
                $0.regexPattern = "TRANSFER|XFER|ACH"
                $0.confidence = 0.75
            },
            CategoryRule(
                categoryId: Category.systemCategoryIds.transfers,
                ruleName: "Capital One Mobile Transfer",
                priority: 105
            ).with {
                $0.regexPattern = "CAPITAL ONE MOBILE(?!.*PAYMENT)"
                $0.confidence = 0.95
            }
        ])
        
        // Enhanced AI & Tech Services Rules
        rules.append(contentsOf: [
            CategoryRule(
                categoryId: Category.systemCategoryIds.subscriptions,
                ruleName: "Claude AI",
                priority: 90
            ).with {
                $0.merchantContains = "CLAUDE"
                $0.confidence = 0.9
            },
            CategoryRule(
                categoryId: Category.systemCategoryIds.subscriptions,
                ruleName: "Anthropic",
                priority: 90
            ).with {
                $0.merchantContains = "ANTHROPIC"
                $0.confidence = 0.9
            },
            CategoryRule(
                categoryId: Category.systemCategoryIds.subscriptions,
                ruleName: "OpenAI",
                priority: 90
            ).with {
                $0.merchantContains = "OPENAI"
                $0.confidence = 0.9
            },
            CategoryRule(
                categoryId: Category.systemCategoryIds.subscriptions,
                ruleName: "ChatGPT",
                priority: 90
            ).with {
                $0.merchantContains = "CHATGPT"
                $0.confidence = 0.9
            },
            CategoryRule(
                categoryId: Category.systemCategoryIds.subscriptions,
                ruleName: "Google Services",
                priority: 85
            ).with {
                $0.merchantContains = "GOOGLE"
                $0.confidence = 0.85
            },
            CategoryRule(
                categoryId: Category.systemCategoryIds.education,
                ruleName: "Coursera",
                priority: 85
            ).with {
                $0.merchantContains = "COURSERA"
                $0.confidence = 0.85
            }
        ])
        
        // Enhanced Food & Coffee Rules
        rules.append(contentsOf: [
            CategoryRule(
                categoryId: Category.systemCategoryIds.foodDining,
                ruleName: "Rifle Coffee",
                priority: 90
            ).with {
                $0.merchantContains = "RIFLE COFFEE"
                $0.confidence = 0.9
            },
            CategoryRule(
                categoryId: Category.systemCategoryIds.foodDining,
                ruleName: "Panera",
                priority: 90
            ).with {
                $0.merchantContains = "PANERA"
                $0.confidence = 0.9
            }
        ])
        
        // Enhanced Transportation & Parking Rules
        rules.append(contentsOf: [
            CategoryRule(
                categoryId: Category.systemCategoryIds.transportation,
                ruleName: "Parking",
                priority: 85
            ).with {
                $0.merchantContains = "PARKING"
                $0.confidence = 0.85
            },
            CategoryRule(
                categoryId: Category.systemCategoryIds.transportation,
                ruleName: "76 Gas",
                priority: 85
            ).with {
                $0.regexPattern = "76\\s"
                $0.confidence = 0.85
            },
            CategoryRule(
                categoryId: Category.systemCategoryIds.transportation,
                ruleName: "PY Transport",
                priority: 80
            ).with {
                $0.regexPattern = "PY\\s"
                $0.confidence = 0.8
            }
        ])
        
        // Mexican Stores Rules
        rules.append(contentsOf: [
            CategoryRule(
                categoryId: Category.systemCategoryIds.shopping,
                ruleName: "OXXO",
                priority: 85
            ).with {
                $0.merchantContains = "OXXO"
                $0.confidence = 0.85
            },
            CategoryRule(
                categoryId: Category.systemCategoryIds.groceries,
                ruleName: "Carniceria",
                priority: 85
            ).with {
                $0.merchantContains = "CARNICERIA"
                $0.confidence = 0.85
            },
            CategoryRule(
                categoryId: Category.systemCategoryIds.groceries,
                ruleName: "Fruteria",
                priority: 85
            ).with {
                $0.merchantContains = "FRUTERIA"
                $0.confidence = 0.85
            },
            CategoryRule(
                categoryId: Category.systemCategoryIds.groceries,
                ruleName: "Carn Store",
                priority: 80
            ).with {
                $0.regexPattern = "CARN\\s"
                $0.confidence = 0.8
            }
        ])
        
        // Hotel & Lodging Rules
        rules.append(contentsOf: [
            CategoryRule(
                categoryId: Category.systemCategoryIds.lodging,
                ruleName: "Motel",
                priority: 90
            ).with {
                $0.merchantContains = "MOTEL"
                $0.confidence = 0.9
            },
            CategoryRule(
                categoryId: Category.systemCategoryIds.lodging,
                ruleName: "Hotel",
                priority: 90
            ).with {
                $0.merchantContains = "HOTEL"
                $0.confidence = 0.9
            }
        ])
        
        // Enhanced Entertainment & Streaming Rules
        rules.append(contentsOf: [
            CategoryRule(
                categoryId: Category.systemCategoryIds.entertainment,
                ruleName: "Crunchyroll",
                priority: 90
            ).with {
                $0.merchantContains = "CRUNCHYROLL"
                $0.confidence = 0.9
            },
            CategoryRule(
                categoryId: Category.systemCategoryIds.entertainment,
                ruleName: "Netflix",
                priority: 90
            ).with {
                $0.merchantContains = "NETFLIX"
                $0.confidence = 0.9
            },
            CategoryRule(
                categoryId: Category.systemCategoryIds.entertainment,
                ruleName: "YouTube",
                priority: 85
            ).with {
                $0.merchantContains = "YOUTUBE"
                $0.confidence = 0.85
            }
        ])
        
        // Financial Services Rules
        rules.append(contentsOf: [
            CategoryRule(
                categoryId: Category.systemCategoryIds.business,
                ruleName: "PayPal",
                priority: 80
            ).with {
                $0.merchantContains = "PAYPAL"
                $0.confidence = 0.8
            }
        ])
        
        return rules
    }()
}

// Helper extension for builder pattern
private extension CategoryRule {
    func with(_ block: (inout CategoryRule) -> Void) -> CategoryRule {
        var copy = self
        block(&copy)
        return copy
    }
}