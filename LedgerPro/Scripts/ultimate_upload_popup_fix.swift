// 1. REMOVE ALL FRAME CONSTRAINTS from ImportSummaryView
// Let content drive the size completely

// 2. Add WindowGroup scene modifier (if using SwiftUI App)
.commands {
    CommandGroup(after: .windowSize) {
        Button("Expand Import Window") {
            // Toggle full screen
        }
        .keyboardShortcut("F", modifiers: [.command, .shift])
    }
}

// 3. Use GeometryReader for truly responsive design
GeometryReader { geometry in
    if geometry.size.width < 1200 {
        // Compact layout - stack vertically
        VStack { /* content */ }
    } else {
        // Wide layout - side by side
        HStack { /* content */ }
    }
}

// 4. Add collapsible sections
@State private var showingTransactionDetails = true
DisclosureGroup("Transaction Details", isExpanded: $showingTransactionDetails) {
    // Transaction list
}

// 5. Better empty state handling
if result.transactions.isEmpty {
    ContentUnavailableView(
        "No Transactions Found",
        systemImage: "doc.text.magnifyingglass",
        description: Text("Try uploading a different file")
    )
}