//
//  WebView.swift
//  WebViewDemo
//
//  Created by yunchou on 15/11/6.
//  Copyright © 2015年 aixin. All rights reserved.
//

import UIKit

public enum WebviewNavgateType{
    case Link
    case Other
}
public protocol WebviewDelegate:NSObjectProtocol{
    func webviewLoadBegin(webView:WebView)
    func webviewLoadComplete(webView:WebView)
    func webview(webview:WebView, fail:ErrorType)
    func webview(webview:WebView, message:AnyObject)
    func webView(webview:WebView,log:String)
    func webView(webview:WebView,shouldNavgate:NSURLRequest,type:WebviewNavgateType) -> Bool
}
public extension WebviewDelegate{
    func webviewLoadBegin(webView:WebView){}
    func webviewLoadComplete(webView:WebView){}
    func webview(webview:WebView, fail:ErrorType){}
    func webview(webview:WebView, message:AnyObject){}
    func webView(webview:WebView,log:String){}
    func webView(webview:WebView,shouldNavgate:NSURLRequest,type:WebviewNavgateType) -> Bool{ return true }
}
protocol InternalWebview{
    var view:UIView{get}
    var scrollView:UIScrollView{get}
    var custom_inputAccessoryView:UIView?{get set}
    func load(req:NSURLRequest)
    func load(html:String, baseURL: NSURL?)
    func reLoad()
    func stopLoad()
    func evaluate(js:String,completion:((AnyObject?,ErrorType?) -> Void)?)
}
protocol WebviewPoolInterface{
    func dequeue() -> InternalWebview
    func enqueue(web:InternalWebview)
}

public class WebView: UIView{
    internal var internalWebview:InternalWebview!
    #if DEBUG
    public var debugOn:Bool = true
    #else
    public var debugOn:Bool = false
    #endif
    public var supportMenuActions:[String] = []
    public var toolbar:UIView? = nil{
        didSet{
            if toolbar != oldValue{
                if toolbar == nil{
                    if internalWebview.custom_inputAccessoryView != nil{
                        internalWebview.custom_inputAccessoryView = toolbar
                    }
                }else{
                    if internalWebview.custom_inputAccessoryView == nil{
                        internalWebview.custom_inputAccessoryView = toolbar
                    }
                }
            }
        }
    }
    weak public var delegate:WebviewDelegate?
    public var scrollView:UIScrollView{
        return self.internalWebview.scrollView
    }
    convenience init(){
        self.init(frame:CGRectZero)
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    deinit {
        self.delegate = nil
        self.reuseWebview()
    }
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    public override func canBecomeFirstResponder() -> Bool {
        return true
    }
    private func commonInit(){
        internalWebview = self.newWebview()
        addSubview(internalWebview.view)
    }
    
    internal func newWebview() -> InternalWebview{
        return WebviewPool.shared.dequeue()
    }
    
    internal func reuseWebview(){
        if self.internalWebview.custom_inputAccessoryView != nil{
            self.internalWebview.custom_inputAccessoryView = nil
        }
        if self.internalWebview.scrollView.delegate != nil{
            self.internalWebview.scrollView.delegate = nil
        }
        let web = self.internalWebview
        self.internalWebview = nil
        WebviewPool.shared.enqueue(web)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        internalWebview.view.frame = self.bounds
    }

    public override func canPerformAction(action: Selector, withSender sender: AnyObject?) -> Bool {
        return self.supportMenuActions.contains("\(action)")
    }
}

//MARK: public functons
extension WebView{
    public func load(request:NSURLRequest){
        if debugOn{
            self.delegate?.webView(self, log:"load request \(request)")
        }
        internalWebview.load(request)
    }
    public func load(html:String,baseUrl:NSURL? = nil){
        internalWebview.load(html, baseURL: baseUrl)
    }
    public func reload(){
        internalWebview.reLoad()
    }
    public func stopLoading(){
        internalWebview.stopLoad()
    }
    public func eval(js:String,complete:((AnyObject?,ErrorType?) -> Void)? = nil){
        if debugOn{
            self.delegate?.webView(self, log:"eval javascript \(js)")
        }
        internalWebview.evaluate(js, completion: complete)
    }
}


