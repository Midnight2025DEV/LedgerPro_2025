import SwiftUI

/// Example of how to add accessibility identifiers to SwiftUI views
struct AccessibleButton: View {
    let title: String
    let action: () -> Void
    let accessibilityId: String
    
    var body: some View {
        Button(action: action) {
            Text(title)
        }
        .accessibilityIdentifier(accessibilityId)
        .accessibilityLabel(title)
        .accessibilityHint("Tap to \(title.lowercased())")
    }
}

// Usage example:
// AccessibleButton(
//     title: "Upload Statement",
//     action: { showUploadSheet = true },
//     accessibilityId: "uploadStatementButton"
// )
