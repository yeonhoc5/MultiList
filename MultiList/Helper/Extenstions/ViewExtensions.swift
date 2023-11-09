//
//  ViewExtensions.swift
//  MultiList
//
//  Created by yeonhoc5 on 10/11/23.
//

import SwiftUI

extension View {
    
    func imageScaleToFit(systemName: String) -> some View {
        Image(systemName: systemName)
            .resizable()
            .scaledToFit()
    }
    
}
