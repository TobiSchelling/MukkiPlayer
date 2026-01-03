//
//  TileModel.swift
//  MukkiPlayer
//
//  Created by Tobias Schelling on 02.01.26.
//

import Foundation
import SwiftUI
import CoreData
import MusicKit
import Combine

/// Represents the isolated state and configuration for a single tile
@MainActor
class TileModel: ObservableObject, Identifiable {
    nonisolated let objectWillChange = ObservableObjectPublisher()
    
    nonisolated let position: Int
    
    var tileConfig: TileConfig?
    var displayName: String = ""
    var artworkImage: Image?
    var isConfigured: Bool = false
    var isPlaying: Bool = false
    
    var id: UUID? {
        tileConfig?.id
    }
    
    // Rainbow colors for 9 tiles
    static let rainbowColors: [Color] = [
        Color(red: 1.0, green: 0.3, blue: 0.3),     // Red
        Color(red: 1.0, green: 0.6, blue: 0.2),     // Orange
        Color(red: 1.0, green: 0.9, blue: 0.3),     // Yellow
        Color(red: 0.4, green: 0.9, blue: 0.4),     // Green
        Color(red: 0.3, green: 0.8, blue: 0.8),     // Teal
        Color(red: 0.3, green: 0.5, blue: 1.0),     // Blue
        Color(red: 0.5, green: 0.3, blue: 0.9),     // Indigo
        Color(red: 0.8, green: 0.4, blue: 0.9),     // Purple
        Color(red: 1.0, green: 0.5, blue: 0.7),     // Pink
    ]
    
    var backgroundColor: Color {
        TileModel.rainbowColors[position % TileModel.rainbowColors.count]
    }
    
    init(position: Int) {
        self.position = position
        loadFromCoreData()
    }
    
    func loadFromCoreData() {
        if let tile = PersistenceController.shared.getTile(at: position) {
            self.tileConfig = tile
            self.displayName = tile.displayName ?? ""
            self.isConfigured = tile.musicItemID != nil
            
            // Load cached artwork
            if let artworkData = tile.artworkData,
               let uiImage = UIImage(data: artworkData) {
                self.artworkImage = Image(uiImage: uiImage)
            }
            objectWillChange.send()
        }
    }
    
    func configure(with album: Album) async {
        guard let tile = tileConfig else { return }
        
        tile.musicItemID = album.id.rawValue
        tile.musicItemType = "album"
        tile.displayName = album.title
        tile.lastPlayedTrackIndex = 0
        tile.lastPlayedTrackID = nil
        
        // Cache artwork
        if let artworkData = await MusicKitService.shared.fetchArtworkData(from: album.artwork) {
            tile.artworkData = artworkData
            if let uiImage = UIImage(data: artworkData) {
                self.artworkImage = Image(uiImage: uiImage)
            }
        }
        
        self.displayName = album.title
        self.isConfigured = true
        objectWillChange.send()
        
        PersistenceController.shared.save()
    }
    
    func configure(with playlist: Playlist) async {
        guard let tile = tileConfig else { return }
        
        tile.musicItemID = playlist.id.rawValue
        tile.musicItemType = "playlist"
        tile.displayName = playlist.name
        tile.lastPlayedTrackIndex = 0
        tile.lastPlayedTrackID = nil
        
        // Cache artwork
        if let artworkData = await MusicKitService.shared.fetchArtworkData(from: playlist.artwork) {
            tile.artworkData = artworkData
            if let uiImage = UIImage(data: artworkData) {
                self.artworkImage = Image(uiImage: uiImage)
            }
        }
        
        self.displayName = playlist.name
        self.isConfigured = true
        objectWillChange.send()
        
        PersistenceController.shared.save()
    }
    
    func clearConfiguration() {
        guard let tile = tileConfig else { return }
        
        tile.musicItemID = nil
        tile.musicItemType = nil
        tile.displayName = nil
        tile.artworkData = nil
        tile.lastPlayedTrackIndex = 0
        tile.lastPlayedTrackID = nil
        
        self.displayName = ""
        self.artworkImage = nil
        self.isConfigured = false
        objectWillChange.send()
        
        PersistenceController.shared.save()
    }
    
    func play() async {
        guard let tile = tileConfig else { return }
        await MusicPlayerManager.shared.play(tile: tile)
    }
    
    func updatePlayingState(activeTileID: UUID?) {
        isPlaying = id == activeTileID && MusicPlayerManager.shared.isPlaying
        objectWillChange.send()
    }
}
