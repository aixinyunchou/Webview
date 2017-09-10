//
//  ViewController.swift
//  Demo
//
//  Created by 彭运筹 on 2017/6/16.
//  Copyright © 2017年 彭运筹. All rights reserved.
//

import UIKit
import DjWebview

class ViewController: UIViewController,WebviewDelegate {
    @IBOutlet weak var webview: WebView!
    var km = KeyboardMan()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.webview.supportMenuActions = ["createCommentCmd","reportBugCmd","copyCmd","selectAllCmd"]
        self.webview.delegate = self
        self.webview.scrollView.keyboardDismissMode = .Interactive
        let urlStr = NSBundle.mainBundle().pathForResource("demo", ofType: "html")!
        let url = NSURL(fileURLWithPath: urlStr)
        let request = NSURLRequest(URL: url)
        self.webview.load(request)
        self.webview.becomeFirstResponder()
        km.animateWhenKeyboardAppear = { _,_,_ in
            self.webview.toolbar = NSBundle.mainBundle().loadNibNamed("ToolbarView", owner: nil, options: nil)?.first as! ToolbarView
            
        }
        km.animateWhenKeyboardDisappear = { _ in
            self.webview.toolbar = nil
        }
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func webviewLoadBegin(webView:WebView){
        print("webviewLoadBegin")
    }
    func webviewLoadComplete(webView:WebView){
        print("webviewLoadComplete")
        self.webview.eval("getInfo()") { (obj, err) in
            print("\(obj,err)")
        }
    }
    func webview(webview:WebView, fail:ErrorType){
        print(" webview(webview:WebView, fail:ErrorType?) => \(fail)")
    }
    func webview(webview:WebView, message:AnyObject){
        print("message->\(message)")
    }
    func webView(webview:WebView,log:String){
        print("log:\(log)")
    }
    func webView(webview:WebView,shouldNavgate:NSURLRequest,type:WebviewNavgateType) -> Bool{
        return true
    }
}

