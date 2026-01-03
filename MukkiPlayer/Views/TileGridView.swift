//
//  TileGridView.swift
//  MukkiPlayer
//
//  Created by Tobias Schelling on 02.01.26.
//

import SwiftUI

struct TileGridView: View {
    @StateObject private var playerManager = MusicPlayerManager.shared
    
    // Create isolated tile models for each position
    @StateObject private var tile0 = TileModel(position: 0)
    @StateObject private var tile1 = TileModel(position: 1)
    @StateObject private var tile2 = TileModel(position: 2)
    @StateObject private var tile3 = TileModel(position: 3)
    @StateObject private var tile4 = TileModel(position: 4)
    @StateObject private var tile5 = TileModel(position: 5)
    @StateObject private var tile6 = TileModel(position: 6)
    @StateObject private var tile7 = TileModel(position: 7)
    @StateObject private var tile8 = TileModel(position: 8)
    
    private var tiles: [TileModel] {
        [tile0, tile1, tile2, tile3, tile4, tile5, tile6, tile7, tile8]
    }
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(tiles, id: \.position) { tileModel in
                TileView(tileModel: tileModel)
                    .aspectRatio(1.0, contentMode: .fit)
            }
        }
        .padding(16)
    }
}

#Preview {
    TileGridView()
}
