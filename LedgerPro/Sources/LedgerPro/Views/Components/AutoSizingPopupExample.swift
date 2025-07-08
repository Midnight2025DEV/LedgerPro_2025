import SwiftUI

// Example of auto-sizing popup in practice
struct AutoSizingPopupExample: View {
    @State private var showPopup = false
    @State private var items = ["Item 1", "Item 2", "Item 3"]
    
    var body: some View {
        Button("Show Auto-Sizing Popup") {
            showPopup = true
        }
        .sheet(isPresented: $showPopup) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Auto-Sizing Example")
                    .font(.headline)
                
                Text("This popup grows with content!")
                    .foregroundColor(.secondary)
                
                ForEach(items, id: \.self) { item in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(item)
                        Spacer()
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
                
                HStack {
                    Button("Add Item") {
                        items.append("Item \(items.count + 1)")
                    }
                    
                    Spacer()
                    
                    Button("Done") {
                        showPopup = false
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding()
            .frame(minWidth: 300, idealWidth: 400)
        }
    }
}