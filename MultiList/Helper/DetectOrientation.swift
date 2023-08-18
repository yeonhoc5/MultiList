//
//  DetectOrientation.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/15.
//

import SwiftUI
    
var screenSize: CGSize {
    get {
        guard let size = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.screen.bounds.size
        else {
            return CGSize(width: 200, height: 300)
        }
        return size
    }
}

struct OrientationDetector: ViewModifier {
  @Binding var orientation: UIDeviceOrientation

  func body(content: Content) -> some View {
    content
      .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
        orientation = UIDevice.current.orientation
      }
  }
}

extension View {
  func detectOrientation(_ binding: Binding<UIDeviceOrientation>) -> some View {
    self.modifier(OrientationDetector(orientation: binding))
  }
}
