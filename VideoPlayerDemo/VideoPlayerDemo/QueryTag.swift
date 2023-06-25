//
//  QueryTag.swift
//  VideoPlayerDemo
//
//  Created by gaoxiaoxing on 6/25/23.
//

import SwiftUI

struct QueryTag: View {
    var query: Query
    var isSelected: Bool
    
    var body: some View {
        Text(query.rawValue)
            .font(.caption)
            .bold()
            .foregroundColor(isSelected ? .blue : .gray)
            .padding(20)
            .background(.thinMaterial)
            .cornerRadius(20)
    }
    
}

struct QueryTag_Previews: PreviewProvider {
    static var previews: some View {
        QueryTag(query: Query.nature, isSelected: true)
    }
}
