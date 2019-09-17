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
    
    enum RequestType {
        //case `init`
        case headerRefresh
        case footerRefresh
    }

}

open class RXCEntityListViewController: RELFirstTimeViewController, ASTableDataSource,ASTableDelegate,ASCollectionDataSource,ASCollectionDelegate, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, RXCDiffArrayDelegate {

    public typealias SectionELement = RELCard
    public typealias RowElement = RELEntity
    public typealias DataList = RXCDiffArray<ContiguousArray<RELCard>, RELEntity>

    //下面的别名是为了方便我们整合代码, 当需要修改的时候直接改这里就好, 降低复杂度, 为了通用性考虑, 默认直接采用AnyObject也是极好的
    
    public typealias ListRequestTask = AnyObject
    public typealias ListRequestResponse = AnyObject

    open var listViewObject:RELListViewProtocol!
    #if (CanUseASDK || canImport(AsyncDisplayKit))
    open var tableNode:ASTableNode! {return self.listViewObject as? ASTableNode}
    open var collectionNode:ASCollectionNode! {return self.listViewObject as? ASCollectionNode}
    #endif
    open var tableView:UITableView! {
        if let tv = self.listViewObject as? UITableView {return tv}
        #if canImport(AsyncDisplayKit)
        if let tn = self.listViewObject as? ASTableNode {return tn.view}
        #endif
        return nil
    }
    open var collectionView:UICollectionView! {
        if let cv = self.listViewObject as? UICollectionView {return cv}
        #if canImport(AsyncDisplayKit)
        if let cn = self.listViewObject as? ASCollectionNode {return cn.view}
        #endif
        return nil
    }

    //MARK: - UI 及其相关

    ///cell的选择器, 需要在初始化方法中初始化之后使用
    var cellSelectorManager:RELCellSelectorManager!

    //MARK: - 数据 / Data

    open var dataList:DataList!
    ///当请求到数据后, 按照顺序让数据处理器对新请求到的数据进行处理或者过滤
    open var dataProcessors:[RELListRequestDataProcessorProtocol] = []
    ///当前列表数据的最大页码, 为0表示当前没有进行请求
    open var page:Int = 0

    //MARK: - 标记 / MARK

    ///自动内容控制，当数据源发生变化的时候自动更新ListView
    open var autoContentControl:Bool = true

    #if (CanUseASDK || canImport(AsyncDisplayKit))
    open var useASDK:Bool
    #endif
    open var useCollectionView:Bool

    //MARK: - 请求相关

    open var lastHeaderRequest:ListRequestTask?
    open var lastFooterRequest:ListRequestTask?
    ///列表还有更多内容
    open var hasMoreData:Bool = true
    ///头部刷新组件指针, 用于确定是否安装了头部刷新组件
    open var headerRefreshComponent:AnyObject?
    ///底部刷新组件指针, 用于确定是否安装了底部刷新组件
    open var footerRefreshComponent:AnyObject?
    
    //MARK: - 性能
    
    #if (CanUseASDK || canImport(AsyncDisplayKit))
    ///添加或者更新Cell的时候可能会引起闪烁, 每次更新之前, 将要更新的Cell的位置加入这个数组, TableNode在返回Cell的时候会将这个Cell的neverShowPlaceholder设置为true, 一段时间后再改回falsse, 之后将该indexPath从本数组删除, 解决办法来自贝聊科技的文章
    open var neverShowPlaceholderIndexPathes:[IndexPath] = []
    #endif

    //MARK: - 初始化 / INIT

