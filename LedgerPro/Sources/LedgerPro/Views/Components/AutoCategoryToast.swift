import SwiftUI

// MARK: - Auto-Category Toast Notification

struct AutoCategoryToast: View {
    let message: String
    let merchantName: String
    let categoryName: String
    @Binding var isShowing: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.title2)
                .foregroundColor(.blue)
                .symbolRenderingMode(.hierarchical)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(message)
                    .font(.headline)
                
                HStack(spacing: 4) {
                    Text(merchantName)
                        .fontWeight(.medium)
                    Image(systemName: "arrow.right")
                        .font(.caption)
                    Text(categoryName)
                        .foregroundColor(.blue)
                }
                .font(.subheadline)
            }
            
            Spacer()
            
            Button(action: { isShowing = false }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
        )
        .transition(.move(edge: .top).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    isShowing = false
                }
            }
        }
    }
}

// MARK: - Toast Overlay Modifier

extension View {
    func autoCategorizationToast(
        isShowing: Binding<Bool>,
        message: String,
        merchantName: String,
        categoryName: String
    ) -> some View {
        self.overlay(
            Group {
                if isShowing.wrappedValue {
                    AutoCategoryToast(
                        message: message,
                        merchantName: merchantName,
                        categoryName: categoryName,
                        isShowing: isShowing
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(999)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 20)
            .padding(.horizontal, 20)
        )
    }
}