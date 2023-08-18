//
//  CustomView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/16.
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
    
    func buttonImage(image: String, colorNum: Int, completion: @escaping () -> Void) -> some View {
        Image(systemName: image)
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
            .foregroundColor(Color.colorSet[colorNum])
    }
}
