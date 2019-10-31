//
//  RELListViewProtocol.swift
//  RXCEntityListViewController
//
//  Created by ruixingchen on 9/15/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import UIKit
#if canImport(AsyncDisplayKit)
import AsyncDisplayKit
#endif
#if canImport(RXCDiffArray)
import RXCDiffArray
#endif

fileprivate extension UICollectionView.ScrollPosition {
    func toTableViewScrollPosition()->UITableView.ScrollPosition {
        if self == .top {return .top}
        else if self == .centeredVertically || self == .centeredHorizontally {return .middle}
        else if self == .bottom {return .bottom}
        return .none
    }
}

///将所有列表视图的API进行统一
public protocol RELListViewProtocol: RXCScrollViewLikeObjectProtocol {

    var rel_numberOfSections: Int { get }

    func rel_numberOfRows(inSection section: Int) -> Int

    func rel_rectForRow(at indexPath: IndexPath) -> CGRect

    func rel_indexPathForRow(at point: CGPoint) -> IndexPath?

    func rel_indexPath(for cell: AnyObject) -> IndexPath?

    func rel_cellForRow(at indexPath: IndexPath) -> AnyObject?

    var rel_visibleCells: [AnyObject] { get }

    var rel_indexPathsForVisibleRows: [IndexPath] { get }

    func rel_scrollToRow(at indexPath: IndexPath, at scrollPosition: UICollectionView.ScrollPosition, animated: Bool)

    // Reloading and Updating

    func rel_performBatchUpdates(userInfo:[AnyHashable:Any]?, _ updates: (() -> Void)?, completion: ((Bool) -> Void)?)

    func rel_insertSections(_ sections: IndexSet, with animation: UITableView.RowAnimation)

    func rel_deleteSections(_ sections: IndexSet, with animation: UITableView.RowAnimation)

    func rel_reloadSections(_ sections: IndexSet, with animation: UITableView.RowAnimation)

    func rel_moveSection(_ section: Int, toSection newSection: Int)

    func rel_insertRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation)

    func rel_deleteRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation)

    func rel_reloadRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation)

    func rel_moveRow(at indexPath: IndexPath, to newIndexPath: IndexPath)

    func rel_reloadData()

    var rel_allowsSelection: Bool {get set}

    @available(iOS 5.0, *)
    var rel_allowsMultipleSelection: Bool {get set}

    // Selection

    var rel_indexPathForSelectedRow: IndexPath? { get }

    @available(iOS 5.0, *)
    var rel_indexPathsForSelectedRows: [IndexPath] { get }

    func rel_selectRow(at indexPath: IndexPath?, animated: Bool, scrollPosition: UICollectionView.ScrollPosition)

    func rel_deselectRow(at indexPath: IndexPath, animated: Bool)

}

extension UITableView: RELListViewProtocol {
    public var rel_numberOfSections: Int {
        return self.numberOfSections
    }

    public func rel_numberOfRows(inSection section: Int) -> Int {
        return self.numberOfRows(inSection: section)
    }

    public func rel_rectForRow(at indexPath: IndexPath) -> CGRect {
        return self.rectForRow(at: indexPath)
    }

    public func rel_indexPathForRow(at point: CGPoint) -> IndexPath? {
        return self.indexPathForRow(at: point)
    }

    public func rel_indexPath(for cell: AnyObject) -> IndexPath? {
        if let c = cell as? UITableViewCell {
            return self.indexPath(for: c)
        }
        return nil
    }

    public func rel_cellForRow(at indexPath: IndexPath) -> AnyObject? {
        return self.cellForRow(at: indexPath)
    }

    public var rel_visibleCells: [AnyObject] {
        return self.visibleCells
    }

    public var rel_indexPathsForVisibleRows: [IndexPath] {
        return self.indexPathsForVisibleRows ?? []
    }

    public func rel_scrollToRow(at indexPath: IndexPath, at scrollPosition: UICollectionView.ScrollPosition, animated: Bool) {
        return self.scrollToRow(at: indexPath, at: scrollPosition.toTableViewScrollPosition(), animated: animated)
    }

