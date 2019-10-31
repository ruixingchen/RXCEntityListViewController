//
//  RXCViewLikeObjectProtocol.swift
//  CoolMarket
//
//  Created by ruixingchen on 9/5/19.
//  Copyright © 2019 CoolApk. All rights reserved.
//

import UIKit
#if (CanUseASDK || canImport(AsyncDisplayKit))
import AsyncDisplayKit
#endif

///使用协议来统一Node和UIView
public protocol RXCViewLikeObjectProtocol: AnyObject {
    var frame:CGRect {get set}
    var bounds:CGRect {get set}
    var backgroundColor:UIColor? {get set}
    var layer:CALayer {get}

    func likeViewToView()->UIView
}

extension UIView: RXCViewLikeObjectProtocol {

    public func likeViewToView() -> UIView {
        return self
    }
}

#if (CanUseASDK || canImport(AsyncDisplayKit))
extension ASDisplayNode: RXCViewLikeObjectProtocol {

    public func likeViewToView() -> UIView {
        return self.view
    }
}
#endif
