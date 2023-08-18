//
//  CustomProgressView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/16.
//

import SwiftUI


struct CustomProgressView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(.primary.opacity(0.5))
                .frame(width: 100, height: 100)
            ProgressView()
                .tint(.primaryInverted)
                .progressViewStyle(.circular)
        }
    }
}  