    public func rel_performBatchUpdates(userInfo: [AnyHashable : Any]?, _ updates: (() -> Void)?, completion: ((Bool) -> Void)?) {
        if #available(iOS 11.0, *) {
            self.performBatchUpdates(updates, completion: completion)
        } else {
            self.beginUpdates()
            updates?()
            self.endUpdates()
            completion?(true)
        }
    }

    public func rel_insertSections(_ sections: IndexSet, with animation: UITableView.RowAnimation) {
        self.insertSections(sections, with: animation)
    }

    public func rel_deleteSections(_ sections: IndexSet, with animation: UITableView.RowAnimation) {
        self.deleteSections(sections, with: animation)
    }

    public func rel_reloadSections(_ sections: IndexSet, with animation: UITableView.RowAnimation) {
        self.reloadSections(sections, with: animation)
    }

    public func rel_moveSection(_ section: Int, toSection newSection: Int) {
        self.moveSection(section, toSection: newSection)
    }

    public func rel_insertRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        self.insertRows(at: indexPaths, with: animation)
    }

    public func rel_deleteRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        self.deleteRows(at: indexPaths, with: animation)
    }

    public func rel_reloadRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        self.reloadRows(at: indexPaths, with: animation)
    }

    public func rel_moveRow(at indexPath: IndexPath, to newIndexPath: IndexPath) {
        self.moveRow(at: indexPath, to: newIndexPath)
    }

    public func rel_reloadData() {
        self.reloadData()
    }

    public var rel_allowsSelection: Bool {
        get {
            return self.allowsSelection
        }
        set {
            self.allowsSelection = newValue
        }
    }

    public var rel_allowsMultipleSelection: Bool {
        get {
            return self.allowsMultipleSelection
        }
        set {
            self.allowsMultipleSelection = newValue
        }
    }

    public var rel_indexPathForSelectedRow: IndexPath? {
        return self.indexPathForSelectedRow
    }

    public var rel_indexPathsForSelectedRows: [IndexPath] {
        return self.indexPathsForSelectedRows ?? []
    }

    public func rel_selectRow(at indexPath: IndexPath?, animated: Bool, scrollPosition: UICollectionView.ScrollPosition) {
        self.selectRow(at: indexPath, animated: animated, scrollPosition: scrollPosition.toTableViewScrollPosition())
    }

    public func rel_deselectRow(at indexPath: IndexPath, animated: Bool) {
        self.deselectRow(at: indexPath, animated: animated)
    }

}

extension UICollectionView: RELListViewProtocol {
    public var rel_numberOfSections: Int {
        return self.numberOfSections
    }

    public func rel_numberOfRows(inSection section: Int) -> Int {
        return self.numberOfItems(inSection: section)
    }

    public func rel_rectForRow(at indexPath: IndexPath) -> CGRect {
        return self.layoutAttributesForItem(at: indexPath)?.frame ?? CGRect.zero
    }

    public func rel_indexPathForRow(at point: CGPoint) -> IndexPath? {
        return self.indexPathForItem(at: point)
    }

    public func rel_indexPath(for cell: AnyObject) -> IndexPath? {
        if let c = cell as? UICollectionViewCell {
            return self.indexPath(for: c)
        }
        return nil
    }

    public func rel_cellForRow(at indexPath: IndexPath) -> AnyObject? {
        return self.cellForItem(at: indexPath)
    }

    public var rel_visibleCells: [AnyObject] {
        return self.visibleCells
    }

    public var rel_indexPathsForVisibleRows: [IndexPath] {
        return self.indexPathsForVisibleItems
    }

    public func rel_scrollToRow(at indexPath: IndexPath, at scrollPosition: UICollectionView.ScrollPosition, animated: Bool) {
        self.scrollToItem(at: indexPath, at: scrollPosition, animated: animated)
    }

    public func rel_performBatchUpdates(userInfo: [AnyHashable : Any]?, _ updates: (() -> Void)?, completion: ((Bool) -> Void)?) {
        self.performBatchUpdates(updates, completion: completion)
    }

    public func rel_insertSections(_ sections: IndexSet, with animation: UITableView.RowAnimation) {
        self.insertSections(sections)
    }

    public func rel_deleteSections(_ sections: IndexSet, with animation: UITableView.RowAnimation) {
        self.deleteSections(sections)
    }

    public func rel_reloadSections(_ sections: IndexSet, with animation: UITableView.RowAnimation) {
        self.reloadSections(sections)
    }

