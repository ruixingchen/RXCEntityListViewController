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
#if canImport(Alamofire)
import Alamofire
#endif
#if canImport(MJRefresh)
import MJRefresh
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
 关于数据源：采用双数据源，一个保存服务器传来的原始数据留作存档， 一个是本地化后的数据源，本地数据源可以添加一些特殊的占位数据而不影响服务器数据的整体顺序，但是要求更新数据源的时候要针对两个数据源都进行更新

 关于数据请求：页面第一次将要显示的时候，进行初始化请求，默认的初始化请求是一个底部刷新行为，接收到请求后，进入数据处理，数据合并，更新UI，请求结束几个流程，下面是对几个流程的工作内容描述：
    数据处理阶段 1：服务器数据会有一些配置型的数据混在返回数据中，遍历返回的数据，处理配置型数据后删除这些配置型数据
    数据处理阶段 2: 根据页面的不同，通过上阶段1的数据计算出一份本地数据，例如添加一些分割线，添加一些占位图等等
    数据合并：      将上一步生成的两份数据合并到本地的数据源中
    更新UI：       在处理数据之前，记录下本地数据的状态，之后将新数据和旧数据做对比，根据Diff结果更新UI

 */

open class RXCEntityListViewController: RELFirstTimeViewController, ASTableDataSource, ASTableDelegate, ASCollectionDataSource, ASCollectionDelegate, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, RXCDiffArrayDelegate {

    public typealias SectionELement = Card
    public typealias RowElement = Entity
    public typealias DataList = RXCDiffArray<ContiguousArray<SectionELement>, RowElement>
    //下面的别名是为了方便我们整合代码, 当需要修改的时候直接改这里就好, 降低复杂度, 为了通用性考虑, 默认直接采用AnyObject也是极好的
    public typealias ListRequestSpec = EntityListRequestSpecV2
    public typealias ListRequestTask = AnyObject
    public typealias ListRequestResponse = ApiRequestResultV2<[Entity]>

    ///本地存储列表视图的指针
    open var listViewObject: RELListViewProtocol!

    #if (CanUseASDK || canImport(AsyncDisplayKit))

    open var tableNode: ASTableNode! {
        return self.listViewObject as? ASTableNode
    }

    open var collectionNode: ASCollectionNode! {
        return self.listViewObject as? ASCollectionNode
    }
    #endif

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

    //MARK: - UI 及其相关

    ///cell的选择器, 需要在初始化方法中初始化之后使用
    open var cellSelectorManager: RELCellSelectorManager!

    ///请求状态管理器, 用于在进行列表页请求的时候显示合适的loading图标, 加载失败的时候显示合适的文案
    open var requestStateManager:AnyObject?

    //MARK: - 数据 / Data

    /**
     试验性的采用双数据源, 一份本地优化过的数据源, 一份来自服务器的数据源
     有时候服务器传来的数据是经过多层嵌套的, 比如一个Card里面含有很多个Feed, b如果将这些Feed都放在一个Cell中显示, 显然不合适
     我们可以将服务器传来的Card数据进行拆分, 将Card拆分成许多兄弟Entity, 再添加描述分割线高度的占位Entity, 组成一个一维列表
     逻辑如下:
     原始数据:  Card(Entity, Entity, Entity...)
     转换成:   Entity,分割线, Entity, 分割线 Entity...
     这样我们就可以自由的控制分割线的高度和任何样式
     当请求的时候, 我们直接从原始数据源中读取数据就可以了
     缺点就是请求的时候需要对两个数据源都要进行更新
     */
    open var localDataList: DataList!

    ///从服务器获取的数据源, 具体逻辑参考localDataList的注释
    open var originDataList:[[RowElement]] = []

    ///当请求到数据后, 按照顺序让数据处理器对新请求到的数据进行处理或者过滤
    open var dataProcessors: [RELListRequestDataProcessorProtocol] = []

    ///当前列表数据的最大页码, 为0表示当前没有进行请求
    open var page: Int = 0

    //MARK: - 标记 / MARK

    ///自动内容控制，当数据源发生变化的时候自动更新ListView
    open var autoContentControl: Bool = true

    #if (CanUseASDK || canImport(AsyncDisplayKit))
    open var useASDK: Bool
    #endif
    open var useCollectionView: Bool

