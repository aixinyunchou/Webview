//
//  Webview+wkwebview.swift
//  DjWebview
//
//  Created by 彭运筹 on 2017/8/9.
//  Copyright © 2017年 彭运筹. All rights reserved.
//

import Foundation
import WebKit
// for WKWebbview
private struct WkWebviewAssociatedObjects{
    static var AccessoryView = "AccessoryView"
    static var HackishFixClassName = "WKContentViewMinusAccessoryView"
    static var HackishFixClass:AnyClass? = nil
    static var handlerKey:String = "handlerKey"
}
typealias WkWebviewKeyboardFunctionType =  @convention(c)(AnyObject,Selector,UnsafePointer<Void>,Bool,Bool,UnsafePointer<Void>) -> Void
extension WKWebView{
    var custom_inputAccessoryView:UIView?{
        get {
            return objc_getAssociatedObject(self, &WkWebviewAssociatedObjects.AccessoryView) as? UIView
        }
        
        set{
            objc_setAssociatedObject(self, &WkWebviewAssociatedObjects.AccessoryView, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            guard let browserView = self.hackishlyFoundBrowserView() else{
                return
            }
            self.ensureHackishSubclassExistsOfBrowserViewClass(object_getClass(browserView))
            if let hackClass = WkWebviewAssociatedObjects.HackishFixClass{
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
            if className.containsString("WKContentView"){
                browserView = subview
                break
            }
        }
        return browserView
    }
    @objc private func methodReturningCustomInputAccessoryView() ->UIView?{
        var view:UIView? = self
        var customInputAccessoryView:UIView? = nil
        while (view != nil) && !(view is WKWebView){
            view = view?.superview
        }
        if let webView = view as? WKWebView{
            customInputAccessoryView = webView.custom_inputAccessoryView
        }
        return customInputAccessoryView
    }
    private func ensureHackishSubclassExistsOfBrowserViewClass(browserViewClass:AnyClass){
        if WkWebviewAssociatedObjects.HackishFixClass == nil{
            let newClass:AnyClass = objc_allocateClassPair(browserViewClass, WkWebviewAssociatedObjects.HackishFixClassName, 0)
            let nilImp = self.methodForSelector(#selector(methodReturningCustomInputAccessoryView))
            class_addMethod(newClass, Selector("inputAccessoryView"), nilImp, "@@:")
            objc_registerClassPair(newClass)
            WkWebviewAssociatedObjects.HackishFixClass = newClass
        }
    }
    internal class func keyboardDisplayDoesNotRequireUserAction(){
        let sel = sel_getUid("_startAssistingNode:userIsInteracting:blurPreviousNode:userObject:")
        guard let WKContentView:AnyClass? = NSClassFromString("WKContentView") else { return }
        let method = class_getInstanceMethod(WKContentView, sel)
        let originalImp = unsafeBitCast(method_getImplementation(method), WkWebviewKeyboardFunctionType.self)
        let block : @convention(block) (AnyObject,UnsafePointer<Void>,Bool,Bool,UnsafePointer<Void>) -> Void = { sself, arg0, arg1, arg2, arg3 in
            originalImp(sself, sel, arg0, true, arg2, arg3)
        }
        let imp = imp_implementationWithBlock(unsafeBitCast(block, AnyObject.self))
        method_setImplementation(method, imp);
    }
    var handler:WKWebviewHandler?{
        get {
            return objc_getAssociatedObject(self, &WkWebviewAssociatedObjects.handlerKey) as? WKWebviewHandler
        }
        set{
            objc_setAssociatedObject(self, &WkWebviewAssociatedObjects.handlerKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            self.navigationDelegate = newValue
        }
    }
}

extension UIView {
    override public class func initialize() {
        guard NSStringFromClass(self) == "WKContentView" else { return }
        swizzleMethod(#selector(canPerformAction), withSelector: #selector(swizzledCanPerformAction))
    }
    private class func swizzleMethod(selector: Selector, withSelector: Selector) {
        let originalSelector = class_getInstanceMethod(self, selector)
        let swizzledSelector = class_getInstanceMethod(self, withSelector)
        method_exchangeImplementations(originalSelector, swizzledSelector)
    }
    private func findWebview() -> WebView?{
        var view:UIView? = self
        while view != nil{
            if let v = view as? WebView{
                return v
            }
            view = view?.superview
        }
        return nil
    }
    @objc private func swizzledCanPerformAction(action: Selector, withSender sender: AnyObject?) -> Bool {
        if let web = self.findWebview(){
            if !web.supportMenuActions.isEmpty{
                return false
            }
        }
        return self.swizzledCanPerformAction(action, withSender: sender)
    }
}

extension WKWebView{
    var parentView:WebView?{
        return self.superview as? WebView
    }
}

class WKWebviewHandler:NSObject,WKScriptMessageHandler,WKNavigationDelegate{
    private weak var webview:WKWebView? = nil
    func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.webview = webView
        if let web = webView.parentView{
            web.delegate?.webviewLoadBegin(web)
        }
    }
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        if let web = webView.parentView{
            web.delegate?.webviewLoadComplete(web)
        }
    }
    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        if let web = webView.parentView{
            web.delegate?.webview(web, fail: error)
        }
    }
    
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        if let web = webView.parentView{
            var navType = WebviewNavgateType.Other
            if navigationAction.navigationType == .LinkActivated{
                navType = .Link
            }
            let ret = web.delegate?.webView(web, shouldNavgate: navigationAction.request, type: navType) ?? true
            decisionHandler(ret ? .Allow : .Cancel)
        }else{
            decisionHandler(.Allow)
        }
    }
    @objc internal func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if let web = self.webview?.parentView{
            if web.debugOn{
                web.delegate?.webView(web, log: "on web message:\(message.body)")
            }
            web.delegate?.webview(web, message: message.body)
        }
    }
}
extension WKWebView:InternalWebview{
    var view:UIView{
        return self
    }
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
        self.evaluateJavaScript(js, completionHandler: completion)
    }
}