    public func rel_moveSection(_ section: Int, toSection newSection: Int) {
        self.moveSection(section, toSection: newSection)
    }

    public func rel_insertRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        self.insertItems(at: indexPaths)
    }

    public func rel_deleteRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        self.deleteItems(at: indexPaths)
    }

    public func rel_reloadRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        self.reloadItems(at: indexPaths)
    }

    public func rel_moveRow(at indexPath: IndexPath, to newIndexPath: IndexPath) {
        self.moveItem(at: indexPath, to: newIndexPath)
    }

    public func rel_reloadData() {
        self.reloadData()
    }

    public var rel_allowsSelection: Bool {
        get {
            return self.allowsSelection
        }
        set {
            self.allowsSelection = newValue
        }
    }

    public var rel_allowsMultipleSelection: Bool {
        get {
            return self.allowsMultipleSelection
        }
        set {
            self.allowsMultipleSelection = newValue
        }
    }

    public var rel_indexPathForSelectedRow: IndexPath? {
        return self.indexPathsForSelectedItems?.first
    }

    public var rel_indexPathsForSelectedRows: [IndexPath] {
        return self.indexPathsForSelectedItems ?? []
    }

    public func rel_selectRow(at indexPath: IndexPath?, animated: Bool, scrollPosition: UICollectionView.ScrollPosition) {
        self.selectItem(at: indexPath, animated: animated, scrollPosition: scrollPosition)
    }

    public func rel_deselectRow(at indexPath: IndexPath, animated: Bool) {
        self.deselectItem(at: indexPath, animated: animated)
    }

}

#if (CanUseASDK || canImport(AsyncDisplayKit))

extension ASTableNode: RELListViewProtocol {

    public var rel_numberOfSections: Int {
        return self.numberOfSections
    }

    public func rel_numberOfRows(inSection section: Int) -> Int {
        return self.numberOfRows(inSection: section)
    }

    public func rel_rectForRow(at indexPath: IndexPath) -> CGRect {
        return self.rectForRow(at: indexPath)
    }

    public func rel_indexPathForRow(at point: CGPoint) -> IndexPath? {
        return self.indexPathForRow(at: point)
    }

    public func rel_indexPath(for cell: AnyObject) -> IndexPath? {
        if let c = cell as? ASCellNode {
            return self.indexPath(for: c)
        }
        return nil
    }

    public func rel_cellForRow(at indexPath: IndexPath) -> AnyObject? {
        return self.cellForRow(at: indexPath)
    }

    public var rel_visibleCells: [AnyObject] {
        return self.visibleNodes
    }

    public var rel_indexPathsForVisibleRows: [IndexPath] {
        return self.indexPathsForVisibleRows()
    }

    public func rel_scrollToRow(at indexPath: IndexPath, at scrollPosition: UICollectionView.ScrollPosition, animated: Bool) {
        return self.scrollToRow(at: indexPath, at: scrollPosition.toTableViewScrollPosition(), animated: animated)
    }

    public func rel_performBatchUpdates(userInfo: [AnyHashable : Any]?, _ updates: (() -> Void)?, completion: ((Bool) -> Void)?) {
        self.performBatch(animated: userInfo?["animated"] as? Bool ?? true, updates: updates, completion: completion)
    }

    public func rel_insertSections(_ sections: IndexSet, with animation: UITableView.RowAnimation) {
        self.insertSections(sections, with: animation)
    }

    public func rel_deleteSections(_ sections: IndexSet, with animation: UITableView.RowAnimation) {
        self.deleteSections(sections, with: animation)
    }

    public func rel_reloadSections(_ sections: IndexSet, with animation: UITableView.RowAnimation) {
        self.reloadSections(sections, with: animation)
    }

    public func rel_moveSection(_ section: Int, toSection newSection: Int) {
        self.moveSection(section, toSection: newSection)
    }

