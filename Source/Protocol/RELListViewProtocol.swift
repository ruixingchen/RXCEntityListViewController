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

///将所有列表视图的API进行统一
public protocol RELListViewProtocol: AnyObject {

    //MARL: - 列表操作

//    func rel_reloadData()
//
//    var rel_numberOfSections: Int { get }
//
//    func rel_numberOfRows(inSection section: Int) -> Int
//
//    var rel_indexPathsForVisibleRows: [IndexPath] { get }

}

extension UITableView: RELListViewProtocol {

}

extension UICollectionView: RELListViewProtocol {

}

#if CanUseASDK || canImport(AsyncDisplayKit)

extension ASTableNode: RELListViewProtocol {

}

extension ASCollectionNode: RELListViewProtocol {

}

#endif
