import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        Form {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundStyle(.linearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Text(appState.localizedString("settings_title"))
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .padding(.bottom, 5)
                
                // Section 1: API
                VStack(alignment: .leading, spacing: 8) {
                    Text(appState.localizedString("settings_groq"))
                        .font(.headline)
                    
                    SecureField(appState.localizedString("enter_api_key"), text: $appState.groqApiKey)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: .infinity)
                    
                    Text(appState.localizedString("api_hint"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
                
                Divider()
                
                // Section 2: Behavior & Language (Audio & ASR)
                VStack(alignment: .leading, spacing: 10) {
                    Text(appState.localizedString("integration"))
                        .font(.headline)
                    
                    HStack {
                        Text(appState.localizedString("recording_lang"))
                            .fontWeight(.medium)
                        Spacer()
                        Picker("", selection: $appState.selectedLanguage) {
                            ForEach(LanguageOption.allCases) { option in
                                Text(appState.localizedString("lang_" + option.rawValue)).tag(option.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 280)
                    }
                    .padding(.vertical, 2)
                    
                    HStack {
                        Text(appState.localizedString("max_duration_lbl"))
                            .fontWeight(.medium)
                        Spacer()
                        Picker("", selection: $appState.maxRecordingDuration) {
                            Text(appState.localizedString("duration_1min")).tag(60.0)
                            Text(appState.localizedString("duration_2min")).tag(120.0)
                            Text(appState.localizedString("duration_3min")).tag(180.0)
                            Text(appState.localizedString("duration_5min")).tag(300.0)
                            Text(appState.localizedString("duration_10min")).tag(600.0)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 280)
                    }
                    .padding(.vertical, 2)
                    
                    Toggle(appState.localizedString("auto_paste_toggle"), isOn: $appState.autoPasteEnabled)
                        .toggleStyle(.checkbox)
                        .padding(.top, 4)
                    
                    Text(appState.localizedString("auto_paste_hint"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
                
                Divider()
                
                // Section 3: Shortcut
                VStack(alignment: .leading, spacing: 10) {
                    Text(appState.localizedString("hotkey_title"))
                        .font(.headline)
                    
                    HStack {
                        Text(appState.localizedString("hotkey_lbl"))
                            .fontWeight(.medium)
                        Spacer()
                        Picker("", selection: $appState.selectedHotkey) {
                            ForEach(HotkeyOption.allCases) { option in
                                Text(option.displayName).tag(option.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 280)
                    }
                    .padding(.vertical, 2)
                    
                    HStack {
                        Image(systemName: "keyboard")
                            .foregroundColor(.purple)
                        Text(appState.localizedString("hotkey_hint"))
                            .fontWeight(.medium)
                            .font(.subheadline)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)
                    
                    Text(appState.localizedString("hotkey_desc"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
                
                Divider()
                
                // Section 4: Interface & Theme
                VStack(alignment: .leading, spacing: 10) {
                    Text(appState.localizedString("settings_ui_header"))
                        .font(.headline)
                    
                    HStack {
                        Text(appState.localizedString("ui_lang"))
                            .fontWeight(.medium)
                        Spacer()
                        Picker("", selection: $appState.selectedUILanguage) {
                            ForEach(UILanguage.allCases) { option in
                                Text(appState.localizedString("ui_lang_" + option.rawValue)).tag(option.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 280)
                    }
                    .padding(.vertical, 2)
                    
                    HStack {
                        Text(appState.localizedString("theme_title"))
                            .fontWeight(.medium)
                        Spacer()
                        Picker("", selection: $appState.selectedTheme) {
                            ForEach(ThemeOption.allCases) { option in
                                Text(appState.localizedString("theme_" + option.rawValue)).tag(option.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 280)
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding()
        }
        .frame(width: 480, height: 680)
    }
}
