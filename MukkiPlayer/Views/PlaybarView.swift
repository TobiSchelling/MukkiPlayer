//
//  PlaybarView.swift
//  MukkiPlayer
//
//  Created by Tobias Schelling on 02.01.26.
//

import SwiftUI

struct PlaybarView: View {
    @ObservedObject var playerManager = MusicPlayerManager.shared
    
    var body: some View {
        HStack(spacing: 0) {
            // Previous button
            Button(action: {
                Task {
                    await playerManager.skipToPrevious()
                }
            }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .frame(width: 80, height: 80)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlaybarButtonStyle())
            
            Spacer()
            
            // Track info
            VStack(spacing: 4) {
                if !playerManager.currentTrackTitle.isEmpty {
                    Text(playerManager.currentTrackTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(playerManager.currentTrackArtist)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                } else {
                    Text("No music playing")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity)
            
            // Play/Pause button
            Button(action: {
                Task {
                    await playerManager.togglePlayPause()
                }
            }) {
                Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
                    .frame(width: 80, height: 80)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlaybarButtonStyle())
            
            Spacer()
            
            // Next button
            Button(action: {
                Task {
                    await playerManager.skipToNext()
                }
            }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .frame(width: 80, height: 80)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlaybarButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.2, green: 0.2, blue: 0.3),
                    Color(red: 0.15, green: 0.15, blue: 0.25)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(20, corners: [.topLeft, .topRight])
    }
}

struct PlaybarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// Corner radius extension for specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    PlaybarView()
        .frame(height: 100)
}
