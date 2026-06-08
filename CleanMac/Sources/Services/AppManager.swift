import Foundation
import AppKit

/// Service for managing and uninstalling applications
class AppManager: ObservableObject {
    
    // MARK: - App Info
    struct InstalledApp: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let bundleIdentifier: String?
        let path: String
        let icon: NSImage?
        let size: Int64
        let version: String?
        let lastUsed: Date?
        
        // Paths where app might store data
        var associatedPaths: [String] {
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            guard let bundleId = bundleIdentifier else { return [] }
            
            // Get vendor/company prefix from bundle ID (e.g., "com.macpaw" from "com.macpaw.CleanMyMac")
            let bundleParts = bundleId.split(separator: ".")
            let vendorPrefix = bundleParts.count >= 2 ? "\(bundleParts[0]).\(bundleParts[1])" : bundleId
            
            var paths = [
                // Standard locations
                "\(home)/Library/Application Support/\(name)",
                "\(home)/Library/Application Support/\(bundleId)",
                "\(home)/Library/Preferences/\(bundleId).plist",
                "\(home)/Library/Caches/\(bundleId)",
                "\(home)/Library/Containers/\(bundleId)",
                "\(home)/Library/Saved Application State/\(bundleId).savedState",
                "\(home)/Library/Logs/\(bundleId)",
                "\(home)/Library/HTTPStorages/\(bundleId)",
                "\(home)/Library/WebKit/\(bundleId)",
                "\(home)/Library/Cookies/\(bundleId).binarycookies",
                
                // Group containers
                "\(home)/Library/Group Containers/\(bundleId)",
            ]
            
            // Search Containers for any folder containing the bundle ID or vendor prefix
            let containersPath = "\(home)/Library/Containers"
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: containersPath) {
                for item in contents {
                    if item.contains(bundleId) || item.contains(vendorPrefix) || item.lowercased().contains(name.lowercased()) {
                        paths.append("\(containersPath)/\(item)")
                    }
                }
            }
            