    //MARK: - 请求相关

    ///头部请求的请求对象,只要不为空我们就认为请求正在进行, 请求完毕后应该将本对象置空
    open var headerRequest: ListRequestTask?

    ///底部请求的请求对象,只要不为空我们就认为请求正在进行, 请求完毕后应该将本对象置空
    open var footerRequest: ListRequestTask?

    ///列表是否还有更多内容
    open var hasMoreData: Bool = true

    ///初始化请求是否已经完成，如果没有完成表示没有数据
    ///暂不使用
    //open var initRequestCalled:Bool = false

    ///头部刷新组件指针, 用于确定是否安装了头部刷新组件
    open var headerRefreshComponent: AnyObject?

    ///底部刷新组件指针, 用于确定是否安装了底部刷新组件
    ///ASDK模式下，可以通过给这个变量赋值任意指针来实现已经安装了底部刷新控件的假象，当请求的时候， 将Batch对象赋值给本变量，结束刷新的时候，做一个cast后调用completion就可以了
    open var footerRefreshComponent: AnyObject?

    //MARK: - 性能

    #if (CanUseASDK || canImport(AsyncDisplayKit))
    ///添加或者更新Cell的时候可能会引起闪烁, 每次更新之前, 将要更新的Cell的位置加入这个数组, TableNode在返回Cell的时候会将这个Cell的neverShowPlaceholder设置为true, 一段时间后再改回falsse, 之后将该indexPath从本数组删除, 解决办法来自贝聊科技的文章
    open var neverShowPlaceholderIndexPaths: [IndexPath] = []
    #endif

    //MARK: - 初始化 / INIT

    #if (CanUseASDK || canImport(AsyncDisplayKit))
    public init(style: UITableView.Style, useCollectionView: Bool, useASDK: Bool) {
        self.useASDK = useASDK
        self.useCollectionView = useCollectionView
        super.init(nibName: nil, bundle: nil)
        //这里的初始化顺序不要改
        self.initCellSelectorManager()
        self.initListView()
        self.initDataList()
        self.initDataProcessors()
    }
    #else
    public init(style: UITableView.Style, useCollectionView: Bool) {
        self.useCollectionView = useCollectionView
        super.init(nibName: nil, bundle: nil)
        self.initCellSelectorManager()
        self.initListView()
        self.initDataList()
        self.initDataProcessors()
    }
    #endif

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func initCellSelectorManager() {
        self.cellSelectorManager = RELCellSelectorManager()
        //子类可以override之后注册需要的选择器
    }

