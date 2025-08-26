import SwiftUI
import PhotosUI

struct MerchantLogoManager: View {
    let merchantName: String
    @State private var selectedImage: PhotosPickerItem?
    @State private var merchantLogo: Image?
    @State private var showingIconPicker = false
    @State private var selectedSFSymbol: String?
    @State private var selectedColor: Color = .accentColor
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: FinancialDataManager
    
    // Popular merchant logos from SF Symbols
    let suggestedIcons = [
        "cart.fill": "Shopping",
        "fork.knife": "Dining",
        "car.fill": "Transport",
        "house.fill": "Home",
        "creditcard.fill": "Finance",
        "tv.fill": "Entertainment",
        "heart.fill": "Healthcare",
        "book.fill": "Education",
        "airplane": "Travel",
        "fuelpump.fill": "Gas",
        "cup.and.saucer.fill": "Coffee",
        "bag.fill": "Retail"
    ]
    
    // Color palette
    let colorOptions: [Color] = [
        .blue, .green, .orange, .red, .purple, .pink, .yellow, .cyan, .indigo, .mint
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text("Merchant Logo")
                    .font(.title2.bold())
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Current Logo Preview
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    if let merchantLogo {
                        merchantLogo
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } else if let symbol = selectedSFSymbol {
                        ZStack {
                            Circle()
                                .fill(selectedColor.opacity(0.2))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: symbol)
                                .font(.system(size: 50))
                                .foregroundColor(selectedColor)
                        }
                    } else {
                        Text(merchantName.prefix(2).uppercased())
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(merchantName)
                    .font(.title3.bold())
                
                Text("This logo will appear in all transactions from this merchant")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            
            Divider()
            
            // Logo Options
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Upload Custom
                    PhotosPicker(selection: $selectedImage,
                               matching: .images,
                               photoLibrary: .shared()) {
                        HStack {
                            Image(systemName: "photo")
                                .font(.title3)
                            VStack(alignment: .leading) {
                                Text("Upload Custom Logo")
                                    .font(.headline)
                                Text("Choose from your photo library")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .onChange(of: selectedImage) { _ in
                        Task {
                            if let data = try? await selectedImage?.loadTransferable(type: Data.self),
                               let nsImage = NSImage(data: data) {
                                merchantLogo = Image(nsImage: nsImage)
                                selectedSFSymbol = nil
                            }
                        }
                    }
                    
                    // Choose Icon
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Or choose an icon")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                            ForEach(suggestedIcons.sorted(by: { $0.key < $1.key }), id: \.key) { icon, name in
                                Button(action: {
                                    selectedSFSymbol = icon
                                    merchantLogo = nil
                                }) {
                                    VStack(spacing: 8) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(selectedSFSymbol == icon ? selectedColor.opacity(0.2) : Color.gray.opacity(0.1))
                                                .frame(width: 60, height: 60)
                                            
                                            Image(systemName: icon)
                                                .font(.title2)
                                                .foregroundColor(selectedSFSymbol == icon ? selectedColor : .secondary)
                                        }
                                        Text(name)
                                            .font(.caption2)
                                            .foregroundColor(.primary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        // Color picker for SF Symbols
                        if selectedSFSymbol != nil {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Icon Color")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 12) {
                                    ForEach(colorOptions, id: \.self) { color in
                                        Button(action: { selectedColor = color }) {
                                            Circle()
                                                .fill(color)
                                                .frame(width: 30, height: 30)
                                                .overlay(
                                                    Circle()
                                                        .strokeBorder(Color.primary, lineWidth: selectedColor == color ? 2 : 0)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(.top)
                        }
                    }
                    
                    // Recent merchants without logos
                    if let recentMerchants = getRecentMerchantsWithoutLogos() {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Other merchants without logos")
                                .font(.headline)
                                .padding(.top)
                            
                            ForEach(recentMerchants, id: \.self) { merchant in
                                Button(action: {
                                    // Switch to this merchant
                                }) {
                                    HStack {
                                        Text(merchant)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Actions
            HStack {
                Button("Remove Logo") {
                    merchantLogo = nil
                    selectedSFSymbol = nil
                    saveMerchantLogo()
                }
                .buttonStyle(.plain)
                .disabled(merchantLogo == nil && selectedSFSymbol == nil)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
                
                Button("Save") {
                    saveMerchantLogo()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 500, height: 700)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            loadExistingLogo()
        }
    }
    
    private func loadExistingLogo() {
        // Load existing logo from data manager
        if let logoData = dataManager.getMerchantLogo(for: merchantName) {
            if let symbol = logoData.sfSymbol {
                selectedSFSymbol = symbol
                selectedColor = Color(logoData.color ?? "accentColor") ?? .accentColor
            } else if let imageData = logoData.imageData,
                      let nsImage = NSImage(data: imageData) {
                merchantLogo = Image(nsImage: nsImage)
            }
        }
    }
    
    private func saveMerchantLogo() {
        var logoData = MerchantLogoData(merchantName: merchantName)
        
        if let symbol = selectedSFSymbol {
            logoData.sfSymbol = symbol
            logoData.color = selectedColor.description
        } else if merchantLogo != nil {
            // Save custom image data
            // Note: In real implementation, convert Image to Data
            logoData.imageData = nil // Placeholder
        }
        
        dataManager.saveMerchantLogo(logoData)
    }
    
    private func getRecentMerchantsWithoutLogos() -> [String]? {
        let allMerchants = Set(dataManager.transactions.map { $0.merchantName })
        let merchantsWithLogos = dataManager.getMerchantsWithLogos()
        let merchantsWithoutLogos = allMerchants.subtracting(merchantsWithLogos)
        
        return Array(merchantsWithoutLogos.prefix(5)).sorted()
    }
}

struct MerchantLogoData: Codable {
    let merchantName: String
    var sfSymbol: String?
    var color: String?
    var imageData: Data?
    var backgroundColor: Color?
    
    enum CodingKeys: String, CodingKey {
        case merchantName, sfSymbol, color, imageData
    }
    
    init(merchantName: String, sfSymbol: String? = nil, color: String? = nil, imageData: Data? = nil, backgroundColor: Color? = nil) {
        self.merchantName = merchantName
        self.sfSymbol = sfSymbol
        self.color = color
        self.imageData = imageData
        self.backgroundColor = backgroundColor
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        merchantName = try container.decode(String.self, forKey: .merchantName)
        sfSymbol = try container.decodeIfPresent(String.self, forKey: .sfSymbol)
        color = try container.decodeIfPresent(String.self, forKey: .color)
        imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
        backgroundColor = nil // Will be set from color string
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(merchantName, forKey: .merchantName)
        try container.encodeIfPresent(sfSymbol, forKey: .sfSymbol)
        try container.encodeIfPresent(color, forKey: .color)
        try container.encodeIfPresent(imageData, forKey: .imageData)
    }
}

// MARK: - Merchant Manager View

struct MerchantManagerView: View {
    @EnvironmentObject var dataManager: FinancialDataManager
    @State private var selectedMerchant: String?
    @State private var showingLogoManager = false
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    
    var merchants: [String] {
        let allMerchants = dataManager.transactions
            .map { $0.merchantName }
            .filter { !$0.isEmpty }
        
        let uniqueMerchants = Array(Set(allMerchants)).sorted()
        
        if searchText.isEmpty {
            return uniqueMerchants
        } else {
            return uniqueMerchants.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Merchant Management")
                    .font(.title2.bold())
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search merchants", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .padding()
            
            // Merchant List
            List(merchants, id: \.self) { merchant in
                MerchantRow(
                    merchantName: merchant,
                    transactionCount: dataManager.transactionCount(for: merchant),
                    onEditLogo: {
                        selectedMerchant = merchant
                        showingLogoManager = true
                    }
                )
            }
            .listStyle(.inset)
        }
        .sheet(isPresented: $showingLogoManager) {
            if let merchant = selectedMerchant {
                MerchantLogoManager(merchantName: merchant)
                    .environmentObject(dataManager)
            }
        }
    }
}

struct MerchantRow: View {
    let merchantName: String
    let transactionCount: Int
    let onEditLogo: () -> Void
    @EnvironmentObject var dataManager: FinancialDataManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Logo preview
            ZStack {
                Circle()
                    .fill(logoBackgroundColor.gradient)
                    .frame(width: 40, height: 40)
                
                if let logo = merchantLogo {
                    Image(nsImage: logo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .clipShape(Circle())
                } else if let symbol = sfSymbol {
                    Image(systemName: symbol)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                } else {
                    Text(merchantName.prefix(2).uppercased())
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            // Merchant Info
            VStack(alignment: .leading, spacing: 2) {
                Text(merchantName)
                    .font(.headline)
                
                Text("\(transactionCount) transaction\(transactionCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Edit button
            Button("Edit Logo") {
                onEditLogo()
            }
            .buttonStyle(.borderless)
            .foregroundColor(.accentColor)
        }
        .padding(.vertical, 4)
    }
    
    private var merchantLogoData: MerchantLogoData? {
        dataManager.getMerchantLogo(for: merchantName)
    }
    
    private var merchantLogo: NSImage? {
        guard let logoData = merchantLogoData,
              let imageData = logoData.imageData else { return nil }
        return NSImage(data: imageData)
    }
    
    private var sfSymbol: String? {
        merchantLogoData?.sfSymbol
    }
    
    private var logoBackgroundColor: Color {
        merchantLogoData?.backgroundColor ?? .blue
    }
}

// Extension to show merchant logos in transaction rows
struct MerchantLogoView: View {
    let merchantName: String
    @EnvironmentObject var dataManager: FinancialDataManager
    
    var body: some View {
        if let logoData = dataManager.getMerchantLogo(for: merchantName) {
            if let symbol = logoData.sfSymbol {
                Image(systemName: symbol)
                    .foregroundColor(Color(logoData.color ?? "accentColor") ?? .accentColor)
            } else if let imageData = logoData.imageData,
                      let nsImage = NSImage(data: imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
            } else {
                defaultLogo
            }
        } else {
            defaultLogo
        }
    }
    
    private var defaultLogo: some View {
        Text(merchantName.prefix(1).uppercased())
            .font(.caption.bold())
            .foregroundColor(.secondary)
    }
}