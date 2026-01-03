//
//  ContentView.swift
//  MukkiPlayer
//
//  Created by Tobias Schelling on 02.01.26.
//

import SwiftUI
import MusicKit

struct ContentView: View {
    @StateObject private var musicKitService = MusicKitService.shared
    @StateObject private var playerManager = MusicPlayerManager.shared
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Authorization overlay or main content
                if !musicKitService.isAuthorized {
                    authorizationView
                } else {
                    // Main tile grid
                    TileGridView()
                        .frame(maxHeight: .infinity)
                    
                    // Bottom playbar
                    PlaybarView()
                        .frame(height: 100)
                }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.15),
                        Color(red: 0.15, green: 0.12, blue: 0.2)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .task {
            await musicKitService.checkAuthorization()
        }
    }
    
    private var authorizationView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "music.note.house.fill")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.8))
            
            Text("Welcome to MukkiPlayer!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("A kid-friendly music player for your Apple Music library")
                .font(.title3)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            Button(action: {
                Task {
                    await musicKitService.requestAuthorization()
                }
            }) {
                HStack {
                    Image(systemName: "music.note")
                    Text("Connect to Apple Music")
                }
                .font(.title2.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.pink, .purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
            
            Spacer()
        }
    }
}

#Preview {
    ContentView()
}
