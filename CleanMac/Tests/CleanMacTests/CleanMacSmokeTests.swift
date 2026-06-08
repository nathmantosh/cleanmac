import XCTest
@testable import CleanMac

final class CleanMacSmokeTests: XCTestCase {
    func testJunkScannerCleanDeletesSelectedFilesAndReturnsExactBytes() async throws {
        let scanner = JunkScanner()
        let tempDir = try makeTempDir(prefix: "junk-clean")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let selectedFile = tempDir.appendingPathComponent("selected.log")
        let unselectedFile = tempDir.appendingPathComponent("keep.log")

        try makeFile(at: selectedFile, size: 2_048)
        try makeFile(at: unselectedFile, size: 1_024)

        scanner.scanResults = [
            JunkScanner.ScanResult(
                category: .userLogs,
                files: [
                    JunkScanner.FileInfo(path: selectedFile.path, name: selectedFile.lastPathComponent, size: 2_048, modificationDate: nil, isSelected: true),
                    JunkScanner.FileInfo(path: unselectedFile.path, name: unselectedFile.lastPathComponent, size: 1_024, modificationDate: nil, isSelected: false)
                ],
                isSelected: true
            )
        ]

        let cleaned = await scanner.clean()

        XCTAssertEqual(cleaned, 2_048)
        XCTAssertFalse(FileManager.default.fileExists(atPath: selectedFile.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: unselectedFile.path))
        XCTAssertTrue(scanner.scanResults.isEmpty)
    }

    func testDuplicateScanPreselectsRemovalsAndDeleteSelectedRemovesDuplicates() async throws {
        let analyzer = FileAnalyzer()
        let tempDir = try makeTempDir(prefix: "dup-scan")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let original = tempDir.appendingPathComponent("a-original.txt")
        let duplicate = tempDir.appendingPathComponent("b-duplicate.txt")
        let unique = tempDir.appendingPathComponent("unique.txt")

        let duplicatePayload = Data("same-content".utf8)
        try duplicatePayload.write(to: original)
        try duplicatePayload.write(to: duplicate)
        try Data("different".utf8).write(to: unique)

        // Make "original" deterministically older so it is kept.
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 1)], ofItemAtPath: original.path)
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 2)], ofItemAtPath: duplicate.path)

        await analyzer.scanDuplicates(in: tempDir.path)

        XCTAssertEqual(analyzer.duplicateGroups.count, 1)
        guard let group = analyzer.duplicateGroups.first else {
            XCTFail("Expected a duplicate group")
            return
        }

        XCTAssertEqual(group.files.count, 2)
        XCTAssertEqual(group.files.filter(\.isOriginal).count, 1)
        XCTAssertEqual(group.files.filter { !$0.isOriginal && $0.isSelected }.count, 1)

        let deleted = await analyzer.deleteSelectedDuplicates()
        XCTAssertGreaterThan(deleted, 0)

        let originalExists = FileManager.default.fileExists(atPath: original.path)
        let duplicateExists = FileManager.default.fileExists(atPath: duplicate.path)
        XCTAssertNotEqual(originalExists, duplicateExists, "Exactly one duplicate file should remain")

        await analyzer.scanDuplicates(in: tempDir.path)
        XCTAssertTrue(analyzer.duplicateGroups.isEmpty)
    }

    func testSmartScanConfiguredCategoriesFollowSettings() {
        let categories = SmartScanView.configuredCategories(
            cleanSystemCache: false,
            cleanUserCache: true,
            cleanLogs: false,
            cleanDeveloperJunk: true,
            cleanDownloads: true,
            cleanTrash: false
        )

        XCTAssertTrue(categories.contains(.browserCache))
        XCTAssertTrue(categories.contains(.developerJunk))
        XCTAssertTrue(categories.contains(.userCache))
        XCTAssertTrue(categories.contains(.downloads))

        XCTAssertFalse(categories.contains(.systemCache))
        XCTAssertFalse(categories.contains(.userLogs))
        XCTAssertFalse(categories.contains(.systemLogs))
        XCTAssertFalse(categories.contains(.trash))
    }

    // MARK: - Helpers

    private func makeTempDir(prefix: String) throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("\(prefix)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func makeFile(at url: URL, size: Int) throws {
        let data = Data(repeating: 0xAB, count: size)
        try data.write(to: url)
    }
}
