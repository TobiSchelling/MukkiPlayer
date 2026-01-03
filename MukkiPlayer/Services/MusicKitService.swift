//
//  MusicKitService.swift
//  MukkiPlayer
//
//  Created by Tobias Schelling on 02.01.26.
//

import Foundation
import MusicKit
import Combine

@MainActor
class MusicKitService: ObservableObject {
    nonisolated let objectWillChange = ObservableObjectPublisher()
    
    static let shared = MusicKitService()
    
    var authorizationStatus: MusicAuthorization.Status = .notDetermined {
        didSet { objectWillChange.send() }
    }
    var isAuthorized: Bool = false {
        didSet { objectWillChange.send() }
    }
    
    private init() {
        Task {
            await checkAuthorization()
        }
    }
    
    func checkAuthorization() async {
        let status = await MusicAuthorization.request()
        authorizationStatus = status
        isAuthorized = status == .authorized
    }
    
    func requestAuthorization() async -> Bool {
        let status = await MusicAuthorization.request()
        authorizationStatus = status
        isAuthorized = status == .authorized
        return isAuthorized
    }
    
    // MARK: - Search
    
    func searchAlbums(query: String) async throws -> [Album] {
        guard !query.isEmpty else { return [] }
        
        var request = MusicCatalogSearchRequest(term: query, types: [Album.self])
        request.limit = 25
        
        let response = try await request.response()
        return Array(response.albums)
    }
    
    func searchPlaylists(query: String) async throws -> [Playlist] {
        guard !query.isEmpty else { return [] }
        
        var request = MusicCatalogSearchRequest(term: query, types: [Playlist.self])
        request.limit = 25
        
        let response = try await request.response()
        return Array(response.playlists)
    }
    
    func searchAll(query: String) async throws -> ([Album], [Playlist]) {
        guard !query.isEmpty else { return ([], []) }
        
        var request = MusicCatalogSearchRequest(term: query, types: [Album.self, Playlist.self])
        request.limit = 15
        
        let response = try await request.response()
        return (Array(response.albums), Array(response.playlists))
    }
    
    // MARK: - Fetch by ID
    
    func fetchAlbum(id: String) async throws -> Album? {
        let request = MusicCatalogResourceRequest<Album>(matching: \.id, equalTo: MusicItemID(id))
        let response = try await request.response()
        return response.items.first
    }
    
    func fetchPlaylist(id: String) async throws -> Playlist? {
        let request = MusicCatalogResourceRequest<Playlist>(matching: \.id, equalTo: MusicItemID(id))
        let response = try await request.response()
        return response.items.first
    }
    
    // MARK: - Artwork Caching
    
    private var artworkCache: [String: Data] = [:]
    
    func fetchArtworkData(for url: URL?, size: CGSize = CGSize(width: 300, height: 300)) async -> Data? {
        guard let url = url else { return nil }
        
        let cacheKey = url.absoluteString
        if let cached = artworkCache[cacheKey] {
            return cached
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            artworkCache[cacheKey] = data
            return data
        } catch {
            print("Error fetching artwork: \(error)")
            return nil
        }
    }
    
    func fetchArtworkData(from artwork: Artwork?, size: CGSize = CGSize(width: 300, height: 300)) async -> Data? {
        guard let artwork = artwork else { return nil }
        let url = artwork.url(width: Int(size.width), height: Int(size.height))
        return await fetchArtworkData(for: url, size: size)
    }
}
