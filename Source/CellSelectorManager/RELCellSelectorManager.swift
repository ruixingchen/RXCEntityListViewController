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

    public class PrioritySelectorPair {
        public var priority: Priority
        public var selectors:[RELCellSelector] = []

        public init(priority: Priority) {
            self.priority = priority
        }
    }

    internal let readWriteQueue:DispatchQueue = DispatchQueue.init(label: "readWriteQueue", qos: .default, attributes: .concurrent)

    ///higher priority to lower priority
    public var prioritySelectorPairs:[PrioritySelectorPair] = []

    internal func safeRead(closure:@escaping()->Void) {
        self.readWriteQueue.sync {
            closure()
        }
    }

    internal func safeWrite(closure:@escaping()->Void) {
        let g = DispatchGroup()
        self.readWriteQueue.async(group: g, qos: .default, flags: .barrier) {
            closure()
        }
        g.wait()
    }

    ///返回某个优先级的全部选择器
    internal func selectors(for priority:Priority)->[RELCellSelector]? {
        return self.prioritySelectorPairs.filter({$0.priority==priority}).first?.selectors
    }

    ///为某个优先级设置选择器
    internal func setSelectors(for priority:Priority, selectors:[RELCellSelector]) {
        let pair = PrioritySelectorPair(priority: priority)
        pair.selectors = selectors
        if let index = self.prioritySelectorPairs.firstIndex(where: {$0.priority == priority}) {
            //alread exist
            self.prioritySelectorPairs[index] = pair
        }else if let index = self.prioritySelectorPairs.firstIndex(where: {$0.priority < priority}) {
            //insert a new
            self.prioritySelectorPairs.insert(pair, at: index)
        }else {
            //insert at the end
            self.prioritySelectorPairs.append(pair)
        }
    }

}

//MARK: - Register
extension RELCellSelectorManager {

    /// the most common register, register a selector directly
    ///
    /// - Parameters:
    ///   - insert: false: append on the last, true: insert at the first
    public func register(_ selector: RELCellSelector, priority: Priority = .medium, insert:Bool=false) {
        self.safeWrite {
            var selectors = self.selectors(for: priority) ?? []
            if insert {
                selectors.insert(selector, at: 0)
            }else{
                selectors.append(selector)
            }
            self.setSelectors(for: priority, selectors: selectors)
        }
    }

    ///register a defualt selector, we store only one default selector
    public func registerDefault(_ selector: RELCellSelector) {
        self.safeWrite {
            self.setSelectors(for: Priority.min, selectors: [selector])
        }
    }
}

