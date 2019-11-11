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
#if canImport(DifferenceKit)
import DifferenceKit
#endif
#if canImport(MJRefresh)
import MJRefresh
#endif
#if canImport(RXCSwiftComponents)
import RXCSwiftComponents
#endif
#if canImport(RXCFirstTimeViewController)
import RXCFirstTimeViewController
#endif
#if canImport(RXCLoadingStateManager)
import RXCLoadingStateManager
#endif

#if !(CanUseASDK || canImport(AsyncDisplayKit))
private protocol ASTableDataSource {
}

private protocol ASTableDelegate {
}

private protocol ASCollectionDataSource {
}

private protocol ASCollectionDelegate {
}
#endif

public extension RXCEntityListViewController {

    ///页面的结构
    enum ListStructure {
        ///one entity for one row, just 1 section
        case entityForRow
        ///one entity for one section, every section only has 1 row
        case entityForSection
        ///2D structure, the root element must be a card
        case cardForSection
    }

    ///头部刷新的数据合并模式
    enum HeaderRefreshMode {
        ///new data will be inserted at the head
        case insert
        ///will reload all content, set page to 1
        case reload
    }

    enum ListRequestType {
        ///头部刷新请求
        case headerRefresh
        ///底部刷新请求
        case footerRefresh
    }

}

/*
通用界面的思路描述：
 关于数据请求：页面第一次将要显示的时候，进行初始化请求，默认的初始化请求是一个底部刷新行为，接收到请求后，进入数据处理，数据合并，更新UI，请求结束几个流程，下面是对几个流程的工作内容描述：
    数据处理阶段：服务器数据会有一些配置型的数据混在返回数据中，通过processor来处理数据
    数据合并：   将上一步生成的两份数据合并到本地的数据源中
    更新UI：    在处理数据之前，记录下本地数据的状态，之后将新数据和旧数据做对比，根据Diff结果更新UI

 */

open class RXCEntityListViewController: RXCFirstTimeViewController, ASTableDataSource, ASTableDelegate, ASCollectionDataSource, ASCollectionDelegate, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, RXCDiffArrayDelegate {

    public typealias SectionELement = RELSectionCardProtocolWrapper
    public typealias RowElement = RELRowEntityProtocolWrapper
    public typealias DataList = RXCDiffArray<[SectionELement]>
    //下面的别名是为了方便我们整合代码, 当需要修改的时候直接改这里就好, 降低复杂度, 为了通用性考虑, 默认直接采用AnyObject也是极好的
    public typealias ListRequestSpec = RELEntityListRequestSpec
    public typealias ListRequestResponse = RELListRequestResponseSpec<[RowElement]>
    public typealias ListRequestTask = AnyObject

    internal var _listViewObject:RXCListViewProtocol?
    ///本地存储列表视图的指针
    open var listViewObject: RXCListViewProtocol {
        if self._listViewObject == nil {
            self._listViewObject = self.initListView()
            self.registerCellOrNibForListView()
        }
        return self._listViewObject!
    }

    open var tableView: UITableView! {
        if let tv = self.listViewObject as? UITableView {
            return tv
        }
        #if canImport(AsyncDisplayKit)
        if let tn = self.listViewObject as? ASTableNode {
            return tn.view
        }
        #endif
        return nil
    }

    open var collectionView: UICollectionView! {
        if let cv = self.listViewObject as? UICollectionView {
            return cv
        }
        #if canImport(AsyncDisplayKit)
        if let cn = self.listViewObject as? ASCollectionNode {
            return cn.view
        }
        #endif
        return nil
    }

    #if (CanUseASDK || canImport(AsyncDisplayKit))
    open var tableNode: ASTableNode! {
        return self.listViewObject as? ASTableNode
    }

    open var collectionNode: ASCollectionNode! {
        return self.listViewObject as? ASCollectionNode
    }
    #endif

    //MARK: - UI 及其相关

    internal var _cellSelectorManager: RELCellSelectorManager?
    ///cell的选择器, 需要在初始化方法中初始化之后使用
    open var cellSelectorManager: RELCellSelectorManager {
        if self._cellSelectorManager == nil {
            self._cellSelectorManager = self.initCellSelectorManager()
        }
        return self._cellSelectorManager!
    }

