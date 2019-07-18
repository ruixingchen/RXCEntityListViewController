//
//  RELTableViewCellSelectorManager.swift
//  RXCEntityListViewController
//
//  Created by ruixingchen on 7/19/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import UIKit
#if canImport(AsyncDisplayKit)
import AsyncDisplayKit
#endif

///manage all selectors and make cells
public class RELTableViewCellSelectorManager {

    public enum Priority:Int {
        case max = 0
        case high
        case `default`
        case low
        case count
    }

    fileprivate var selectorArray: [[RELTableViewCellSelector]] = [[RELTableViewCellSelector]].init(repeating: [], count: Priority.count.rawValue+1)

    //MARK: - Register

    /// the most common register, register a selector directly
    ///
    /// - Parameters:
    ///   - append: true: append on the last, false: insert at the first
    public func register(_ selector: RELTableViewCellSelector, priority: Priority = Priority.default, insert:Bool=false) {
        if insert {
            self.selectorArray[priority.rawValue].insert(selector, at: 0)
        }else{
            self.selectorArray[priority.rawValue].append(selector)
        }
    }

    ///register a defualt selector, we store only one default selector
    public func registerDefault(identifier:String, _ cellBlock: @escaping RELTableViewCellSelector.UITableViewCellBlock){
        let selector = RELTableViewCellSelector(matchBlock: {_ in return true},cellBlock: cellBlock)
        selector.identifier = identifier
        self.selectorArray[Priority.count.rawValue] = [selector]
    }

    #if canImport(AsyncDisplayKit)
    public func registerDefault(cellBlock: @escaping ASCellNodeBlock){
        let selector = RELTableViewCellSelector(matchBlock: {_ in return true}, cellBlock: cellBlock)
        self.selectorArray[Priority.count.rawValue] = [selector]
    }
    #endif

    //MARK: - Retrive

    ///retrive a selector, private function
    fileprivate func selector(for object:Any?, indexPath:IndexPath?=nil, includeDefault:Bool=true)->RELTableViewCellSelector? {
        for i in self.selectorArray {
            for j in i {
                if j.isMatched(object: object) {
                    return j
                }
            }
        }
        if includeDefault {
            let s = self.selectorArray.last?.last
            return s
        }
        return nil
    }

    ///retrive a cell if possible
    public func retriveCell(for tableView:UITableView, object: Any?, indexPath: IndexPath?=nil, includeDefault:Bool=true, userInfoForBindData userInfo:[AnyHashable:Any]?=nil) -> UITableViewCell? {
        guard let selector: RELTableViewCellSelector = self.selector(for: object, indexPath: indexPath,includeDefault: includeDefault) else {
            return nil
        }

        //we store the indexPath in the userInfo, so the cell can know the indexPath
        var outUserInfo:[AnyHashable:Any] = userInfo ?? [:]
        if outUserInfo["rel_indexPath"] == nil {
            outUserInfo["rel_indexPath"] = indexPath
        }

        var cell: UITableViewCell?
        let identifier: String? = selector.identifier
        if let validIdentifier:String = identifier {
            //deque from table view first
            cell = tableView.dequeueReusableCell(withIdentifier: validIdentifier)
        }
        if cell == nil {
            //init a cell
            cell = selector.makeCell(identifier: identifier)
        }
        guard let validCell = cell else {
            //WTF?
            #if (debug || DEBUG)
            fatalError("SHOULD INIT THE CELL HERE!!!")
            #else
            return nil
            #endif
        }

        if let bindDataBlock = selector.bindDataBlock {
            bindDataBlock(object, validCell, outUserInfo)
        }else{
            //default data binding
            if let needBind = cell as? RELNeedBindDataObject {
                needBind.bindData(object: object, userInfo: outUserInfo)
            }
        }

        return validCell
    }

    #if canImport(AsyncDisplayKit)
    ///retrive a cell if possible
    public func retriveCell(for tableNode:ASTableNode, object: Any?, indexPath: IndexPath?=nil, includeDefault:Bool=true, userInfoForBindData userInfo:[AnyHashable:Any]?=nil) -> ASCellNode? {
        guard let selector: RELTableViewCellSelector = self.selector(for: object, indexPath: indexPath,includeDefault: includeDefault) else {
            return nil
        }

        //we store the indexPath in the userInfo, so the cell can know the indexPath
        var outUserInfo:[AnyHashable:Any] = userInfo ?? [:]
        if outUserInfo["rel_indexPath"] == nil {
            outUserInfo["rel_indexPath"] = indexPath
        }
        
        let cell:ASCellNode = selector.makeCell()

        if let bindDataBlock = selector.bindDataBlock_ASDK {
            bindDataBlock(object, cell, outUserInfo)
        }else{
            //default data binding
            if let needBind = cell as? RELNeedBindDataObject {
                needBind.bindData(object: object, userInfo: outUserInfo)
            }
        }

        return cell
    }
    #endif

}

public extension RELTableViewCellSelectorManager {

    func register(matchBlock:@escaping RELTableViewCellSelector.MatchBlock, cellBlock: @escaping RELTableViewCellSelector.UITableViewCellBlock,bindDataBlock: @escaping RELTableViewCellSelector.BindDataBlock, priority: Priority = Priority.default, insert:Bool=false) {
        let selector = RELTableViewCellSelector(matchBlock: matchBlock, cellBlock: cellBlock)
        selector.bindDataBlock = bindDataBlock
        self.register(selector)
    }

    #if canImport(AsyncDisplayKit)
    func register(matchBlock:@escaping RELTableViewCellSelector.MatchBlock, cellBlock: @escaping RELTableViewCellSelector.ASDKCellBlock,bindDataBlock: @escaping RELTableViewCellSelector.BindDataBlock_ASDK, priority: Priority = Priority.default, insert:Bool=false) {
        let selector = RELTableViewCellSelector(matchBlock: matchBlock, cellBlock: cellBlock)
        selector.bindDataBlock_ASDK = bindDataBlock
        self.register(selector)
    }
    #endif

}
