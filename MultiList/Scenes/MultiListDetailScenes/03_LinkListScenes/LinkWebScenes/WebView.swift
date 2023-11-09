//
//  WebView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/29.
//


import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    var result: (Bool) -> Void
    var webView: WKWebView = WKWebView()
    
    func makeUIView(context: Context) -> WKWebView {
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.uiDelegate = context.coordinator
        webView.navigationDelegate = context.coordinator
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func goBack() {
        webView.goBack()
    }
    
    func goForward() {
        webView.goForward()
    }
    
}

class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate {
    
    var parent: WebView
    
    init(_ parent: WebView) {
        self.parent = parent
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        parent.result(true)
    }

}
