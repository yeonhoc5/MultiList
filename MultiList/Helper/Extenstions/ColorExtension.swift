//
//  ColorExtension.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/14.
//

import SwiftUI

extension Color {
    static var primaryInverted: Color = Color(uiColor: UIColor.systemBackground)
    
    static var numberingGray: Color = Color(red: 230/255, green: 230/255, blue: 230/255)
    
    static let colorSet: [Color] = [
        Color(red: 230/255, green: 90/255, blue: 72/255),
        Color(red: 243/255, green: 185/255, blue: 0/255),
//        Color(red: 0/255, green: 150/255, blue: 168/255),
//        Color(red: 209/255, green: 122/255, blue: 127/255),
        Color(red: 0/255, green: 186/255, blue: 206/255),
        Color(red: 102/255, green: 198/255, blue: 92/255),
        Color(red: 140/255, green: 54/255, blue: 167/255),
        
        
        Color(red: 249/255, green: 118/255, blue: 220/255),
        Color(red: 239/255, green: 234/255, blue: 145/255),
        Color(red: 37/255, green: 120/255, blue: 224/255),
        Color(red: 0/255, green: 85/255, blue: 0/255),
        Color(red: 137/255, green: 150/255, blue: 255/255)
    
        
//        Color(red: 255/255, green: 92/255, blue: 118/255),
//        Color(red: 197/255, green: 198/255, blue: 40/255),
//        Color(red: 249/255, green: 204/255, blue: 105/255),
//        Color(red: 212/255, green: 54/255, blue: 0/255),
//        Color(red: 148/255, green: 203/255, blue: 236/255),
//        Color(red: 212/255, green: 64/255, blue: 163/255),
//        Color(red: 52/255, green: 178/255, blue: 102/255),
//        Color(red: 164/255, green: 21/255, blue: 3/255),
//        Color(red: 151/255, green: 95/255, blue: 139/255),
//        Color(red: 40/255, green: 100/255, blue: 188/255),
//        Color(red: 0/255, green: 219/255, blue: 182/255),
//        Color(red: 154/255, green: 43/255, blue: 111/255),
//        Color(red: 109/255, green: 128/255, blue: 139/255),
//        Color(red: 147/255, green: 0/255, blue: 66/255),
//        Color(red: 82/255, green: 145/255, blue: 0/255),
//        Color(red: 30/255, green: 65/255, blue: 175/255)]
    ]
}


struct ColorSampleView: View {
    var body: some View {
        VStack {
            colorBall(color: .numberingGray)
            let row = Array(repeating: GridItem(.flexible(), 
                                                spacing: 10,
                                                alignment: .center),
                            count: 5)
            LazyVGrid(columns: row, content: {
                ForEach(Color.colorSet, id: \.self) { color in
                    colorBall(color: color)
                }
            })
        }
    }
    
    func colorBall(color: Color) -> some View {
        Circle()
            .foregroundStyle(color)
            .frame(width: 40, height: 40)
    }
}

#Preview {
    ColorSampleView()
}
