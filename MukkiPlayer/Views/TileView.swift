//
//  TileView.swift
//  MukkiPlayer
//
//  Created by Tobias Schelling on 02.01.26.
//

import SwiftUI
import Combine

struct TileView: View {
    @ObservedObject var tileModel: TileModel
    @ObservedObject var playerManager = MusicPlayerManager.shared
    
    @State private var isPulsing: Bool = false
    @State private var showingConfiguration: Bool = false
    
    var isActive: Bool {
        tileModel.id == playerManager.activeTileID
    }
    
    var isPlaying: Bool {
        isActive && playerManager.isPlaying
    }
    
    var body: some View {
        Button(action: {
            Task {
                await tileModel.play()
            }
        }) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 20)
                    .fill(tileModel.backgroundColor)
                    .shadow(color: isActive ? tileModel.backgroundColor.opacity(0.6) : .clear, radius: 10)
                
                // Content
                VStack(spacing: 12) {
                    if let artwork = tileModel.artworkImage {
                        artwork
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(16)
                    } else if tileModel.isConfigured {
                        Image(systemName: "music.note")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.8))
                    } else {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.6))
                        Text("Tap to configure")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    if !tileModel.displayName.isEmpty {
                        Text(tileModel.displayName)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                            .padding(.bottom, 8)
                    }
                }
                
                // Playing indicator
                if isPlaying {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "play.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Circle().fill(Color.black.opacity(0.3)))
                                .padding(8)
                        }
                        Spacer()
                    }
                }
            }
            .scaleEffect(isPulsing ? 1.03 : 1.0)
            .animation(
                isPlaying ?
                Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true) :
                    .default,
                value: isPulsing
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture {
            showingConfiguration = true
        }
        .sheet(isPresented: $showingConfiguration) {
            ConfigurationView(tileModel: tileModel)
        }
        .onChange(of: isPlaying) { oldValue, newValue in
            isPulsing = newValue
        }
        .onAppear {
            isPulsing = isPlaying
        }
    }
}

#Preview {
    TileView(tileModel: TileModel(position: 0))
        .frame(width: 200, height: 200)
        .padding()
}
