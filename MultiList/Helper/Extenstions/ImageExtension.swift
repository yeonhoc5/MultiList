//
//  ImageExtension.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/13.
//

import SwiftUI

extension View {

    func shareMark(width: CGFloat) -> some View {
        ZStack(alignment: .center) {
//            Circle().fill(Color.white)
//                .shadow(color: .black, radius: 1, x: 0, y: 0)
            Image(systemName: "person.2.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 0)
//                .padding(width * 0.13)
        }
        .frame(width: width, height: width)
    }
}

//struct ImageExtension_Previews: PreviewProvider {
//    static var previews: some View {
//        ImageExtension()
//    }
//}
