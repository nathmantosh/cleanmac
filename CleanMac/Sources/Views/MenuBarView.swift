import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.green)
                Text("CleanMac")
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // Quick Stats
            VStack(spacing: 12) {
                // Disk Space
                HStack {
                    Label("Disk", systemImage: "internaldrive")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(formatBytes(appState.freeDiskSpace)) free")
                        .fontWeight(.medium)
                }
                
                // Memory
                HStack {
                    Label("Memory", systemImage: "memorychip")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(appState.memoryUsage))% used")
                        .fontWeight(.medium)
                }
                
                // Last Scan
                HStack {
                    Label("Last Scan", systemImage: "clock")
                        .foregroundColor(.secondary)
                    Spacer()
                    if let date = appState.lastScanDate {
                        Text(date.formatted(date: .abbreviated, time: .shortened))
                            .fontWeight(.medium)
                    } else {
                        Text("Never")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .font(.system(size: 12))
            .padding()
            
            Divider()
            
            // Quick Actions
            VStack(spacing: 4) {
                MenuBarButton(title: "Quick Scan", icon: "magnifyingglass", color: .blue) {
                    // TODO: Quick scan
                }
                
                MenuBarButton(title: "Free Memory", icon: "memorychip", color: .purple) {
                    // TODO: Free memory
                }
                
                MenuBarButton(title: "Empty Trash", icon: "trash", color: .orange) {
                    emptyTrash()
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider()
            
            // Footer Buttons
            HStack {
                Button("Open CleanMac") {
                    NSApp.activate(ignoringOtherApps: true)
                    if let window = NSApp.windows.first(where: { $0.title == "CleanMac" || $0.isKeyWindow }) {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Spacer()
                
                Button("Quit") {
                    NSApp.terminate(nil)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding()
        }
        .frame(width: 280)
    }
    
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    func emptyTrash() {
        let trashURL = FileManager.default.urls(for: .trashDirectory, in: .userDomainMask).first
        if let trashURL = trashURL {
            do {
                let contents = try FileManager.default.contentsOfDirectory(at: trashURL, includingPropertiesForKeys: nil)
                for item in contents {
                    try FileManager.default.removeItem(at: item)
                }
            } catch {
                print("Error emptying trash: \(error)")
            }
        }
    }
}

struct MenuBarButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 20)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovering ? Color.gray.opacity(0.2) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

/*
#Preview {
    MenuBarView()
        .environmentObject(AppState())
}
*/
