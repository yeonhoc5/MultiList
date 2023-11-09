//
//  ContextMenuViewModifier.swift
//  MultiList
//
//  Created by yeonhoc5 on 10/9/23.
//

import SwiftUI

extension View {
    func contextMenu(actions: [UIAction], willEnd: (() -> Void)? = nil, willDisplay: (() -> Void)? = nil) -> some View {
        modifier(ContextMenuViewModifier(actions: actions, willEnd: willEnd, willDisplay: willDisplay))
    }
}
struct ContextMenuViewModifier: ViewModifier {
    let actions: [UIAction]
    let willEnd: (() -> Void)?
    let willDisplay: (() -> Void)?
    
    func body(content: Content) -> some View {
        Interaction_UI(view: {content}, actions: actions, willEnd: willEnd, willDisplay: willDisplay)
            .fixedSize()
        
    }
}

struct Interaction_UI<Content2: View>: UIViewRepresentable{
    typealias UIViewControllerType = UIView
    @ViewBuilder var view: Content2
    let actions: [UIAction]
    let willEnd: (() -> Void)?
    let willDisplay: (() -> Void)?
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    func makeUIView(context: Context) -> some UIView {
        
        let v = UIHostingController(rootView: view).view!
        context.coordinator.contextMenu = UIContextMenuInteraction(delegate: context.coordinator)
        v.addInteraction(context.coordinator.contextMenu!)
        return v
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
    class Coordinator: NSObject,  UIContextMenuInteractionDelegate{
        var contextMenu: UIContextMenuInteraction!
        
        let parent: Interaction_UI
        
        init(parent: Interaction_UI) {
            self.parent = parent
        }
        
        func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
            UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { [self]
                suggestedActions in
                
                return UIMenu(title: "", children: parent.actions)
            })
        }
        func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willDisplayMenuFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
            parent.willDisplay?()
        }
        func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willEndFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
            parent.willEnd?()
        }
    }
}
