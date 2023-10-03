//
//  LinkWebView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/29.
//

import SwiftUI
import WebKit

struct LinkWebView: View {
    
    var linkHistory: [String] = []
    var linkHistoryCount: Int = 0
    
    var url: String
    
    @State var isShowingProgressView: Bool = true
    
    var body: some View {
        if let url = URL(string: url) {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    WebView(url: url) { bool in
                        DispatchQueue.main.async {
                            isShowingProgressView = false
                        }
                    }
                    BlurView(style: .extraLight)
                        .frame(height: 50)
                }
                navigationControllView
            }
            .overlay(content: {
                if isShowingProgressView {
                    CustomProgressView()
                }
            })
            .edgesIgnoringSafeArea(.bottom)
        } else {
            Rectangle()
        }
    }
    
    
    var navigationControllView: some View {
        BlurView(style: .regular)
            .frame(height: 70)
            .overlay(alignment: .top) {
                HStack {
                    Spacer()
                    Button {
                        
                    } label: {
                        Image(systemName: "chevron.left")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                    Spacer()
                    Button {
                        
                    } label: {
                        Image(systemName: "chevron.right")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                    Spacer()
                    Spacer()
                    Spacer()
                    Button {
                        
                    } label: {
                        Image(systemName: "safari")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)

                    }
                    Spacer()
                }
                .padding(.top, 10)
            }
    }
}

struct LinkWebView_Previews: PreviewProvider {
    static var previews: some View {
        LinkWebView(url: "https://naver.com")
    }
}
