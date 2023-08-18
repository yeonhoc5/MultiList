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

    init(alignment: Alignment = .center, spacing: CGFloat? = nil, isVerticalFirst: Bool = true,
    @ViewBuilder content: @escaping () -> Content) {
           self.alignment = alignment
           self.spacing = spacing
           self.isVerticalFirst = isVerticalFirst
           self.content = content
       }

    var body: some View {
        Group {
            if isVerticalFirst {
                if orientation.isLandscape {
                    HStack(alignment: alignment.vertical,
                           spacing: spacing,
                           content: content)
                } else {
                    VStack(alignment: alignment.horizontal,
                           spacing: spacing,
                           content: content)
                }
            } else {
                if !orientation.isLandscape {
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
        .detectOrientation($orientation)
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
