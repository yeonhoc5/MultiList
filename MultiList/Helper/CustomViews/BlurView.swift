//
//  BlurView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/21.
//

import SwiftUI

struct BlurView: UIViewRepresentable {
    
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> some UIView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }
    
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
}


struct BlurView_Previews: PreviewProvider {
    static var previews: some View {
        BlurView(style: .prominent)
    }
}
