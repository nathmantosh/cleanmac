import SwiftUI
import AppKit

// MARK: - CleanMyMac-Style Colors
extension Color {
    static let cmPurpleDark = Color(red: 0.10, green: 0.04, blue: 0.18)
    static let cmPurpleLight = Color(red: 0.18, green: 0.11, blue: 0.31)
    static let cmPurpleMid = Color(red: 0.14, green: 0.07, blue: 0.24)
    static let cmAccentPink = Color(red: 0.85, green: 0.25, blue: 0.55)
    static let cmAccentGreen = Color(red: 0.25, green: 0.85, blue: 0.55)
    static let cmAccentOrange = Color(red: 0.95, green: 0.55, blue: 0.25)
    static let cmAccentBlue = Color(red: 0.35, green: 0.55, blue: 0.95)
    static let cmGlass = Color.white.opacity(0.08)
    static let cmGlassBorder = Color.white.opacity(0.12)
}

// MARK: - Glassmorphism Card Style
struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 16
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.cmGlass)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial.opacity(0.3))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.cmGlassBorder, lineWidth: 1)
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20, padding: CGFloat = 16) -> some View {
        self.modifier(GlassCard(cornerRadius: cornerRadius, padding: padding))
    }
}

// MARK: - Smart Care Card (CleanMyMac Style)
struct SmartCareCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconGradient: [Color]
    let hasReviewButton: Bool
    var reviewAction: (() -> Void)? = nil
    var action: (() -> Void)? = nil
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon area with gradient background
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: iconGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 100)
                
                Image(systemName: icon)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            
            // Title
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            // Subtitle
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
            
            // Review button if needed
            if hasReviewButton {
                Button {
                    reviewAction?()
                } label: {
                    Text("Review")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.2))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cmGlass)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isHovered ? Color.white.opacity(0.3) : Color.cmGlassBorder, lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .shadow(color: isHovered ? iconGradient[0].opacity(0.3) : .clear, radius: 12, x: 0, y: 6)
        .animation(.easeOut(duration: 0.2), value: isHovered)
        .onTapGesture {
            action?()
        }
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

