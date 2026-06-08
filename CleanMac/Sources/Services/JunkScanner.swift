import Foundation

/// Service for scanning and cleaning system junk files
class JunkScanner: ObservableObject {
    
    // MARK: - Junk Categories
    enum JunkCategory: String, CaseIterable {
        case userCache = "User Cache"
        case systemCache = "System Cache"
        case userLogs = "User Logs"
        case systemLogs = "System Logs"
        case downloads = "Downloads"
        case trash = "Trash"
        case xcodeJunk = "Xcode Junk"
        case browserCache = "Browser Cache"
        
        var paths: [String] {
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            switch self {
            case .userCache:
                return ["\(home)/Library/Caches"]
            case .systemCache:
                return ["/Library/Caches"]
            case .userLogs:
                return ["\(home)/Library/Logs"]
            case .systemLogs:
                return ["/Library/Logs", "/private/var/log"]
            case .downloads:
                return ["\(home)/Downloads"]
            case .trash:
                return ["\(home)/.Trash"]
            case .xcodeJunk:
                return [
                    "\(home)/Library/Developer/Xcode/DerivedData",
                    "\(home)/Library/Developer/Xcode/Archives",
                    "\(home)/Library/Developer/CoreSimulator/Devices"
                ]
            case .browserCache:
                return [
                    "\(home)/Library/Caches/com.apple.Safari",
                    "\(home)/Library/Caches/Google/Chrome",
                    "\(home)/Library/Caches/Firefox"
                ]
            }
        }
        
        var icon: String {
            switch self {
            case .userCache, .systemCache: return "folder.badge.gearshape"
            case .userLogs, .systemLogs: return "doc.text"
            case .downloads: return "arrow.down.circle"
            case .trash: return "trash"
            case .xcodeJunk: return "hammer"
            case .browserCache: return "globe"
            }
        }
        
        // MARK: - Safety Level
        enum SafetyLevel: String {
            case safe = "Safe"
            case caution = "Caution"
            case warning = "Warning"
            
            var color: String {
                switch self {
                case .safe: return "green"
                case .caution: return "orange"
                case .warning: return "red"
                }
            }
            
            var icon: String {
                switch self {
                case .safe: return "checkmark.shield.fill"
                case .caution: return "exclamationmark.shield.fill"
                case .warning: return "xmark.shield.fill"
                }
            }
        }
        
        var safetyLevel: SafetyLevel {
            switch self {
            case .browserCache, .xcodeJunk, .trash:
                return .safe
            case .userCache, .userLogs, .systemLogs:
                return .caution
            case .systemCache:
                return .caution
            case .downloads:
                return .warning
            }
        }
        
        var safetyDescription: String {
            switch self {
            case .userCache:
                return "✅ Safe - Apps will recreate needed cache files"
            case .systemCache:
                return "⚠️ Caution - Only clean if you have admin access"
            case .userLogs:
                return "✅ Safe - Old log files, rarely needed"
            case .systemLogs:
                return "⚠️ Caution - May affect troubleshooting"
            case .downloads:
                return "⛔️ Warning - Contains YOUR personal files!"
            case .trash:
                return "✅ Safe - Already deleted files"
            case .xcodeJunk:
                return "✅ Safe - Build cache, regenerated when needed"
            case .browserCache:
                return "✅ Safe - Browser will rebuild cache"
            }
        }
    }
    
    // MARK: - Scan Result
    struct ScanResult: Identifiable {
        let id = UUID()
        let category: JunkCategory
        var files: [FileInfo]
        var totalSize: Int64 {
            files.reduce(0) { $0 + $1.size }
        }
        var isSelected: Bool = true
    }
    
    struct FileInfo: Identifiable {
        let id = UUID()
        let path: String
        let name: String
        let size: Int64
        let modificationDate: Date?
        var isSelected: Bool = true
    }
    
    // MARK: - Properties
    @Published var scanResults: [ScanResult] = []
    @Published var isScanning = false
    @Published var progress: Double = 0
    @Published var currentCategory: String = ""
    
    var totalJunkSize: Int64 {
        scanResults.reduce(0) { $0 + $1.totalSize }
    }
    
    var selectedSize: Int64 {
        scanResults.filter(\.isSelected).reduce(0) { total, result in
            total + result.files.filter(\.isSelected).reduce(0) { $0 + $1.size }
        }
    }
    