    ///请求状态管理器, 用于在进行列表页请求的时候显示合适的loading图标, 加载失败的时候显示合适的文案
    open var loadingStateManager:RXCLoadingStateManager?

    //MARK: - 数据 / Data

    ///专门用来操作数据源的queue, 所有对数据源的操作都必须在这个queue里面
    open lazy var dataListOperationQueue:DispatchQueue = DispatchQueue.init(label: "dataListOperationQueue", qos: .default, attributes: .concurrent)

    internal var _localDataList:DataList?
    open var localDataList: DataList {
        if self._localDataList == nil {
            self._localDataList = self.initDataList()
        }
        return self.localDataList
    }

    ///安全地读取数据源, 所有的读取操作都必须在这里执行
    open func safeReadDataList(closure:@escaping()->Void) {
        self.dataListOperationQueue.sync(execute: closure)
    }

    ///安全地操作本地数据源, 所有的修改操作都必须在这里执行
    open func safeOperatingDataList(closure:@escaping()->Void) {
        let g = DispatchGroup()
        self.dataListOperationQueue.async(group: g, qos: .default, flags: .barrier, execute: closure)
        g.wait()
    }

    internal var _dataProcessors: [RELListRequestDataProcessorProtocol]?
    ///当请求到数据后, 按照顺序让数据处理器对新请求到的数据进行处理或者过滤
    open var dataProcessors: [RELListRequestDataProcessorProtocol] {
        if self._dataProcessors == nil {
            self._dataProcessors = self.initDataProcessors()
        }
        return self._dataProcessors!
    }

    ///当前列表数据的最大页码, 为0表示当前没有进行请求
    open var page: Int = 0

    //MARK: - 标记 / MARK

    ///自动内容控制，当数据源发生变化的时候自动更新ListView
    open var autoContentControl: Bool = true

    ///是否使用CollectionView作为ListView
    open var useCollectionView: Bool
    #if (CanUseASDK || canImport(AsyncDisplayKit))
    ///是否使用ASDK
    open var useASDK: Bool
    #endif

    //MARK: - 请求相关

    ///头部请求的请求对象,只要不为空我们就认为请求正在进行, 请求完毕后应该将本对象置空
    open var headerRequest: ListRequestTask?

    ///底部请求的请求对象,只要不为空我们就认为请求正在进行, 请求完毕后应该将本对象置空
    open var footerRequest: ListRequestTask?

    ///列表是否还有更多内容
    open var hasMoreData: Bool = true

    ///头部刷新组件指针, 用于确定是否安装了头部刷新组件
    open var headerRefreshComponent: AnyObject?

    ///底部刷新组件指针, 用于确定是否安装了底部刷新组件
    ///ASDK模式下，可以通过给这个变量赋值任意指针来实现已经安装了底部刷新控件的假象，当请求的时候， 将Batch对象赋值给本变量，结束刷新的时候，做一个cast后调用completion就可以了
    open var footerRefreshComponent: AnyObject?

    //MARK: - 性能

    #if (CanUseASDK || canImport(AsyncDisplayKit))
    ///添加或者更新Cell的时候可能会引起闪烁, 每次reloadRow之前, 将要reload的Cell的位置加入这个数组, TableNode在返回Cell的时候会将这个Cell的neverShowPlaceholder设置为true, 一段时间后再改回false, 之后将该indexPath从本数组删除, 解决办法来自贝聊科技的文章
    open var neverShowPlaceholderIndexPaths: [IndexPath] = []
    #endif

    //MARK: - 初始化 / INIT

    #if (CanUseASDK || canImport(AsyncDisplayKit))
    public init(style: UITableView.Style, useCollectionView: Bool, useASDK: Bool) {
        self.useASDK = useASDK
        self.useCollectionView = useCollectionView
        super.init(nibName: nil, bundle: nil)
    }
    #else
    public init(style: UITableView.Style, useCollectionView: Bool) {
        self.useCollectionView = useCollectionView
        super.init(nibName: nil, bundle: nil)
    }
    #endif

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    ///初始化数据源
    open func initDataList()->DataList {
        //默认没有数据
        let dataList = DataList()
        dataList.addDelegate(self)
        return dataList
    }

    //子类可以override之后注册需要的选择器
    //务必注意引用循环的问题, 如果selector要引用self, 必须使用weak, 否则一定会循环
    open func initCellSelectorManager()->RELCellSelectorManager {
        fatalError("MUST OVERRIDE THIS FUNCTION TO RETURN A MANAGER")
    }

