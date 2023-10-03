//
//  LinkListImage.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/22.
//

import SwiftUI

struct LinkListImage: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .foregroundColor(.white)
                .shadow(color: .secondary, radius: 1, x: 0, y: 0)
            VStack(spacing: 20) {
                Text("링크 리스트")
                    .foregroundColor(.black)
                    .bold()
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(0..<4) { int in
                        HStack(alignment: .bottom) {
                            Text("\(int + 1).")
                            Rectangle()
                                .frame(height: 1)
                            Image(systemName: "link")
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct LinkListImage_Previews: PreviewProvider {
    static var previews: some View {
        LinkListImage()
    }
}
