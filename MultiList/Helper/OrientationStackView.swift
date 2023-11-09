//
//  OrientationView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/15.
//

import SwiftUI

struct OStack<Content>: View where Content: View {
    let alignment: Alignment
    let verticalSpacing: CGFloat?
    let horizontalSpacing: CGFloat?
    let isVerticalFirst: Bool
    let content: () -> Content
    
    @State private var orientation = UIDevice.current.orientation
    @State private var current: UIDeviceOrientation = .portrait
    
    @State var isChanged: Bool = false
    
    init(alignment: Alignment = .center, verticalSpacing: CGFloat? = nil, horizontalSpacing: CGFloat? = nil, spacing: CGFloat? = nil, isVerticalFirst: Bool = true, @ViewBuilder content: @escaping () -> Content) {
        self.alignment = alignment
        
        if verticalSpacing == nil && horizontalSpacing == nil {
            self.verticalSpacing = spacing
            self.horizontalSpacing = spacing
        } else {
            self.verticalSpacing = verticalSpacing
            self.horizontalSpacing = horizontalSpacing
        }
        self.isVerticalFirst = isVerticalFirst
        self.content = content
        if orientation.isValidInterfaceOrientation {
            current = orientation
        }
   }

    var body: some View {
        Group {
            if isVerticalFirst {
                if current.isPortrait {
                    VStack(alignment: alignment.horizontal,
                           spacing: verticalSpacing,
                           content: content)
                } else if current.isLandscape  {
                    HStack(alignment: alignment.vertical,
                           spacing: horizontalSpacing,
                           content: content)
                }
            } else {
                if current.isPortrait {
                    HStack(alignment: alignment.vertical,
                           spacing: horizontalSpacing,
                           content: content)
                } else if current.isLandscape  {
                    VStack(alignment: alignment.horizontal,
                           spacing: verticalSpacing,
                           content: content)
                }
            }
        }
        .detectOrientation($orientation)
        .onAppear(perform: {
            if orientation.isValidInterfaceOrientation {
                self.current = self.orientation
                self.isChanged = true
            }
        })
        .onChange(of: orientation) { newValue in
            if newValue.isValidInterfaceOrientation {
                self.current = newValue
                self.isChanged = true
            }
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
