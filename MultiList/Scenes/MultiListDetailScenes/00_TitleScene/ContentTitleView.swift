//
//  ContentTitleView.swift
//  MultiList
//
//  Created by yeonhoc5 on 10/9/23.
//

import SwiftUI

struct ContentTitleView: View {
    let title: String
    @Binding var isShowingTitleAlert: Bool
    @Binding var newTitle: String
    
    var body: some View {
        HStack(alignment: .top) {
            Button {
                newTitle = title
                self.isShowingTitleAlert = true
            } label: {
                Image(systemName: "square.and.pencil")
                    .imageScale(.large)
                    .foregroundStyle(Color.teal)
            }
            .buttonStyle(ScaleEffect(scale: 0.7))
            .frame(height: 38)
            Text(title)
                .font(.largeTitle)
                .multilineTextAlignment(.leading)
                .lineLimit(3, reservesSpace: screenSize.width > screenSize.height)
            Spacer()
        }
        .fontWeight(.bold)
        .padding([.horizontal, .top], 15)
        .padding(.bottom, 10)
    }
}

#Preview {
    ContentTitleView(title: "Title", isShowingTitleAlert: .constant(true), newTitle: .constant(""))
}
