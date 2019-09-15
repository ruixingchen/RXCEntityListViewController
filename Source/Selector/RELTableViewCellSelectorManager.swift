//
//  RELCellSelectorManager.swift
//  RXCEntityListViewController
//
//  Created by ruixingchen on 7/19/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import UIKit
#if canImport(AsyncDisplayKit) && CanUseASDK
import AsyncDisplayKit
#endif

///manage all selectors and make cells
public class RELCellSelectorManager {

    public typealias Priority = RELCellSelectorPriority
    public typealias PriorityValueType = RELCellSelectorPriority.PriorityValueType

    fileprivate var selectorsCollection:[PriorityValueType:[RELCellSelector]] = [:]
    fileprivate var defaultSelector:RELCellSelector?
    //record all priorities
    fileprivate var priorities:[PriorityValueType] = []

    public func lock() {
        objc_sync_enter(self.selectorsCollection)
    }

    public func unlock() {
        objc_sync_exit(self.selectorsCollection)
    }

    public func selectors(for priority:PriorityValueType)->[RELCellSelector]? {
        return self.selectorsCollection[priority]
    }

    public func setSelectors(for priority:PriorityValueType, selectors:[RELCellSelector]) {
        self.selectorsCollection[priority] = selectors
        //将优先级排序存储
        var index:Int = 0
        for i in 0..<self.priorities.count {
            let p = self.priorities[i]
            if priority == p {return}
            index = i
            if priority < p {
                index += 1
                break
            }
        }
        self.priorities.insert(priority, at: index)
    }

    //MARK: - Register

    /// the most common register, register a selector directly
    ///
    /// - Parameters:
    ///   - append: true: append on the last, false: insert at the first
    public func register(_ selector: RELCellSelector, priority: Priority = .medium, insert:Bool=false) {
        var selectors = self.selectors(for: priority.value) ?? []
        if insert {
            selectors.insert(selector, at: 0)
        }else{
            selectors.append(selector)
        }
        self.setSelectors(for: priority.value, selectors: selectors)
    }

    ///register a defualt selector, we store only one default selector
    public func registerDefault(identifier:String, _ cellBlock: @escaping RELCellSelector.TableViewCellBlock){
        let selector = RELCellSelector(matchBlock: {_ in return true}, identifier: identifier, cellBlock: cellBlock)
        self.defaultSelector = selector
    }

    public func registerDefault(identifier:String, cellClass: UICollectionViewCell.Type) {
        let selector = RELCellSelector(matchBlock: {_ in return true}, identifier: identifier, collectionViewCellClass: cellClass)
        self.defaultSelector = selector
    }

    #if canImport(AsyncDisplayKit)
    public func registerDefault(cellBlock: @escaping RELCellSelector.NodeCellBlock){
        let selector = RELCellSelector(matchBlock: {_ in return true}, cellBlock: cellBlock)
        self.defaultSelector = selector
    }
    #endif

    //MARK: - Retrive

    ///retrive a selector, private function
    func selector(for object:Any?, indexPath:IndexPath?=nil, includeDefault:Bool=true)->RELCellSelector? {

        for i in self.priorities {
            guard let selectors = self.selectors(for: i) else {continue}
            for j in selectors {
                if j.isMatched(object: object) {
                    return j
                }
            }
        }
        if includeDefault {
            if let s = self.defaultSelector {
                return s
            }
        }
        return nil
    }

