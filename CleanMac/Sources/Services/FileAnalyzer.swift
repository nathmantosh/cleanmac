import Foundation
import CryptoKit

/// Service for finding large and duplicate files
class FileAnalyzer: ObservableObject {
    
    // MARK: - Large File
    struct LargeFile: Identifiable {
        let id = UUID()
        let path: String
        let name: String
        let size: Int64
        let modificationDate: Date?
        let fileType: FileType
        var isSelected: Bool = false
        
        enum FileType: String {
            case video = "Video"
            case audio = "Audio"
            case image = "Image"
            case archive = "Archive"
            case document = "Document"
            case application = "Application"
            case other = "Other"
            
            var icon: String {
                switch self {
                case .video: return "film"
                case .audio: return "music.note"
                case .image: return "photo"
                case .archive: return "archivebox"
                case .document: return "doc"
                case .application: return "app"
                case .other: return "doc.fill"
                }
            }
        }
    }
    
    // MARK: - Duplicate Group
    struct DuplicateGroup: Identifiable {
        let id = UUID()
        let hash: String
        let size: Int64
        var files: [DuplicateFile]
        
        var wastedSpace: Int64 {
            // All but one file is "wasted"
            size * Int64(max(0, files.count - 1))
        }
    }
    
    struct DuplicateFile: Identifiable {
        let id = UUID()
        let path: String
        let name: String
        let modificationDate: Date?
        var isSelected: Bool = false
        var isOriginal: Bool = false  // Keep this one
    }
    
    // MARK: - Properties
    @Published var largeFiles: [LargeFile] = []
    @Published var duplicateGroups: [DuplicateGroup] = []
    @Published var isScanning = false
    @Published var progress: Double = 0
    @Published var currentPath: String = ""
    
    private var lastDuplicateScanPath: String?
    
    private let minLargeFileSize: Int64 = 50 * 1024 * 1024  // 50MB
    