    public func rel_insertRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        self.insertRows(at: indexPaths, with: animation)
    }

    public func rel_deleteRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        self.deleteRows(at: indexPaths, with: animation)
    }

    public func rel_reloadRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        self.reloadRows(at: indexPaths, with: animation)
    }

    public func rel_moveRow(at indexPath: IndexPath, to newIndexPath: IndexPath) {
        self.moveRow(at: indexPath, to: newIndexPath)
    }

    public func rel_reloadData() {
        self.reloadData()
    }

    public var rel_allowsSelection: Bool {
        get {
            return self.allowsSelection
        }
        set {
            self.allowsSelection = newValue
        }
    }

    public var rel_allowsMultipleSelection: Bool {
        get {
            return self.allowsMultipleSelection
        }
        set {
            self.allowsMultipleSelection = newValue
        }
    }

    public var rel_indexPathForSelectedRow: IndexPath? {
        return self.indexPathForSelectedRow
    }

    public var rel_indexPathsForSelectedRows: [IndexPath] {
        return self.indexPathsForSelectedRows ?? []
    }

    public func rel_selectRow(at indexPath: IndexPath?, animated: Bool, scrollPosition: UICollectionView.ScrollPosition) {
        self.selectRow(at: indexPath, animated: animated, scrollPosition: scrollPosition.toTableViewScrollPosition())
    }

    public func rel_deselectRow(at indexPath: IndexPath, animated: Bool) {
        self.deselectRow(at: indexPath, animated: animated)
    }

}

extension ASCollectionNode: RELListViewProtocol {

    public var rel_numberOfSections: Int {
        return self.numberOfSections
    }

    public func rel_numberOfRows(inSection section: Int) -> Int {
        return self.numberOfItems(inSection: section)
    }

    public func rel_rectForRow(at indexPath: IndexPath) -> CGRect {
        guard let cell = self.nodeForItem(at: indexPath) else {return CGRect.zero}
        return cell.frame
    }

    public func rel_indexPathForRow(at point: CGPoint) -> IndexPath? {
        return self.indexPathForItem(at: point)
    }

    public func rel_indexPath(for cell: AnyObject) -> IndexPath? {
        if let c = cell as? ASCellNode {
            return self.indexPath(for: c)
        }
        return nil
    }

    public func rel_cellForRow(at indexPath: IndexPath) -> AnyObject? {
        return self.cellForItem(at: indexPath)
    }

    public var rel_visibleCells: [AnyObject] {
        return self.visibleNodes
    }

    public var rel_indexPathsForVisibleRows: [IndexPath] {
        return self.indexPathsForVisibleItems
    }

    public func rel_scrollToRow(at indexPath: IndexPath, at scrollPosition: UICollectionView.ScrollPosition, animated: Bool) {
        self.scrollToItem(at: indexPath, at: scrollPosition, animated: animated)
    }

    public func rel_performBatchUpdates(userInfo: [AnyHashable : Any]?, _ updates: (() -> Void)?, completion: ((Bool) -> Void)?) {
        self.performBatchUpdates(updates, completion: completion)
    }

    public func rel_insertSections(_ sections: IndexSet, with animation: UITableView.RowAnimation) {
        self.insertSections(sections)
    }

    public func rel_deleteSections(_ sections: IndexSet, with animation: UITableView.RowAnimation) {
        self.deleteSections(sections)
    }

    public func rel_reloadSections(_ sections: IndexSet, with animation: UITableView.RowAnimation) {
        self.reloadSections(sections)
    }

    public func rel_moveSection(_ section: Int, toSection newSection: Int) {
        self.moveSection(section, toSection: newSection)
    }

    public func rel_insertRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        self.insertItems(at: indexPaths)
    }

    public func rel_deleteRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        self.deleteItems(at: indexPaths)
    }

    public func rel_reloadRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        self.reloadItems(at: indexPaths)
    }

    public func rel_moveRow(at indexPath: IndexPath, to newIndexPath: IndexPath) {
        self.moveItem(at: indexPath, to: newIndexPath)
    }

    public func rel_reloadData() {
        self.reloadData()
    }

    public var rel_allowsSelection: Bool {
        get {
            return self.allowsSelection
        }
        set {
            self.allowsSelection = newValue
        }
    }

    public var rel_allowsMultipleSelection: Bool {
        get {
            return self.allowsMultipleSelection
        }
        set {
            self.allowsMultipleSelection = newValue
        }
    }

    public var rel_indexPathForSelectedRow: IndexPath? {
        return self.indexPathsForSelectedItems?.first
    }

    public var rel_indexPathsForSelectedRows: [IndexPath] {
        return self.indexPathsForSelectedItems ?? []
    }

    public func rel_selectRow(at indexPath: IndexPath?, animated: Bool, scrollPosition: UICollectionView.ScrollPosition) {
        self.selectItem(at: indexPath, animated: animated, scrollPosition: scrollPosition)
    }

    public func rel_deselectRow(at indexPath: IndexPath, animated: Bool) {
        self.deselectItem(at: indexPath, animated: animated)
    }
}