// MARK: - Large Run Button
struct LargeRunButton: View {
    let isScanning: Bool
    let action: () -> Void
    @State private var isPulsing = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Glow
                Circle()
                    .fill(Color.cmAccentPink.opacity(0.4))
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)
                    .opacity(isPulsing ? 0.8 : 0.4)
                
                // Main button
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.cmAccentPink, .purple],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: .cmAccentPink.opacity(0.5), radius: 10, x: 0, y: 5)
                
                Text(isScanning ? "Stop" : "Run")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack(spacing: 0) {
            SidebarView()
            
            DetailView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 900, minHeight: 600)
        .background(
            LinearGradient(
                colors: [.cmPurpleDark, .cmPurpleMid, .cmPurpleLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

// MARK: - Icon-Only Sidebar (CleanMyMac Style)
struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    @State private var settingsHovered = false
    
    var usedPercentage: Double {
        guard appState.totalDiskSpace > 0 else { return 0 }
        return Double(appState.usedDiskSpace) / Double(appState.totalDiskSpace)
    }
    
    var settingsButtonContent: some View {
        ZStack {
            if settingsHovered {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 44, height: 44)
            }
            
            Image(systemName: "gearshape.fill")
                .font(.system(size: 18))
                .foregroundColor(settingsHovered ? .white : .white.opacity(0.5))
        }
        .frame(width: 44, height: 44)
    }

    private func openSettingsWindow() {
        // Use both selectors to support different macOS SwiftUI host behaviors.
        if NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil) {
            return
        }
        if NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil) {
            return
        }
        
        // Fail-safe fallback: Open a custom NSWindow containing SettingsView
        let windowName = "CleanMac Settings"
        if let existingWindow = NSApp.windows.first(where: { $0.title == windowName }) {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let settingsView = SettingsView().environmentObject(appState)
        let hostingController = NSHostingController(rootView: settingsView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 300),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = windowName
        window.contentViewController = hostingController
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // App Icon
            ZStack {
                Circle()
                    .fill(Color.cmAccentGreen.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .blur(radius: 15)
                
                Image(systemName: "leaf.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cmAccentGreen, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.top, 20)
            .padding(.bottom, 10)
            
            // Module Icons
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(CleaningModule.allCases) { module in
                        IconModuleButton(module: module)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Spacer()
            
            // Settings Button
            Button {
                openSettingsWindow()
            } label: {
                settingsButtonContent
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                settingsHovered = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            .help("Settings")
            .padding(.bottom, 8)
            
            // Disk usage mini indicator
            VStack(spacing: 4) {
                DiskMiniIndicator()
                Text("Disk: \(Int(usedPercentage * 100))%")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.bottom, 16)
        }
        .frame(width: 70)
        .background(
            LinearGradient(
                colors: [.cmPurpleDark, .cmPurpleMid],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - Icon Module Button
struct IconModuleButton: View {
    @EnvironmentObject var appState: AppState
    let module: CleaningModule
    @State private var isHovered = false
    
    var isSelected: Bool {
        appState.selectedModule == module
    }
    
    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                appState.selectedModule = module
            }
        } label: {
            HStack(spacing: 0) {
                // Left accent bar for selected state
                RoundedRectangle(cornerRadius: 2)
                    .fill(isSelected ? module.color : Color.clear)
                    .frame(width: 3, height: 30)
                    .padding(.leading, 2)
                
                Spacer()
                
                ZStack {
                    // Selection/hover background
                    if isSelected || isHovered {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? module.color.opacity(0.3) : Color.white.opacity(0.1))
                            .frame(width: 46, height: 46)
                    }
                    
                    // Glow for selected - enhanced
                    if isSelected {
                        Circle()
                            .fill(module.color.opacity(0.5))
                            .frame(width: 35, height: 35)
                            .blur(radius: 12)
                    }
                    
                    Image(systemName: module.icon)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(isSelected ? module.color : (isHovered ? .white.opacity(0.8) : .white.opacity(0.5)))
                        .scaleEffect(isHovered && !isSelected ? 1.1 : 1.0)
                        .animation(.easeOut(duration: 0.15), value: isHovered)
                }
                .frame(width: 50, height: 50)
                
                Spacer()
            }
            .frame(width: 70, height: 50)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .help(module.rawValue)
    }
}

// MARK: - Mini Disk Indicator
struct DiskMiniIndicator: View {
    @EnvironmentObject var appState: AppState
    
    var usedPercentage: Double {
        guard appState.totalDiskSpace > 0 else { return 0 }
        return Double(appState.usedDiskSpace) / Double(appState.totalDiskSpace)
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 3)
                .foregroundColor(.white.opacity(0.1))
            
            Circle()
                .trim(from: 0, to: usedPercentage)
                .stroke(
                    LinearGradient(
                        colors: usedPercentage > 0.85 ? [.cmAccentOrange, .red] : [.cmAccentGreen, .mint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 30, height: 30)
    }
}

// MARK: - Disk Space Indicator
struct DiskSpaceIndicator: View {
    @EnvironmentObject var appState: AppState
    
    var usedPercentage: Double {
        guard appState.totalDiskSpace > 0 else { return 0 }
        return Double(appState.usedDiskSpace) / Double(appState.totalDiskSpace)
    }
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(lineWidth: 6)
                    .foregroundColor(.white.opacity(0.1))
                
                Circle()
                    .trim(from: 0, to: usedPercentage)
                    .stroke(
                        LinearGradient(
                            colors: usedPercentage > 0.85 ? [.cmAccentOrange, .red] : [.cmAccentGreen, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: usedPercentage)
                
                VStack(spacing: 0) {
                    Text("\(Int(usedPercentage * 100))%")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Used")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .frame(width: 70, height: 70)
            
            HStack(spacing: 16) {
                VStack(alignment: .center, spacing: 2) {
                    Text(formatBytes(appState.freeDiskSpace))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.cmAccentGreen)
                    Text("Free")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }
                
                VStack(alignment: .center, spacing: 2) {
                    Text(formatBytes(appState.totalDiskSpace))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    Text("Total")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Module Button
struct ModuleButton: View {
    @EnvironmentObject var appState: AppState
    let module: CleaningModule
    @State private var isHovered = false
    
    var isSelected: Bool {
        appState.selectedModule == module
    }
    
    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                appState.selectedModule = module
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    // Glow for selected
                    if isSelected {
                        Circle()
                            .fill(module.color.opacity(0.4))
                            .frame(width: 36, height: 36)
                            .blur(radius: 8)
                    }
                    
                    Image(systemName: module.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(isSelected ? .white : module.color)
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isSelected ? module.color : module.color.opacity(0.2))
                        )
                }
                
                Text(module.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                
                Spacer()
                
                // Active dot indicator
                if isSelected {
                    Circle()
                        .fill(module.color)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.white.opacity(0.1) : (isHovered ? Color.white.opacity(0.05) : Color.clear))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Detail View
struct DetailView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(appState.selectedModule.rawValue)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(appState.selectedModule.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
            }
            .padding(24)
            
            // Content Area
            ScrollView {
                ModuleContentView(module: appState.selectedModule)
                    .padding(24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
}

// MARK: - Module Content Views
struct ModuleContentView: View {
    @EnvironmentObject var appState: AppState
    let module: CleaningModule
    
    var body: some View {
        switch module {
        case .smartScan:
            SmartScanView()
        case .systemJunk:
            SystemJunkView()
        case .largeFiles:
            LargeFilesView()
        case .duplicates:
            DuplicatesView()
        case .uninstaller:
            UninstallerView()
        case .privacy:
            PrivacyView()
        case .maintenance:
            MaintenanceView()
        }
    }
}

// MARK: - Smart Scan View (Real Implementation)
struct SmartScanView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var scanner = JunkScanner()
    @State private var showingCleanConfirm = false
    @State private var showingVerification = false
    @AppStorage("cleanSystemCache") private var cleanSystemCache = true
    @AppStorage("cleanUserCache") private var cleanUserCache = true
    @AppStorage("cleanLogs") private var cleanLogs = true
    @AppStorage("cleanDeveloperJunk") private var cleanDeveloperJunk = true
    @AppStorage("cleanDownloads") private var cleanDownloads = false
    @AppStorage("cleanTrash") private var cleanTrash = false

    static func configuredCategories(
        cleanSystemCache: Bool,
        cleanUserCache: Bool,
        cleanLogs: Bool,
        cleanDeveloperJunk: Bool,
        cleanDownloads: Bool,
        cleanTrash: Bool
    ) -> [JunkScanner.JunkCategory] {
        var categories: [JunkScanner.JunkCategory] = [.browserCache]

        if cleanUserCache {
            categories.append(.userCache)
        }
        if cleanSystemCache {
            categories.append(.systemCache)
        }
        if cleanLogs {
            categories.append(contentsOf: [.userLogs, .systemLogs])
        }
        if cleanDeveloperJunk {
            categories.append(.developerJunk)
        }
        if cleanDownloads {
            categories.append(.downloads)
        }
        if cleanTrash {
            categories.append(.trash)
        }

        return categories.isEmpty ? JunkScanner.JunkCategory.allCases : categories
    }

    private var smartScanCategories: [JunkScanner.JunkCategory] {
        Self.configuredCategories(
            cleanSystemCache: cleanSystemCache,
            cleanUserCache: cleanUserCache,
            cleanLogs: cleanLogs,
            cleanDeveloperJunk: cleanDeveloperJunk,
            cleanDownloads: cleanDownloads,
            cleanTrash: cleanTrash
        )
    }
    
    var body: some View {
        VStack(spacing: 24) {
            if scanner.isScanning {
                // Scanning Animation
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 8)
                            .opacity(0.2)
                            .frame(width: 150, height: 150)
                        
                        Circle()
                            .trim(from: 0, to: scanner.progress)
                            .stroke(
                                LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 150, height: 150)
                            .rotationEffect(.degrees(-90))
                        
                        VStack {
                            Text("\(Int(scanner.progress * 100))%")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text(scanner.currentCategory)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    
                    Text("Scanning your Mac...")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, minHeight: 300)
            } else if !scanner.scanResults.isEmpty {
                // Results View
                VStack(spacing: 20) {
                    // Header with actions - Glass Style
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.cmAccentGreen)
                        
                        VStack(alignment: .leading) {
                            Text("Scan Complete!")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("\(scanner.formatBytes(scanner.totalJunkSize)) of junk found")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        // Export Report Button
                        Button {
                            if let url = scanner.saveReportToDesktop() {
                                NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
                            }
                        } label: {
                            HStack {
                                Image(systemName: "doc.text")
                                Text("Export Report")
                            }
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .help("Export detailed scan report to Desktop")
                        
                        // Verify Button
                        Button {
                            showingVerification = true
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.shield")
                                Text("Verify")
                            }
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.cmAccentOrange.opacity(0.3))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.cmAccentOrange, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .help("Verify scan accuracy")
                        
                        // Clean Up Button - Gradient
                        Button {
                            showingCleanConfirm = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Clean Up")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(LinearGradient(
                                        colors: [.cmAccentPink, .cmAccentPink.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ))
                            )
                            .shadow(color: .cmAccentPink.opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.cmAccentGreen.opacity(0.15))
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.cmGlass)
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.cmAccentGreen.opacity(0.3), lineWidth: 1)
                    )
                    
                    // Verification Sheet
                    .sheet(isPresented: $showingVerification) {
                        VStack(spacing: 16) {
                            HStack {
                                Text("🔍 Verification Report")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Spacer()
                                Button("Done") {
                                    showingVerification = false
                                }
                            }
                            .padding(.bottom)
                            
                            ScrollView {
                                VStack(alignment: .leading, spacing: 12) {
                                    ForEach(scanner.scanResults) { result in
                                        VerificationRow(scanner: scanner, category: result.category)
                                    }
                                }
                            }
                            
                            Divider()
                            
                            Text("✓ = Sizes match within 5%  ✗ = Mismatch detected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(width: 500, height: 400)
                    }
                    
                    // Results List with Bindings
                    ForEach($scanner.scanResults) { $result in
                        JunkCategoryRow(scanner: scanner, result: $result)
                    }
                }
                .alert("Clean Up", isPresented: $showingCleanConfirm) {
                    Button("Cancel", role: .cancel) {}
                    Button("Clean", role: .destructive) {
                        Task {
                            let cleaned = await scanner.clean()
                            appState.lastScanDate = Date()
                            appState.updateSystemInfo()
                            print("Cleaned: \(scanner.formatBytes(cleaned))")
                        }
                    }
                } message: {
                    Text("This will permanently delete \(scanner.formatBytes(scanner.selectedSize)) of junk files. This cannot be undone.")
                }
            } else {
                // Smart Care Dashboard (CleanMyMac Style)
                VStack(spacing: 24) {
                    // Welcome message
                    VStack(spacing: 8) {
                        Text("Welcome to CleanMac")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Start with a quick and extensive scan of your Mac")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.top, 20)
                    
                    // Cards Grid (3 + 2 layout)
                    VStack(spacing: 16) {
                        // Top row - 3 cards
                        HStack(spacing: 16) {
                            SmartCareCard(
                                title: "Cleanup",
                                subtitle: "Remove junk files",
                                icon: "trash.circle.fill",
                                iconGradient: [.cmAccentPink, .purple],
                                hasReviewButton: false,
                                action: {
                                    withAnimation {
                                        appState.selectedModule = .systemJunk
                                    }
                                }
                            )
                            
                            SmartCareCard(
                                title: "Protection",
                                subtitle: "Scan for threats",
                                icon: "shield.lefthalf.filled",
                                iconGradient: [.cmAccentGreen, .teal],
                                hasReviewButton: false,
                                action: {
                                    withAnimation {
                                        appState.selectedModule = .privacy
                                    }
                                }
                            )
                            
                            SmartCareCard(
                                title: "Performance",
                                subtitle: "Optimize your Mac",
                                icon: "bolt.circle.fill",
                                iconGradient: [.cmAccentBlue, .indigo],
                                hasReviewButton: false,
                                action: {
                                    withAnimation {
                                        appState.selectedModule = .maintenance
                                    }
                                }
                            )
                        }
                        
                        // Bottom row - 2 cards
                        HStack(spacing: 16) {
                            SmartCareCard(
                                title: "Applications",
                                subtitle: "Manage apps",
                                icon: "square.grid.2x2.fill",
                                iconGradient: [.yellow, .orange],
                                hasReviewButton: false,
                                action: {
                                    withAnimation {
                                        appState.selectedModule = .uninstaller
                                    }
                                }
                            )
                            
                            SmartCareCard(
                                title: "My Clutter",
                                subtitle: "Find duplicates",
                                icon: "doc.on.doc.fill",
                                iconGradient: [.cyan, .blue],
                                hasReviewButton: false,
                                action: {
                                    withAnimation {
                                        appState.selectedModule = .duplicates
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Large RUN Button
                    LargeRunButton(isScanning: false) {
                        Task {
                            await scanner.scan(categories: smartScanCategories)
                            appState.lastScanDate = Date()
                        }
                    }
                    .padding(.bottom, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// MARK: - Verification Row
struct VerificationRow: View {
    let scanner: JunkScanner
    let category: JunkScanner.JunkCategory
    @State private var isVerifying = false
    @State private var verification: (reported: Int64, actual: Int64, match: Bool)?
    
    var body: some View {
        HStack {
            Image(systemName: category.icon)
                .foregroundColor(.orange)
                .frame(width: 24)
            
            Text(category.rawValue)
                .fontWeight(.medium)
            
            Spacer()
            
            if isVerifying {
                ProgressView()
                    .scaleEffect(0.7)
            } else if let v = verification {
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("Reported:")
                            .foregroundColor(.secondary)
                        Text(formatBytes(v.reported))
                    }
                    HStack(spacing: 4) {
                        Text("Actual:")
                            .foregroundColor(.secondary)
                        Text(formatBytes(v.actual))
                    }
                }
                .font(.caption)
                
                Image(systemName: v.match ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(v.match ? .green : .red)
                    .font(.system(size: 20))
            } else {
                Button("Check") {
                    isVerifying = true
                    DispatchQueue.global().async {
                        let result = scanner.verifyCategory(category)
                        DispatchQueue.main.async {
                            verification = result
                            isVerifying = false
                        }
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
    
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Junk Category Row (Enhanced with Selection)
struct JunkCategoryRow: View {
    @ObservedObject var scanner: JunkScanner
    @Binding var result: JunkScanner.ScanResult
    @State private var isExpanded = false
    @State private var searchText = ""
    @State private var isCheckboxHovered = false
    @State private var isFolderHovered = false
    @State private var isChevronHovered = false
    
    var selectedFilesCount: Int {
        result.files.filter(\.isSelected).count
    }
    
    var selectedSize: Int64 {
        result.files.filter(\.isSelected).reduce(0) { $0 + $1.size }
    }
    
    var filteredFiles: [JunkScanner.FileInfo] {
        if searchText.isEmpty {
            return result.files
        }
        return result.files.filter { 
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.path.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Category Header - Glass Style
            HStack {
                // Category Checkbox
                Button {
                    scanner.toggleCategorySelection(result.category)
                } label: {
                    Image(systemName: result.isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(result.isSelected ? .cmAccentGreen : .white.opacity(0.4))
                        .font(.system(size: 20))
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    isCheckboxHovered = hovering
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                
                // Clicking anywhere on the middle toggles expansion
                HStack(spacing: 12) {
                    Image(systemName: result.category.icon)
                        .foregroundColor(.cmAccentOrange)
                        .frame(width: 24)
                    
                    Text(result.category.rawValue)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    // Safety Badge
                    safetyBadge
                    
                    Spacer()
                    
                    // Selected info
                    if selectedFilesCount > 0 && selectedFilesCount < result.files.count {
                        Text("\(selectedFilesCount)/\(result.files.count)")
                            .font(.caption)
                            .foregroundColor(.cmAccentBlue)
                    }
                    
                    Text(formatBytes(result.totalSize))
                        .foregroundColor(.cmAccentGreen)
                        .fontWeight(.medium)
                    
                    Text("\(result.files.count) files")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.white.opacity(0.1)))
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                
                // Open in Finder
                Button {
                    if let firstPath = result.category.paths.first {
                        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: firstPath)
                    }
                } label: {
                    Image(systemName: "folder")
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
                .help("Open in Finder")
                .onHover { hovering in
                    isFolderHovered = hovering
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                
                // Expand Button
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(8)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    isChevronHovered = hovering
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cmGlass)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(result.isSelected ? Color.cmAccentGreen.opacity(0.5) : Color.cmGlassBorder, lineWidth: 1)
            )
            
            // Expanded File List
            if isExpanded {
                VStack(spacing: 1) {
                    // Select All / Deselect All
                    HStack {
                        Button("Select All") {
                            toggleAllFiles(selected: true)
                        }
                        .font(.caption)
                        .foregroundColor(.cmAccentBlue)
                        
                        Text("•")
                            .foregroundColor(.white.opacity(0.3))
                        
                        Button("Deselect All") {
                            toggleAllFiles(selected: false)
                        }
                        .font(.caption)
                        .foregroundColor(.cmAccentPink)
                        
                        Spacer()
                        
                        Text("Selected: \(formatBytes(selectedSize))")
                            .font(.caption)
                            .foregroundColor(.cmAccentGreen)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.cmGlass)
                    
                    // Search Bar - Visible with pill background
                    HStack(spacing: 12) {
                        // Search input with pill background
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white.opacity(0.7))
                            
                            TextField("Search files...", text: $searchText)
                                .textFieldStyle(.plain)
                                .foregroundColor(.white)
                            
                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        
                        if !searchText.isEmpty {
                            Text("\(filteredFiles.count) matches")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            
                            // Select/Deselect filtered
                            Button("Select Matches") {
                                selectFilteredFiles(selected: true)
                            }
                            .font(.caption2)
                            .foregroundColor(.cmAccentGreen)
                            
                            Button("Deselect") {
                                selectFilteredFiles(selected: false)
                            }
                            .font(.caption2)
                            .foregroundColor(.cmAccentPink)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.cmGlass)
                    
                    // File List (scrollable if many)
                    ScrollView {
                        LazyVStack(spacing: 1) {
                            ForEach(filteredFiles) { file in
                                if let index = result.files.firstIndex(where: { $0.id == file.id }) {
                                    FileRowView(file: $result.files[index]) {
                                        // Update category selection based on file selections
                                        result.isSelected = result.files.allSatisfy(\.isSelected)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                    
                    // Show message if no matches
                    if !searchText.isEmpty && filteredFiles.isEmpty {
                        Text("No files match '\(searchText)'")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .background(Color.cmGlass.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // MARK: - Safety Badge
    var safetyBadge: some View {
        let safety = result.category.safetyLevel
        let color: Color = {
            switch safety {
            case .safe: return .green
            case .caution: return .orange
            case .warning: return .red
            }
        }()
        
        return HStack(spacing: 4) {
            Image(systemName: safety.icon)
                .foregroundColor(color)
                .font(.system(size: 12))
            
            Text(safety.rawValue)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
        .help(result.category.safetyDescription)
    }
    
    // MARK: - Toggle All Files Helper
    func toggleAllFiles(selected: Bool) {
        result.isSelected = selected
        
        if result.files.count < 1000 {
            // Small file count - update directly
            for i in result.files.indices {
                result.files[i].isSelected = selected
            }
        } else {
            // Large file count - batch update in background
            DispatchQueue.global(qos: .userInteractive).async {
                var updatedFiles = result.files
                for i in updatedFiles.indices {
                    updatedFiles[i].isSelected = selected
                }
                DispatchQueue.main.async {
                    result.files = updatedFiles
                }
            }
        }
    }
    
    // MARK: - Select Filtered Files
    func selectFilteredFiles(selected: Bool) {
        let filteredIDs = Set(filteredFiles.map { $0.id })
        
        if filteredFiles.count < 1000 {
            for i in result.files.indices {
                if filteredIDs.contains(result.files[i].id) {
                    result.files[i].isSelected = selected
                }
            }
        } else {
            DispatchQueue.global(qos: .userInteractive).async {
                var updatedFiles = result.files
                for i in updatedFiles.indices {
                    if filteredIDs.contains(updatedFiles[i].id) {
                        updatedFiles[i].isSelected = selected
                    }
                }
                DispatchQueue.main.async {
                    result.files = updatedFiles
                }
            }
        }
        
        // Update category selection based on total selection
        let allSelected = result.files.allSatisfy(\.isSelected)
        result.isSelected = allSelected
    }
    
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - File Row View
struct FileRowView: View {
    @Binding var file: JunkScanner.FileInfo
    let onToggle: () -> Void
    @State private var isHovering = false
    @State private var isCheckboxHovered = false
    @State private var isFinderHovered = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Checkbox
            Button {
                file.isSelected.toggle()
                onToggle()
            } label: {
                Image(systemName: file.isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(file.isSelected ? .cmAccentGreen : .white.opacity(0.4))
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isCheckboxHovered = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            
            // File icon
            Image(systemName: "doc")
                .foregroundColor(.cmAccentOrange)
                .frame(width: 16)
            
            // File name
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(file.path)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Size
            Text(formatBytes(file.size))
                .font(.caption)
                .foregroundColor(.cmAccentGreen)
                .frame(width: 70, alignment: .trailing)
            
            // Open in Finder button (shows on hover)
            Button {
                NSWorkspace.shared.selectFile(file.path, inFileViewerRootedAtPath: "")
            } label: {
                Image(systemName: "folder")
                    .foregroundColor(.cmAccentBlue)
            }
            .buttonStyle(.plain)
            .opacity(isHovering ? 1 : 0.3)
            .help("Show in Finder")
            .onHover { hovering in
                isFinderHovered = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(isHovering ? Color.white.opacity(0.08) : Color.clear)
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - System Junk View (Real Implementation)
struct SystemJunkView: View {
    @StateObject private var scanner = JunkScanner()
    @State private var selectedCategories: Set<JunkScanner.JunkCategory> = Set(JunkScanner.JunkCategory.allCases)
    
    var body: some View {
        VStack(spacing: 20) {
            if scanner.isScanning {
                ProgressView("Scanning \(scanner.currentCategory)...")
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if !scanner.scanResults.isEmpty {
                // Results
                ForEach($scanner.scanResults) { $result in
                    JunkCategoryRow(scanner: scanner, result: $result)
                }
                
                HStack {
                    Text("Total: \(scanner.formatBytes(scanner.totalJunkSize))")
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button("Clean Selected") {
                        Task {
                            await scanner.clean()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.top)
            } else {
                // Category Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select categories to scan:")
                        .font(.headline)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(JunkScanner.JunkCategory.allCases, id: \.rawValue) { category in
                            CategoryToggle(
                                category: category,
                                isSelected: selectedCategories.contains(category)
                            ) {
                                if selectedCategories.contains(category) {
                                    selectedCategories.remove(category)
                                } else {
                                    selectedCategories.insert(category)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
                
                Button {
                    Task {
                        await scanner.scan(categories: Array(selectedCategories))
                    }
                } label: {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Scan System Junk")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.orange)
                    )
                }
                .buttonStyle(.plain)
                .disabled(selectedCategories.isEmpty)
            }
        }
    }
}

struct CategoryToggle: View {
    let category: JunkScanner.JunkCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: category.icon)
                    .frame(width: 24)
                Text(category.rawValue)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.green : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Large Files View (Real Implementation)
struct LargeFilesView: View {
    @StateObject private var analyzer = FileAnalyzer()
    @State private var sortBySize = true
    
    var body: some View {
        VStack(spacing: 20) {
            if analyzer.isScanning {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Scanning...")
                        .foregroundColor(.secondary)
                    Text(analyzer.currentPath)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else if !analyzer.largeFiles.isEmpty {
                // Header
                HStack {
                    Text("\(analyzer.largeFiles.count) large files found")
                        .font(.headline)
                    
                    Spacer()
                    
                    let selectedSize = analyzer.largeFiles.filter(\.isSelected).reduce(0) { $0 + $1.size }
                    if selectedSize > 0 {
                        Button("Delete Selected (\(analyzer.formatBytes(selectedSize)))") {
                            Task {
                                await analyzer.deleteSelectedLargeFiles()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                }
                
                // File List
                List {
                    ForEach(Array(analyzer.largeFiles.enumerated()), id: \.element.id) { index, file in
                        LargeFileRow(file: file) {
                            analyzer.largeFiles[index].isSelected.toggle()
                        }
                    }
                }
                .listStyle(.inset)
            } else {
                // Initial
                VStack(spacing: 20) {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.purple)
                    
                    Text("Large Files")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Find files larger than 50MB taking up space on your Mac")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button {
                        Task {
                            await analyzer.scanLargeFiles()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Find Large Files")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.purple)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, minHeight: 300)
            }
        }
    }
}

struct LargeFileRow: View {
    let file: FileAnalyzer.LargeFile
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: file.isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(file.isSelected ? .blue : .gray)
            }
            .buttonStyle(.plain)
            
            Image(systemName: file.fileType.icon)
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading) {
                Text(file.name)
                    .lineLimit(1)
                Text(file.path)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(file.fileType.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.gray.opacity(0.2)))
            
            Text(formatBytes(file.size))
                .fontWeight(.medium)
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
    
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Duplicates View (Real Implementation)
struct DuplicatesView: View {
    @StateObject private var analyzer = FileAnalyzer()
    
    var totalWasted: Int64 {
        analyzer.duplicateGroups.reduce(0) { $0 + $1.wastedSpace }
    }

    var selectedDuplicateSize: Int64 {
        analyzer.duplicateGroups.reduce(0) { total, group in
            let selectedCount = group.files.filter { $0.isSelected && !$0.isOriginal }.count
            return total + (group.size * Int64(selectedCount))
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            if analyzer.isScanning {
                VStack(spacing: 12) {
                    ProgressView(value: analyzer.progress) {
                        Text("Scanning for duplicates...")
                    }
                    .frame(width: 300)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else if !analyzer.duplicateGroups.isEmpty {
                // Header
                HStack {
                    Text("\(analyzer.duplicateGroups.count) duplicate groups")
                        .font(.headline)
                    
                    Text("(\(formatBytes(totalWasted)) can be freed)")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Delete Selected (\(formatBytes(selectedDuplicateSize)))") {
                        Task {
                            await analyzer.deleteSelectedDuplicates()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(selectedDuplicateSize == 0)
                }
                
                // Groups List
                List {
                    ForEach($analyzer.duplicateGroups) { $group in
                        DuplicateGroupRow(group: $group)
                    }
                }
                .listStyle(.inset)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    
                    Text("Duplicate Finder")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Find duplicate files wasting space on your Mac")
                        .foregroundColor(.secondary)
                    
                    Button {
                        Task {
                            await analyzer.scanDuplicates()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Find Duplicates")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.green)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, minHeight: 300)
            }
        }
    }
    
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct DuplicateGroupRow: View {
    @Binding var group: FileAnalyzer.DuplicateGroup
    @State private var isExpanded = false

    var selectedDuplicatesCount: Int {
        group.files.filter { $0.isSelected && !$0.isOriginal }.count
    }

    var selectedWastedSpace: Int64 {
        group.size * Int64(selectedDuplicatesCount)
    }
    
    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach($group.files) { $file in
                HStack {
                    if file.isOriginal {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Button {
                            file.isSelected.toggle()
                        } label: {
                            Image(systemName: file.isSelected ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(file.isSelected ? .blue : .gray)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Text(file.name)
                        .lineLimit(1)
                    
                    if file.isOriginal {
                        Text("Keep")
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.green.opacity(0.2)))
                    } else if file.isSelected {
                        Text("Delete")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.blue.opacity(0.2)))
                    }
                    
                    Spacer()
                    
                    Text(file.path)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .padding(.leading, 24)
            }
        } label: {
            HStack {
                Text("\(group.files.count) files")
                    .fontWeight(.medium)
                
                Spacer()
                
                if selectedDuplicatesCount > 0 {
                    Text("\(selectedDuplicatesCount) selected")
                        .font(.caption)
                        .foregroundColor(.blue)
                }

                Text(formatBytes(group.size))
                    .foregroundColor(.secondary)
                
                Text("Wasted: \(formatBytes(selectedDuplicatesCount > 0 ? selectedWastedSpace : group.wastedSpace))")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }
    
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Uninstaller View (Real Implementation)
struct UninstallerView: View {
    @StateObject private var appManager = AppManager()
    @State private var searchText = ""
    @State private var selectedApp: AppManager.InstalledApp?
    @State private var showingUninstallConfirm = false
    @State private var leftovers: [AppManager.AppLeftover] = []
    @State private var activeTab = 0 // 0 = Apps, 1 = Leftovers
    
    var filteredApps: [AppManager.InstalledApp] {
        if searchText.isEmpty {
            return appManager.installedApps
        }
        return appManager.installedApps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var totalLeftoverSize: Int64 {
        appManager.orphanedLeftovers.filter(\.isSelected).reduce(0) { $0 + $1.size }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if appManager.isLoading {
                ProgressView("Loading applications...")
                    .frame(maxWidth: .infinity, minHeight: 300)
            } else if appManager.installedApps.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "xmark.app")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    
                    Text("App Uninstaller")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Completely remove apps and their leftover files")
                        .foregroundColor(.secondary)
                    
                    ProgressView("Loading applications...")
                        .padding(.top)
                }
                .frame(maxWidth: .infinity, minHeight: 300)
                .onAppear {
                    Task {
                        await appManager.loadInstalledApps()
                    }
                }
            } else {
                // Tab Picker
                Picker("", selection: $activeTab) {
                    Text("Apps").tag(0)
                    Text("Leftovers").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.bottom, 8)
                
                if activeTab == 0 {
                    // Apps Tab - Search Header
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search apps...", text: $searchText)
                            .textFieldStyle(.plain)
                        
                        Spacer()
                        
                        Text("\(appManager.installedApps.count) apps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(nsColor: .controlBackgroundColor))
                    )
                    .padding(.bottom)
                
                // App List
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(filteredApps) { app in
                            AppRowButton(app: app, isSelected: selectedApp?.id == app.id) {
                                // Toggle selection - click same app to deselect
                                if selectedApp?.id == app.id {
                                    selectedApp = nil
                                } else {
                                    selectedApp = app
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .frame(minHeight: 200)
                
                // Selected App Actions
                if let app = selectedApp {
                    Divider()
                    
                    HStack {
                        if let icon = app.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 48, height: 48)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(app.name)
                                .fontWeight(.bold)
                            Text(appManager.formatBytes(app.size))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Find Leftovers") {
                            Task {
                                leftovers = await appManager.findLeftovers(for: app)
                            }
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Uninstall") {
                            showingUninstallConfirm = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                }
                } // End of activeTab == 0
                
                // Leftovers Tab
                if activeTab == 1 {
                    if appManager.isScannningLeftovers {
                        ProgressView("Scanning for orphaned leftovers...")
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if appManager.orphanedLeftovers.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "doc.badge.gearshape")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                            
                            Text("Find Orphaned Leftovers")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Scan for files left behind by uninstalled apps")
                                .foregroundColor(.secondary)
                            
                            Button("Scan for Leftovers") {
                                Task {
                                    await appManager.scanForOrphanedLeftovers()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        // Leftovers Header
                        HStack {
                            Text("\(appManager.orphanedLeftovers.count) orphaned items")
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text("Total: \(appManager.formatBytes(totalLeftoverSize))")
                                .foregroundColor(.secondary)
                            
                            Button("Rescan") {
                                Task {
                                    await appManager.scanForOrphanedLeftovers()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.bottom, 8)
                        
                        // Leftovers List
                        ScrollView {
                            LazyVStack(spacing: 4) {
                                ForEach(Array(appManager.orphanedLeftovers.indices), id: \.self) { index in
                                    LeftoverRow(leftover: $appManager.orphanedLeftovers[index])
                                }
                            }
                        }
                        .frame(minHeight: 200)
                        
                        // Clean Button
                        HStack {
                            Button("Select All") {
                                for i in appManager.orphanedLeftovers.indices {
                                    appManager.orphanedLeftovers[i].isSelected = true
                                }
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Deselect All") {
                                for i in appManager.orphanedLeftovers.indices {
                                    appManager.orphanedLeftovers[i].isSelected = false
                                }
                            }
                            .buttonStyle(.bordered)
                            
                            Spacer()
                            
                            Button("Clean Selected") {
                                Task {
                                    let cleaned = await appManager.cleanOrphanedLeftovers()
                                    print("Cleaned \(appManager.formatBytes(cleaned)) of leftovers")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            .disabled(totalLeftoverSize == 0)
                        }
                        .padding(.top)
                    }
                }
            }
        }
        .alert("Uninstall \(selectedApp?.name ?? "")?", isPresented: $showingUninstallConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Uninstall", role: .destructive) {
                if let app = selectedApp {
                    Task {
                        _ = try? await appManager.uninstall(app: app)
                        selectedApp = nil
                    }
                }
            }
        } message: {
            Text("This will permanently remove the application and its associated files.")
        }
        .onAppear {
            if appManager.installedApps.isEmpty {
                Task {
                    await appManager.loadInstalledApps()
                }
            }
        }
    }
}

struct AppRow: View {
    let app: AppManager.InstalledApp
    
    var body: some View {
        HStack {
            if let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 32, height: 32)
            } else {
                Image(systemName: "app.fill")
                    .frame(width: 32, height: 32)
            }
            
            VStack(alignment: .leading) {
                Text(app.name)
                if let version = app.version {
                    Text("v\(version)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(formatBytes(app.size))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - App Row Button
struct AppRowButton: View {
    let app: AppManager.InstalledApp
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if let icon = app.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 32, height: 32)
                } else {
                    Image(systemName: "app.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 32)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(app.name)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    if let version = app.version {
                        Text("v\(version)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text(formatBytes(app.size))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Leftover Row
struct LeftoverRow: View {
    @Binding var leftover: AppManager.OrphanedLeftover
    
    var body: some View {
        HStack {
            Button {
                leftover.isSelected.toggle()
            } label: {
                Image(systemName: leftover.isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(leftover.isSelected ? .blue : .secondary)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(leftover.name)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(leftover.path)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(leftover.type)
                .font(.caption)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(0.2))
                )
                .foregroundColor(.orange)
            
            Text(formatBytes(leftover.size))
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(leftover.isSelected ? Color.blue.opacity(0.1) : Color(nsColor: .controlBackgroundColor))
        )
    }
    
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Privacy View
struct PrivacyView: View {
    @State private var cleanBrowserHistory = true
    @State private var cleanCookies = true
    @State private var cleanDownloads = false
    @State private var cleanRecentItems = true
    @State private var isCleaning = false
    @State private var cleanedItems = 0
    @State private var statusMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 50))
                .foregroundColor(.pink)
            
            Text("Privacy Cleaner")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Clear browsing data and recent activity")
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Browser History & Cache", isOn: $cleanBrowserHistory)
                Toggle("Cookies & Site Data", isOn: $cleanCookies)
                Toggle("Downloads History", isOn: $cleanDownloads)
                Toggle("Recent Items List", isOn: $cleanRecentItems)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .frame(maxWidth: 400)
            
            Button {
                cleanPrivacyData()
            } label: {
                HStack {
                    if isCleaning {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "sparkles")
                    }
                    Text(isCleaning ? "Cleaning..." : "Clean Privacy Data")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 200, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.pink)
                )
            }
            .buttonStyle(.plain)
            .disabled(isCleaning)
            
            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .foregroundColor(cleanedItems > 0 ? .green : .secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
    
    func cleanPrivacyData() {
        isCleaning = true
        cleanedItems = 0
        statusMessage = ""

        let shouldCleanBrowserHistory = cleanBrowserHistory
        let shouldCleanCookies = cleanCookies
        let shouldCleanDownloadsHistory = cleanDownloads
        let shouldCleanRecentItems = cleanRecentItems
        
        DispatchQueue.global().async {
            let fileManager = FileManager.default
            let home = fileManager.homeDirectoryForCurrentUser.path
            var count = 0

            func removeIfExists(_ path: String) -> Bool {
                guard fileManager.fileExists(atPath: path) else { return false }
                do {
                    try fileManager.removeItem(atPath: path)
                    return true
                } catch {
                    return false
                }
            }
            
            if shouldCleanBrowserHistory {
                let browserHistoryPaths = [
                    "\(home)/Library/Safari/History.db",
                    "\(home)/Library/Application Support/Google/Chrome/Default/History"
                ]

                for path in browserHistoryPaths where removeIfExists(path) {
                    count += 1
                }

                let firefoxProfilesPath = "\(home)/Library/Application Support/Firefox/Profiles"
                if let profiles = try? fileManager.contentsOfDirectory(atPath: firefoxProfilesPath) {
                    for profile in profiles {
                        let historyPath = "\(firefoxProfilesPath)/\(profile)/places.sqlite"
                        if removeIfExists(historyPath) {
                            count += 1
                        }
                    }
                }
            }
            
            if shouldCleanCookies {
                let cookiePaths = [
                    "\(home)/Library/Cookies/Cookies.binarycookies",
                    "\(home)/Library/Containers/com.apple.Safari/Data/Library/Cookies/Cookies.binarycookies",
                    "\(home)/Library/Application Support/Google/Chrome/Default/Cookies"
                ]

                for path in cookiePaths where removeIfExists(path) {
                    count += 1
                }
            }

            if shouldCleanDownloadsHistory {
                let downloadsHistoryPaths = [
                    "\(home)/Library/Safari/Downloads.plist",
                    "\(home)/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments/com.apple.finder.sfl2"
                ]

                for path in downloadsHistoryPaths where removeIfExists(path) {
                    count += 1
                }
            }

            if shouldCleanRecentItems {
                // Clear recent items via AppleScript
                let script = "tell application \"System Events\" to delete every recent document"
                if let appleScript = NSAppleScript(source: script) {
                    var error: NSDictionary?
                    appleScript.executeAndReturnError(&error)
                    if error == nil {
                        count += 1
                    }
                }
            }
            
            DispatchQueue.main.async {
                cleanedItems = count
                statusMessage = count > 0 ? "✓ Cleaned \(count) items" : "No matching privacy data found"
                isCleaning = false
            }
        }
    }
}

// MARK: - Maintenance View
struct MaintenanceView: View {
    @State private var runningTask: String?
    @State private var completedTasks: Set<String> = []
    @State private var taskOutput: [String: String] = [:]
    
    // Organized maintenance tasks with descriptions
    let systemTasks: [(name: String, command: String, icon: String, description: String)] = [
        ("Repair Disk Permissions", "diskutil resetUserPermissions / $(id -u)", "wrench", "Fixes file permission issues"),
        ("Verify Disk", "diskutil verifyVolume /", "internaldrive", "Checks disk for errors"),
        ("Flush DNS Cache", "dscacheutil -flushcache; killall -HUP mDNSResponder", "network", "Clears DNS cache, fixes connection issues"),
        ("Purge Memory", "purge", "memorychip", "Frees up inactive RAM"),
    ]
    
    let cacheTasks: [(name: String, command: String, icon: String, description: String)] = [
        ("Clear Font Cache", "atsutil databases -remove; atsutil server -shutdown; atsutil server -ping", "textformat", "Fixes font rendering issues"),
        ("Clear Thumbnail Cache", "rm -rf ~/Library/Caches/com.apple.QuickLookDaemon/*", "photo", "Clears Quick Look previews"),
        ("Clear Icon Cache", "rm -rf /Library/Caches/com.apple.iconservices.store 2>/dev/null; killall Finder", "app.badge", "Resets app icon cache"),
    ]
    
    let indexTasks: [(name: String, command: String, icon: String, description: String)] = [
        ("Rebuild Spotlight Index", "mdutil -E /", "magnifyingglass", "Rebuilds search index (takes time)"),
        ("Rebuild Launch Services", "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user", "square.grid.2x2", "Fixes 'Open With' menu"),
        ("Rebuild Mail Index", "rm ~/Library/Mail/V*/MailData/Envelope\\ Index*", "envelope", "Fixes Mail search issues"),
    ]
    
    let cleanupTasks: [(name: String, command: String, icon: String, description: String)] = [
        ("Empty Trash Securely", "rm -rf ~/.Trash/*", "trash", "Permanently empties Trash"),
        ("Clear Recent Items", "rm -rf ~/Library/Application\\ Support/com.apple.sharedfilelist/*", "clock.arrow.circlepath", "Clears recent files list"),
        ("Run Maintenance Scripts", "periodic daily weekly monthly", "terminal", "Runs macOS maintenance scripts"),
    ]
    
    var allTasks: [(name: String, command: String, icon: String, description: String)] {
        systemTasks + cacheTasks + indexTasks + cleanupTasks
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.system(size: 50))
                        .foregroundColor(.cyan)
                    
                    Text("System Maintenance")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Run maintenance scripts to optimize your Mac")
                        .foregroundColor(.secondary)
                    
                    if !completedTasks.isEmpty {
                        Text("✓ \(completedTasks.count) of \(allTasks.count) tasks completed")
                            .foregroundColor(.green)
                            .font(.subheadline)
                    }
                    
                    // Run All Button
                    Button {
                        runAllTasks()
                    } label: {
                        HStack {
                            Image(systemName: "bolt.fill")
                            Text("Run All Tasks")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.cyan)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(runningTask != nil)
                }
                .padding(.bottom)
                
                // System Tasks
                TaskSection(title: "System", icon: "gearshape.fill", color: .blue, tasks: systemTasks, runningTask: $runningTask, completedTasks: $completedTasks, runTask: runTask)
                
                // Cache Tasks
                TaskSection(title: "Cache", icon: "folder.fill", color: .orange, tasks: cacheTasks, runningTask: $runningTask, completedTasks: $completedTasks, runTask: runTask)
                
                // Index Tasks
                TaskSection(title: "Indexing", icon: "doc.text.magnifyingglass", color: .purple, tasks: indexTasks, runningTask: $runningTask, completedTasks: $completedTasks, runTask: runTask)
                
                // Cleanup Tasks
                TaskSection(title: "Cleanup", icon: "trash.fill", color: .red, tasks: cleanupTasks, runningTask: $runningTask, completedTasks: $completedTasks, runTask: runTask)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
    
    func runTask(name: String, command: String) {
        guard runningTask == nil else { return }
        runningTask = name
        
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.launchPath = "/bin/zsh"
            process.arguments = ["-c", command]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                
                DispatchQueue.main.async {
                    taskOutput[name] = output
                    completedTasks.insert(name)
                    runningTask = nil
                }
            } catch {
                DispatchQueue.main.async {
                    taskOutput[name] = "Error: \(error.localizedDescription)"
                    completedTasks.insert(name)
                    runningTask = nil
                }
            }
        }
    }
    
    func runAllTasks() {
        let tasks = allTasks.filter { !completedTasks.contains($0.name) }
        guard !tasks.isEmpty else { return }
        
        // Run tasks sequentially
        func runNext(index: Int) {
            guard index < tasks.count else { return }
            let task = tasks[index]
            runningTask = task.name
            
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.5) {
                let process = Process()
                process.launchPath = "/bin/zsh"
                process.arguments = ["-c", task.command]
                
                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = pipe
                
                do {
                    try process.run()
                    process.waitUntilExit()
                } catch {
                    // Continue anyway
                }
                
                DispatchQueue.main.async {
                    completedTasks.insert(task.name)
                    runningTask = nil
                    
                    // Run next task
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        runNext(index: index + 1)
                    }
                }
            }
        }
        
        runNext(index: 0)
    }
}

struct TaskSection: View {
    let title: String
    let icon: String
    let color: Color
    let tasks: [(name: String, command: String, icon: String, description: String)]
    @Binding var runningTask: String?
    @Binding var completedTasks: Set<String>
    let runTask: (String, String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
            }
            .padding(.horizontal)
            
            VStack(spacing: 4) {
                ForEach(tasks, id: \.name) { task in
                    MaintenanceTaskRow(
                        name: task.name,
                        icon: task.icon,
                        description: task.description,
                        isRunning: runningTask == task.name,
                        isCompleted: completedTasks.contains(task.name)
                    ) {
                        runTask(task.name, task.command)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
        }
        .frame(maxWidth: 600)
    }
}

struct MaintenanceTaskRow: View {
    let name: String
    let icon: String
    let description: String
    let isRunning: Bool
    let isCompleted: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundColor(.cyan)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 20))
            } else if isRunning {
                ProgressView()
                    .scaleEffect(0.7)
            } else {
                Button("Run") {
                    action()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 8)
    }
}


/*
#Preview {
    ContentView()
        .environmentObject(AppState())
}
*/
