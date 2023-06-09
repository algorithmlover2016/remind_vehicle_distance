//
//  ContentView.swift
//  VideoPlayerDemo
//
//  Created by gaoxiaoxing on 6/25/23.
//

import SwiftUI

struct ContentView: View {
    @StateObject var videoManager = VideoManager()
    var columns = [GridItem(.adaptive(minimum: 160), spacing: 20)]
    
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Text("Hello, world!")
                HStack {
                    ForEach(Query.allCases, id: \.self) {
                        searchQuery in
                        QueryTag(query: searchQuery, isSelected: videoManager.selectedQuery == searchQuery)
                            .onTapGesture {
                                videoManager.selectedQuery = searchQuery
                            }
                    }
                    
                }
                ScrollView {
                    if videoManager.videos.isEmpty {
                        ProgressView()
                    } else {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(videoManager.videos, id: \.id) {
                            video in
                            NavigationLink {
                                VideoView(video: video)
                            } label: {
                                VideoCard(video: video)
                            }
                        }
                        
                    }.padding()
                        
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .background(Color("AccentColor"))
            .navigationBarHidden(true)
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
