//
//  RELCellSelectorManager.swift
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
public class RELCellSelectorManager {

    public typealias Priority = RELCellSelectorPriority
    public typealias PriorityValueType = RELCellSelectorPriority.PriorityValueType

    public class PrioritySelectorPair {
        public var priority: Priority
        public var selectors:[RELCellSelector] = []

        public init(priority: Priority) {
            self.priority = priority
        }
    }

    ///higher priority to lower priority
    public var prioritySelectorPairs:[PrioritySelectorPair] = []

    fileprivate func lock() {
        objc_sync_enter(self.prioritySelectorPairs)
    }

    fileprivate func unlock() {
        objc_sync_exit(self.prioritySelectorPairs)
    }

    public func selectors(for priority:PriorityValueType)->[RELCellSelector]? {
        return self.prioritySelectorPairs.filter({$0.priority.value==priority}).first?.selectors
    }

    public func setSelectors(for priority:PriorityValueType, selectors:[RELCellSelector]) {
        self.lock()
        let p = PrioritySelectorPair(priority: Priority(integerLiteral: priority))
        p.selectors = selectors
        if let index = self.prioritySelectorPairs.firstIndex(where: {$0.priority.value <= priority}) {
            self.prioritySelectorPairs.insert(p, at: index)
        }else {
            self.prioritySelectorPairs.append(p)
        }
        self.unlock()
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
        self.setSelectors(for: PriorityValueType.min, selectors: [selector])
    }

    public func registerDefault(identifier:String, cellClass: UICollectionViewCell.Type) {
        let selector = RELCellSelector(matchBlock: {_ in return true}, identifier: identifier, collectionViewCellClass: cellClass)
        self.setSelectors(for: PriorityValueType.min, selectors: [selector])
    }

    #if canImport(AsyncDisplayKit)
    public func registerDefault(cellBlock: @escaping RELCellSelector.NodeCellBlock){
        let selector = RELCellSelector(matchBlock: {_ in return true}, cellBlock: cellBlock)
        self.setSelectors(for: PriorityValueType.min, selectors: [selector])
    }
    #endif

    //MARK: - Retrive

    ///retrive a selector, private function
    public func selector(for object:Any?, indexPath:IndexPath?=nil, includeDefault:Bool=true)->RELCellSelector? {

        for i in self.prioritySelectorPairs {
            if !includeDefault && i.priority.value == PriorityValueType.min {continue}
            let selectors = i.selectors
            for j in selectors {
                if j.isMatched(object: object) {
                    return j
                }
            }
        }
        return nil
    }

    ///公共的取回Cell的方法
    fileprivate func _retriveCell(for listView: AnyObject, object: Any?, indexPath: IndexPath?, includeDefault:Bool, userInfoForBindingData userInfo:[AnyHashable:Any]?) -> AnyObject? {
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
        }else {
            #if (CanUseASDK || canImport(AsyncDisplayKit))
            if let _ = listView as? ASTableNode {
                cell = selector.makeCell(userInfo: nil)
            }else if let _ = listView as? ASCollectionNode {
                cell = selector.makeCell(userInfo: nil)
            }
            #endif
        }

        guard let validCell = cell else {
            //WTF?
            assertionFailure("SHOULD INIT THE CELL HERE!!!")
            return nil
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
    public func retriveCell(for listView:UITableView, object: Any?, indexPath: IndexPath?=nil, includeDefault:Bool=true, userInfoForBindData userInfo:[AnyHashable:Any]?=nil) -> UITableViewCell? {

        let cellObject = self._retriveCell(for: listView, object: object, indexPath: indexPath, includeDefault: includeDefault, userInfoForBindingData: userInfo)
        if let cell = cellObject as? UITableViewCell {
            return cell
        }else {
            assertionFailure("生成的Cell类型不合适")
            print("生成的Cell类型不合适")
        }
        return nil
    }

    ///retrive a cell if possible
    public func retriveCell(for listView:UICollectionView, object: Any?, indexPath: IndexPath?=nil, includeDefault:Bool=true, userInfoForBindData userInfo:[AnyHashable:Any]?=nil) -> UICollectionViewCell? {

        let cellObject = self._retriveCell(for: listView, object: object, indexPath: indexPath, includeDefault: includeDefault, userInfoForBindingData: userInfo)
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
    public func retriveCell(for listView:ASTableNode, object: Any?, indexPath: IndexPath?=nil, includeDefault:Bool=true, userInfoForBindData userInfo:[AnyHashable:Any]?=nil) -> ASCellNode? {
        let cellObject = self._retriveCell(for: listView, object: object, indexPath: indexPath, includeDefault: includeDefault, userInfoForBindingData: userInfo)
        if let cell = cellObject as? ASCellNode {
            return cell
        }else {
            assertionFailure("生成的Cell类型不合适")
            print("生成的Cell类型不合适")
        }
        return nil
    }

    public func retriveCell(for listView:ASCollectionNode, object: Any?, indexPath: IndexPath?=nil, includeDefault:Bool=true, userInfoForBindData userInfo:[AnyHashable:Any]?=nil) -> ASCellNode? {
        let cellObject = self._retriveCell(for: listView, object: object, indexPath: indexPath, includeDefault: includeDefault, userInfoForBindingData: userInfo)
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

//MARK: - Convenience register
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

public extension RELCellSelectorManager {

    func collectionViewRegister(collectionView:UICollectionView) {
        ///从小优先级开始注册
        for i in self.prioritySelectorPairs.reversed() {
            for j in i.selectors.reversed() {
                guard let id = j.identifier else {continue}

                if let kind = j.supplementaryViewOfKind {
                    //注册SupplementaryView
                    if let nib = j.collectionViewRegisterObject as? UINib {
                        collectionView.register(nib, forSupplementaryViewOfKind: kind, withReuseIdentifier: id)
                    }else if let classs = j.collectionViewRegisterObject as? AnyClass {
                        collectionView.register(classs, forSupplementaryViewOfKind: kind, withReuseIdentifier: id)
                    }
                }else {
                    //注册Cell
                    if let classs = j.collectionViewRegisterObject as? UICollectionViewCell.Type {
                        collectionView.register(classs, forCellWithReuseIdentifier: id)
                    }else if let nib = j.collectionViewRegisterObject as? UINib {
                        collectionView.register(nib, forCellWithReuseIdentifier: id)
                    }
                }
            }
        }
    }

}
