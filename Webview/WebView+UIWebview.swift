//
//  Webview+UIWebview.swift
//  DjWebview
//
//  Created by 彭运筹 on 2017/8/10.
//  Copyright © 2017年 彭运筹. All rights reserved.
//

import Foundation
import JavaScriptCore
private struct UIWebViewAssociatedObjects{
    static var AccessoryView = "AccessoryView"
    static var HackishFixClassName = "UIWebBrowserViewMinusAccessoryView"
    static var HackishFixClass:AnyClass? = nil
    static var handlerKey:String = "handlerKey"
    static var jsContextKey:String = "jsContextKey"
    static var djJsObjectKey:String = "djJsObjectKey"
}
extension UIWebView:InternalWebview{
    func load(req:NSURLRequest){
        self.loadRequest(req)
    }
    func load(html:String, baseURL: NSURL?){
        self.loadHTMLString(html, baseURL: baseURL)
    }
    func reLoad(){
        self.reload()
    }
    func stopLoad(){
        self.stopLoading()
    }
    func evaluate(js:String,completion:((AnyObject?,ErrorType?) -> Void)?){
        let obj = self.jsContext?.evaluateScript(js).toObject()
        completion?(obj,nil)
    }
    var custom_inputAccessoryView:UIView?{
        get {
            return objc_getAssociatedObject(self, &UIWebViewAssociatedObjects.AccessoryView) as? UIView
        }
        set{
            objc_setAssociatedObject(self, &UIWebViewAssociatedObjects.AccessoryView, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            guard let browserView = self.hackishlyFoundBrowserView() else{
                return
            }
            self.ensureHackishSubclassExistsOfBrowserViewClass(object_getClass(browserView))
            if let hackClass = UIWebViewAssociatedObjects.HackishFixClass{
                object_setClass(browserView, hackClass)
            }
            if browserView.isFirstResponder(){
                browserView.reloadInputViews()
            }
            
        }
    }
    private func hackishlyFoundBrowserView() -> UIView?{
        let scrollView = self.scrollView
        var browserView:UIView? = nil
        for subview in scrollView.subviews{
            let className = NSStringFromClass(object_getClass(subview))
            if className.containsString("UIWebBrowserView"){
                browserView = subview
                break
            }
        }
        return browserView
    }
    func methodReturningCustomInputAccessoryView() ->UIView?{
        var view:UIView? = self
        var customInputAccessoryView:UIView? = nil
        while (view != nil) && !(view is UIWebView){
            view = view?.superview
        }
        if let webView = view as? UIWebView{
            customInputAccessoryView = webView.custom_inputAccessoryView
        }
        return customInputAccessoryView
    }
    private func ensureHackishSubclassExistsOfBrowserViewClass(browserViewClass:AnyClass){
        if UIWebViewAssociatedObjects.HackishFixClass == nil{
            let newClass:AnyClass = objc_allocateClassPair(browserViewClass, UIWebViewAssociatedObjects.HackishFixClassName, 0)
            let nilImp = self.methodForSelector(#selector(UIWebView.methodReturningCustomInputAccessoryView))
            class_addMethod(newClass, Selector("inputAccessoryView"), nilImp, "@@:")
            objc_registerClassPair(newClass)
            UIWebViewAssociatedObjects.HackishFixClass = newClass
        }
    }
    
    var view:UIView{
        return self
    }
    
    var handler:UIWebviewHandler?{
        get {
            return objc_getAssociatedObject(self, &UIWebViewAssociatedObjects.handlerKey) as? UIWebviewHandler
        }
        set{
            objc_setAssociatedObject(self, &UIWebViewAssociatedObjects.handlerKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            self.delegate = newValue
        }
    }
    var jsContext:JSContext?{
        get {
            return objc_getAssociatedObject(self, &UIWebViewAssociatedObjects.jsContextKey) as? JSContext
        }
        set{
            objc_setAssociatedObject(self, &UIWebViewAssociatedObjects.jsContextKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    var djJsObject:UIWebviewJSObject?{
        get {
            return objc_getAssociatedObject(self, &UIWebViewAssociatedObjects.djJsObjectKey) as? UIWebviewJSObject
        }
        set{
            objc_setAssociatedObject(self, &UIWebViewAssociatedObjects.djJsObjectKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
extension UIWebView{
    var parentView:WebView?{
        return self.superview as? WebView
    }
}
class UIWebviewHandler:NSObject,UIWebViewDelegate{

    private func loadJsContext(webview:UIWebView){
        webview.jsContext = webview.valueForKeyPath("documentView.webView.mainFrame.javaScriptContext") as? JSContext
        let jsHandler = UIWebviewJSObject()
        jsHandler.webview = webview
        webview.jsContext?.setObject(jsHandler, forKeyedSubscript: "webview")
        webview.djJsObject = jsHandler
    }
    func webViewDidStartLoad(webView: UIWebView) {
        if let web = webView.parentView{
            web.delegate?.webviewLoadBegin(web)
        }
    }
    func webViewDidFinishLoad(webView: UIWebView) {
        self.loadJsContext(webView)
        if let web = webView.parentView{
            web.delegate?.webviewLoadComplete(web)
        }
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        if let web = webView.parentView{
            web.delegate?.webview(web, fail: error)
        }
    }
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        self.loadJsContext(webView)
        if let web = webView.parentView{
            var navType = WebviewNavgateType.Other
            if navigationType == .LinkClicked{
                navType = .Link
            }
            return web.delegate?.webView(web, shouldNavgate: request, type: navType) ?? true
        }
        return true
    }
}

@objc public  protocol UIWebviewJSInterface:JSExport{
    @objc func post(msg:AnyObject)
}
public class UIWebviewJSObject:NSObject,UIWebviewJSInterface{
    weak var webview:UIWebView?
    public func post(msg:AnyObject){
        dispatch_async(dispatch_get_main_queue()) { 
            if let web = self.webview?.parentView{
                if web.debugOn{
                    web.delegate?.webView(web, log: "on web message:\(msg)")
                }
                web.delegate?.webview(web, message: msg)
            }
        }
    }
}

