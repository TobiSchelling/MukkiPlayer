//
//  MusicPlayerManager.swift
//  MukkiPlayer
//
//  Created by Tobias Schelling on 02.01.26.
//

import Foundation
import MusicKit
import Combine
import CoreData

@MainActor
class MusicPlayerManager: ObservableObject {
    nonisolated let objectWillChange = ObservableObjectPublisher()
    
    static let shared = MusicPlayerManager()
    
    private let player = ApplicationMusicPlayer.shared
    private var cancellables = Set<AnyCancellable>()
    
    var isPlaying: Bool = false {
        didSet { objectWillChange.send() }
    }
    var currentEntry: ApplicationMusicPlayer.Queue.Entry? {
        didSet { objectWillChange.send() }
    }
    var activeTileID: UUID? {
        didSet { objectWillChange.send() }
    }
    var currentTrackTitle: String = "" {
        didSet { objectWillChange.send() }
    }
    var currentTrackArtist: String = "" {
        didSet { objectWillChange.send() }
    }
    
    private init() {
        setupObservers()
    }
    
    private func setupObservers() {
        // Observe playback state
        player.state.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updatePlaybackState()
            }
            .store(in: &cancellables)
        
        // Observe queue changes
        player.queue.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateCurrentEntry()
            }
            .store(in: &cancellables)
    }
    
    private func updatePlaybackState() {
        isPlaying = player.state.playbackStatus == .playing
    }
    
    private func updateCurrentEntry() {
        currentEntry = player.queue.currentEntry
        
        if let entry = currentEntry {
            switch entry.item {
            case .song(let song):
                currentTrackTitle = song.title
                currentTrackArtist = song.artistName
            default:
                currentTrackTitle = entry.title
                currentTrackArtist = entry.subtitle ?? ""
            }
        } else {
            currentTrackTitle = ""
            currentTrackArtist = ""
        }
        
        // Update last played track for active tile
        if let tileID = activeTileID, let entry = currentEntry {
            saveLastPlayedTrack(for: tileID, entry: entry)
        }
    }
    
    // MARK: - Playback Control
    
    func play(tile: TileConfig) async {
        guard let musicItemID = tile.musicItemID,
              let musicItemType = tile.musicItemType else {
            return
        }
        
        activeTileID = tile.id
        
        do {
            if musicItemType == "album" {
                if let album = try await MusicKitService.shared.fetchAlbum(id: musicItemID) {
                    let detailedAlbum = try await album.with([.tracks])
                    
                    // Find the starting track
                    var startingTrackIndex = Int(tile.lastPlayedTrackIndex)
                    if let tracks = detailedAlbum.tracks, startingTrackIndex >= tracks.count {
                        startingTrackIndex = 0
                    }
                    
                    // Get tracks and create queue
                    if let tracks = detailedAlbum.tracks {
                        player.queue = ApplicationMusicPlayer.Queue(for: tracks)
                        try await player.play()
                        
                        // Skip to last played track if needed
                        for _ in 0..<startingTrackIndex {
                            try await player.skipToNextEntry()
                        }
                    }
                }
            } else if musicItemType == "playlist" {
                if let playlist = try await MusicKitService.shared.fetchPlaylist(id: musicItemID) {
                    let detailedPlaylist = try await playlist.with([.tracks])
                    
                    // Find the starting track
                    var startingTrackIndex = Int(tile.lastPlayedTrackIndex)
                    if let tracks = detailedPlaylist.tracks, startingTrackIndex >= tracks.count {
                        startingTrackIndex = 0
                    }
                    
                    // Get tracks and create queue
                    if let tracks = detailedPlaylist.tracks {
                        player.queue = ApplicationMusicPlayer.Queue(for: tracks)
                        try await player.play()
                        
                        // Skip to last played track if needed
                        for _ in 0..<startingTrackIndex {
                            try await player.skipToNextEntry()
                        }
                    }
                }
            }
        } catch {
            print("Error playing: \(error)")
        }
    }
    
    func pause() {
        player.pause()
    }
    
    func resume() async {
        do {
            try await player.play()
        } catch {
            print("Error resuming: \(error)")
        }
    }
    
    func togglePlayPause() async {
        if isPlaying {
            pause()
        } else {
            await resume()
        }
    }
    
    func skipToNext() async {
        do {
            try await player.skipToNextEntry()
        } catch {
            print("Error skipping to next: \(error)")
        }
    }
    
    func skipToPrevious() async {
        do {
            try await player.skipToPreviousEntry()
        } catch {
            print("Error skipping to previous: \(error)")
        }
    }
    
    func stop() {
        player.stop()
        activeTileID = nil
    }
    
    // MARK: - Track State Persistence
    
    private func saveLastPlayedTrack(for tileID: UUID, entry: ApplicationMusicPlayer.Queue.Entry) {
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<TileConfig> = TileConfig.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", tileID as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            if let tile = try context.fetch(fetchRequest).first {
                // Find index of current entry
                let index = player.queue.entries.firstIndex(where: { $0.id == entry.id }) ?? 0
                tile.lastPlayedTrackIndex = Int32(index)
                
                if case .song(let song) = entry.item {
                    tile.lastPlayedTrackID = song.id.rawValue
                }
                PersistenceController.shared.save()
            }
        } catch {
            print("Error saving last played track: \(error)")
        }
    }
    
    func getCurrentTrackIndex() -> Int {
        guard let entry = currentEntry else { return 0 }
        return player.queue.entries.firstIndex(where: { $0.id == entry.id }) ?? 0
    }
}
