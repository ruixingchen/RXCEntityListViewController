//
//  RXCEntityListViewController.swift
//  RXCEntityListViewController
//
//  Created by ruixingchen on 7/18/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import UIKit
#if canImport(AsyncDisplayKit)
import AsyncDisplayKit
#endif
#if canImport(RXCDelegateArray)
import RXCDelegateArray
#endif

#if !canImport(AsyncDisplayKit)
fileprivate protocol ASTableDataSource {}
fileprivate protocol ASTableDelegate {}
#endif

open class RXCEntityListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ASTableDataSource, ASTableDelegate, RXCDelegateArrayDelegate {

    public enum DataReflection {
        ///one entity for one row, just 1 section
        case objectToRow
        ///one entity for one section, every section only has 1 row
        case objectToSection
        ///2D structure, requires dataList element conforms to RELCard
        case cardToSection
    }

    public enum HeaderRefreshMode {
        ///new data will be inserted at the head
        case insert
        ///will reload all content, and set page to 1
        case reload
    }

    //MARK: - Store Property

    open var dataReflection:DataReflection = DataReflection.objectToRow
    open var dataList:RXCDelegateArray<Any> = RXCDelegateArray()
    open var cellSelectorManager:RELTableViewCellSelectorManager = RELTableViewCellSelectorManager()

    ///manage cell automatically by RXCDelegateArray? if set to false, manage tableView by yourself
    open var autoTableViewContentControl:Bool = true
    open var autoTableViewContentControlAnimation:UITableView.RowAnimation = .none

    fileprivate var _tableViewStyle:UITableView.Style = UITableView.Style.plain

    #if canImport(AsyncDisplayKit)
    fileprivate var _useASDK:Bool = false
    #endif

    fileprivate var _tableViewObject:AnyObject!

    //MARK: - Calculated Property

    open var tableView:UITableView! {
        #if canImport(AsyncDisplayKit)
        if let node = self._tableViewObject as? ASTableNode {
            return node.view
        }
        #endif
        return _tableViewObject as? UITableView
    }

    #if canImport(AsyncDisplayKit)
    open var tableNode:ASTableNode! {
        return self._tableViewObject as? ASTableNode
    }
    #endif

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initCellSelectorManager()
        self.initDataList()
        self.initTableView()
    }

    public init(tableViewStyle:UITableView.Style, nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self._tableViewStyle = tableViewStyle
        self.initCellSelectorManager()
        self.initDataList()
        self.initTableView()
    }

    ///register your selector here
    func initCellSelectorManager() {
        #if canImport(AsyncDisplayKit)
        if self._tableViewObject is ASTableNode {
            self.cellSelectorManager.registerDefault(cellBlock: {ASCellNode()})
            return
        }
        #endif
        self.cellSelectorManager.registerDefault(identifier: "default_cell", {_ in UITableViewCell()})
    }

    ///we can add some init data here, or custom our dataList
    ///must call super at the end
    func initDataList() {
        if !self.dataList.delegateContains(self) {
            self.dataList.addDelegate(self)
        }
    }

    ///we can init our custom UITableView or ASTableNode here
    func initTableView() {
        #if canImport(AsyncDisplayKit)
        if self._useASDK {
            let node = ASTableNode(style: self._tableViewStyle)
            //node.dataSource = self
            //node.delegate = self
            self._tableViewObject = node
            return
        }
        #endif
        let tv = UITableView(frame: CGRect.zero, style: self._tableViewStyle)
        //tv.dataSource = self
        //tv.delegate = self
        self._tableViewObject = tv
    }

    open override func loadView() {
        super.loadView()
        #if canImport(AsyncDisplayKit)
        if let node = self._tableViewObject as? ASTableNode {
            self.view.addSubnode(node)
            return
        }
        #endif
        if let tv = self._tableViewObject as? UITableView {
            self.view.addSubview(tv)
        }
    }

    //MARK: - RXCDelegateArrayDelegate

    open func delegateArray<Element>(array: RXCDelegateArray<Element>, didInsertObjectAt range: Range<Int>) {
        guard array === self.dataList else {return}
        guard self.autoTableViewContentControl else {return}
        guard Thread.isMainThread else {
            fatalError("MUST RUN ON MAIN THREAD")
        }
        guard self.dataReflection == .objectToRow else {
            //fatalError("CAN NOT WORK WHEN DATA REFLECTION IS CARDTOSECTION")
            fatalError("CAN ONLY WORK IN OBJECTTOROW MODE")
        }

        print("dataList insert@\(range)")

        objc_sync_enter(self.dataList)
        defer {
            objc_sync_exit(self.dataList)
        }

        let animation = self.autoTableViewContentControlAnimation
        let animated:Bool = animation != .none
        let dataRefrection:DataReflection = self.dataReflection

        #if canImport(AsyncDisplayKit)
        if self._tableViewObject is ASTableNode {
            let __tableNode:ASTableNode = self.tableNode
            __tableNode.performBatch(animated: animated, updates: {
                __tableNode.insertRows(at: range.map({return IndexPath(row: $0, section: 0)}), with: animation)
            }, completion: {(finish) in

            })
            return
        }
        #endif
    }

    open func delegateArray<Element>(array: RXCDelegateArray<Element>, didRemoveObjectAt range: Range<Int>, oldElements: [Element]) {

    }

    open func delegateArray<Element>(array: RXCDelegateArray<Element>, didReplaceObjectAt range: Range<Int>, oldElements: [Element]) {

    }

    //MARK: - UITableViewDataSource

    ///for default we only support 1, if you override with other number, manage tableView by your self
    open func numberOfSections(in tableView: UITableView) -> Int {
        //for default we only support 1, if you override with other number, manage tableView by your self
        return 1
    }

    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataList.count
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let object = self.dataList.safeGet(at: indexPath.row) else {return UITableViewCell()}
        let cell = self.cellSelectorManager.retriveCell(for: tableView, object: object, indexPath: indexPath, includeDefault: true, userInfoForBindData: nil)
        return cell ?? UITableViewCell()
    }

    //MARL: - ASTableSource

    ///for default we only support 1, if you override with other number, manage tableView by your self
    open func numberOfSections(in tableNode: ASTableNode) -> Int {
        //for default we only support 1, if you override with other number, manage tableView by your self
        return 1
    }

    open func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return self.dataList.count
    }

    open func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        guard let object = self.dataList.safeGet(at: indexPath.row) else {
            return {[weak self] () in
                let _ = self
                return ASCellNode()
            }
        }
        return { [weak self] ()->ASCellNode in
            guard let sself = self else {return ASCellNode()}
            let cell = sself.cellSelectorManager.retriveCell(for: tableNode, object: object, indexPath: indexPath, includeDefault: true, userInfoForBindData: nil)
            return cell ?? ASCellNode()
        }
    }

    //MARK: - Request

    ///the url for a page
    open func url(page:Int, userInfo:[AnyHashable:Any]?)->URL {
        fatalError("MUST OVERRIDE THIS TO PROVIDE AN URL")
    }

    ///the request spec for a page
//    open func requestSpec()->AnyObject {
//        return ""
//    }

}
