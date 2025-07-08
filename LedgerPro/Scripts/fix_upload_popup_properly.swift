// Find these lines in FileUploadView.swift around line 74:
// .frame(width: 800, height: 600)
// REPLACE WITH:
// .frame(minWidth: 900, idealWidth: 1000, maxWidth: .infinity, 
//        minHeight: 700, idealHeight: 800, maxHeight: .infinity)

// For ImportSummaryView around line 582:
// .frame(width: 700, height: 600)
// REPLACE WITH:
// Remove the frame entirely OR use:
// .frame(minWidth: 800, minHeight: 700)
// .presentationDetents([.large])

// Better yet, for the main sheet presentation, use:
.sheet(isPresented: $showingImportSummary) {
    if let result = importResult {
        ImportSummaryView(result: result) {
            // completion
        }
        .presentationDetents([.large]) // Uses 90% of screen
        .presentationDragIndicator(.visible)
    }
}