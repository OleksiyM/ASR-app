import SwiftUI

struct MainPopoverView: View {
    @ObservedObject var appState: AppState
    @State private var animateGradient = false
    @State private var micPulse = false
    
    var body: some View {
        ZStack {
            // Liquid Glass Background
            VisualEffectView(material: .popover, blendingMode: .behindWindow)
                .overlay(
                    // Floating vibrant liquid gradient blobs
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.18))
                            .frame(width: 250, height: 250)
                            .blur(radius: 40)
                            .offset(x: animateGradient ? -80 : 80, y: animateGradient ? -60 : 60)
                        
                        Circle()
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 200, height: 200)
                            .blur(radius: 40)
                            .offset(x: animateGradient ? 70 : -70, y: animateGradient ? 50 : -50)
                        
                        Circle()
                            .fill(Color.pink.opacity(0.12))
                            .frame(width: 150, height: 150)
                            .blur(radius: 35)
                            .offset(x: animateGradient ? -40 : 40, y: animateGradient ? 80 : -80)
                    }
                    .animation(.easeInOut(duration: 7).repeatForever(autoreverses: true), value: animateGradient)
                )
            
            // App Layout
            VStack(spacing: 16) {
                // Top Header Bar
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "waveform")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.linearGradient(colors: [.pink, .purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                        Text("ASR-app")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    // About Button
                    Button {
                        openAboutWindow()
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(appState.localizedString("about_title"))
                    .padding(.trailing, 4)
                    
                    // Settings Button
                    Button {
                        openSettingsWindow()
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(appState.localizedString("settings_title"))
                    
                    // Exit Button
                    Button {
                        NSApp.terminate(nil)
                    } label: {
                        Image(systemName: "power")
                            .font(.system(size: 14))
                            .foregroundColor(.pink.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 8)
                    .help(appState.localizedString("exit"))
                }
                .padding(.horizontal, 4)
                
                // Central Workspace Area
                VStack(spacing: 12) {
                    switch appState.status {
                    case .idle:
                        idleStateView
                    case .recording:
                        recordingStateView
                    case .uploading, .transcribing:
                        loadingStateView
                    case .success(let text):
                        successStateView(text: text)
                    case .failure(let error):
                        failureStateView(error: error)
                    }
                }
                .frame(maxHeight: .infinity)
                
                // Quick Controls Footer
                HStack {
                    HStack(spacing: 6) {
                        Toggle("", isOn: $appState.autoPasteEnabled)
                            .toggleStyle(.switch)
                            .scaleEffect(0.7)
                            .labelsHidden()
                        
                        Text("\(appState.localizedString("paste")) (\(getHotkeySymbol()))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if !appState.groqApiKey.isEmpty {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text("Groq ASR")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Button {
                            openSettingsWindow()
                        } label: {
                            Text(appState.localizedString("configure_api_key"))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.pink)
                                .underline()
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 4)
            }
            .padding(16)
        }
        .frame(width: 320, height: 260)
        .onAppear {
            animateGradient = true
        }
    }
    
    // MARK: - State Views
    
    private var idleStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            
            // Neon Pulsing Mic Button
            Button {
                appState.toggleRecording()
            } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 64, height: 64)
                        .overlay(
                            Circle()
                                .stroke(LinearGradient(colors: [.purple.opacity(0.8), .blue.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
                        )
                        .shadow(color: .purple.opacity(0.3), radius: 10)
                    
                    Image(systemName: "mic.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(.linearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
            }
            .buttonStyle(.plain)
            
            Text(appState.localizedString("ready_to_record"))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    private var recordingStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            
            // Interactive 9-band audio visualizer
            WaveformView(level: appState.audioLevel)
            
            HStack(spacing: 8) {
                // Pulsing red indicator
                Circle()
                    .fill(Color.pink)
                    .frame(width: 8, height: 8)
                    .opacity(micPulse ? 0.3 : 1.0)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                            micPulse.toggle()
                        }
                    }
                
                Text(formatTime(appState.recordingDuration))
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
            }
            
            Button {
                appState.toggleRecording()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.pink.opacity(0.15))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle()
                                .stroke(Color.pink.opacity(0.8), lineWidth: 2)
                        )
                        .shadow(color: .pink.opacity(0.4), radius: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.pink)
                        .frame(width: 14, height: 14)
                }
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
    }
    
    private var loadingStateView: some View {
        VStack(spacing: 14) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.2)
                .accentColor(.purple)
            
            Text(appState.status == .uploading ? appState.localizedString("uploading") : appState.localizedString("transcribing"))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary.opacity(0.8))
            
            Text(appState.localizedString("whisper_model_info"))
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    private func successStateView(text: String) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 16, weight: .bold))
                Text(appState.autoPasteEnabled ? appState.localizedString("success_pasted") : appState.localizedString("success_copied"))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.green)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
            .background(Color.green.opacity(0.1))
            .cornerRadius(20)
            
            // Transcription Preview Container
            ScrollView {
                Text(text)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary.opacity(0.9))
                    .multilineTextAlignment(.leading)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: 110)
            .background(.ultraThinMaterial)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
            
            // Reset Button
            Button {
                appState.resetToIdle()
            } label: {
                Text(appState.localizedString("done"))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 16)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
    }
    
    private func failureStateView(error: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.pink)
                .font(.system(size: 32))
            
            Text(error)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.pink)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .padding(.horizontal, 12)
            
            Button {
                appState.resetToIdle()
            } label: {
                Text(appState.localizedString("back"))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.pink)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 16)
                    .background(Color.pink.opacity(0.15))
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
    }
    
    // MARK: - Helpers
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    private func getHotkeySymbol() -> String {
        let option = HotkeyOption(rawValue: appState.selectedHotkey) ?? .optionSpace
        switch option {
        case .optionSpace: return "⌥Space"
        case .controlSpace: return "⌃Space"
        case .optionZ: return "⌥Z"
        case .cmdShiftK: return "⌘⇧K"
        case .cmdOptionK: return "⌘⌥K"
        }
    }
    
    private func openSettingsWindow() {
        NotificationCenter.default.post(name: Notification.Name("OpenSettingsWindow"), object: nil)
    }
    
    private func openAboutWindow() {
        NotificationCenter.default.post(name: Notification.Name("OpenAboutWindow"), object: nil)
    }
}

// MARK: - Waveform View

struct WaveformView: View {
    let level: Float
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<9) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(LinearGradient(
                        colors: [.pink.opacity(0.9), .purple.opacity(0.9), .blue.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(width: 4, height: height(for: index))
                    .animation(.spring(response: 0.12, dampingFraction: 0.45), value: level)
            }
        }
        .frame(height: 50)
    }
    
    private func height(for index: Int) -> CGFloat {
        // Natural waveform heights distribution
        let baseHeights: [CGFloat] = [10, 22, 36, 46, 32, 46, 36, 22, 10]
        let scale = CGFloat(level)
        return max(6, baseHeights[index] * (0.15 + scale * 0.85))
    }
}

// MARK: - VisualEffectView for LiquidGlass

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
