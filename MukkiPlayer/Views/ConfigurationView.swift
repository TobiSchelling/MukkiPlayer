//
//  ConfigurationView.swift
//  MukkiPlayer
//
//  Created by Tobias Schelling on 02.01.26.
//

import SwiftUI
import MusicKit

struct ConfigurationView: View {
    @ObservedObject var tileModel: TileModel
    @ObservedObject var musicKitService = MusicKitService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText: String = ""
    @State private var searchResults: ([Album], [Playlist]) = ([], [])
    @State private var isSearching: Bool = false
    @State private var selectedTab: Int = 0
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Authorization check
                if !musicKitService.isAuthorized {
                    authorizationView
                } else {
                    // Search bar
                    searchBar
                    
                    // Segmented control for Albums/Playlists
                    Picker("Type", selection: $selectedTab) {
                        Text("Albums").tag(0)
                        Text("Playlists").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    // Results list
                    if isSearching {
                        ProgressView("Searching...")
                            .frame(maxHeight: .infinity)
                    } else if selectedTab == 0 {
                        albumsList
                    } else {
                        playlistsList
                    }
                }
            }
            .navigationTitle("Configure Tile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if tileModel.isConfigured {
                        Button("Clear") {
                            tileModel.clearConfiguration()
                            dismiss()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .task {
                await musicKitService.checkAuthorization()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var authorizationView: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.house")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Apple Music Access Required")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("MukkiPlayer needs access to Apple Music to browse and play your music.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button(action: {
                Task {
                    await musicKitService.requestAuthorization()
                }
            }) {
                Text("Grant Access")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search albums or playlists...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .onSubmit {
                    performSearch()
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    searchResults = ([], [])
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var albumsList: some View {
        List {
            if searchResults.0.isEmpty && !searchText.isEmpty && !isSearching {
                Text("No albums found")
                    .foregroundColor(.secondary)
            } else {
                ForEach(searchResults.0, id: \.id) { album in
                    AlbumRow(album: album) {
                        selectAlbum(album)
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var playlistsList: some View {
        List {
            if searchResults.1.isEmpty && !searchText.isEmpty && !isSearching {
                Text("No playlists found")
                    .foregroundColor(.secondary)
            } else {
                ForEach(searchResults.1, id: \.id) { playlist in
                    PlaylistRow(playlist: playlist) {
                        selectPlaylist(playlist)
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        Task {
            do {
                searchResults = try await musicKitService.searchAll(query: searchText)
            } catch {
                print("Search error: \(error)")
                errorMessage = error.localizedDescription
            }
            isSearching = false
        }
    }
    
    private func selectAlbum(_ album: Album) {
        Task {
            await tileModel.configure(with: album)
            dismiss()
        }
    }
    
    private func selectPlaylist(_ playlist: Playlist) {
        Task {
            await tileModel.configure(with: playlist)
            dismiss()
        }
    }
}

struct AlbumRow: View {
    let album: Album
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Artwork
                if let artwork = album.artwork {
                    ArtworkImage(artwork, width: 60)
                        .cornerRadius(8)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "music.note")
                                .foregroundColor(.gray)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(album.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(album.artistName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PlaylistRow: View {
    let playlist: Playlist
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Artwork
                if let artwork = playlist.artwork {
                    ArtworkImage(artwork, width: 60)
                        .cornerRadius(8)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "music.note.list")
                                .foregroundColor(.gray)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(playlist.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if let curatorName = playlist.curatorName {
                        Text(curatorName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ConfigurationView(tileModel: TileModel(position: 0))
}
