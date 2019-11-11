//
//  RELCellSelector.swift
//  RXCEntityListViewController
//
//  Created by ruixingchen on 2019/10/31.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import UIKit
#if canImport(AsyncDisplayKit)
import AsyncDisplayKit
#endif

///选择器负责注册Cell, 生成Cell, 绑定数据
public class RELCellSelector {

    public typealias TableViewCellBlock = (_ userInfo:[AnyHashable:Any]?)->UITableViewCell
    #if canImport(AsyncDisplayKit)
    public typealias CellNodeBlock = (_ userInfo:[AnyHashable:Any]?)->ASCellNode
    #endif

    ///传入的对象是否匹配本selector
    public let matchBlock:(Any?)->Bool
    ///绑定数据的操作, 如果想要自定义的绑定数据操作可以传入closure
    public var bindDataBlock:((_ cell:AnyObject, _ data:Any?, _ userInfo:[AnyHashable:Any]?)->Void)?

    ///注册模式向TableView或者CollectionView注册的Nib或者AnyClass, 只能是这两种, 其他类型会直接崩溃
    public var cellRegistration:Any?
    ///生成一个TableViewCell, 适用于非注册模式
    public var tableViewCellMakerBlock:TableViewCellBlock?

    ///适用于TableView和CollectionView时候的复用ID, 必须赋值
    public var reuseIdentifier:String?

    #if canImport(AsyncDisplayKit)
    public var cellNodeMakerBlock:CellNodeBlock?
    #endif

    ///TableView非注册模式
    public init(reuseIdentifier:String, match:@escaping (Any?)->Bool, cell:@escaping (_ userInfo:[AnyHashable:Any]?)->UITableViewCell) {
        self.matchBlock = match
        self.tableViewCellMakerBlock = cell
    }

    ///TableView或者CollectionView的注册模式
    public init(reuseIdentifier:String, cellOrNib:Any, match:@escaping (Any?)->Bool) {
        self.reuseIdentifier = reuseIdentifier
        self.cellRegistration = cellOrNib
        self.matchBlock = match
    }

    #if canImport(AsyncDisplayKit)
    ///ASDK模式
    public init(match:@escaping (Any?)->Bool, cell:@escaping (_ userInfo:[AnyHashable:Any]?)->ASCellNode) {
        self.matchBlock = match
        self.cellNodeMakerBlock = cell
    }
    #endif

    public func isMatched(object:Any?)->Bool {
        return self.matchBlock(object)
    }

    ///在非注册模式下生成Cell
    public func makeTableViewCell(userInfo:[AnyHashable:Any]?)->UITableViewCell {
        precondition(self.tableViewCellMakerBlock != nil, "非注册模式下才可以调用此方法")
        return self.tableViewCellMakerBlock!(userInfo)
    }

    #if canImport(AsyncDisplayKit)
    ///生成ASDK的Cell, 适用于TableNode和CollectionNode
    public func makeCellNodeBlock(userInfo:[AnyHashable:Any]?)->ASCellNode {
        precondition(self.cellNodeMakerBlock != nil, "cellNodeMaker为空")
        return self.cellNodeMakerBlock!(userInfo)
    }
    #endif

}
