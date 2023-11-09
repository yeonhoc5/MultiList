//
//  LinkWebView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/29.
//

import SwiftUI
import WebKit

struct LinkWebView: View {
    
    let startURL: URL
    @State var linkHistory: [URL] = []
    @State var linkLocation: Int = 0
    @State var isShowingMessge: Bool = false
    @State var message: String = ""
    
    @State var isShowingProgressView: Bool = true
    
    @Environment(\.openURL) var openURL
//    let webView: WebView?
    
    init(url: String) {
        self.startURL = URL(string: url)!
        _linkHistory = State(wrappedValue: [startURL])
//        webView = WebView(url: startURL)
    }
    
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
//                webView
                WebView(url: linkHistory[linkLocation]) { bool in
                    if bool {
                        DispatchQueue.main.async {
                            isShowingProgressView = false
                        }
                    } else {
                        message = "올바르지 않은 URL입니다."
                        withAnimation {
                            isShowingMessge = true
                        }
                    }
                }
//                .frame(maxWidth: screenSize.width < screenSize.height ? .infinity : screenSize.width * 0.8)
                BlurView(style: .extraLight)
                    .frame(height: 50)
            }
            navigationControllView
        }
        .ignoresSafeArea(.all)
        .overlay(content: {
            if isShowingProgressView {
                CustomProgressView()
            }
            
        })
        .edgesIgnoringSafeArea(.bottom)
    }
    
    
    var navigationControllView: some View {
        BlurView(style: .regular)
            .frame(height: screenSize.width < screenSize.height ? 70 : 50)
            .overlay(alignment: .top) {
                HStack {
                    Spacer()
                    Button {
//                        linklocation -= linklocation > 0 ? 1 : 0
//                        webView?.goBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundStyle(linkLocation > 0 ? Color.teal : Color.gray)
                    }
                    .disabled(linkLocation == 0)
                    Spacer()
                    Button {
//                        linklocation += linklocation < linkHistory.count ? 1 : 0
//                        webView?.goForward()
                    } label: {
                        Image(systemName: "chevron.right")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundStyle(linkLocation > 0 ? Color.teal : Color.gray)
                    }
                    .disabled(linkLocation <= linkHistory.count - 1)
                    Spacer()
                    Spacer()
                    Spacer()
                    Button {
                        openURL(linkHistory[linkLocation])
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
