import SwiftUI
import CoreData

/// Core Data setup and app initialization
@MainActor
public class CoreDataAppSetup: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public private(set) var isInitialized = false
    @Published public private(set) var initializationError: Error?
    @Published public private(set) var migrationInProgress = false
    @Published public private(set) var migrationProgress: Double = 0.0
    
    // MARK: - Dependencies
    
    private let coreDataManager = CoreDataManager.shared
    private let migrationService = CoreDataMigrationService.shared
    
    // MARK: - Initialization
    
    public init() {
        setupCoreData()
    }
    
    // MARK: - Setup Methods
    
    /// Initialize Core Data and handle migration if needed
    private func setupCoreData() {
        Task {
            do {
                AppLogger.shared.info("🚀 Initializing Core Data setup...", category: "CoreDataSetup")
                
                // Wait for Core Data to initialize
                while !coreDataManager.isInitialized {
                    try await Task.sleep(nanoseconds: 100_000_000) // 100ms
                }
                
                AppLogger.shared.info("✅ Core Data stack initialized", category: "CoreDataSetup")
                
                // Check if migration is needed
                if await migrationService.needsMigration() {
                    AppLogger.shared.info("🔄 Migration needed, starting migration process...", category: "CoreDataSetup")
                    await performMigration()
                } else {
                    AppLogger.shared.info("✅ No migration needed", category: "CoreDataSetup")
                }
                
                isInitialized = true
                
                AppLogger.shared.info("🎉 Core Data setup completed successfully", category: "CoreDataSetup")
                
            } catch {
                AppLogger.shared.error("❌ Core Data setup failed: \(error)", category: "CoreDataSetup")
                initializationError = error
            }
        }
    }
    
    /// Perform migration with progress tracking
    private func performMigration() async {
        migrationInProgress = true
        
        // Observe migration progress
        let progressCancellable = migrationService.$migrationProgress
            .receive(on: DispatchQueue.main)
            .assign(to: \.migrationProgress, on: self)
        
        defer {
            progressCancellable.cancel()
            migrationInProgress = false
        }
        
        do {
            try await migrationService.performMigration()
            AppLogger.shared.info("🎉 Migration completed successfully", category: "CoreDataSetup")
        } catch {
            AppLogger.shared.error("❌ Migration failed: \(error)", category: "CoreDataSetup")
            initializationError = error
        }
    }
    
    // MARK: - Public Interface
    
    /// Create enhanced financial data manager after initialization
    public func createFinancialDataManager() -> EnhancedFinancialDataManager {
        return EnhancedFinancialDataManager()
    }
    
    /// Get Core Data repository
    public func createCoreDataRepository() -> CoreDataRepository {
        return CoreDataRepository(coreDataManager: coreDataManager)
    }
}

/// SwiftUI modifier for Core Data initialization
struct CoreDataSetupModifier: ViewModifier {
    @StateObject private var setup = CoreDataAppSetup()
    @State private var showingMigrationSheet = false
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if !setup.isInitialized {
                    CoreDataInitializationView(setup: setup)
                }
            }
            .sheet(isPresented: .constant(setup.migrationInProgress)) {
                MigrationProgressView(setup: setup)
                    .interactiveDismissDisabled()
            }
            .environmentObject(setup)
    }
}

/// Loading view during Core Data initialization
struct CoreDataInitializationView: View {
    let setup: CoreDataAppSetup
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                
                VStack(spacing: 8) {
                    Text("Initializing LedgerPro")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if let error = setup.initializationError {
                        Text("Error: \(error.localizedDescription)")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else {
                        Text("Setting up Core Data...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.8))
            )
        }
    }
}

/// Migration progress view
struct MigrationProgressView: View {
    let setup: CoreDataAppSetup
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "externaldrive.fill.badge.timemachine")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("Upgrading Data Storage")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Migrating your data to a more efficient storage system")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                ProgressView(value: setup.migrationProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                
                HStack {
                    Text("\(Int(setup.migrationProgress * 100))% Complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Please wait...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(spacing: 4) {
                Text("⚡ Improved Performance")
                Text("🔍 Advanced Search")
                Text("📊 Better Analytics")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(40)
        .frame(width: 400)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(16)
    }
}

/// SwiftUI extension for easy Core Data setup
extension View {
    func withCoreDataSetup() -> some View {
        modifier(CoreDataSetupModifier())
    }
}

// MARK: - Shared Migration Service

extension CoreDataMigrationService {
    static let shared = CoreDataMigrationService()
}