//
//  CustomButtonsViews.swift
//  MultiList
//
//  Created by yeonhoc5 on 10/3/23.
//

import SwiftUI

extension View {
    // home > LoginView (with Image)
    func buttonLogin(image: String,
                     backgroundColor: Color = .white,
                     login: @escaping(() -> Void)) -> some View {
        Button {
            login()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .foregroundColor(backgroundColor)
                Image(image)
                    .resizable()
                    .padding(5)
                    .scaledToFit()
            }
        }
        .buttonStyle(ScaleEffect(scale: 0.9))
    }
    // home > LoginView (with Text)
    func buttonLogin(title: String,
                     btncolor: Color = .teal,
                     textColor: Color = .white,
                     login: @escaping(() -> Void)) -> some View {
        Button {
            login()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .foregroundColor(btncolor)
                Text(title)
                    .font(.headline)
                    .foregroundColor(textColor)
                    .fontWeight(.black)
            }
        }
        .buttonStyle(ScaleEffect(scale: 0.9))
    }
    
    // UserSettingView
    func btnAccount(title: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .foregroundColor(.white)
                Text(title)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(.teal)
            }
        }
        .buttonStyle(ScaleEffect())
        .frame(height: 40)
    }
    
    func buttonImage(image: String, color: Color, scale: Image.Scale = .medium, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Image(systemName: image)
                .resizable()
                .frame(width: 20, height: 20)
                .scaledToFit()
                .foregroundColor(color)
        }
        .buttonStyle(ScaleEffect(scale: 0.7))
    }
    
    func buttonCardView(label: some View, id: MultiListType, selectedType: MultiListType!, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            label
                .overlay {
                    if selectedType == id {
                        Image(systemName: "checkmark")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.red)
                            .padding(40)
                    }
                }
        }
        .buttonStyle(NonEffect())
        .scaleEffect(selectedType == id ? 1 : 0.8)
        .foregroundColor(.blue)
        .frame(maxWidth: 200, maxHeight: 250)
        
    }
}
