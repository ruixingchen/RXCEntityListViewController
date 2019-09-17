//
//  RELCellSelector.swift
//  RXCEntityListViewController
//
//  Created by ruixingchen on 7/18/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import UIKit
#if canImport(AsyncDisplayKit)
import AsyncDisplayKit
#endif

open class RELCellSelector {

    public typealias MatchBlock = (_ object: Any?) -> Bool
    public typealias CellBlock = (_ identifier: String?, _ userInfo:[AnyHashable:Any]?)->AnyObject
    public typealias BindDataBlock = (_ object:Any?, _ cell: AnyObject, _ userInfo:[AnyHashable:Any]?)->Void

    public typealias TableViewCellBlock = (_ identifier: String?, _ userInfo:[AnyHashable:Any]?)->UITableViewCell
    #if (CanUseASDK || canImport(AsyncDisplayKit))
    public typealias NodeCellBlock = (_ userInfo:[AnyHashable:Any]?)->ASCellNode
    #endif

    public typealias TableViewCellBindDataBlock = (_ object:Any?, _ cell: UITableViewCell, _ userInfo:[AnyHashable:Any]?)->Void
    public typealias CollectionViewCellBindDataBlock = (_ object:Any?, _ cell: UICollectionViewCell, _ userInfo:[AnyHashable:Any]?)->Void
    #if (CanUseASDK || canImport(AsyncDisplayKit))
    public typealias NodeCellBindDataBlock = (_ object:Any?, _ cell: ASCellNode, _ userInfo:[AnyHashable:Any]?)->Void
    #endif

    var matchBlock:MatchBlock
    var cellBlock:CellBlock?
    var bindDataBlock:BindDataBlock?

//    var tableViewCellBlock:TableViewCellBlock?
//    var nodeCellBlock:NodeCellBlock?
//
//    var tableViewCellBindDataBlock:TableViewCellBindDataBlock?
//    var collectionViewCellBindDataBlock:CollectionViewCellBindDataBlock?
//    var nodeCellBindDataBlock:NodeCellBindDataBlock?

    var collectionViewRegisterObject:Any?
    var supplementaryViewOfKind:String?

    ///if this is nil, we do not deque cells from tableView but init each time, so better set a identifier
    ///required for collectionView
    ///no need for ASDK
    open var identifier:String?

    public init(matchBlock:@escaping MatchBlock) {
        self.matchBlock = matchBlock
    }

    public convenience init(matchBlock:@escaping MatchBlock, identifier:String?, cellBlock:@escaping TableViewCellBlock) {
        self.init(matchBlock: matchBlock)
        self.identifier = identifier
        self.setCellBlock(cellBlock)
    }

    public convenience init(matchBlock:@escaping MatchBlock, identifier:String, collectionViewCellClass:UICollectionViewCell.Type) {
        self.init(matchBlock: matchBlock)
        self.identifier = identifier
        self.collectionViewRegisterObject = collectionViewCellClass
    }

    #if (CanUseASDK || canImport(AsyncDisplayKit))
    public convenience init(matchBlock:@escaping MatchBlock, cellBlock:@escaping NodeCellBlock) {
        self.init(matchBlock: matchBlock)
        self.setCellBlock(cellBlock)
    }
    #endif

    //MARK: - Link Set

    ///set identifier for UITableView, no need for ASDK
    @discardableResult
    open func setIdentifier(_ id:String) -> RELCellSelector {
        self.identifier = id
        return self
    }

    @discardableResult
    open func setMatchBlock(_ match:@escaping MatchBlock)->RELCellSelector {
        self.matchBlock = match
        return self
    }

    @discardableResult
    open func setCellBlock(_ block:@escaping TableViewCellBlock) -> RELCellSelector {
        self.cellBlock = {(identifier, userInfo) in
            return block(identifier, userInfo)
        }
        return self
    }

    #if (CanUseASDK || canImport(AsyncDisplayKit))
    @discardableResult
    open func setCellBlock(_ block:@escaping NodeCellBlock) -> RELCellSelector {
        self.cellBlock = {(_, userInfo) in
            return block(userInfo)
        }
        return self
    }
    #endif

//    @discardableResult
//    open func setBindDataBlock(_ block:@escaping BindDataBlock)->RELCellSelector {
//        self.bindDataBlock = block
//        return self
//    }

    open func setBindDataBlock(_ block:@escaping TableViewCellBindDataBlock)->RELCellSelector {
        self.bindDataBlock = {(object, cellObject, userInfo) in
            if let cell = cellObject as? UITableViewCell {
                block(object, cell, userInfo)
            }else {
                assertionFailure("要求传入UITableViewCell，却传入了\(cellObject)")
            }
        }
        return self
    }

    open func setBindDataBlock(_ block:@escaping CollectionViewCellBindDataBlock)->RELCellSelector {
        self.bindDataBlock = {(object, cellObject, userInfo) in
            if let cell = cellObject as? UICollectionViewCell {
                block(object, cell, userInfo)
            }else {
                assertionFailure("要求传入UICollectionViewCell，却传入了\(cellObject)")
            }
        }
        return self
    }

    #if (CanUseASDK || canImport(AsyncDisplayKit))
    @discardableResult
    open func setBindDataBlock(_ block:@escaping NodeCellBindDataBlock)->RELCellSelector {
        self.bindDataBlock = {(object, cellObject, userInfo) in
            if let cell = cellObject as? ASCellNode {
                block(object, cell, userInfo)
            }else {
                assertionFailure("要求传入ASCellNode，却传入了\(cellObject)")
            }
        }
        return self
    }
    #endif

    //MARK: - Match

    ///is the object match this selector?
    open func isMatched(object: Any?) -> Bool {
        let match = self.matchBlock(object)
        return match
    }

    //MARK: - Make

    ///脱离容器单独实例化一个Cell对象，只适合于TableView和ASDK
    private func _makeCell(identifier:String?, userInfo:[AnyHashable:Any]?)->AnyObject? {
        guard let block = self.cellBlock else {
            print("生成cell的时候cellBlock为nil, 无法生成cell对象")
            return nil
        }
        let cell = block(identifier, userInfo)
        return cell
    }

    open func makeCell(identifier:String?, userInfo:[AnyHashable:Any]?)->UITableViewCell? {
        if let cellObject = self._makeCell(identifier: identifier, userInfo: userInfo) {
            if let cell = cellObject as? UITableViewCell {
                return cell
            }else {
                print("生成的Cell类型不合适，要求为UITableViewCell，实际为\(cellObject)")
            }
        }
        return nil
    }

    #if (CanUseASDK || canImport(AsyncDisplayKit))
    open func makeCell(userInfo:[AnyHashable:Any]?)->ASCellNode? {
        if let cellObject = self._makeCell(identifier: identifier, userInfo: userInfo) {
            if let cell = cellObject as? ASCellNode {
                return cell
            }else {
                print("生成的Cell类型不合适，要求为ASCellNode，实际为\(cellObject)")
            }
        }
        return nil
    }
    #endif

}
