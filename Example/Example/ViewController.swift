//
//  ViewController.swift
//  Example
//
//  Created by ruixingchen on 2019/10/31.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import UIKit
import RXCFirstTimeViewController
import Alamofire
import RXCDiffArray
import MJRefresh

class RowEntity: RELRowEntityProtocol {
    var rda_diffIdentifier: AnyHashable {return self.title}

    var title:String = UUID().uuidString

}

class CardObject: RELSectionCardProtocol {

    var rel_cardObjects: [Any]?

    var rda_diffIdentifier: AnyHashable = NSUUID().uuidString

    var rda_diffableElements: [RDADiffableRowElementProtocol] {return self.rda_elements as! [RDADiffableRowElementProtocol]}

    var rda_elements: [Any] {
        get {return self.rel_cardObjects ?? []}
        set {self.rel_cardObjects = newValue}
    }

}

class Cell: UITableViewCell, RELDataBindableModelStorageObjectProtocol {

    var rxc_bindedData: Any?

    func rxc_bindData(data: Any?, userInfo: [AnyHashable : Any]?) {
        self.rxc_bindedData = data
        if let entity:RowEntity = self.getEntity() {
            self.textLabel?.text = entity.title
        }
    }

}

class ViewController: RXCEntityListViewController {

    override func initCellSelectorManager() -> RELCellSelectorManager {
        let manager = RELCellSelectorManager()
        manager.register(RELCellSelector.init(reuseIdentifier: "cell", match: {_ in true}, cell: {_ in Cell()}))
        return manager
    }

    override func initDataList() -> RXCEntityListViewController.DataList {
        let data = DataList.init(elements: [RELSectionCardProtocolWrapper(card: CardObject())])
        data.addDelegate(self)
        return data
    }

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func ftv_viewDidAppear_first(_ animated: Bool) {
        super.ftv_viewDidAppear_first(animated)
        self.startInitRequest()
    }

    override func stopFooterRefreshComponent(hasMoreData: Bool, userInfo: [AnyHashable : Any]?) {
        self.tableView.mj_footer?.endRefreshing()
    }

    override func installHeaderRefreshComponentIfNeeded() {

        self.tableView.mj_header = MJRefreshNormalHeader(refreshingBlock: {[weak self] () in
            guard let sself = self else {return}
            if sself.canTakeFooterRefreshRequest() && sself.headerRefreshComponent != nil {
                sself.headerRefreshAction(sender: self?.tableView.mj_header)
            }else {
                sself.tableView.mj_header?.endRefreshing()
            }
        })
        self.headerRefreshComponent = self.tableView.mj_header
    }

    override func installFooterRefreshComponentIfNeeded() {
        self.tableView.mj_footer = MJRefreshAutoFooter(refreshingBlock: {[weak self] () in
            guard let sself = self else {return}
            if sself.canTakeFooterRefreshRequest() && sself.footerRefreshComponent != nil {
                sself.footerRefreshAction(sender: sself.tableView.mj_footer)
            }else {
                sself.tableView.mj_footer?.endRefreshing()
            }
        })
        self.footerRefreshComponent = self.tableView.mj_footer
    }

    override func hasMoreDataAfter(requestSpec: RXCEntityListViewController.ListRequestSpec, response: RXCEntityListViewController.ListRequestResponse, userInfo: [AnyHashable : Any]?) -> Bool {
        return true
    }

    override func listRequestUrl(requestType: RXCEntityListViewController.ListRequestType, page: Int, userInfo: [AnyHashable : Any]?) -> URL {
        return URL(string: "https://www.baidu.com")!
    }

    override func listRequestSpec(requestType: RXCEntityListViewController.ListRequestType, page: Int, userInfo: [AnyHashable : Any]?) -> RXCEntityListViewController.ListRequestSpec {
        let url = self.listRequestUrl(requestType: requestType, page: page, userInfo: userInfo)
        return ListRequestSpec(url: url, page: page, requestType: requestType)
    }

    override func startListRequest(requestSpec: RXCEntityListViewController.ListRequestSpec, userInfo: [AnyHashable : Any]?) -> RXCEntityListViewController.ListRequestTask {

        let url = requestSpec.url
        let request = Alamofire.request(url).responseData { (dr) in
            let newRow:[RELRowEntityProtocolWrapper] = ((0..<10).map({_ in RowEntity()})).map({RELRowEntityProtocolWrapper(entity: $0)})
            let response = ListRequestResponse(data: newRow, response: dr.response, error: dr.error)
            self.onListRequestResponse(requestSpec: requestSpec, response: response, userInfo: userInfo)
        }
        return request
    }

}