    // MARK: - Scan Methods
    func scan(categories: [JunkCategory] = JunkCategory.allCases) async {
        await MainActor.run {
            isScanning = true
            scanResults = []
            progress = 0
        }
        
        let totalCategories = Double(categories.count)
        
        for (index, category) in categories.enumerated() {
            await MainActor.run {
                currentCategory = category.rawValue
            }
            
            let files = await scanCategory(category)
            
            if !files.isEmpty {
                let result = ScanResult(category: category, files: files)
                await MainActor.run {
                    scanResults.append(result)
                }
            }
            
            await MainActor.run {
                progress = Double(index + 1) / totalCategories
            }
        }
        
        await MainActor.run {
            isScanning = false
            currentCategory = ""
        }
    }
    
    private func scanCategory(_ category: JunkCategory) async -> [FileInfo] {
        var files: [FileInfo] = []
        let fileManager = FileManager.default
        
        for path in category.paths {
            guard fileManager.fileExists(atPath: path) else { continue }
            
            let url = URL(fileURLWithPath: path)
            
            guard let enumerator = fileManager.enumerator(
                at: url,
                includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else { continue }
            
            while let fileURL = enumerator.nextObject() as? URL {
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [
                        .fileSizeKey,
                        .contentModificationDateKey,
                        .isDirectoryKey
                    ])
                    
                    // Skip directories for now
                    if resourceValues.isDirectory == true { continue }
                    
                    let size = Int64(resourceValues.fileSize ?? 0)
                    let modDate = resourceValues.contentModificationDate
                    
                    let fileInfo = FileInfo(
                        path: fileURL.path,
                        name: fileURL.lastPathComponent,
                        size: size,
                        modificationDate: modDate
                    )
                    
                    files.append(fileInfo)
                } catch {
                    // Skip files we can't access
                    continue
                }
            }
        }
        
