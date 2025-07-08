# Auto-Sizing Popup Design Guide for LedgerPro

## Problem Statement
Fixed-size popups cause issues:
- Content gets cut off when too large
- Excessive whitespace when content is small
- Different screens need different sizes
- Manual sizing for each popup is tedious

## Solution: Content-Driven Auto-Sizing

### Quick Start: Using AutoSizingPopup

```swift
// In your view:
.autoSizingPopup(isPresented: $showCategoryPicker) {
    CategoryPickerPopup(
        transaction: transaction,
        isPresented: $showCategoryPicker,
        onSelect: handleCategorySelection
    )
}
```

### Core Principles

1. **Let Content Determine Size**
   ```swift
   .fixedSize(horizontal: false, vertical: true)  // Key line!
   ```

2. **Set Sensible Constraints**
   ```swift
   .frame(
       minWidth: 400,                          // Minimum usable width
       maxWidth: geometry.size.width * 0.9,    // 90% of screen max
       maxHeight: geometry.size.height * 0.9   // 90% of screen max
   )
   ```

3. **Content Should Expand Horizontally**
   ```swift
   VStack {
       YourContent()
           .frame(maxWidth: .infinity)  // Fill available width
   }
   ```

### Implementation Patterns

#### Pattern 1: Simple Auto-Sizing Popup
```swift
struct SimplePopup: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Title")
                .font(.headline)
            
            // Content that determines height
            ForEach(items) { item in
                ItemRow(item: item)
            }
            
            Button("Done") {
                isPresented = false
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
    }
}
```

#### Pattern 2: Scrollable Content with Max Height
```swift
struct ScrollablePopup: View {
    var body: some View {
        VStack(spacing: 0) {
            // Fixed header
            HeaderView()
                .fixedSize(horizontal: false, vertical: true)
            
            // Scrollable content
            ScrollView {
                LazyVStack {
                    ForEach(manyItems) { item in
                        ItemView(item: item)
                    }
                }
            }
            .frame(maxHeight: 500)  // Limit scroll area
            
            // Fixed footer
            FooterView()
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(minWidth: 400, maxWidth: 800)
    }
}
```

#### Pattern 3: Responsive Card Layout
```swift
struct ResponsiveCards: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(cards) { card in
                    CardView(card: card)
                        .frame(idealWidth: 300)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
```

### Common Mistakes to Avoid

1. **❌ Fixed Heights**
   ```swift
   // Bad
   .frame(width: 600, height: 400)
   
   // Good
   .frame(minWidth: 400, maxWidth: 600)
   .fixedSize(horizontal: false, vertical: true)
   ```

2. **❌ Not Setting Max Constraints**
   ```swift
   // Bad - Can grow infinitely
   .fixedSize(horizontal: false, vertical: true)
   
   // Good - Has reasonable limits
   .frame(maxHeight: geometry.size.height * 0.9)
   .fixedSize(horizontal: false, vertical: true)
   ```

3. **❌ Forgetting Content Alignment**
   ```swift
   // Bad - Content might not fill width
   VStack { }
   
   // Good - Content fills available space
   VStack {
       content
           .frame(maxWidth: .infinity)
   }
   ```

### Testing Checklist

- [ ] Test with minimal content (1-2 items)
- [ ] Test with maximum content (100+ items)
- [ ] Test on small screen (13" MacBook)
- [ ] Test on large screen (27" iMac)
- [ ] Verify scrolling works when needed
- [ ] Check that popup doesn't exceed screen bounds
- [ ] Ensure dismiss gestures work properly

### Real Example: CategoryPickerPopup Enhancement

**Before**: Fixed size 850x650
- Too large for small screens
- Wasted space with few categories
- Content cut off with many categories

**After**: Auto-sizing with constraints
- Fits content perfectly
- Respects screen size
- Scrolls when needed
- Better user experience

### Quick Reference

```swift
// The magic formula for auto-sizing popups:
YourPopupContent()
    .padding()
    .frame(maxWidth: .infinity)
    .frame(
        minWidth: 400,
        maxWidth: min(900, geometry.size.width * 0.9),
        maxHeight: geometry.size.height * 0.9
    )
    .fixedSize(horizontal: false, vertical: true)
    .background(Color(NSColor.windowBackgroundColor))
    .cornerRadius(12)
    .shadow(radius: 20)
```

### Additional Resources

- SwiftUI Layout System: Use `fixedSize` wisely
- GeometryReader: Get screen dimensions
- ScrollView: Handle overflow content
- ViewModifiers: Create reusable popup styles

---

Last Updated: January 2025
Part of LedgerPro UI Guidelines