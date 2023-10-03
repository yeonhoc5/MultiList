//
//  CustomView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/16.
//

import SwiftUI

extension View {
    
    func labelText(label: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white)
                Spacer()
            }
            HStack {
                Text(content)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                Spacer()
            }
        }
        .padding(.horizontal, 10)
    }
    

    
    @ViewBuilder
    func contextMenuItem(title: String, image: String!, role: ButtonRole = .cancel, action: @escaping () -> Void) -> some View {
        Button(role: role) {
            action()
        } label: {
            if image == nil {
                Text(title)
            } else {
                HStack {
                    Text(title)
                    Image(systemName: image)
                        .imageScale(.medium)
                }
            }
        }
    }
    
    
    func blurViewWithTapAction(tapActioin: @escaping () -> Void) -> some View {
        Rectangle()
            .fill(Color.primaryInverted.opacity(0.7))
            .onTapGesture {
                tapActioin()
            }
    }
    
    func additionalSpace(color: Color = .primaryInverted) -> some View {
        Rectangle()
            .foregroundColor(color)
            .frame(height: 60)
    }
    
    
    func loadingView(color: Color) -> some View {
        RoundedRectangle(cornerRadius: 5)
            .foregroundColor(color)
            .overlay {
                Text("Loading...")
                    .foregroundColor(.white.opacity(0.5))
                    .font(.caption)
                    .padding(.bottom, 10)
            }
    }
    
    func listMaskView(color: Color = .teal, radius: CGFloat! = 20) -> some View {
        RoundedRectangle(cornerRadius: radius)
            .foregroundColor(color)
    }
    
}