        return files.sorted { $0.size > $1.size }
    }
    
    // MARK: - Clean Methods
    func clean() async -> Int64 {
        var cleanedSize: Int64 = 0
        var failedFiles: [(path: String, size: Int64)] = []
        let fileManager = FileManager.default
        
        for result in scanResults where result.isSelected {
            for file in result.files where file.isSelected {
                do {
                    try fileManager.removeItem(atPath: file.path)
                    cleanedSize += file.size
                } catch {
                    // File might need admin privileges
                    failedFiles.append((path: file.path, size: file.size))
                    print("Failed to remove: \(file.path) - \(error)")
                }
            }
        }
        
        // If we have failed files (likely system files), try with admin privileges
        if !failedFiles.isEmpty {
            let adminCleaned = await cleanWithAdminPrivileges(files: failedFiles)
            cleanedSize += adminCleaned
        }
        
        // Clear results after cleaning
        await MainActor.run {
            scanResults = []
        }
        
        return cleanedSize
    }
    
    // MARK: - Admin Privilege Cleaning
    @MainActor
    private func cleanWithAdminPrivileges(files: [(path: String, size: Int64)]) async -> Int64 {
        guard !files.isEmpty else { return 0 }

        let filePaths = files.map(\.path)
        let expectedCleanedSize = files.reduce(0) { $0 + $1.size }
        
        // Write file paths to a temp file to avoid command line limits
        let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("cleanmac_delete_\(UUID().uuidString).txt")
        
        do {
            let content = filePaths.joined(separator: "\n")
            try content.write(to: tempFile, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to write temp file: \(error)")
            return 0
        }
        
        // Single AppleScript command to delete all files from the list
        let appleScript = """
        do shell script "while IFS= read -r file; do rm -rf \\"$file\\"; done < '\(tempFile.path)'; rm '\(tempFile.path)'" with administrator privileges
        """
        
        // Run via osascript - single password prompt
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", appleScript]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                print("Admin cleaned \(files.count) files successfully")
                return expectedCleanedSize
            } else {
                let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
                let errorMessage = String(data: errorData, encoding: .utf8) ?? ""
                print("Admin clean failed: \(errorMessage)")
                // Clean up temp file on failure
                try? FileManager.default.removeItem(at: tempFile)
            }
        } catch {
            print("Admin clean error: \(error)")
            try? FileManager.default.removeItem(at: tempFile)
        }
        
        return 0
    }
    
    func toggleCategorySelection(_ category: JunkCategory) {
        if let index = scanResults.firstIndex(where: { $0.category == category }) {
            let newState = !scanResults[index].isSelected
            scanResults[index].isSelected = newState
            
            if scanResults[index].files.count < 1000 {
                for i in scanResults[index].files.indices {
                    scanResults[index].files[i].isSelected = newState
                }
            } else {
                let currentFiles = scanResults[index].files
                DispatchQueue.global(qos: .userInteractive).async {
                    var updatedFiles = currentFiles
                    for i in updatedFiles.indices {
                        updatedFiles[i].isSelected = newState
                    }
                    DispatchQueue.main.async {
                        if let updatedIndex = self.scanResults.firstIndex(where: { $0.category == category }) {
                            self.scanResults[updatedIndex].files = updatedFiles
                            self.objectWillChange.send()
                        }
                    }
                }
            }
            objectWillChange.send()
        }
    }

    // MARK: - Utility
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    // MARK: - Report Generation
    func generateReport() -> String {
        var report = """
        =====================================
        CLEANMAC SCAN REPORT
        Generated: \(Date().formatted())
        =====================================
        
        SUMMARY
        -------
        Total Junk Found: \(formatBytes(totalJunkSize))
        Selected for Cleaning: \(formatBytes(selectedSize))
        Categories Scanned: \(scanResults.count)
        
        """
        
        for result in scanResults {
            report += """
            
            [\(result.category.rawValue)]
            Total Size: \(formatBytes(result.totalSize))
            Files: \(result.files.count)
            Selected: \(result.isSelected ? "Yes" : "No")
            Paths Scanned: \(result.category.paths.joined(separator: ", "))
            
            Top 20 Files by Size:
            """
            
            for (index, file) in result.files.prefix(20).enumerated() {
                report += """
                
                \(index + 1). \(file.name)
                   Path: \(file.path)
                   Size: \(formatBytes(file.size))
                   Selected: \(file.isSelected ? "✓" : "✗")
                """
            }
            
            if result.files.count > 20 {
                report += "\n   ... and \(result.files.count - 20) more files"
            }
            
            report += "\n"
        }
        
        report += """
        
        =====================================
        END OF REPORT
        =====================================
        """
        
        return report
    }
    
    func saveReportToDesktop() -> URL? {
        let report = generateReport()
        let desktop = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        let filename = "CleanMac_Report_\(Date().formatted(.dateTime.year().month().day().hour().minute())).txt"
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: ":", with: "-")
        
        let fileURL = desktop.appendingPathComponent(filename)
        
        do {
            try report.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to save report: \(error)")
            return nil
        }
    }
    
    // MARK: - Verification
    func verifyCategory(_ category: JunkCategory) -> (reported: Int64, actual: Int64, match: Bool) {
        let fileManager = FileManager.default
        var actualSize: Int64 = 0
        
        for path in category.paths {
            guard fileManager.fileExists(atPath: path) else { continue }
            
            // Use du-like calculation
            let url = URL(fileURLWithPath: path)
            if let enumerator = fileManager.enumerator(
                at: url,
                includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) {
                while let fileURL = enumerator.nextObject() as? URL {
                    if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]),
                       resourceValues.isDirectory != true,
                       let size = resourceValues.fileSize {
                        actualSize += Int64(size)
                    }
                }
            }
        }
        
        // Find reported size for this category
        let reported = scanResults.first { $0.category == category }?.totalSize ?? 0
        
        // Allow 5% variance for files being modified during scan
        let variance = Double(abs(reported - actualSize)) / Double(max(actualSize, 1))
        let match = variance < 0.05
        
        return (reported: reported, actual: actualSize, match: match)
    }
    
    func generateVerificationReport() -> String {
        var report = "VERIFICATION REPORT\n"
        report += "===================\n\n"
        
        for result in scanResults {
            let verification = verifyCategory(result.category)
            let status = verification.match ? "✓ MATCH" : "✗ MISMATCH"
            
            report += """
            \(result.category.rawValue):
              Reported: \(formatBytes(verification.reported))
              Actual:   \(formatBytes(verification.actual))
              Status:   \(status)
            
            """
        }
        
        return report
    }
}
