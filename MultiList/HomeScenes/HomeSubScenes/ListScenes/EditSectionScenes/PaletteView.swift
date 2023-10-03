//
//  PaletteView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/21.
//

import SwiftUI

struct PaletteView: View {
    @Binding var selectedIndex: Int
    var currentColor: Int
    
    var body: some View {
        let colomn = Array(repeating: GridItem(.flexible(minimum: 30, maximum: 40), spacing: 10, alignment: .center), count: 5)
        LazyVGrid(columns: colomn) {
            ForEach(Color.colorSet.indices) { index in
                circleView(index: index)
                    .onTapGesture {
                        selectedIndex = index
                    }
            }
        }
    }
    
    func circleView(index: Int) -> some View {
        Circle()
            .foregroundColor(Color.colorSet[index])
            .shadow(color: .primaryInverted, radius: index == selectedIndex ? 3 : 0, x: 0, y: 0)
            .overlay {
                if index == selectedIndex {
                        Image(systemName: "checkmark")
                        .imageScale(.large)
                        .foregroundColor(.white)
                        .font(.caption)
                        .fontWeight(.black)
                }
                if index == currentColor {
                    nowMark
                }
            }
    }
}

struct PaletteView_Previews: PreviewProvider {
    static var previews: some View {
        PaletteView(selectedIndex: .constant(3), currentColor: 3)
    }
}
