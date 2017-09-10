//
//  WebViewPool.swift
//  DjWebview
//
//  Created by 彭运筹 on 2017/8/10.
//  Copyright © 2017年 彭运筹. All rights reserved.
//

import Foundation
import WebKit
public class WebviewPool:WebviewPoolInterface{
    static let shared = WebviewPool()
    private let processPool = WKProcessPool()
    private let preferences = WKPreferences()
    private var webviews:[InternalWebview] = []
    private var maxCount:Int = 0
    public var useWkWebView = true
    func dequeue() -> InternalWebview{
        if let web = webviews.first{
            self.webviews.removeFirst()
            return web
        }else{
            self.preCreateWebviews()
            return createWebview()
        }
    }
    func enqueue(web:InternalWebview){
        web.stopLoad()
        if self.webviews.count > maxCount{
            return
        }
        if let blankUrl = NSURL(string: "about:blank"){
            web.load(NSURLRequest(URL: blankUrl))
        }
        self.webviews.append(web)
    }
    private init() {
        if self.useWkWebView{
            WKWebView.keyboardDisplayDoesNotRequireUserAction()
        }
        self.preCreateWebviews()
    }
    
    private func preCreateWebviews(){
        for _ in 0 ..< maxCount{
            self.webviews.append(createWebview())
        }
    }
    private func createWebview() -> InternalWebview{
        if self.useWkWebView{
            return self.createWKWebview()
        }else{
            return self.createUIWebview()
        }
    }
    func createUIWebview() -> InternalWebview{
        let w = UIWebView()
        w.scrollView.keyboardDismissMode = .OnDrag
        w.opaque = false
        w.backgroundColor = UIColor.clearColor()
        w.handler = UIWebviewHandler()
        w.scrollView.keyboardDismissMode = .OnDrag
        w.allowsInlineMediaPlayback = true
        w.keyboardDisplayRequiresUserAction = false
        w.dataDetectorTypes = [.Link,.PhoneNumber,.Address]
        w.custom_inputAccessoryView = nil
        w.scrollView.keyboardDismissMode = .Interactive
        return w
    }
    func createWKWebview() -> InternalWebview{
        let config = WKWebViewConfiguration()
        config.processPool = processPool
        config.preferences = preferences
        if #available(iOS 10.0, *) {
            config.dataDetectorTypes = [.Address,.PhoneNumber,.Link]
        }
        let w = WKWebView(frame: CGRectZero, configuration:config)
        w.opaque = false
        w.backgroundColor = UIColor.clearColor()
        let handler = WKWebviewHandler()
        w.handler = handler
        let scriptHandler = handler
        w.configuration.userContentController.addScriptMessageHandler(scriptHandler, name: "dj")
        let djscript = WKUserScript(source: "window.webview={post:function(para){ window.webkit.messageHandlers.dj.postMessage(para) }}", injectionTime: .AtDocumentStart, forMainFrameOnly: false)
        w.configuration.userContentController.addUserScript(djscript)
        w.custom_inputAccessoryView = nil
        w.scrollView.keyboardDismissMode = .Interactive
        return w
    }
}
