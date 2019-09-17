//
//  RELFirstTimeViewController.swift
//  RXCEntityListViewController
//
//  Created by ruixingchen on 9/16/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import UIKit

public extension UIViewController {

    ///表示当前界面的状态
    enum ViewState: Int {
        case none = 0
        case loadView
        case viewDidLoad
        case willLayout
        case willAppear
        case didLayout
        case didAppear
        case willDisappear
        case didDidAppear
    }

}

open class RELFirstTimeViewController: UIViewController {

    /// is this view during rotation transition?
    open var rxc_isRotating: Bool = false
    open var rxc_isViewAppearing:Bool = false
    open var rxc_isViewLayouting:Bool = false
    open var rxc_isViewDisappearing:Bool = false
    open var rxc_isViewAppeared:Bool = false
    open var rxc_isViewLayouted:Bool = false
    open var rxc_isViewDisappeared:Bool = false

    open var viewDidLoad_called:Bool = false
    override open func viewDidLoad() {
        super.viewDidLoad()
        if !viewDidLoad_called {
            viewDidLoad_called = true
            viewDidLoad_first()
        }
    }
    open func viewDidLoad_first() {

    }

    open var viewWillAppear_called:Bool = false
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.rxc_isViewAppearing = true
        self.rxc_isViewAppeared = false
        self.rxc_isViewDisappearing = false
        self.rxc_isViewDisappeared = false
        if !viewWillAppear_called {
            viewWillAppear_called = true
            viewWillAppear_first(animated)
        }
    }
    open func viewWillAppear_first(_ animated: Bool) {

    }

    open var viewWillLayoutSubviews_called:Bool = false
    override open func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.rxc_isViewLayouting = true
        if !viewWillLayoutSubviews_called {
            viewWillLayoutSubviews_called = true
            viewWillLayoutSubviews_first()
        }
    }
    open func viewWillLayoutSubviews_first() {

    }

    open var viewDidLayoutSubviews_called:Bool = false
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.rxc_isViewLayouting = false
        self.rxc_isViewLayouted = true
        if !viewDidLayoutSubviews_called {
            viewDidLayoutSubviews_called = true
            viewDidLayoutSubviews_first()
        }
        if rxc_isRotating {
            viewDidLayoutSubviewsInTransition()
        }
    }
    open func viewDidLayoutSubviews_first(){

    }
    open func viewDidLayoutSubviewsInTransition(){

    }

    open var viewLayoutMarginsDidChange_called:Bool = false
    open override func viewLayoutMarginsDidChange() {
        if #available(iOS 11.0, *) {
            super.viewLayoutMarginsDidChange()
        } else {

        }
        if !viewLayoutMarginsDidChange_called {
            viewLayoutMarginsDidChange_called = true
            self.viewLayoutMarginsDidChange_first()
        }
    }
    open func viewLayoutMarginsDidChange_first(){

    }

    open var viewSafeAreaInsetsDidChange_called:Bool = false
    open override func viewSafeAreaInsetsDidChange() {
        if #available(iOS 11.0, *) {
            super.viewSafeAreaInsetsDidChange()
        } else {
        }
        if !viewSafeAreaInsetsDidChange_called {
            viewSafeAreaInsetsDidChange_called = true
            viewSafeAreaInsetsDidChange_first()
        }
    }
    open func viewSafeAreaInsetsDidChange_first() {

    }

    open var viewDidAppear_called:Bool = false
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.rxc_isViewAppearing = false
        self.rxc_isViewAppeared = true
        self.rxc_isViewDisappearing = false
        self.rxc_isViewDisappeared = false
        if !viewDidAppear_called {
            viewDidAppear_called = true
            viewDidAppear_first(animated)
        }
    }
    open func viewDidAppear_first(_ animated: Bool) {

    }

    open var viewWillDisappear_called:Bool = false
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.rxc_isViewAppearing = false
        self.rxc_isViewAppeared = false
        self.rxc_isViewDisappearing = true
        self.rxc_isViewDisappeared = false
        if !viewWillDisappear_called {
            viewWillDisappear_called = true
            viewWillDisappear_first(animated)
        }
    }
    open func viewWillDisappear_first(_ animated: Bool) {

    }

    open var viewDidDisappear_called:Bool = false
    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.rxc_isViewDisappearing = false
        self.rxc_isViewDisappeared = true
        if !viewDidDisappear_called {
            viewDidDisappear_called = true
            viewDidDisappear_first(animated)
        }
    }
    open func viewDidDisappear_first(_ animated: Bool) {

    }

    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        rxc_isRotating = true
        coordinator.animateAlongsideTransition(in: nil, animation: nil) {[weak self] (_) in
            self?.rxc_isRotating = false
        }
    }

    open var updateViewConstraints_called:Bool = false
    open override func updateViewConstraints() {
        super.updateViewConstraints()
        if !self.updateViewConstraints_called {
            self.updateViewConstraints_called = true
            self.initViewConstraints()
        }
    }
    open func initViewConstraints() {

    }

}

