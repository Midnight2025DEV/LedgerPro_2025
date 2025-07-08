#\!/usr/bin/env swift

import Foundation

print("🧠 Merchant Learning Monitor")
print("=" * 50)

// Check for rules file
let rulesPath = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent("Library/Application Support/LedgerPro/rules.json")

if FileManager.default.fileExists(atPath: rulesPath.path) {
    if let data = try? Data(contentsOf: rulesPath),
       let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
        
        print("\n📊 Current Rules:")
        print("Total rules: \(json.count)")
        
        var merchantRules = 0
        var autoCreatedRules = 0
        
        for rule in json {
            if let name = rule["ruleName"] as? String {
                if name.hasPrefix("Auto:") {
                    autoCreatedRules += 1
                    print("  - \(name)")
                }
                if rule["merchantContains"] \!= nil || rule["merchantExact"] \!= nil {
                    merchantRules += 1
                }
            }
        }
        
        print("\n📈 Statistics:")
        print("Merchant-based rules: \(merchantRules)")
        print("Auto-created rules: \(autoCreatedRules)")
    }
} else {
    print("No rules file found yet. Rules will be created as you categorize transactions.")
}

print("\n💡 Tips:")
print("1. Categorize a few transactions manually")
print("2. Import new transactions to see auto-categorization")
print("3. Run this script again to see learned rules")
EOF < /dev/null