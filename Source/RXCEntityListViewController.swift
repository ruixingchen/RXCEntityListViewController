//
//  RXCEntityListViewController.swift
//  CoolMarket
//
//  Created by ruixingchen on 9/5/19.
//  Copyright © 2019 CoolApk. All rights reserved.
//

import UIKit
#if canImport(AsyncDisplayKit)
import AsyncDisplayKit
#endif
#if canImport(RXCDiffArray)
import RXCDiffArray
#endif
#if canImport(MJRefresh)
import MJRefresh
#endif
#if canImport(Alamofire)
import Alamofire
#endif

#if !(CanUseASDK || canImport(AsyncDisplayKit))
private protocol ASTableDataSource {}
private protocol ASTableDelegate {}
private protocol ASCollectionDataSource {}
private protocol ASCollectionDelegate {}
#endif

public extension RXCEntityListViewController {

    enum ListStructure {
        ///one entity for one row, just 1 section
        case entityForRow
        ///one entity for one section, every section only has 1 row
        case entityForSection
        ///2D structure
        case cardForSection
    }

    enum HeaderRefreshMode {
        ///new data will be inserted at the head
        case insert
        ///will reload all content, set page to 1
        case reload
    }
}

open class RXCEntityListViewController: UIViewController, ASTableDataSource,ASTableDelegate,ASCollectionDataSource,ASCollectionDelegate, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, RXCDiffArrayDelegate {

    public typealias DataList = RXCDiffArray<[RELCard], RELEntity>

    open var listViewObject:RELListViewProtocol!
    #if (CanUseASDK || canImport(AsyncDisplayKit))
    open var tableNode:ASTableNode! {return self.listViewObject as? ASTableNode}
    #endif
    open var tableView:UITableView! {
        if let tv = self.listViewObject as? UITableView {return tv}
        #if canImport(AsyncDisplayKit)
        if let tn = self.listViewObject as? ASTableNode {return tn.view}
        #endif
        return nil
    }
    #if (CanUseASDK || canImport(AsyncDisplayKit))
    open var collectionNode:ASCollectionNode! {return self.listViewObject as? ASCollectionNode}
    #endif
    open var collectionView:UICollectionView! {
        if let cv = self.listViewObject as? UICollectionView {return cv}
        #if canImport(AsyncDisplayKit)
        if let cn = self.listViewObject as? ASCollectionNode {return cn.view}
        #endif
        return nil
    }

    //MARK: - UI

    #if (CanUseASDK || canImport(AsyncDisplayKit))
    open var useASDK:Bool
    #endif
    open var useCollectionView:Bool

    //MARK: - 数据 / Data

    open var dataList:DataList!
    open var dataProcessors:[AnyObject] = []

    //MARK: - 标记 / MARK

    ///自动内容控制，当数据源发生变化的时候自动更新ListView
    open var autoContentControl:Bool = true

    //MARK: - 请求相关

    open var lastHeaderRequest:

    //MARK: - 初始化 / INIT

    #if (CanUseASDK || canImport(AsyncDisplayKit))
    public init(style:UITableView.Style, useCollectionView:Bool, useASDK:Bool) {
        self.useASDK = useASDK
        self.useCollectionView = useCollectionView
        super.init(nibName: nil, bundle: nil)
        self.initListView()
        self.initDataList()
    }
    #else
    public init(style:UITableView.Style, useCollectionView:Bool) {
        self.useCollectionView = useCollectionView
        super.init(nibName: nil, bundle: nil)
        self.initListView()
        self.initDataList()
    }
    #endif

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func initDataList() {
        //默认没有数据
        self.dataList = DataList()
        self.dataList.delegate = self
    }

    open func initListView() {
        #if (CanUseASDK || canImport(AsyncDisplayKit))
        if self.useASDK {
            if self.useCollectionView {
                let flow = UICollectionViewFlowLayout()
                flow.scrollDirection = .vertical
                let cn = ASCollectionNode(collectionViewLayout: flow)
                cn.dataSource = self
                cn.delegate = self
                self.listViewObject = cn
            }else {
                let tn = ASTableNode()
                tn.dataSource = self
                tn.delegate = self
                self.listViewObject = tn
            }
            return
        }
        #endif
        if self.useCollectionView {
            let flow = UICollectionViewFlowLayout()
            flow.scrollDirection = .vertical
            let cv = UICollectionView(frame: UIScreen.main.bounds, collectionViewLayout: flow)
            cv.dataSource = self
            cv.delegate = self
            self.listViewObject = cv
        }else {
            let tv = UITableView()
            tv.dataSource = self
            tv.delegate = self
            self.listViewObject = tv
        }
    }

    //MARK: - 生命周期 / LifeCycle

    open override func viewDidLoad() {
        super.viewDidLoad()
        self.setupListViewOnViewDidLoad()
        #if (CanUseASDK || canImport(AsyncDisplayKit))
        if let node = self.listViewObject as? ASDisplayNode {
            self.view.addSubnode(node)
        }
        #endif
        if let _view = self.listViewObject as? UIView {
            self.view.addSubview(_view)
        }

    }

    open func setupListViewOnViewDidLoad() {

    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //第一次出现的时候请求数据
    }

    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if let likeView = self.listViewObject as? RXCViewLikeObjectProtocol {
            likeView.frame = self.view.bounds
        }
    }

    //MARK: - 操作 ListView

    ///安装顶部刷新控件
    open func installHeaderRefreshComponent() {

    }

    ///卸载顶部刷新控件
    open func uninstallHeaderRefreshComponent() {

    }

    ///安装底部刷新控件
    open func installFooterRefreshComponent() {

    }

    ///卸载底部刷新控件
    open func uninstallFooterRefreshComponent() {

    }

    open func stopHeaderRefreshComponent() {

    }

    open func stopFooterRefreshComponent() {

    }

    //MARK: - TableView

    public func numberOfSections(in tableView: UITableView) -> Int {
        return self.dataList.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataList[section].rda_elements.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }

    //MARK: - CollectionView

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.dataList.count
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataList[section].rda_elements.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return UICollectionViewCell()
    }

    //MARK: - ASTableNode

    public func numberOfSections(in tableNode: ASTableNode) -> Int {
        return self.dataList.count
    }

    public func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return self.dataList[section].rda_elements.count
    }

    public func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return {
            return ASCellNode()
        }
    }

    //MARK: - ASCollectionNode

    public func numberOfSections(in collectionNode: ASCollectionNode) -> Int {
        return self.dataList.count
    }

    public func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        return self.dataList[section].rda_elements.count
    }

    public func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
        return {
            return ASCellNode()
        }
    }

    //MARK: - RXCDiffArrayDelegate

    public func diffArray<SectionContainer, RowElement>(array: RXCDiffArray<SectionContainer, RowElement>, didChange difference: RDADifference<SectionContainer.Element, RowElement>) where SectionContainer : RangeReplaceableCollection {

        if let object = self.listViewObject as? UITableView {
            object.reload(with: difference, animations: RDATableViewAnimations.automatic(), completion: nil)
        }else if let object = self.listViewObject as? UICollectionView {
            object.reload(with: difference, completion: nil)
        }
        #if (CanUseASDK || canImport(AsyncDisplayKit))
        if let object = self.listViewObject as? ASTableNode {
            object.reload(with: difference, animations: RDATableViewAnimations.automatic(), completion: nil)
        }else if let object = self.listViewObject as? ASCollectionNode {
            object.reload(with: difference, completion: nil)
        }
        #endif

    }

    //MARK: - 请求相关



}