    ///初始化列表视图, 返回初始化好的ListView, 默认根据参数初始化一个系统自带的View, 不建议使用继承后的各种ListView, 会有各种问题
    open func initListView()->RXCListViewProtocol {
        #if (CanUseASDK || canImport(AsyncDisplayKit))
        if self.useASDK {
            if self.useCollectionView {
                let flow = UICollectionViewFlowLayout()
                flow.scrollDirection = .vertical
                let cn = ASCollectionNode(collectionViewLayout: flow)
                cn.dataSource = self
                cn.delegate = self
                return cn
            } else {
                let tn = ASTableNode()
                tn.dataSource = self
                tn.delegate = self
                return tn
            }
        }
        #endif
        if self.useCollectionView {
            let flow = UICollectionViewFlowLayout()
            flow.scrollDirection = .vertical
            let cv = UICollectionView(frame: UIScreen.main.bounds, collectionViewLayout: flow)
            cv.dataSource = self
            cv.delegate = self
            return cv
        } else {
            let tv = UITableView()
            tv.dataSource = self
            tv.delegate = self
            return tv
        }
    }

    ///默认返回空数组, 有需要的话可以override
    open func initDataProcessors()->[RELListRequestDataProcessorProtocol] {
        return []
    }

    ///如果要使用TableView的注册模式或者CollectionView, 需要在这里执行注册方法, 如果有需要特殊的注册, 重写后自己注册即可
    open func registerCellOrNibForListView() {
        self.cellSelectorManager.listViewRegistering(listView: self.listViewObject)
    }

    //MARK: - 生命周期 / LifeCycle

    open override func viewDidLoad() {
        super.viewDidLoad()
        self.setupListViewOnViewDidLoadBeforeAdded()
        if let _view = self.listViewObject as? UIView {
            self.view.addSubview(_view)
        } else {
            #if (CanUseASDK || canImport(AsyncDisplayKit))
            if let node = self.listViewObject as? ASDisplayNode {
                self.view.addSubnode(node)
            }
            #endif
        }
    }

    ///在添加到View之前最后一次设置ListView的各项属性
    open func setupListViewOnViewDidLoadBeforeAdded() {

    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }

