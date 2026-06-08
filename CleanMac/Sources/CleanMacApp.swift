import SwiftUI
import AppKit  // Required for NSApp, NSImage, NSWorkspace

@main
struct CleanMacApp: App {
    @StateObject private var appState = AppState()
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = true
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    // TODO: Implement update check
                }
                Divider()
                Button("Refresh System Info") {
                    appState.updateSystemInfo()
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
        
        // Menu Bar Extra
        MenuBarExtra("CleanMac", systemImage: "leaf.fill", isInserted: $showMenuBarIcon) {
            MenuBarView()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.window)
        
        // Settings Window
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}

// MARK: - App Delegate for proper macOS integration
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure the app appears in Dock
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false  // Keep running for menu bar
    }
}

// MARK: - App State with Live Updates
class AppState: ObservableObject {
    @Published var selectedModule: CleaningModule = .smartScan
    @Published var isScanning: Bool = false
    @Published var scanProgress: Double = 0.0
    @Published var totalJunkSize: Int64 = 0
    @Published var lastScanDate: Date?
    
    // System Info
    @Published var usedDiskSpace: Int64 = 0
    @Published var freeDiskSpace: Int64 = 0
    @Published var totalDiskSpace: Int64 = 0
    @Published var memoryUsage: Double = 0.0
    @Published var cpuUsage: Double = 0.0
    
    private var systemInfoTimer: Timer?
    
    init() {
        updateSystemInfo()
        startSystemInfoTimer()
    }
    
    deinit {
        systemInfoTimer?.invalidate()
    }
    
    private func startSystemInfoTimer() {
        // Update system info every 30 seconds
        systemInfoTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateSystemInfo()
            }
        }
    }
    func updateSystemInfo() {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        do {
            let resourceValues = try homeDirectory.resourceValues(forKeys: [
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityKey
            ])
            
            if let total = resourceValues.volumeTotalCapacity,
               let available = resourceValues.volumeAvailableCapacity {
                totalDiskSpace = Int64(total)
                freeDiskSpace = Int64(available)
                usedDiskSpace = totalDiskSpace - freeDiskSpace
            }
        } catch {
            // Fallback to older method
            if let attributes = try? FileManager.default.attributesOfFileSystem(forPath: "/") {
                totalDiskSpace = (attributes[.systemSize] as? Int64) ?? 0
                freeDiskSpace = (attributes[.systemFreeSize] as? Int64) ?? 0
                usedDiskSpace = totalDiskSpace - freeDiskSpace
            }
        }
        
        // Get memory usage
        updateMemoryUsage()
    }
    
    private func updateMemoryUsage() {
        // Report system-wide memory pressure, not this process's footprint.
        var pageSize: vm_size_t = 0
        host_page_size(mach_host_self(), &pageSize)

        var vmStats = vm_statistics64()
        var hostCount = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)

        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(hostCount)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &hostCount)
            }
        }
        
        if result == KERN_SUCCESS {
            let usedPages = Double(
                vmStats.active_count
                + vmStats.inactive_count
                + vmStats.wire_count
                + vmStats.compressor_page_count
            )
            let usedMemory = usedPages * Double(pageSize)
            let totalMemory = Double(ProcessInfo.processInfo.physicalMemory)
            memoryUsage = (usedMemory / totalMemory) * 100
        }
    }
}

// MARK: - Cleaning Modules
enum CleaningModule: String, CaseIterable, Identifiable {
    case smartScan = "Smart Scan"
    case systemJunk = "System Junk"
    case largeFiles = "Large Files"
    case duplicates = "Duplicates"
    case uninstaller = "Uninstaller"
    case privacy = "Privacy"
    case maintenance = "Maintenance"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .smartScan: return "sparkles"
        case .systemJunk: return "trash"
        case .largeFiles: return "doc.fill"
        case .duplicates: return "doc.on.doc"
        case .uninstaller: return "xmark.app"
        case .privacy: return "hand.raised.fill"
        case .maintenance: return "wrench.and.screwdriver"
        }
    }
    
    var color: Color {
        switch self {
        case .smartScan: return .blue
        case .systemJunk: return .orange
        case .largeFiles: return .purple
        case .duplicates: return .green
        case .uninstaller: return .red
        case .privacy: return .pink
        case .maintenance: return .cyan
        }
    }
    
    var description: String {
        switch self {
        case .smartScan: return "One-click cleanup and optimization"
        case .systemJunk: return "Clear cache, logs, and temporary files"
        case .largeFiles: return "Find and remove large files"
        case .duplicates: return "Find and remove duplicate files"
        case .uninstaller: return "Completely remove apps and leftovers"
        case .privacy: return "Clear browsing data and recent items"
        case .maintenance: return "Run system maintenance tasks"
        }
    }
}
