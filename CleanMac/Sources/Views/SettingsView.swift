import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("autoScanEnabled") private var autoScanEnabled = false
    @AppStorage("autoScanInterval") private var autoScanInterval = 7 // days
    
    var body: some View {
        TabView {
            GeneralSettingsView(
                launchAtLogin: $launchAtLogin,
                showMenuBarIcon: $showMenuBarIcon
            )
            .tabItem {
                Label("General", systemImage: "gear")
            }
            
            CleaningSettingsView()
            .tabItem {
                Label("Cleaning", systemImage: "trash")
            }
            
            NotificationSettingsView(
                notificationsEnabled: $notificationsEnabled,
                autoScanEnabled: $autoScanEnabled,
                autoScanInterval: $autoScanInterval
            )
            .tabItem {
                Label("Notifications", systemImage: "bell")
            }
            
            AboutView()
            .tabItem {
                Label("About", systemImage: "info.circle")
            }
        }
        .frame(width: 450, height: 300)
    }
}

// MARK: - General Settings
struct GeneralSettingsView: View {
    @Binding var launchAtLogin: Bool
    @Binding var showMenuBarIcon: Bool
    
    var body: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                Toggle("Show Menu Bar Icon", isOn: $showMenuBarIcon)
            }
            
            Section {
                LabeledContent("Storage Location") {
                    Text("~/Library/Application Support/CleanMac")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Cleaning Settings
struct CleaningSettingsView: View {
    @AppStorage("cleanSystemCache") private var cleanSystemCache = true
    @AppStorage("cleanUserCache") private var cleanUserCache = true
    @AppStorage("cleanLogs") private var cleanLogs = true
    @AppStorage("cleanDownloads") private var cleanDownloads = false
    @AppStorage("cleanTrash") private var cleanTrash = false
    
    var body: some View {
        Form {
            Section("Smart Scan includes:") {
                Toggle("System Cache", isOn: $cleanSystemCache)
                Toggle("User Cache", isOn: $cleanUserCache)
                Toggle("System & App Logs", isOn: $cleanLogs)
                Toggle("Downloads folder", isOn: $cleanDownloads)
                Toggle("Trash", isOn: $cleanTrash)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Notification Settings
struct NotificationSettingsView: View {
    @Binding var notificationsEnabled: Bool
    @Binding var autoScanEnabled: Bool
    @Binding var autoScanInterval: Int
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
            }
            
            Section("Automatic Scanning") {
                Toggle("Enable Auto Scan", isOn: $autoScanEnabled)
                
                if autoScanEnabled {
                    Picker("Scan Interval", selection: $autoScanInterval) {
                        Text("Daily").tag(1)
                        Text("Weekly").tag(7)
                        Text("Monthly").tag(30)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - About View
struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 50))
                .foregroundStyle(.linearGradient(
                    colors: [.green, .mint],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            Text("CleanMac")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Version 1.0.0")
                .foregroundColor(.secondary)
            
            Text("A free, open-source alternative to CleanMyMac")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Divider()
                .frame(width: 200)
            
            Text("Made with ❤️ using SwiftUI")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Link("View on GitHub", destination: URL(string: "https://github.com")!)
                .font(.caption)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

/*
#Preview {
    SettingsView()
        .environmentObject(AppState())
}
*/