            // Search Application Support for name variations
            let appSupportPath = "\(home)/Library/Application Support"
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: appSupportPath) {
                for item in contents {
                    if item.lowercased().contains(name.lowercased().replacingOccurrences(of: " ", with: "")) ||
                       item.contains(bundleId) {
                        let fullPath = "\(appSupportPath)/\(item)"
                        if !paths.contains(fullPath) {
                            paths.append(fullPath)
                        }
                    }
                }
            }
            
            return paths
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(path)
        }
        
        static func == (lhs: InstalledApp, rhs: InstalledApp) -> Bool {
            lhs.path == rhs.path
        }
    }
    
    struct AppLeftover: Identifiable {
        let id = UUID()
        let path: String
        let size: Int64
        let type: LeftoverType
        var isSelected: Bool = true
        
        enum LeftoverType: String {
            case preferences = "Preferences"
            case cache = "Cache"
            case applicationSupport = "App Data"
            case container = "Container"
            case savedState = "Saved State"
            case logs = "Logs"
            case other = "Other"
        }
    }
    
    // MARK: - Properties
    @Published var installedApps: [InstalledApp] = []
    @Published var isLoading = false
    @Published var selectedApp: InstalledApp?
    @Published var leftovers: [AppLeftover] = []
    
    // MARK: - Load Apps
    func loadInstalledApps() async {
        await MainActor.run {
            isLoading = true
        }
        
        var apps: [InstalledApp] = []
        let fileManager = FileManager.default
        
        // Scan /Applications
        let applicationsURL = URL(fileURLWithPath: "/Applications")
        if let contents = try? fileManager.contentsOfDirectory(
            at: applicationsURL,
            includingPropertiesForKeys: [.contentModificationDateKey]
        ) {
            for url in contents where url.pathExtension == "app" {
                if let app = await loadAppInfo(at: url) {
                    apps.append(app)
                }
            }
        }
        
        // Scan ~/Applications
        let userAppsURL = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
        if let contents = try? fileManager.contentsOfDirectory(
            at: userAppsURL,
            includingPropertiesForKeys: nil
        ) {
            for url in contents where url.pathExtension == "app" {
                if let app = await loadAppInfo(at: url) {
                    apps.append(app)
                }
            }
        }
        
        apps.sort { $0.name.lowercased() < $1.name.lowercased() }
        let sortedApps = apps
        
        await MainActor.run {
            installedApps = sortedApps
            isLoading = false
        }
    }
    
    private func loadAppInfo(at url: URL) async -> InstalledApp? {
        let fileManager = FileManager.default
        
        // Get bundle info
        let bundle = Bundle(url: url)
        let bundleId = bundle?.bundleIdentifier
        let version = bundle?.infoDictionary?["CFBundleShortVersionString"] as? String
        
        // Get app name
        let name = (bundle?.infoDictionary?["CFBundleDisplayName"] as? String)
            ?? (bundle?.infoDictionary?["CFBundleName"] as? String)
            ?? url.deletingPathExtension().lastPathComponent
        
        // Get icon
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 32, height: 32)
        
        // Calculate size
        var size: Int64 = 0
        if let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) {
            while let fileURL = enumerator.nextObject() as? URL {
                if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    size += Int64(fileSize)
                }
            }
        }
        
        // Get last used date
        let lastUsed = try? url.resourceValues(forKeys: [.contentAccessDateKey]).contentAccessDate
        
        return InstalledApp(
            name: name,
            bundleIdentifier: bundleId,
            path: url.path,
            icon: icon,
            size: size,
            version: version,
            lastUsed: lastUsed
        )
    }
    
    // MARK: - Find Leftovers
    func findLeftovers(for app: InstalledApp) async -> [AppLeftover] {
        var leftovers: [AppLeftover] = []
        let fileManager = FileManager.default
        
        for path in app.associatedPaths {
            guard fileManager.fileExists(atPath: path) else { continue }
            
            let url = URL(fileURLWithPath: path)
            var size: Int64 = 0
            
            // Calculate size
            if let enumerator = fileManager.enumerator(
                at: url,
                includingPropertiesForKeys: [.fileSizeKey],
                options: []
            ) {
                while let fileURL = enumerator.nextObject() as? URL {
                    if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                        size += Int64(fileSize)
                    }
                }
            } else {
                // Single file
                if let attrs = try? fileManager.attributesOfItem(atPath: path) {
                    size = (attrs[.size] as? Int64) ?? 0
                }
            }
            
            let type = determineLeftoverType(path: path)
            leftovers.append(AppLeftover(path: path, size: size, type: type))
        }
        
        return leftovers.sorted { $0.size > $1.size }
    }
    
    private func determineLeftoverType(path: String) -> AppLeftover.LeftoverType {
        if path.contains("/Preferences/") { return .preferences }
        if path.contains("/Caches/") { return .cache }
        if path.contains("/Application Support/") { return .applicationSupport }
        if path.contains("/Containers/") { return .container }
        if path.contains("/Saved Application State/") { return .savedState }
        if path.contains("/Logs/") { return .logs }
        return .other
    }
    
    // MARK: - Uninstall
    @MainActor
    func uninstall(app: InstalledApp, includeLeftovers: Bool = true) async throws -> Int64 {
        var removedSize: Int64 = 0
        var pathsToTrash: [String] = []
        
        // Add main app bundle
        pathsToTrash.append(app.path)
        removedSize += app.size
        
        // Add leftovers if requested
        if includeLeftovers {
            let appLeftovers = await findLeftovers(for: app)
            for leftover in appLeftovers where leftover.isSelected {
                pathsToTrash.append(leftover.path)
                removedSize += leftover.size
            }
        }

        for path in pathsToTrash {
            do {
                try FileManager.default.trashItem(at: URL(fileURLWithPath: path), resultingItemURL: nil)
            } catch {
                print("Failed to move to Trash: \(path) - \(error)")
                throw NSError(
                    domain: "AppManager",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Could not move \(path) to Trash. CleanMac does not force-delete files with administrator privileges."]
                )
            }
        }
        
        print("Successfully uninstalled: \(app.name)")
        
        // Refresh app list
        await loadInstalledApps()
        
        return removedSize
    }
    
    // MARK: - Orphaned Leftovers Scanner
    struct OrphanedLeftover: Identifiable {
        let id = UUID()
        let path: String
        let name: String
        let size: Int64
        let type: String
        var isSelected: Bool = true
    }
    
    @Published var orphanedLeftovers: [OrphanedLeftover] = []
    @Published var isScannningLeftovers = false
    
    func scanForOrphanedLeftovers() async {
        await MainActor.run { isScannningLeftovers = true }
        
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let fileManager = FileManager.default
        var leftovers: [OrphanedLeftover] = []
        
        // Get all installed app bundle IDs and names
        let installedBundleIds = Set(installedApps.compactMap { $0.bundleIdentifier })
        let installedNames = Set(installedApps.map { $0.name.lowercased() })
        
        // Locations to scan for orphaned files
        let locationsToScan: [(path: String, type: String)] = [
            ("\(home)/Library/Application Support", "App Data"),
            ("\(home)/Library/Containers", "Container"),
            ("\(home)/Library/Caches", "Cache"),
            ("\(home)/Library/Preferences", "Preferences"),
            ("\(home)/Library/Saved Application State", "Saved State"),
            ("\(home)/Library/Logs", "Logs"),
            ("\(home)/Library/HTTPStorages", "HTTP Storage"),
            ("\(home)/Library/Group Containers", "Group Container"),
        ]
        
        for location in locationsToScan {
            guard let contents = try? fileManager.contentsOfDirectory(atPath: location.path) else { continue }
            
            for item in contents {
                // Skip system and common folders
                if item.starts(with: ".") || item == "com.apple" || item.starts(with: "com.apple.") { continue }
                
                let fullPath = "\(location.path)/\(item)"
                let itemLower = item.lowercased()
                
                // Check if this belongs to an installed app
                var belongsToInstalledApp = false
                
                // Check by bundle ID
                for bundleId in installedBundleIds {
                    let bundleLower = bundleId.lowercased()
                    // Check if item contains bundle ID or vendor prefix
                    if itemLower.contains(bundleLower) {
                        belongsToInstalledApp = true
                        break
                    }
                    // Check vendor prefix (e.g., "com.google" from "com.google.Chrome")
                    let parts = bundleId.split(separator: ".")
                    if parts.count >= 2 {
                        let vendor = String(parts[1]).lowercased() // e.g., "google", "brave", "apple"
                        if itemLower.contains(vendor) && vendor.count > 3 {
                            belongsToInstalledApp = true
                            break
                        }
                    }
                }
                
                if !belongsToInstalledApp {
                    // Check by app name - both directions
                    for appName in installedNames {
                        let cleanName = appName.replacingOccurrences(of: " ", with: "").lowercased()
                        let firstWord = appName.split(separator: " ").first.map(String.init)?.lowercased() ?? ""
                        
                        // Check if item contains app name or first word
                        if itemLower.contains(cleanName) || 
                           (firstWord.count > 3 && itemLower.contains(firstWord)) ||
                           cleanName.contains(itemLower.replacingOccurrences(of: "software", with: "")) {
                            belongsToInstalledApp = true
                            break
                        }
                    }
                }
                
                // If not belonging to installed app, it's orphaned
                if !belongsToInstalledApp {
                    // Calculate size
                    var size: Int64 = 0
                    let url = URL(fileURLWithPath: fullPath)
                    if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: []) {
                        while let fileURL = enumerator.nextObject() as? URL {
                            if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                                size += Int64(fileSize)
                            }
                        }
                    }
                    
                    // Only include if has meaningful size
                    if size > 1000 { // > 1KB
                        let displayName = item
                            .replacingOccurrences(of: ".plist", with: "")
                            .replacingOccurrences(of: ".savedState", with: "")
                        
                        leftovers.append(OrphanedLeftover(
                            path: fullPath,
                            name: displayName,
                            size: size,
                            type: location.type
                        ))
                    }
                }
            }
        }
        
        // Sort by size descending
        let sortedLeftovers = leftovers.sorted { $0.size > $1.size }
        
        await MainActor.run {
            orphanedLeftovers = sortedLeftovers
            isScannningLeftovers = false
        }
    }
    
    @MainActor
    func cleanOrphanedLeftovers() async -> Int64 {
        let selectedPaths = orphanedLeftovers.filter(\.isSelected).map(\.path)
        guard !selectedPaths.isEmpty else { return 0 }
        
        var totalSize: Int64 = 0
        for leftover in orphanedLeftovers where leftover.isSelected {
            totalSize += leftover.size
        }
        
        do {
            for path in selectedPaths {
                try FileManager.default.trashItem(at: URL(fileURLWithPath: path), resultingItemURL: nil)
            }
            orphanedLeftovers.removeAll()
            return totalSize
        } catch {
            print("Move orphaned leftovers to Trash error: \(error)")
        }
        
        return 0
    }
    
    // MARK: - Utility
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
