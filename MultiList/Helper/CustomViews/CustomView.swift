//
//  CustomView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/16.
//

import SwiftUI
import Lottie

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
                withAnimation {
                    tapActioin()
                }
            }
    }
    
    func additionalSpace(color: Color = .primaryInverted) -> some View {
        Rectangle()
            .foregroundColor(color)
            .frame(height: 60)
    }
    
    
    func loadingView(color: Color! = Color.gray, onAppear: @escaping () -> Void) -> some View {
        RoundedRectangle(cornerRadius: 5)
            .foregroundStyle(color)
            .overlay {
                LottieView(animation: .named("LoadingImage"))
                    .playing(loopMode: .loop)
//                Text("Loading...")
//                    .foregroundColor(.white)
//                    .font(.caption)
                    .padding([.bottom, .horizontal], 10)
            }
            .onAppear {
                onAppear()
            }
    }
    
    func listMaskView(color: Color = .teal, radius: CGFloat! = 20) -> some View {
        RoundedRectangle(cornerRadius: radius)
            .foregroundColor(color)
    }
    
    
    func minusMark(width: CGFloat) -> some View {
        BlurView(style: .systemChromeMaterialLight)
            .clipShape(Circle())
            .overlay(content: {
                Image(systemName: "minus")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.black)
                    .fontWeight(.semibold)
                    .padding(5)
            })
            .frame(width: width / 4, height: width / 4)
            .clipped()
            .offset(x: -5, y: -5)
            .shadow(color: .black, radius: 2, x: 1, y: 1)
    }

//    func snapshot() -> UIImage {
//        let controller = UIHostingController(rootView: self)
//        let view = controller.view
//
//        let targetSize = controller.view.intrinsicContentSize
//        view?.bounds = CGRect(origin: .zero, size: targetSize)
//        view?.backgroundColor = .clear
//
//        let renderer = UIGraphicsImageRenderer(size: targetSize)
//
//        return renderer.image { _ in
//            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
//        }
//    }
    
}