    // MARK: - Large Files Scanner
    func scanLargeFiles(in path: String? = nil) async {
        await MainActor.run {
            isScanning = true
            largeFiles = []
            progress = 0
        }
        
        let searchPath = path ?? FileManager.default.homeDirectoryForCurrentUser.path
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(
            at: URL(fileURLWithPath: searchPath),
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return }
        
        var foundFiles: [LargeFile] = []
        var fileCount = 0
        
        while let fileURL = enumerator.nextObject() as? URL {
            fileCount += 1
            
            // Update progress periodically
            if fileCount % 100 == 0 {
                await MainActor.run {
                    currentPath = fileURL.path
                }
            }
            
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [
                    .fileSizeKey,
                    .contentModificationDateKey,
                    .isDirectoryKey
                ])
                
                guard resourceValues.isDirectory != true else { continue }
                
                let size = Int64(resourceValues.fileSize ?? 0)
                guard size >= minLargeFileSize else { continue }
                
                let fileType = determineFileType(for: fileURL)
                
                let largeFile = LargeFile(
                    path: fileURL.path,
                    name: fileURL.lastPathComponent,
                    size: size,
                    modificationDate: resourceValues.contentModificationDate,
                    fileType: fileType
                )
                
                foundFiles.append(largeFile)
            } catch {
                continue
            }
        }
        
        foundFiles.sort { $0.size > $1.size }
        let topFiles = Array(foundFiles.prefix(100))  // Top 100 largest
        
        await MainActor.run {
            largeFiles = topFiles
            isScanning = false
            currentPath = ""
        }
    }
    
    private func determineFileType(for url: URL) -> LargeFile.FileType {
        let ext = url.pathExtension.lowercased()
        
        let videoExts = ["mp4", "mov", "avi", "mkv", "wmv", "flv", "m4v"]
        let audioExts = ["mp3", "wav", "aac", "flac", "m4a", "wma"]
        let imageExts = ["jpg", "jpeg", "png", "gif", "tiff", "bmp", "heic", "raw"]
        let archiveExts = ["zip", "rar", "7z", "tar", "gz", "dmg", "iso"]
        let docExts = ["pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx"]
        
        if videoExts.contains(ext) { return .video }
        if audioExts.contains(ext) { return .audio }
        if imageExts.contains(ext) { return .image }
        if archiveExts.contains(ext) { return .archive }
        if docExts.contains(ext) { return .document }
        if ext == "app" { return .application }
        return .other
    }
    
    // MARK: - Duplicate Scanner
    func scanDuplicates(in path: String? = nil) async {
        await MainActor.run {
            isScanning = true
            duplicateGroups = []
            progress = 0
        }
        
        let searchPath = path ?? FileManager.default.homeDirectoryForCurrentUser.path
        lastDuplicateScanPath = searchPath
        let fileManager = FileManager.default
        
        // First pass: group by size
        var sizeGroups: [Int64: [URL]] = [:]
        
        guard let enumerator = fileManager.enumerator(
            at: URL(fileURLWithPath: searchPath),
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return }
        
        while let fileURL = enumerator.nextObject() as? URL {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
                guard resourceValues.isDirectory != true else { continue }
                
                let size = Int64(resourceValues.fileSize ?? 0)
                guard size > 0 else { continue }
                
                sizeGroups[size, default: []].append(fileURL)
            } catch {
                continue
            }
        }
        
        // Filter to only sizes with multiple files
        let potentialDuplicates = sizeGroups.filter { $0.value.count > 1 }
        
        await MainActor.run {
            progress = 0.5
        }
        
        // Second pass: hash files with same size
        var groups: [DuplicateGroup] = []
        var hashGroups: [String: (size: Int64, files: [URL])] = [:]
        let totalPotentialFiles = max(1, potentialDuplicates.values.reduce(0) { $0 + $1.count })
        var processedFiles = 0
        
        for (size, urls) in potentialDuplicates {
            for url in urls {
                if let hash = fullSHA256(for: url) {
                    if hashGroups[hash] == nil {
                        hashGroups[hash] = (size: size, files: [])
                    }
                    hashGroups[hash]?.files.append(url)
                }

                processedFiles += 1
                if processedFiles % 50 == 0 {
                    let progressValue = 0.5 + (Double(processedFiles) / Double(totalPotentialFiles) * 0.5)
                    await MainActor.run {
                        progress = min(progressValue, 0.99)
                    }
                }
            }
        }
        
        // Create duplicate groups
        for (hash, data) in hashGroups where data.files.count > 1 {
            var duplicateFiles: [DuplicateFile] = []

            let sortedFiles = data.files.sorted {
                let lhsDate = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantFuture
                let rhsDate = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantFuture
                if lhsDate == rhsDate {
                    return $0.path < $1.path
                }
                return lhsDate < rhsDate
            }

            for (index, url) in sortedFiles.enumerated() {
                let modDate = try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                let isOriginal = index == 0
                
                duplicateFiles.append(DuplicateFile(
                    path: url.path,
                    name: url.lastPathComponent,
                    modificationDate: modDate,
                    isSelected: !isOriginal,
                    isOriginal: isOriginal
                ))
            }
            
            groups.append(DuplicateGroup(
                hash: hash,
                size: data.size,
                files: duplicateFiles
            ))
        }
        
        groups.sort { $0.wastedSpace > $1.wastedSpace }
        let sortedGroups = groups
        
        await MainActor.run {
            duplicateGroups = sortedGroups
            isScanning = false
            progress = 1.0
        }
    }
    
    private func fullSHA256(for url: URL) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }

        var hasher = SHA256()

        while true {
            let chunk = handle.readData(ofLength: 1024 * 1024)
            if chunk.isEmpty {
                break
            }
            hasher.update(data: chunk)
        }

        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Delete Files
    func deleteSelectedLargeFiles() async -> Int64 {
        var deletedSize: Int64 = 0
        let fileManager = FileManager.default
        
        for file in largeFiles where file.isSelected {
            do {
                try fileManager.trashItem(at: URL(fileURLWithPath: file.path), resultingItemURL: nil)
                deletedSize += file.size
            } catch {
                print("Failed to delete: \(file.path)")
            }
        }
        
        await MainActor.run {
            largeFiles.removeAll { $0.isSelected }
        }
        
        return deletedSize
    }
    
    func deleteSelectedDuplicates() async -> Int64 {
        var deletedSize: Int64 = 0
        let fileManager = FileManager.default
        
        for group in duplicateGroups {
            for file in group.files where file.isSelected && !file.isOriginal {
                do {
                    try fileManager.trashItem(at: URL(fileURLWithPath: file.path), resultingItemURL: nil)
                    deletedSize += group.size
                } catch {
                    print("Failed to delete: \(file.path)")
                }
            }
        }
        
        // Refresh
        await scanDuplicates(in: lastDuplicateScanPath)
        
        return deletedSize
    }
    
    // MARK: - Utility
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
