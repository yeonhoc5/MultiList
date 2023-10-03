//
//  ButtonScaleEffect.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/07.
//

import Foundation
import SwiftUI

struct ScaleEffect: ButtonStyle {
    var scale: CGFloat = 0.95
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
    }
}


struct NonEffect: ButtonStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
