//
//  WebView.swift
//  CLP_Inspection_Robot_Panel
//
//  Created by Kam Ho Leung on 20/9/2024.
//

import SwiftUI
import WebKit
import os

private let logger = Logger(subsystem: "CLP_Inspection_Robot_Panel", category: "WebView")

struct Camera_WebView : View {
    @EnvironmentObject var settings : SettingsHandler
    @State var refreshView = false
    var cleanUI = false
    var body: some View {
        WebView(ip: "http://\(settings.cam_ip)")
            .disabled(true)
            .overlay(alignment: .bottomTrailing, content: {
                Button(action: {
                    refreshView.toggle()
                }){
                    Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                        .padding()
                        .background(Circle().fill(Material.ultraThick))
                }
            })
            .id(refreshView)
        //            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear{
                refreshView.toggle()
            }

    }
}

struct WebView: UIViewRepresentable {
    let ip : String
    let webView = WKWebView()
    
    func makeUIView(context: Context) -> WKWebView {
        webView.isOpaque = false
        webView.backgroundColor = UIColor(Color.clear)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        loadURL()
    }
    
    func loadURL(){
        webView.load(URLRequest(url: URL(string: ip)!))
    }
    
    func makeCoordinator() -> Coordinator {
            Coordinator(self)
    }
        
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: WebView
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            logger.info("WebView started loading")
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            logger.info("WebView finished loading")
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            logger.error("WebView failed with error: \(error.localizedDescription)")
            self.parent.loadURL()
        }
    }
    
}
