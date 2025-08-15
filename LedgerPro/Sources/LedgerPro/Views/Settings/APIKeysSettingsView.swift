import SwiftUI

struct APIKeysSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("API Keys Settings")
                    .font(.largeTitle)
                    .padding()
                
                Text("Configure your AI provider API keys here.")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .padding()
            }
            .padding()
            .navigationTitle("API Keys")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    APIKeysSettingsView()
}