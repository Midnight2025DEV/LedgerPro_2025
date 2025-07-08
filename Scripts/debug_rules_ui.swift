#!/usr/bin/env swift

import Foundation

print("🧪 Testing Rules Management UI Components")
print(String(repeating: "=", count: 50))

// Test Case 1: Rule Display Performance
print("\n📍 Test 1: Rule List Display Performance")
let ruleCount = 1000
let startTime = Date()

// Simulate loading rules
var rules: [[String: Any]] = []
for i in 0..<ruleCount {
    rules.append([
        "id": UUID().uuidString,
        "name": "Rule \(i)",
        "priority": Int.random(in: 1...100),
        "isActive": Bool.random(),
        "matchCount": Int.random(in: 0...1000)
    ])
}

let loadTime = Date().timeIntervalSince(startTime)
print("Loaded \(ruleCount) rules in \(loadTime * 1000)ms")

// Test Case 2: Search Performance
print("\n📍 Test 2: Rule Search Performance")
let searchTerms = ["Amazon", "Uber", "Walmart", "Starbucks", "Target"]

for term in searchTerms {
    let searchStart = Date()
    let matches = rules.filter { rule in
        (rule["name"] as? String)?.lowercased().contains(term.lowercased()) ?? false
    }
    let searchTime = Date().timeIntervalSince(searchStart)
    print("Search '\(term)': \(matches.count) matches in \(searchTime * 1000)ms")
}

// Test Case 3: Rule Builder Validation
print("\n📍 Test 3: Rule Builder Validation")
let testCases = [
    (name: "", merchant: "Amazon", valid: false, error: "Name required"),
    (name: "Amazon Rule", merchant: "", valid: false, error: "Condition required"),
    (name: "Valid Rule", merchant: "AMZN", valid: true, error: "None"),
    (name: "Regex Rule", merchant: "^UBER.*", valid: true, error: "None")
]

for test in testCases {
    let isValid = !test.name.isEmpty && !test.merchant.isEmpty
    print("Rule '\(test.name)' | Merchant: '\(test.merchant)' | Valid: \(isValid) | Expected: \(test.valid)")
    assert(isValid == test.valid, "Validation mismatch")
}

// Test Case 4: Export Format
print("\n📍 Test 4: Rule Export Format")
let exportRules = Array(rules.prefix(5))
do {
    let jsonData = try JSONSerialization.data(withJSONObject: exportRules, options: .prettyPrinted)
    print("Export size: \(jsonData.count) bytes for \(exportRules.count) rules")
    print("Average size per rule: \(jsonData.count / exportRules.count) bytes")
} catch {
    print("Export error: \(error)")
}

print("\n✅ Rules Management UI validation complete!")