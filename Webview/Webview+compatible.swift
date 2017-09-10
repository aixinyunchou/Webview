//
//  Webview+compatible.swift
//  DjWebview
//
//  Created by 彭运筹 on 2017/8/14.
//  Copyright © 2017年 彭运筹. All rights reserved.
//

import Foundation

public class CompatibleWebview:WebView{
    internal override func newWebview() -> InternalWebview{
        return WebviewPool.shared.createUIWebview()
    }
    
    internal override func reuseWebview(){
    }
}
