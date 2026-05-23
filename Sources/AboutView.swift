import SwiftUI

struct AboutView: View {
    @ObservedObject var appState: AppState
    @State private var animateGradient = false
    
    var body: some View {
        ZStack {
            // Liquid Glass Background
            VisualEffectView(material: .popover, blendingMode: .behindWindow)
                .overlay(
                    // Floating vibrant liquid gradient blobs
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.18))
                            .frame(width: 180, height: 180)
                            .blur(radius: 35)
                            .offset(x: animateGradient ? -50 : 50, y: animateGradient ? -40 : 40)
                        
                        Circle()
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 150, height: 150)
                            .blur(radius: 30)
                            .offset(x: animateGradient ? 40 : -40, y: animateGradient ? 30 : -30)
                    }
                    .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: animateGradient)
                )
            
            VStack(spacing: 20) {
                // Neon Wave Icon
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 72, height: 72)
                        .overlay(
                            Circle()
                                .stroke(LinearGradient(colors: [.purple.opacity(0.8), .pink.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
                        )
                        .shadow(color: .purple.opacity(0.3), radius: 10)
                    
                    Image(systemName: "waveform")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.linearGradient(colors: [.purple, .pink, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
                .padding(.top, 10)
                
                // Title and Version
                VStack(spacing: 4) {
                    Text("ASR-app")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("\(appState.localizedString("version")) 1.2.1")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 8)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(6)
                }
                
                // Description
                Text(appState.localizedString("about_desc"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 24)
                    .fixedSize(horizontal: false, vertical: true)
                
                Divider()
                    .padding(.horizontal, 40)
                
                // Warm Credits (Eva & Alex)
                VStack(spacing: 6) {
                    Text(appState.localizedString("about_credits"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.linearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("© 2026 ASR-app Project")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
        .frame(width: 360, height: 380)
        .onAppear {
            animateGradient = true
        }
    }
}
