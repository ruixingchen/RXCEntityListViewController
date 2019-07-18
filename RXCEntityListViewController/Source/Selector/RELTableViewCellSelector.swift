//
//  RELTableViewCellSelector.swift
//  RXCEntityListViewController
//
//  Created by ruixingchen on 7/18/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import UIKit
#if canImport(AsyncDisplayKit)
import AsyncDisplayKit
#endif

open class RELTableViewCellSelector {

    public typealias MatchBlock = (_ object: Any?) -> Bool
    public typealias UITableViewCellBlock = (_ identifier: String?)->UITableViewCell
    public typealias BindDataBlock = (_ object:Any?, _ cell: UITableViewCell, _ userInfo:[AnyHashable:Any]?)->Void
    #if canImport(AsyncDisplayKit)
    public typealias ASDKCellBlock = ASCellNodeBlock
    public typealias BindDataBlock_ASDK = (_ object:Any?, _ cell: ASCellNode, _ userInfo:[AnyHashable:Any]?)->Void
    #endif

    open var matchBlock:MatchBlock?
    open var cellBlock: UITableViewCellBlock?
    open var bindDataBlock:BindDataBlock?
    #if canImport(AsyncDisplayKit)
    open var cellBlock_ASDK: ASDKCellBlock?
    open var bindDataBlock_ASDK:BindDataBlock_ASDK?
    #endif

    ///if this is nil, we do not deque cells from tableView but init each time, so better set a identifier
    ///no need for ASDK
    open var identifier:String?

    public init(cellBlock:@escaping UITableViewCellBlock) {
        self.cellBlock = cellBlock
    }

    #if canImport(AsyncDisplayKit)
    public init(cellBlock:@escaping ASDKCellBlock) {
        self.cellBlock_ASDK = cellBlock
    }
    #endif

    public convenience init(matchBlock:@escaping MatchBlock, cellBlock:@escaping UITableViewCellBlock) {
        self.init(cellBlock: cellBlock)
        self.matchBlock = matchBlock
    }

    #if canImport(AsyncDisplayKit)
    public convenience init(matchBlock:@escaping MatchBlock, cellBlock:@escaping ASDKCellBlock) {
        self.init(cellBlock: cellBlock)
        self.matchBlock = matchBlock
    }
    #endif

    ///set identifier for UITableView, no need for ASDK
    @discardableResult
    open func setIdentifier(_ id:String) -> RELTableViewCellSelector {
        self.identifier = id
        return self
    }

    @discardableResult
    open func setMatchBlock(_ match:@escaping MatchBlock)->RELTableViewCellSelector {
        self.matchBlock = match
        return self
    }

    @discardableResult
    open func setCellBlock(_ block:@escaping UITableViewCellBlock) -> RELTableViewCellSelector {
        self.cellBlock = block
        return self
    }

    #if canImport(AsyncDisplayKit)
    @discardableResult
    open func setCellBlock(_ block:@escaping ASDKCellBlock) -> RELTableViewCellSelector {
        self.cellBlock_ASDK = block
        return self
    }
    #endif

    @discardableResult
    open func setBindDataBlock(_ block:@escaping BindDataBlock)->RELTableViewCellSelector {
        self.bindDataBlock = block
        return self
    }

    #if canImport(AsyncDisplayKit)
    @discardableResult
    open func setBindDataBlock(_ block:@escaping BindDataBlock_ASDK)->RELTableViewCellSelector {
        self.bindDataBlock_ASDK = block
        return self
    }
    #endif

    //MARK: - Match

    ///is the object match this selector?
    open func isMatched(object: Any?) -> Bool {
        if let match = self.matchBlock {
            return match(object)
        }
        return false
    }

    open func makeCell(identifier:String?)->UITableViewCell {
        guard let cellBlock = self.cellBlock else {
            fatalError("MUST SET CELLBLOCK BEFORE makeCell called")
        }
        let cell:UITableViewCell = cellBlock(identifier)
        return cell
    }

    #if canImport(AsyncDisplayKit)
    open func makeCell()->ASCellNode {
        guard let cellBlock = self.cellBlock_ASDK else {
            fatalError("MUST SET CELLBLOCK BEFORE makeCell called")
        }
        return cellBlock()
    }
    #endif

}