//MARK: - Retrive
extension RELCellSelectorManager {
    ///retrive a selector, private function
    public func selector(for object:Any?, indexPath:IndexPath?=nil, includeDefault:Bool=true)->RELCellSelector? {
        for pair in self.prioritySelectorPairs {
            if !includeDefault && pair.priority.value == Priority.ValueType.min {continue}
            let selectors = pair.selectors
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
        let identifier: String? = selector.reuseIdentifier

        if let cv = listView as? UICollectionView {
            precondition(identifier != nil, "collectionView 模式下 identifier不可以为nil")
            precondition(indexPath != nil, "collectionView 模式下 indexPath不可以为nil")
            cell = cv.dequeueReusableCell(withReuseIdentifier: identifier!, for: indexPath!)
        }else if let tv = listView as? UITableView {
            if let validIdentifier = identifier {
                cell = tv.dequeueReusableCell(withIdentifier: validIdentifier)
            }
            if cell == nil {
                cell = selector.makeTableViewCell(userInfo: outUserInfo)
            }
        }else {
            #if (CanUseASDK || canImport(AsyncDisplayKit))
            if let _ = listView as? ASTableNode {
                cell = selector.makeCellNodeBlock(userInfo: outUserInfo)
            }else if let _ = listView as? ASCollectionNode {
                cell = selector.makeCellNodeBlock(userInfo: outUserInfo)
            }
            #endif
        }

        guard let validCell = cell else {
            //WTF?
            assertionFailure("CAN NOT FIND A MATCHED SELECTOR TO INIT CELL, CHECK YOUR CODES OR USE A DEFAULT SELECTOR")
            return nil
        }

        if let bindDataBlock = selector.bindDataBlock {
            bindDataBlock(validCell, object, outUserInfo)
        }else if let needBind = cell as? RELDataBindableObjectProtocol {
            //default data binding
            needBind.rxc_bindData(data: object, userInfo: outUserInfo)
        }

        return validCell
    }

    ///retrive a cell if possible
    public func retriveCell(for listView:UITableView, object: Any?, indexPath: IndexPath?=nil, includeDefault:Bool=true, userInfoForBindData userInfo:[AnyHashable:Any]?=nil) -> UITableViewCell? {

        let cellObject = self._retriveCell(for: listView, object: object, indexPath: indexPath, includeDefault: includeDefault, userInfoForBindingData: userInfo)
        if let cell = cellObject as? UITableViewCell {
            return cell
        }else {
            assertionFailure("wrong cell type")
            return nil
        }
    }

    ///retrive a cell if possible
    public func retriveCell(for listView: UICollectionView, object: Any?, indexPath: IndexPath?=nil, includeDefault:Bool=true, userInfoForBindData userInfo:[AnyHashable:Any]?=nil) -> UICollectionViewCell? {

        let cellObject = self._retriveCell(for: listView, object: object, indexPath: indexPath, includeDefault: includeDefault, userInfoForBindingData: userInfo)
        if let cell = cellObject as? UICollectionViewCell {
            return cell
        }else {
            assertionFailure("wrong cell type")
            return nil
        }
    }

    #if canImport(AsyncDisplayKit)
    ///retrive a cell if possible
    public func retriveCell(for listView:ASTableNode, object: Any?, indexPath: IndexPath?=nil, includeDefault:Bool=true, userInfoForBindData userInfo:[AnyHashable:Any]?=nil) -> ASCellNode? {
        let cellObject = self._retriveCell(for: listView, object: object, indexPath: indexPath, includeDefault: includeDefault, userInfoForBindingData: userInfo)
        if let cell = cellObject as? ASCellNode {
            return cell
        }else {
            assertionFailure("wrong cell type")
            return nil
        }
    }

    public func retriveCell(for listView:ASCollectionNode, object: Any?, indexPath: IndexPath?=nil, includeDefault:Bool=true, userInfoForBindData userInfo:[AnyHashable:Any]?=nil) -> ASCellNode? {
        let cellObject = self._retriveCell(for: listView, object: object, indexPath: indexPath, includeDefault: includeDefault, userInfoForBindingData: userInfo)
        if let cell = cellObject as? ASCellNode {
            return cell
        }else {
            assertionFailure("wrong cell type")
            return nil
        }
    }

    #endif
}

public extension RELCellSelectorManager {

    ///register cells for a list view if the selector is in register mode
    func listViewRegistering(listView: AnyObject) {
        for pair in self.prioritySelectorPairs.reversed() {
            for selector in pair.selectors.reversed() {
                guard let identifier = selector.reuseIdentifier else {continue}
                if let nib = selector.cellRegistration as? UINib {
                    if let cv = listView as? UICollectionView {
                        cv.register(nib, forCellWithReuseIdentifier: identifier)
                    }else if let tv = listView as? UITableView {
                        tv.register(nib, forCellReuseIdentifier: identifier)
                    }
                }else if let classs = selector.cellRegistration as? AnyClass {
                    if let cv = listView as? UICollectionView {
                        cv.register(classs, forCellWithReuseIdentifier: identifier)
                    }else if let tv = listView as? UITableView {
                        tv.register(classs, forCellReuseIdentifier: identifier)
                    }
                }
            }
        }
    }

}