#endif

public extension RELListViewProtocol {

    /// 将diff映射到UI上
    /// - Parameter userInfo: 额外的信息
    /// - Parameter difference: diff数据
    /// - Parameter animations: 动画数据
    /// - Parameter batch: 是否进行批量处理, 一般默认是需要进行批量处理的, 如果是在一个批量处理的内部执行操作, 应该将batch设置为false, 防止引发错误
    /// - Parameter completion: 完成之后的回调
    func reload<SectionElement, RowElement>(userInfo:[AnyHashable:Any]?, with difference:RDADifference<SectionElement, RowElement>,animations:RDATableViewAnimations, batch:Bool, completion: ((Bool) -> Void)? ) {

        if let view = self as? UIView, view.window == nil {
            self.rel_reloadData()
            completion?(true)
            return
        }
        #if CanUseASDK || canImport(AsyncDisplayKit)
        if let node = self as? ASDisplayNode {
            if !node.isNodeLoaded || (node.isNodeLoaded && node.supernode == nil && node.view.superview == nil)  {
                self.rel_reloadData()
                completion?(true)
                return
            }
        }
        #endif

        let updatesClosure:()->Void = {

            if !difference.sectionRemoved.isEmpty {
                self.rel_deleteSections(IndexSet(difference.sectionRemoved.map({$0.offset})), with: animations.deleteSection)
            }
            if !difference.sectionInserted.isEmpty {
                self.rel_insertSections(IndexSet(difference.sectionInserted.map({$0.offset})), with: animations.insertSection)
            }
            if !difference.sectionUpdated.isEmpty {
                self.rel_reloadSections(IndexSet(difference.sectionUpdated.map({$0.offset})), with: animations.reloadSection)
            }
            for i in difference.sectionMoved {
                switch i {
                case .sectionMove(fromOffset: let from, toOffset: let to, element: _):
                    self.rel_moveSection(from, toSection: to)
                default:
                    assertionFailure("sectionMoved 中含有非法的枚举类型")
                    break
                }
            }
            if !difference.elementRemoved.isEmpty {
                var indexPathes:[IndexPath] = []
                for i in difference.elementRemoved {
                    switch i {
                    case .elementRemove(offset: let row, section: let section, element: _):
                        indexPathes.append(IndexPath(row: row, section: section))
                    default:
                        break
                    }
                }
                self.rel_deleteRows(at: indexPathes, with: animations.deleteRow)
            }
            if !difference.elementInserted.isEmpty {
                var indexPathes:[IndexPath] = []
                for i in difference.elementInserted {
                    switch i {
                    case .elementInsert(offset: let row, section: let section, element: _):
                        indexPathes.append(IndexPath(row: row, section: section))
                    default:
                        break
                    }
                }
                self.rel_insertRows(at: indexPathes, with: animations.insertRow)
            }
            if !difference.elementUpdated.isEmpty {
                var indexPathes:[IndexPath] = []
                for i in difference.elementUpdated {
                    switch i {
                    case .elementUpdate(offset: let row, section: let section, oldElement: _, newElement: _):
                        indexPathes.append(IndexPath(row: row, section: section))
                    default:
                        break
                    }
                }
                self.rel_reloadRows(at: indexPathes, with: animations.reloadRow)
            }
            for i in difference.elementMoved {
                switch i {
                case .elementMove(fromOffset: let fromRow, fromSection: let fromSection, toOffset: let toRow, toSection: let toSection, element: _):
                    self.rel_moveRow(at: IndexPath(row: fromRow, section: fromSection), to: IndexPath(row: toRow, section: toSection))
                default:break
                }
            }
        }

        if userInfo?["batch"] as? Bool ?? true {
            self.rel_performBatchUpdates(userInfo: nil, updatesClosure, completion: completion)
        }else {
            updatesClosure()
            completion?(true)
        }
    }

}
