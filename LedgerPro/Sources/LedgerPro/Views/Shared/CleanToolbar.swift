import SwiftUI

struct CleanToolbar: ToolbarContent {
    let onRefresh: () -> Void
    let onSettings: () -> Void
    
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            HStack(spacing: 12) {
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .medium))
                }
                .help("Refresh transactions")
                
                Button(action: onSettings) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 16, weight: .medium))
                }
                .help("Settings")
            }
        }
    }
}