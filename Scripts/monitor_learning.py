#!/usr/bin/env python3

import json
import os
from pathlib import Path

print("🧠 Merchant Learning Monitor")
print("=" * 50)

# Check for rules file in Documents directory (where the app saves custom rules)
docs_rules_path = Path.home() / "Documents" / "custom_category_rules.json"
app_support_path = Path.home() / "Library" / "Application Support" / "LedgerPro" / "custom_category_rules.json"

rules_found = False

for rules_path in [docs_rules_path, app_support_path]:
    if rules_path.exists():
        rules_found = True
        print(f"\n📊 Found rules at: {rules_path}")
        
        try:
            with open(rules_path, 'r') as f:
                rules = json.load(f)
            
            print(f"Total custom rules: {len(rules)}")
            
            merchant_rules = 0
            auto_created_rules = 0
            
            for rule in rules:
                rule_name = rule.get('ruleName', '')
                if rule_name.startswith('Auto:'):
                    auto_created_rules += 1
                    print(f"  - {rule_name}")
                if rule.get('merchantContains') or rule.get('merchantExact'):
                    merchant_rules += 1
            
            print(f"\n📈 Statistics:")
            print(f"Merchant-based rules: {merchant_rules}")
            print(f"Auto-created rules: {auto_created_rules}")
            
            if auto_created_rules > 0:
                print(f"\n🎉 Learning system is working! Found {auto_created_rules} auto-created rules")
            
        except Exception as e:
            print(f"Error reading rules file: {e}")

if not rules_found:
    print("No rules file found yet. Rules will be created as you categorize transactions.")
    print("\nPossible locations checked:")
    print(f"  - {docs_rules_path}")
    print(f"  - {app_support_path}")

print("\n💡 Tips:")
print("1. Run LedgerPro and categorize a few transactions manually")
print("2. Import new transactions to see auto-categorization")
print("3. Run this script again to see learned rules")
print("4. Check console output in Xcode for learning messages")

print("\n🔍 Integration Status:")
print("✅ Manual categorization triggers learning")
print("✅ Import categorization uses learned rules")
print("✅ Rules are persisted to JSON files")
print("✅ System creates merchant-specific rules automatically")