    fileprivate func retriveCell(for listView: AnyObject, object: Any?, indexPath: IndexPath?, includeDefault:Bool, userInfoForBindingData userInfo:[AnyHashable:Any]?) -> AnyObject? {
        guard let selector: RELCellSelector = self.selector(for: object, indexPath: indexPath,includeDefault: includeDefault) else {
            return nil
        }

        //we store the indexPath in the userInfo, so the cell can know the indexPath
        var outUserInfo:[AnyHashable:Any] = userInfo ?? [:]
        if outUserInfo["indexPath"] == nil {
            outUserInfo["indexPath"] = indexPath
        }

        var cell: AnyObject?
        let identifier: String? = selector.identifier

        if let cv = listView as? UICollectionView {
            precondition(identifier != nil, "collectionView 模式下 identifier不可以为nil")
            cell = cv.dequeueReusableCell(withReuseIdentifier: identifier!, for: indexPath!)
        }else if let tv = listView as? UITableView {
            if let validIdentifier = identifier {
                cell = tv.dequeueReusableCell(withIdentifier: validIdentifier)
            }
            if cell == nil {
                cell = selector.makeCell(identifier: identifier, userInfo: nil)
            }
        }
        #if CanUseASDK
        if let _ = listView as? ASTableNode {
            cell = selector.makeCell(userInfo: nil)
        }else if let _ = listView as? ASCollectionNode {
            cell = selector.makeCell(userInfo: nil)
        }
        #endif

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
            if let needBind = cell as? RELDataBindableObjectProtocol {
                needBind.bindData(object: object, userInfo: outUserInfo)
            }
        }

        return validCell
    }

    ///retrive a cell if possible
    public func retriveCell(for tableView:UITableView, object: Any?, indexPath: IndexPath?=nil, includeDefault:Bool=true, userInfoForBindData userInfo:[AnyHashable:Any]?=nil) -> UITableViewCell? {

        let cellObject = self.retriveCell(for: tableView, object: object, indexPath: indexPath, includeDefault: includeDefault, userInfoForBindingData: userInfo)
        if let cell = cellObject as? UITableViewCell {
            return cell
        }else {
            assertionFailure("生成的Cell类型不合适")
            print("生成的Cell类型不合适")
        }
        return nil
    }

    ///retrive a cell if possible
    public func retriveCell(for collectionView:UICollectionView, object: Any?, indexPath: IndexPath?=nil, includeDefault:Bool=true, userInfoForBindData userInfo:[AnyHashable:Any]?=nil) -> UICollectionViewCell? {

        let cellObject = self.retriveCell(for: collectionView, object: object, indexPath: indexPath, includeDefault: includeDefault, userInfoForBindingData: userInfo)
        if let cell = cellObject as? UICollectionViewCell {
            return cell
        }else {
            assertionFailure("生成的Cell类型不合适")
            print("生成的Cell类型不合适")
        }
        return nil

    }

    #if canImport(AsyncDisplayKit)
    ///retrive a cell if possible
    public func retriveCell(for tableNode:ASTableNode, object: Any?, indexPath: IndexPath?=nil, includeDefault:Bool=true, userInfoForBindData userInfo:[AnyHashable:Any]?=nil) -> ASCellNode? {
        let cellObject = self.retriveCell(for: tableNode, object: object, indexPath: indexPath, includeDefault: includeDefault, userInfoForBindingData: userInfo)
        if let cell = cellObject as? ASCellNode {
            return cell
        }else {
            assertionFailure("生成的Cell类型不合适")
            print("生成的Cell类型不合适")
        }
        return nil
    }
    #endif

}

//MARK: - Convenience Init
public extension RELCellSelectorManager {

    func register(identifier:String?, matchBlock:@escaping RELCellSelector.MatchBlock, cellBlock: @escaping RELCellSelector.TableViewCellBlock, priority: Priority = Priority.medium, insert:Bool=false) {
        let selector = RELCellSelector(matchBlock: matchBlock, identifier: identifier, cellBlock: cellBlock)
        self.register(selector, priority: priority, insert: insert)
    }

    func register(identifier:String, matchBlock:@escaping RELCellSelector.MatchBlock, cellClass:UICollectionViewCell.Type, priority: Priority = Priority.medium, insert:Bool=false) {

        let selector = RELCellSelector(matchBlock: matchBlock, identifier: identifier, collectionViewCellClass: cellClass)
        self.register(selector, priority: priority, insert: insert)

    }

    #if canImport(AsyncDisplayKit)
    func register(matchBlock:@escaping RELCellSelector.MatchBlock, cellBlock: @escaping RELCellSelector.NodeCellBlock, priority: Priority = Priority.medium, insert:Bool=false) {
        let selector = RELCellSelector(matchBlock: matchBlock, cellBlock: cellBlock)
        self.register(selector)
    }
    #endif

}