    ///初始化数据源
    open func initDataList() {
        //默认没有数据
        //初始化的时候有数据, 则必须先调用一次reloadData(), 否则可能导致UI和数据源不同步
        //如果是UICollectionView, 需要执行注册函数
        self.localDataList = DataList()
        self.localDataList.delegate = self
        self.listViewObject.rel_reloadData()
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
            } else {
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
            //如果是UICollectionView, 我们需要注册Cell
            self.registerCellForUICollectionView()
        } else {
            let tv = UITableView()
            tv.dataSource = self
            tv.delegate = self
            self.listViewObject = tv
        }
    }

    ///如果是UICollectionView, 需要在显示之前执行注册Cell的操作, 默认是让CellSelectorManager自己去处理
    open func registerCellForUICollectionView() {
        if let view = self.collectionView {
            self.cellSelectorManager.collectionViewRegister(collectionView: view)
        }
    }

    open func initDataProcessors() {

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

    open override func viewWillAppear_first(_ animated: Bool) {
        super.viewWillAppear_first(animated)
        //第一次出现的时候请求数据
        self.initRequest()
    }

    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.layoutListView()
    }

    ///调整ListView的位置
    open func layoutListView() {
        self.listViewObject.frame = self.view.bounds
    }

    //MARK: - 数据的读取和写入

    ///读取本地数据源位于指定位置的数据, 线程不安全
    open func localRowElement(at indexPath:IndexPath)->RowElement? {
        return self.localDataList.element(at: indexPath)
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
        if let obj = self.listViewObject as? UITableView ?? self.tableView, obj.refreshControl != nil {
            obj.refreshControl = nil
        } else if let obj = self.listViewObject as? UICollectionView ?? self.collectionView, obj.refreshControl != nil {
            obj.refreshControl = nil
        } else {
            assertionFailure("无法找到合适的类型来卸载头部刷新组件:\(String(describing: self.listViewObject))")
        }
        self.headerRefreshComponent = nil
    }

    ///安装底部刷新控件
    open func installFooterRefreshComponent() {

    }

    ///卸载底部刷新控件
    open func uninstallFooterRefreshComponent() {

    }

    /// 停止头部刷新控件
    /// - Parameter success: 本次刷新是否成功
    /// - Parameter hasMore: 是否还有更多数据
    open func stopHeaderRefreshComponent(success:Bool, hasMore:Bool, userInfo:[AnyHashable:Any]?) {
        if let refresh = self.headerRefreshComponent as? UIRefreshControl {
            refresh.endRefreshing()
        }
        #if canImport(MJRefresh)
        if let refresh = self.headerRefreshComponent as? MJRefreshHeader {
            refresh.endRefreshing()
        }
        #endif
    }

    /// 停止底部刷新控件
    /// - Parameter success: 本次刷新是否成功
    /// - Parameter hasMore: 是否还有更多数据
    open func stopFooterRefreshComponent(success:Bool, hasMore:Bool, userInfo:[AnyHashable:Any]?) {
        #if canImport(AsyncDisplayKit)
        if let batch = self.footerRefreshComponent as? AsyncDisplayKit.ASBatchContext {
            batch.completeBatchFetching(true)
            return
        }
        #endif
        #if canImport(MJRefresh)
        if let refresh = self.footerRefreshComponent as? MJRefreshFooter {
            refresh.endRefreshing()
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

    //除非需要对Cell做特殊处理, 否则子类无需override本方法
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let element = self.localRowElement(at: indexPath)
        if element == nil {
            assertionFailure("无法获取IndexPath:\(indexPath)对应的元素")
        }
        let userInfo:[AnyHashable:Any] = ["indexPath": indexPath]

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
        if element == nil {
            assertionFailure("无法获取IndexPath:\(indexPath)对应的元素")
        }
        let userInfo:[AnyHashable:Any] = ["indexPath": indexPath]

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
        if element == nil {
            assertionFailure("无法获取IndexPath:\(indexPath)对应的元素")
        }
        let userInfo:[AnyHashable:Any] = ["indexPath": indexPath]

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

    #endif

    //MARK: - ListView 操作

    open func listView_appendSection(card:Card) {

    }

    open func listView_appendRow(in section: Int, entities:[Entity]) {

    }

    open func listView_reloadRow(at indexPaths:[IndexPath], animation: UITableView.RowAnimation) {
        
    }

    //MARK: - RXCDiffArrayDelegate
    open func diffArray<SectionContainer, RowElement>(array: RXCDiffArray<SectionContainer, RowElement>, didChange difference: RDADifference<SectionContainer.Element, RowElement>, userInfo: [AnyHashable: Any]?) where SectionContainer: RangeReplaceableCollection {
        let batch = userInfo?["batch"] as? Bool ?? true
        self.listViewObject.reload(userInfo: userInfo, with: difference, animations: RDATableViewAnimations.automatic(), batch: batch) { (finish) in
            print("差异映射UI结束: \(finish)")
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
        #if canImport(Alamofire)
        if let req = self.headerRequest as? Alamofire.Request {
            req.cancel()
            return
        }
        #endif
        fatalError("子类需要重写来实现功能")
    }

    open func cancelFooterRefreshRequest() {
        if let req = self.footerRequest as? URLSessionTask {
            req.cancel()
            return
        }
        #if canImport(Alamofire)
        if let req = self.headerRequest as? Alamofire.Request {
            req.cancel()
            return
        }
        #endif
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
    open func endHeaderRefresh(success:Bool, hasMore:Bool, userInfo:[AnyHashable:Any]?) {
        self.stopHeaderRefreshComponent(success: success, hasMore: hasMore, userInfo: userInfo)
    }

    ///结束一个底部刷新, 典型操作是结束刷新控件的刷新
    open func endFooterRefresh(success:Bool, hasMore:Bool, userInfo:[AnyHashable:Any]?) {
        self.stopFooterRefreshComponent(success: success, hasMore: hasMore, userInfo: userInfo)
    }

    //MARK: - 请求逻辑

    ///这个函数可以接收头部刷新传来的事件
    @objc open func headerRefreshAction(sender: Any?) {
        //当执行头部刷新的时候, 先取消底部刷新, 防止干扰
        guard self.canTakeHeaderRefreshRequest() else {
            return
        }
        //取消请求后会同时结束刷新
        self.cancelFooterRefreshRequest()
    }

    ///前置请求, 有些界面需要有前置请求, 根据前置请求的结果来决定列表页的接口
    open func initRequest() {
        //请求完毕后安装底部刷新控件, 之后就能正常启用列表请求的逻辑
        //默认没有前置请求，直接判断为前置请求完成
    }

    ///返回列表页请求的URL
    open func listRequestUrl(requestType: ListRequestType, page: Int, userInfo: [AnyHashable: Any]?) -> URL {
        fatalError("本方法应由子类提供实现")
    }

    ///返回列表页请求的描述对象
    open func listRequestSpec(requestType: ListRequestType, page: Int, userInfo: [AnyHashable: Any]?) -> ListRequestSpec {
        let url = self.listRequestUrl(requestType: requestType, page: page, userInfo:userInfo)
        let headers = APIService.Util.makeHeader()
        let spec = ListRequestSpec.init(url: url, requestType: requestType)
        return spec
    }

    //开始请求
    open func startListRequest(requestSpec: ListRequestSpec, userInfo: [AnyHashable: Any]?) {
        //默认请求到的数据是一个数组, 至于数组内部的对象则根据请求接口不一样而不一样
        let request = APIServiceV2.shared.basicRequest(requestSpec: requestSpec) {[weak self] (result:ListRequestResponse) in
            self?.onListRequestResponse(requestSpec: requestSpec, response: result, userInfo: nil)
        }
        switch requestSpec.requestType {
        case .headerRefresh:
            self.headerRequest = request
        case .footerRefresh:
            self.footerRequest = request
        }
    }

    ///请求接收到回应
    open func onListRequestResponse(requestSpec: ListRequestSpec, response: ListRequestResponse, userInfo: [AnyHashable: Any]?) {
        ///接收到服务器的回应后，根据回应进入不同的处理分支

    }

    ///请求没有正确完成，任何错误都会进入本流程
    open func onListRequestResponseError(requestSpec: ListRequestSpec, response: ListRequestResponse, userInfo: [AnyHashable: Any]?) {

    }

    ///根据服务器的返回结果判断列表后面是否还有数据
    open func hasMoreDataAfter(requestSpec: ListRequestSpec, response: ListRequestResponse, userInfo: [AnyHashable: Any]?) -> Bool {
        //由于很多时候判断后面是否还有数据的方法不尽相同, 这里采用一个函数来处理
        //一般我们判断的标准是服务器返回了空数组，但是有些界面需要重写本方法，比如综合搜索的第一页就有可能返回空数组但是后面还有数据
        if let data = response.data {
            return data.isEmpty
        }
        //默认是还有数据
        return true
    }

    ///服务器传来了没有更多数据的标记，这是一个单独的分支，进入后处理一下hasMoreData的标记后就可以结束请求了
    open func onListRequestResponseNoMoreData(requestSpec: ListRequestSpec, response: ListRequestResponse, userInfo: [AnyHashable: Any]?) {



    }

    //请求成功后的处理逻辑：success -> (process-> merge) -> updateUI
    //success方法记录下当前的状态，之后调用process，process继续吊用merge， 之后success方法再调用updateUI，更新完之后调用end
    //process：处理服务器传来的数据，

    ///列表请求成功
    open func onListRequestSuccess(requestSpec: ListRequestSpec, response: ListRequestResponse, userInfo: [AnyHashable: Any]?) {

        //由于本地列表的数据不可能很多, 最多最多最多也就1k-2k这个数量级, 我们采用diff来实现数据和UI同步, 采用DifferenceKit来实现

        objc_sync_enter(self.listViewObject as Any)
        objc_sync_enter(self)

        //这里可以采用两种方案，一种是利用DiffArray的batch方法，将修改包括在一个closure中，之后DiffArray可以自动计算并且返回差异
        //另一种是手动记录当前的状态，之后直接调用后续阶段的方法，等数据处理合并阶段完成后，再手动计算差异
        //这里我们用第二种方案，主要是考虑到第一种方案，所有的流程都在本方法

        let differences = self.localDataList.batchWithDifferenceKit {
            //注意, 数据处理内部如果要操作本地列表数据, 一定要禁用DataList的通知，只操作数据不操作ListView的UI部分
            //下面的方法将会链式调用
            let newRemoteData = response.data!
            self.onListRequestDataProcessing(requestSpec: requestSpec, response: response, newRemoteData: newRemoteData)
        }

        //        let animated = userInfo?["animated"] as? Bool ?? true
        //        let enabledSave = UIView.areAnimationsEnabled
        //        UIView.setAnimationsEnabled(animated)

        for i in differences {
            if let data = i.dk_finalDataForCurrentStep {
                self.localDataList.rda_removeAllSection(userInfo: [DataList.Key.notify: false], where: { _ in true })
                self.localDataList.rda_appendSection(contentsOf: data, userInfo: [DataList.Key.notify: false])
            }
            self.listViewObject.reload(userInfo: nil, with: i, animations: RDATableViewAnimations.automatic(), batch: true) { (finish) in
                print("数据Diff更新UI完成")
            }
        }

//        UIView.setAnimationsEnabled(enabledSave)
        objc_sync_exit(self.listViewObject as Any)
        objc_sync_exit(self)
    }

    /// 数据处理第一阶段阶段, 这个阶段将对服务器传来的数据进行过滤和处理, 同时也可能会对现有列表进行修改, 比如删除重复项
    /// - Parameter response: 服务器传过来的请求
    open func onListRequestDataProcessing(requestSpec: ListRequestSpec, response: ListRequestResponse, newRemoteData:[RowElement], userInfo: [AnyHashable: Any]?) {
        var newDataList = response.data!
        for i in self.dataProcessors {
            let processed = i.process(newObjects: newDataList, userInfo: nil) as? [Entity]
            if processed == nil {
                LogUtil.error("列表请求数据处理器返回了错误的类型")
            }
            newDataList = processed ?? newDataList
        }
        let newResponse = ListRequestResponse(data: newDataList)
        self.onListRequestRemoteDataToLocalData(requestSpec: requestSpec, response: newResponse, newRemoteData: newResponse)
    }

    /// 数据处理第二阶段，将上一步处理好的远程数据映射成一组本地数据，这里的典型操作是向远程数据中加入一些分割线数据等等，默认什么也不做
    /// - Parameter requestSpec: 请求的描述
    /// - Parameter response: 服务器返回的请求
    /// - Parameter newRemoteData: <#newRemoteData description#>
    open func onListRequestRemoteDataToLocalData(requestSpec: ListRequestSpec, response: ListRequestResponse, newRemoteData:[RowElement], userInfo: [AnyHashable: Any]?) {

    }

    /// 数据合并阶段, 这个阶段将服务器传来的数据合并到现有的列表中, 这个阶段不应该对上一步传过来的数据做修改
    /// - Parameter requestSpec: 请求的描述
    /// - Parameter localData: 处理后的本地数据
    /// - Parameter remoteData: 处理过的远程数据
    open func onListRequestDataMerge(requestSpec: ListRequestSpec, newLocalData:[RowElement], newRemoteData:[RowElement], userInfo: [AnyHashable: Any]?) {
        //将 （服务器传来的数据，以及根据服务器数据计算的新的本地数据） 合并到本地数据源中, 之后数据合并阶段结束


    }

    ///列表数据请求更新列表对应的Section，默认是0
    open func sectionForListRequestUpdateListView(requestSpec: ListRequestSpec, response: ListRequestResponse, userInfo: [AnyHashable: Any]?) -> Int {
        return 0
    }

    ///更新UI阶段
    open func onListRequestUpdateListView(differences:DataList.Difference, requestSpec: ListRequestSpec, response: ListRequestResponse, userInfo: [AnyHashable: Any]?, completion:(Bool)->Void) {

        self.onListRequestEnd(requestSpec: requestSpec, response: response)
    }

    open func onListRequestEnd(requestSpec: ListRequestSpec, response: ListRequestResponse) {

    }

}