    open override func rxc_viewWillAppear_first(_ animated: Bool) {
        super.rxc_viewWillAppear_first(animated)
        //第一次出现的时候请求数据, 子类自己重写后来决定什么时候发起请求
        //self.startInitRequest()
    }

    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.layoutListView()
    }

    ///调整ListView的位置
    open func layoutListView() {
        self.listViewObject.rsc_frame = self.view.bounds
    }

    //MARK: - 数据的读取和写入

    ///读取本地数据源位于指定位置的数据, 线程不安全
    open func localRowElement(at indexPath:IndexPath)->RowElement {

        let element = self.localDataList[indexPath.section].rda_elements[indexPath.row]
        if let casted = element as? RowElement {
            return casted
        }else {
            fatalError("本地数据源出现了非法类型:\(element)")
        }
    }

    //MARK: - 操作 ListView

    ///安装顶部刷新控件
    open func installHeaderRefreshComponent() {
        //默认安装系统的刷新组件
        guard self.headerRefreshComponent == nil else {
            return
        }
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(headerRefreshAction(sender:)), for: .valueChanged)
        if let obj = self.listViewObject as? UITableView {
            obj.refreshControl = refresh
        } else if let obj = self.listViewObject as? UICollectionView {
            obj.refreshControl = refresh
        } else {
            #if (CanUseASDK || canImport(AsyncDisplayKit))
            if let obj = self.listViewObject as? ASTableNode {
                obj.view.refreshControl = refresh
            } else if let obj = self.listViewObject as? ASCollectionNode {
                obj.view.refreshControl = refresh
            } else {
                assertionFailure("无法找到合适的ListViewObject类型来安装头部刷新组件:\(String(describing: self.listViewObject))")
            }
            #else
            assertionFailure("无法找到合适的ListViewObject类型来安装头部刷新组件:\(String(describing: self.listViewObject))")
            #endif
        }
        self.headerRefreshComponent = refresh
    }

    ///卸载顶部刷新控件
    open func uninstallHeaderRefreshComponent() {
        guard self.headerRefreshComponent != nil else {
            return
        }
        //这里由于ASDK也可以获取到指针, 直接用??一起获取了
        if let obj = self.tableView, obj.refreshControl != nil {
            obj.refreshControl = nil
        } else if let obj = self.collectionView, obj.refreshControl != nil {
            obj.refreshControl = nil
        } else {
            assertionFailure("无法找到合适的类型来卸载头部刷新组件:\(String(describing: self.listViewObject))")
        }
        self.headerRefreshComponent = nil
    }

    ///安装底部刷新控件
    open func installFooterRefreshComponent() {
        #if canImport(AsyncDisplayKit)
        if self.useASDK {
            self.footerRefreshComponent = NSObject()
            return
        }
        #endif
        fatalError("子类需要继承后重写本方法来安装底部刷新控件")
    }

    ///卸载底部刷新控件
    open func uninstallFooterRefreshComponent() {
        #if canImport(AsyncDisplayKit)
        if self.useASDK {
            self.footerRefreshComponent = nil
            return
        }
        #endif
        fatalError("子类需要继承后重写本方法来卸载底部刷新控件")
    }

    /// 停止头部刷新控件
    open func stopHeaderRefreshComponent(userInfo:[AnyHashable:Any]?) {
        if let refresh = self.headerRefreshComponent as? UIRefreshControl {
            refresh.endRefreshing()
            return
        }
        #if canImport(MJRefresh)
        if let refresh = self.headerRefreshComponent as? MJRefreshHeader {
            refresh.endRefreshing()
            return
        }
        #endif
        assertionFailure("没有找到匹配的头部刷新控件类型")
    }

    /// 停止底部刷新控件
    open func stopFooterRefreshComponent(hasMoreData:Bool, userInfo:[AnyHashable:Any]?) {
        #if canImport(AsyncDisplayKit)
        if let batch = self.footerRefreshComponent as? AsyncDisplayKit.ASBatchContext {
            batch.completeBatchFetching(true)
            return
        }
        #endif
        #if canImport(MJRefresh)
        if let refresh = self.footerRefreshComponent as? MJRefreshFooter {
            if hasMoreData {
                refresh.endRefreshing()
            }else {
                refresh.endRefreshingWithNoMoreData()
            }
            return
        }
        #endif
        assertionFailure("没有找到匹配的底部刷新控件类型")
    }

    //MARK: - TableView

    open func numberOfSections(in tableView: UITableView) -> Int {
        return self.localDataList.count
    }

    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.localDataList[section].rda_elements.count
    }

    ///除非需要对Cell做特殊处理, 否则子类无需override本方法
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let element = self.localRowElement(at: indexPath)
        var userInfo:[AnyHashable:Any] = ["indexPath": indexPath]
        userInfo["listView"] = tableView
        userInfo["viewController"] = self

        if let cell = self.cellSelectorManager.retriveCell(for: tableView, object: element, indexPath: indexPath, includeDefault: true, userInfoForBindData: userInfo) {
            return cell
        }else {
            assertionFailure("无法取回Cell")
            return UITableViewCell()
        }
    }

    //MARK: - CollectionView

    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.localDataList.count
    }

    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.localDataList[section].rda_elements.count
    }

    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let element = self.localRowElement(at: indexPath)
        var userInfo:[AnyHashable:Any] = ["indexPath": indexPath]
        userInfo["listView"] = collectionView
        userInfo["viewController"] = self

        if let cell = self.cellSelectorManager.retriveCell(for: collectionView, object: element, indexPath: indexPath, includeDefault: true, userInfoForBindData: userInfo) {
            return cell
        }else {
            fatalError("无法取回Cell")
        }
    }

    //MARK: - ASTableNode

    #if (CanUseASDK || canImport(AsyncDisplayKit))

    ///ASTableNode和ASCollectionNode的返回Cell的函数是类似的, 整合到这个方法中一起执行
    open func listNode(_ node:ASDisplayNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        let element = self.localRowElement(at: indexPath)
        var userInfo:[AnyHashable:Any] = ["indexPath": indexPath]
        userInfo["listView"] = node
        userInfo["viewController"] = self

        return { [weak self] () in
            var cell:ASCellNode?
            if let tn = node as? ASTableNode {
                cell = self?.cellSelectorManager.retriveCell(for: tn, object: element, indexPath: indexPath, includeDefault: true, userInfoForBindData: userInfo)
            }else {
                cell = self?.cellSelectorManager.retriveCell(for: node as! ASCollectionNode, object: element, indexPath: indexPath, includeDefault: true, userInfoForBindData: userInfo)
            }
            guard let validCell = cell else {
                assertionFailure("无法取回Cell @ \(indexPath)")
                return ASCellNode()
            }
            ///解决闪烁问题
            self?.updateCellNodeNeverShowPlaceholdersIfNeededToAvoidFlash(cell: validCell, indexPath: indexPath)
            return validCell
        }
    }

    open func numberOfSections(in tableNode: ASTableNode) -> Int {
        return self.localDataList.count
    }

    open func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return self.localDataList[section].rda_elements.count
    }

    open func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return self.listNode(tableNode, nodeBlockForRowAt: indexPath)
    }

    //MARK: - ASCollectionNode

    open func numberOfSections(in collectionNode: ASCollectionNode) -> Int {
        return self.localDataList.count
    }

    open func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        return self.localDataList[section].rda_elements.count
    }

    open func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
        return self.listNode(collectionNode, nodeBlockForRowAt: indexPath)
    }

    ///当本地存储有这个Cell的indexPath, 要求这个位置的Cell进入同步状态, 避免发生闪烁的时候, 更新这个Cell的neverShowPlaceholders属性, 并在一段时间后重新设置回原来的属性
    open func updateCellNodeNeverShowPlaceholdersIfNeededToAvoidFlash(cell: ASCellNode, indexPath:IndexPath) {
        if self.neverShowPlaceholderIndexPaths.contains(indexPath) {
            self.neverShowPlaceholderIndexPaths.removeAll(where: {$0==indexPath})
            let saved = cell.neverShowPlaceholders
            if !saved {
                //已经处于同步状态就没必要了
                cell.neverShowPlaceholders = true
                //这里2秒足够了
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                    cell.neverShowPlaceholders = saved
                }
            }
        }
    }

    public func shouldBatchFetch(for tableNode: ASTableNode) -> Bool {
        return self.canTakeFooterRefreshRequest()
    }

    public func shouldBatchFetch(for collectionNode: ASCollectionNode) -> Bool {
        return self.canTakeFooterRefreshRequest()
    }

    public func tableNode(_ tableNode: ASTableNode, willBeginBatchFetchWith context: ASBatchContext) {
        //开始底部请求

    }

    public func collectionNode(_ collectionNode: ASCollectionNode, willBeginBatchFetchWith context: ASBatchContext) {

    }

    #endif

    ////MARK: - ListView 操作

    //MARK: - RXCDiffArrayDelegate

    open func diffArray<ElementContainer>(diffArray: RXCDiffArray<ElementContainer>, didModifiedWith differences: [RDADifference<ElementContainer>]) where ElementContainer : RangeReplaceableCollection {

        if let __tableView = self.listViewObject as? UITableView {
            for i in differences {
                __tableView.reload(with: i, animations: .none(), reloadDataSource: { (newData) in
                    self.safeOperatingDataList {
                        self.localDataList.removeAll(userInfo: [DataList.Key.notify as AnyHashable: false], where: {_ in true})
                        self.localDataList.add(contentsOf: newData as! [SectionELement], userInfo: [DataList.Key.notify: false])
                    }
                }) { (finish) in

                }
            }
        }else if let __collectionView = self.listViewObject as? UICollectionView {
            for i in differences {
                __collectionView.reload(with: i, animations: .none(), reloadDataSource: { (newData) in
                    self.safeOperatingDataList {
                        self.localDataList.removeAll(userInfo: [DataList.Key.notify as AnyHashable: false], where: {_ in true})
                        self.localDataList.add(contentsOf: newData as! [SectionELement], userInfo: [DataList.Key.notify: false])
                    }
                }) { (finish) in

                }
            }
        }else {
            #if (CanUseASDK || canImport(AsyncDisplayKit))
            if self.listViewObject is ASDisplayNode {
                for i in differences {
                    for j in i.changes {
                        switch j {
                        case .elementInsert(offset: let row, section: let section):
                            self.neverShowPlaceholderIndexPaths.append(IndexPath(row: row, section: section))
                        case .elementUpdate(offset: let row, section: let section):
                            self.neverShowPlaceholderIndexPaths.append(IndexPath(row: row, section: section))
                        default: break
                        }
                    }
                }
            }

            if let __tableNode = self.listViewObject as? ASTableNode {
                for i in differences {
                    __tableNode.reload(with: i, animations: .none(), reloadDataSource: { (newData) in
                        self.safeOperatingDataList {
                            self.localDataList.removeAll(userInfo: [DataList.Key.notify as AnyHashable: false], where: {_ in true})
                            self.localDataList.add(contentsOf: newData as! [SectionELement], userInfo: [DataList.Key.notify: false])
                        }
                    }) { (finish) in

                    }
                }
            }else if let __collectionNode = self.listViewObject as? ASCollectionNode {
                for i in differences {
                    __collectionNode.reload(with: i, animations: .none(), reloadDataSource: { (newData) in
                        self.safeOperatingDataList {
                            self.localDataList.removeAll(userInfo: [DataList.Key.notify as AnyHashable: false], where: {_ in true})
                            self.localDataList.add(contentsOf: newData as! [SectionELement], userInfo: [DataList.Key.notify: false])
                        }
                    }) { (finish) in

                    }
                }
            }
            #endif
        }
    }

    //MARK: - 请求状态

    open func isHeaderRequesting() -> Bool {
        return self.headerRequest != nil
    }

    open func isFooterRequesting() -> Bool {
        return self.footerRequest != nil
    }

    open func cancelHeaderRefreshRequest() {
        if let req = self.headerRequest as? URLSessionTask {
            req.cancel()
            return
        }
        fatalError("子类需要重写来实现功能")
    }

    open func cancelFooterRefreshRequest() {
        if let req = self.footerRequest as? URLSessionTask {
            req.cancel()
            return
        }
        fatalError("子类需要重写来实现功能")
    }

    ///此时是否可以发起头部刷新请求
    open func canTakeHeaderRefreshRequest() -> Bool {
        //一般情况下, 头部刷新优先级高于底部刷新, 头部刷新进行的时候, 直接取消底部刷新
        return true
    }

    ///此时是否可以发起底部刷新请求
    open func canTakeFooterRefreshRequest() -> Bool {
        if self.isHeaderRequesting() {
            return false
        }
        if !self.hasMoreData {
            return false
        }
        return true
    }

    ///结束一个头部刷新, 典型操作是结束刷新控件的刷新
    open func endHeaderRefresh(userInfo:[AnyHashable:Any]?) {
        self.stopHeaderRefreshComponent(userInfo: userInfo)
        self.headerRequest = nil
    }

    ///结束一个底部刷新, 典型操作是结束刷新控件的刷新
    open func endFooterRefresh(hasMoreData:Bool, userInfo:[AnyHashable:Any]?) {
        self.stopFooterRefreshComponent(hasMoreData: hasMoreData, userInfo: userInfo)
        self.hasMoreData = hasMoreData
        self.footerRequest = nil
    }

    //MARK: - 请求逻辑

    ///这个函数可以接收头部刷新控件传来的要求进行刷新的事件
    @objc open func headerRefreshAction(sender: Any?) {
        //当执行头部刷新的时候, 先取消底部刷新, 防止干扰
        guard self.canTakeHeaderRefreshRequest() else {
            return
        }
        self.cancelFooterRefreshRequest()
    }



    ///开始前置请求, 有些界面需要有前置请求, 根据前置请求的结果来决定列表页的接口
    ///默认没有前置请求, 直接调用底部刷新接口
    open func startInitRequest() {
        //请求完毕后安装底部刷新控件, 之后就能正常启用列表请求的逻辑
        //默认没有前置请求，直接判断为前置请求完成
        //如果需要前置请求, 可以重写后进行请求, 请求完毕之后, 设置头尾的刷新控件即可
        //example:
        /*
        self.loadingStateManager?.startLoading()
        let request = URLRequest(url: URL(string: "https://www.baidu.com")!)
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error != nil {
                self.loadingStateManager?.finishLoading(success: false)
            }else {
                //合并数据
                self.safeOperatingDataList {
                    var diff:[DataList.Difference]!
                    self.safeOperatingDataList {
                        diff = self.localDataList.batchWithDifferenceKit_2D {
                            //在这里插入数据
                        }
                    }
                    self.diffArray(diffArray: self.localDataList, didModifiedWith: diff)
                }
                self.loadingStateManager?.finishLoading(success: true)
                self.installHeaderRefreshComponent()
                self.installFooterRefreshComponent()
            }
        }
        task.resume()
         */
        //下面是默认的请求
        let spec = self.listRequestSpec(requestType: .footerRefresh, page: self.page+1, userInfo: nil)
        self.startListRequest(requestSpec: spec, userInfo: nil)
    }

    ///返回列表页请求的URL
    open func listRequestUrl(requestType: ListRequestType, page: Int, userInfo: [AnyHashable: Any]?) -> URL {
        fatalError("本方法应由子类提供实现")
    }

    ///返回列表页请求的描述对象
    open func listRequestSpec(requestType: ListRequestType, page: Int, userInfo: [AnyHashable: Any]?) -> ListRequestSpec {
        fatalError("本方法应由子类提供实现")
        //let url = self.listRequestUrl(requestType: requestType, page: page, userInfo:userInfo)
        //let spec = RELEntityListRequestSpec.init(url: url, requestType: requestType)
        //return spec
    }

    ///根据服务器的返回结果判断列表后面是否还有数据
    open func hasMoreDataAfter(requestSpec: ListRequestSpec, response: ListRequestResponse, userInfo: [AnyHashable: Any]?) -> Bool {
        //由于很多时候判断后面是否还有数据的方法不尽相同, 这里采用一个函数来处理
        fatalError("本方法应由子类提供实现")
        //下面是example
        /*
        if requestSpec.requestType == .headerRefresh {
            return true
        }
        if response.isSuccess {
            return (response.result.value?.count ?? 0) > 0
        }else {
            ///请求没有成功的情况下, 默认后面还有数据, 方便进行下一次请求
            return true
        }
         */
    }

    ///数据合并的时候, 新的数据应该合并到哪个section中? 默认是0
    ///有时候我们需要在第0节显示占位信息, 这里就可以强制让新数据插入到其他节中了
    open func listRequestDataMergeSection(requestSpec: ListRequestSpec, response: ListRequestResponse)->Int {
        return 0
    }

    //开始请求
    open func startListRequest(requestSpec: ListRequestSpec, userInfo: [AnyHashable: Any]?) {
        //默认请求到的数据是一个数组, 至于数组内部的对象则根据请求接口不一样而不一样
        fatalError("子类必须重写来实现请求")
        //下面是example
//        let request = APIServiceV2.shared.basicRequest(requestSpec: requestSpec) {[weak self] (result:ListRequestResponse) in
//            self?.onListRequestResponse(requestSpec: requestSpec, response: result, userInfo: nil)
//        }
//        switch requestSpec.requestType {
//        case .headerRefresh:
//            self.headerRequest = request
//        case .footerRefresh:
//            self.footerRequest = request
//        }
    }

    ///请求接收到回应
    open func onListRequestResponse(requestSpec: ListRequestSpec, response: ListRequestResponse, userInfo: [AnyHashable: Any]?) {
        ///接收到服务器的回应后，根据回应进入不同的处理分支
        if !response.isSuccess {
            //请求失败分支
            self.onListRequestResponseError(requestSpec: requestSpec, response: response, userInfo: userInfo)
        }else {
            //请求成功
            self.onListRequestSuccess(requestSpec: requestSpec, response: response, userInfo: userInfo)
        }
    }

    ///请求没有正确完成，任何错误都会进入本流程
    open func onListRequestResponseError(requestSpec: ListRequestSpec, response: ListRequestResponse, userInfo: [AnyHashable: Any]?) {
        fatalError("本方法应由子类提供实现")
        //下面是example
        /*
        if response.error?.isURLErrorCancelled ?? false {
            //请求被取消的时候不做任何处理
            return
        }
        //请求错误后, 做出一些提示, 如弹出toast
        self.loadingStateManager?.finishLoading(success: false)
        self.hasMoreData = self.hasMoreDataAfter(requestSpec: requestSpec, response: response, userInfo: userInfo)
        switch requestSpec.requestType {
        case .headerRefresh:
            self.endHeaderRefresh(userInfo: userInfo)
        case .footerRefresh:
            self.endFooterRefresh(hasMoreData: self.hasMoreData, userInfo: userInfo)
        }
         */
    }

    ///列表请求成功, 执行
    open func onListRequestSuccess(requestSpec: ListRequestSpec, response: ListRequestResponse, userInfo: [AnyHashable: Any]?) {
        //这里可以采用两种方案，一种是利用DiffArray的batch方法，将修改包括在一个closure中，之后DiffArray可以自动计算并且返回差异
        //另一种是手动记录当前的状态，之后直接调用后续阶段的方法，等数据处理合并阶段完成后，再计算差异
        //目前选择第二种方法, 逻辑要清楚一些
        objc_sync_enter(self.localDataList)
        let oldData = self.localDataList.toArray()

        let animated = userInfo?["animated"] as? Bool ?? true
        let enabledSave = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(animated)

        //注意, 数据处理内部如果要操作本地列表数据, 一定要禁用DataList的通知，只操作数据不操作ListView的UI部分

        //处理数据
        let processedNewData = self.listRequestDataProcessing(requestSpec: requestSpec, response: response, userInfo: userInfo)
        //合并数据
        self.listRequestDataMerge(requestSpec: requestSpec, response: response, processedNewData: processedNewData, userInfo: userInfo)
        let newData = self.localDataList.toArray()
        let diffs = DataList.Difference.differences_2D(between: oldData, and: newData)
        //更新UI
        self.onListRequestUpdateListView(differences: diffs, requestSpec: requestSpec, response: response, userInfo: userInfo, completion: nil)

        UIView.setAnimationsEnabled(enabledSave)
        objc_sync_exit(self.localDataList)

        //请求结束
        self.onListRequestEnd(requestSpec: requestSpec, response: response, userInfo: userInfo)
    }

    /// 数据处理第一阶段阶段, 这个阶段将对服务器传来的数据进行过滤和处理, 同时也可能会对现有列表进行修改, 比如删除重复项
    /// - Parameter response: 服务器传过来的请求
    open func listRequestDataProcessing(requestSpec: ListRequestSpec, response: ListRequestResponse, userInfo: [AnyHashable: Any]?)->[RowElement] {
        var newDataList:[RowElement] = response.result.value!
        for i in self.dataProcessors {
            let processed = i.process(newObjects: newDataList, userInfo: userInfo) as? [RowElement]
            assert(processed != nil, "数据处理器返回了不正确的类型")
            newDataList = processed ?? newDataList
        }
        return newDataList
    }

    /// 数据合并阶段, 这个阶段将服务器传来的数据合并到现有的列表中, 这个阶段不应该对上一步传过来的数据做修改
    open func listRequestDataMerge(requestSpec: ListRequestSpec,response: ListRequestResponse, processedNewData:[RowElement], userInfo: [AnyHashable: Any]?) {
        let section = self.listRequestDataMergeSection(requestSpec: requestSpec, response: response)
        var userInfo = userInfo ?? [:]
        userInfo[DataList.Key.notify] = false

        switch requestSpec.requestType {
        case .headerRefresh:
            self.localDataList.insertRow(contentsOf: processedNewData, at: 0, in: section, userInfo: userInfo)
        case .footerRefresh:
            self.localDataList.addRow(contentsOf: processedNewData, in: section, userInfo: userInfo)
        }

    }

    ///更新UI阶段
    open func onListRequestUpdateListView(differences:[DataList.Difference], requestSpec: ListRequestSpec, response: ListRequestResponse, userInfo: [AnyHashable: Any]?, completion:((Bool)->Void)?) {
        ///根据旧数据和新数据的对比, 计算出差异后应用到ListView上
        self.diffArray(diffArray: self.localDataList, didModifiedWith: differences)
    }

    open func onListRequestEnd(requestSpec: ListRequestSpec, response: ListRequestResponse, userInfo: [AnyHashable: Any]?) {
        switch requestSpec.requestType {
        case .headerRefresh:
            self.endHeaderRefresh(userInfo: userInfo)
            self.installHeaderRefreshComponent()
        case .footerRefresh:
            let hasmoreData = self.hasMoreDataAfter(requestSpec: requestSpec, response: response, userInfo: userInfo)
            self.endFooterRefresh(hasMoreData: hasmoreData, userInfo: userInfo)
            self.installFooterRefreshComponent()
        }
    }

}