    #if (CanUseASDK || canImport(AsyncDisplayKit))
    public init(style:UITableView.Style, useCollectionView:Bool, useASDK:Bool) {
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
    public init(style:UITableView.Style, useCollectionView:Bool) {
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

    open func initDataList() {
        //默认没有数据
        //初始化的时候有数据, 则必须先调用一次reloadData(), 否则可能导致UI和数据源不同步
        //如果是UICollectionView, 需要执行注册函数
        self.dataList = DataList()
        self.dataList.delegate = self
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
            //如果是UICollectionView, 我们需要注册Cell
            self.registerCellForUICollectionView()
        }else {
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
        }else {
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

    }

    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.layoutListView()
    }

    open func layoutListView() {
        if let likeView = self.listViewObject as? RXCViewLikeObjectProtocol {
            likeView.frame = self.view.bounds
        }
    }

    //MARK: - 操作 ListView

    ///安装顶部刷新控件
    open func installHeaderRefreshComponent() {
        //默认安装系统的刷新组件
        guard self.headerRefreshComponent == nil else {return}
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(headerRefreshAction(sender:)), for: .valueChanged)
        if let obj = self.listViewObject as? UITableView {
            obj.refreshControl = refresh
        }else if let obj = self.listViewObject as? UICollectionView {
            obj.refreshControl = refresh
        }else {
            #if (CanUseASDK || canImport(AsyncDisplayKit))
            if let obj = self.listViewObject as? ASTableNode {
                obj.view.refreshControl = refresh
            }else if let obj = self.listViewObject as? ASCollectionNode {
                obj.view.refreshControl = refresh
            }else {
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
        guard self.headerRefreshComponent != nil else {return}
        //这里由于ASDK也可以获取到指针, 直接用??一起获取了
        if let obj = self.listViewObject as? UITableView ?? self.tableView, obj.refreshControl != nil {
            obj.refreshControl = nil
        }else if let obj = self.listViewObject as? UICollectionView ?? self.collectionView, obj.refreshControl != nil {
            obj.refreshControl = nil
        }else {
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

    open func stopHeaderRefreshComponent() {
        if let refresh = self.headerRefreshComponent as? UIRefreshControl {
            refresh.endRefreshing()
        }
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
    
    #if (CanUseASDK || canImport(AsyncDisplayKit))
    
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
    
    #endif

    //MARK: - RXCDiffArrayDelegate

    public func diffArray<SectionContainer, RowElement>(array: RXCDiffArray<SectionContainer, RowElement>, didChange difference: RDADifference<SectionContainer.Element, RowElement>, userInfo: [AnyHashable : Any]?) where SectionContainer : RangeReplaceableCollection {
        let batch = userInfo?["batch"] as? Bool ?? true
        self.listViewObject.reload(userInfo: userInfo, with: difference, animations: RDATableViewAnimations.automatic(), batch: batch) { (finish) in
            print("差异映射UI结束: \(finish)")
        }
    }

    //MARK: - 请求状态
    
    func isHeaderRequesting()->Bool {
        return self.lastHeaderRequest != nil
    }
    
    func isFooterRequesting()->Bool {
        return self.lastFooterRequest != nil
    }
    
    func cancelHeaderRefreshRequest() {
        if let req = self.lastHeaderRequest as? URLSessionTask {
            req.cancel()
            return
        }
        #if canImport(Alamofire)
        if let req = self.lastHeaderRequest as? AnyObject {
            return
        }
        #endif
        fatalError("子类需要重写来实现功能")
    }
    
    func cancelFooterRefreshRequest() {
        if let req = self.lastHeaderRequest as? URLSessionTask {
            req.cancel()
            return
        }
        #if canImport(Alamofire)
        if let req = self.lastHeaderRequest as? AnyObject {
            return
        }
        #endif
        fatalError("子类需要重写来实现功能")
    }
    
    ///此时是否可以发起头部刷新请求
    open func canTakeHeaderRefreshRequest()->Bool {
        //一般情况下, 头部刷新优先级高于底部刷新, 头部刷新进行的时候, 直接取消底部刷新
        return true
    }
    
    ///此时是否可以发起底部刷新请求
    open func canTakeFooterRefreshRequest()->Bool {
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
        self.stopHeaderRefreshComponent()
    }
    
    ///结束一个底部刷新, 典型操作是结束刷新控件的刷新
    open func endFooterRefresh(userInfo:[AnyHashable:Any]?) {
        self.stopFooterRefreshComponent()
    }
    
    //MARK: - 请求逻辑
    
    ///这个函数可以接收头部刷新传来的事件
    @objc func headerRefreshAction(sender:Any?) {
        //当执行头部刷新的时候, 先取消底部刷新, 防止干扰
        guard self.canTakeHeaderRefreshRequest() else {return}
        self.cancelFooterRefreshRequest()
        self.stopFooterRefreshComponent()
    }

    ///前置请求, 有些界面需要有前置请求, 根据前置请求的结果来决定列表页的接口
    func initRequest() {
        //请求完毕后安装底部刷新控件, 之后就能正常启用列表请求的逻辑
    }

    ///返回列表页请求的URL
    open func listRequestUrl(requestType:RequestType, page:Int, userInfo:[AnyHashable:Any]?)->URL {
        fatalError("本方法应由子类提供实现")
    }

    ///返回列表页请求的描述对象
    open func listRequestSpec(requestType:RequestType, page:Int, userInfo:[AnyHashable:Any]?) -> RELRequestSpec {
        fatalError("稍等实现")
    }
    
    //开始请求
    open func startListRequest(requestSpec:RELListRequestSpec, userInfo:[AnyHashable:Any]?) {
        fatalError("本方法应由子类提供实现")
        //默认请求到的数据是一个数组, 至于数组内部的对象则根据请求接口不一样而不一样
    }
    
    ///请求接收到回应
    open func onListRequestResponse(requestSpec:RELListRequestSpec, response:ListRequestResponse, userInfo:[AnyHashable:Any]?) {

    }
    
    ///请求的回应是错误信息
    open func onListRequestResponseError(requestSpec:RELListRequestSpec, response:ListRequestResponse, userInfo:[AnyHashable:Any]?) {

    }
    
    ///根据服务器的返回结果判断列表后面是否还有数据
    open func hasMoreDataAfter(requestSpec:RELListRequestSpec, response:ListRequestResponse, userInfo:[AnyHashable:Any]?)->Bool {
        //由于很多时候判断后面是否还有数据的方法不尽相同, 这里采用一个函数来处理
        fatalError("本方法应由子类提供实现")
    }
    
    ///列表请求成功
    open func onListRequestSuccess(requestSpec:RELListRequestSpec, response:ListRequestResponse, userInfo:[AnyHashable:Any]?) {
        //数据处理流程
        //数据合并流程
        //UI更新流程
        //结束请求流程

        //由于本地列表的数据不可能很多, 最多最多最多也就1k-2k这个数量级, 我们采用diff来实现数据和UI同步, 采用DifferenceKit来实现

        let animated = userInfo?["animated"] as? Bool ?? true
        let enabledSave = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(animated)
        
        objc_sync_enter(self.listViewObject as Any)
        objc_sync_enter(self)

        let diffArray = self.dataList.batchWithDifferenceKit {
            //注意, 数据处理内部如果要操作本地列表数据, 一定要禁用DataList的通知
            self.onListRequestDataProcessing(requestSpec: requestSpec, response: response)
        }
        for i in diffArray {
            if let data = i.dk_finalDataForCurrentStep {
                self.dataList.rda_removeAllSection(userInfo: [DataList.Key.notify: false], where: {_ in true})
                self.dataList.rda_appendSection(contentsOf: data, userInfo: [DataList.Key.notify: false])
            }
            self.listViewObject.reload(userInfo: nil, with: i, animations: RDATableViewAnimations.automatic(), batch: true) { (finish) in
                print("数据Diff更新UI完成")
            }
        }

        UIView.setAnimationsEnabled(enabledSave)
        objc_sync_exit(self.listViewObject as Any)
        objc_sync_exit(self)
    }
    
    //下面三个方法是依次调用的, 每个方法需要保证要调用下一个方法, 或者子类override后将所有逻辑都自己处理也可以

    ///数据处理阶段, 这个阶段将对服务器传来的数据进行过滤, 同时也可能会对现有列表进行修改, 比如删除重复项
    open func onListRequestDataProcessing(requestSpec:RELListRequestSpec, response:ListRequestResponse) {
        for i in self.dataProcessors {

        }
        self.onListRequestDataMerge(requestSpec: requestSpec, response: response)
    }

    ///数据合并阶段, 这个阶段将服务器传来的数据合并到现有的列表中, 这个阶段不应该对数据做修改
    open func onListRequestDataMerge(requestSpec:RELListRequestSpec, response:ListRequestResponse) {
        self.onListRequestUpdateUI(requestSpec: requestSpec, response: response)
    }

    ///更新UI阶段
    open func onListRequestUpdateUI(requestSpec:RELListRequestSpec, response:ListRequestResponse) {
        self.onListRequestEnd(requestSpec: requestSpec, response: response)
    }
    
    open func onListRequestEnd(requestSpec:RELListRequestSpec, response:ListRequestResponse) {
        
    }

}

