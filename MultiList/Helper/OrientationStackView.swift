//
//  OrientationView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/15.
//

import SwiftUI

struct OStack<Content>: View where Content: View {
    let alignment: Alignment
    let spacing: CGFloat?
    let isVerticalFirst: Bool
    let content: () -> Content
    
    @State private var orientation = UIDevice.current.orientation
    @State private var current: UIDeviceOrientation = .portrait
    @State private var beforeOrientation: UIDeviceOrientation = .portrait
    
    init(alignment: Alignment = .center, spacing: CGFloat? = nil, isVerticalFirst: Bool = true, @ViewBuilder content: @escaping () -> Content) {
        self.alignment = alignment
        self.spacing = spacing
        self.isVerticalFirst = isVerticalFirst
        self.content = content
        if orientation.isValidInterfaceOrientation {
            current = orientation
        }
   }

    var body: some View {
        Group {
            if isVerticalFirst {
                if orientation.isPortrait {
                    VStack(alignment: alignment.horizontal,
                           spacing: spacing,
                           content: content)
                } else if orientation.isLandscape {
                    HStack(alignment: alignment.vertical,
                           spacing: spacing,
                           content: content)
                } else {
                    if self.beforeOrientation == .portrait {
                        VStack(alignment: alignment.horizontal,
                               spacing: spacing,
                               content: content)
                    } else {
                        HStack(alignment: alignment.vertical,
                               spacing: spacing,
                               content: content)
                    }
                }
            } else {
                if orientation.isPortrait {
                    HStack(alignment: alignment.vertical,
                           spacing: spacing,
                           content: content)
                } else if orientation.isLandscape {
                    VStack(alignment: alignment.horizontal,
                           spacing: spacing,
                           content: content)
                } else  {
                    if self.beforeOrientation == .portrait {
                        HStack(alignment: alignment.vertical,
                               spacing: spacing,
                               content: content)
                    } else {
                        VStack(alignment: alignment.horizontal,
                               spacing: spacing,
                               content: content)
                    }
                }
            }
        }
        .detectOrientation($orientation)
        .onChange(of: orientation) { newValue in
            if newValue.isValidInterfaceOrientation {
                self.beforeOrientation = newValue
            }
            
//            if newValue.isPortrait {
//                print("beforeOrientation setted Portrait")
//                beforeOrientation = newValue
//            } else if newValue.isLandscape {
//                print("beforeOrientation setted Landscape")
//                beforeOrientation = .landscapeLeft
//            }
            
        }
    }

  enum Alignment {
    case topOrLeading, center, bottomOrTrailing

    var vertical: VerticalAlignment {
      switch self {
      case .topOrLeading:
        return .top
      case .center:
        return .center
      case .bottomOrTrailing:
        return .bottom
      }
    }

    var horizontal: HorizontalAlignment {
      switch self {
      case .topOrLeading:
        return .leading
      case .center:
        return .center
      case .bottomOrTrailing:
        return .trailing
      }
    }
  }
}
