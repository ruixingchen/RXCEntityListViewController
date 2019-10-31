//
//  RXCScrollViewLikeObjectProtocol.swift
//  CoolMarket
//
//  Created by ruixingchen on 9/18/19.
//  Copyright © 2019 CoolApk. All rights reserved.
//

import UIKit
#if (CanUseASDK || canImport(AsyncDisplayKit))
import AsyncDisplayKit
#endif

public protocol RXCScrollViewLikeObjectProtocol: RXCViewLikeObjectProtocol {
    var contentOffset: CGPoint {get set}

    var contentSize: CGSize {get set}// default CGSizeZero

    var contentInset: UIEdgeInsets {get set} // default UIEdgeInsetsZero. add additional scroll area around content


    /* When contentInsetAdjustmentBehavior allows, UIScrollView may incorporate
     its safeAreaInsets into the adjustedContentInset.
     */
    @available(iOS 11.0, *)
    var adjustedContentInset: UIEdgeInsets { get }

    /* Also see -scrollViewDidChangeAdjustedContentInset: in the UIScrollViewDelegate protocol.
     */
    @available(iOS 11.0, *)
    func adjustedContentInsetDidChange()


    /* Configure the behavior of adjustedContentInset.
     Default is UIScrollViewContentInsetAdjustmentAutomatic.
     */
    @available(iOS 11.0, *)
    var contentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior {get set}

    /* Configures whether the scroll indicator insets are automatically adjusted by the system.
     Default is YES.
     */
    @available(iOS 13.0, *)
    var automaticallyAdjustsScrollIndicatorInsets: Bool {get set}


    /* contentLayoutGuide anchors (e.g., contentLayoutGuide.centerXAnchor, etc.) refer to
     the untranslated content area of the scroll view.
     */
    @available(iOS 11.0, *)
    var contentLayoutGuide: UILayoutGuide { get }


    /* frameLayoutGuide anchors (e.g., frameLayoutGuide.centerXAnchor) refer to
     the untransformed frame of the scroll view.
     */
    @available(iOS 11.0, *)
    var frameLayoutGuide: UILayoutGuide { get }

    //var delegate: UIScrollViewDelegate? {get set} // default nil. weak reference

    var isDirectionalLockEnabled: Bool {get set} // default NO. if YES, try to lock vertical or horizontal scrolling while dragging

    var bounces: Bool {get set} // default YES. if YES, bounces past edge of content and back again

    var alwaysBounceVertical: Bool {get set} // default NO. if YES and bounces is YES, even if content is smaller than bounds, allow drag vertically

    var alwaysBounceHorizontal: Bool {get set} // default NO. if YES and bounces is YES, even if content is smaller than bounds, allow drag horizontally

    var isPagingEnabled: Bool {get set} // default NO. if YES, stop on multiples of view bounds

    var isScrollEnabled: Bool {get set} // default YES. turn off any dragging temporarily


    var showsVerticalScrollIndicator: Bool {get set} // default YES. show indicator while we are tracking. fades out after tracking

    var showsHorizontalScrollIndicator: Bool {get set} // default YES. show indicator while we are tracking. fades out after tracking

    var indicatorStyle: UIScrollView.IndicatorStyle {get set}// default is UIScrollViewIndicatorStyleDefault


    @available(iOS 11.1, *)
    var verticalScrollIndicatorInsets: UIEdgeInsets {get set} // default is UIEdgeInsetsZero.

    @available(iOS 11.1, *)
    var horizontalScrollIndicatorInsets: UIEdgeInsets {get set} // default is UIEdgeInsetsZero.

    var scrollIndicatorInsets: UIEdgeInsets {get set} // use the setter only, as a convenience for setting both verticalScrollIndicatorInsets and horizontalScrollIndicatorInsets to the same value. if those properties have been set to different values, the return value of this getter (deprecated) is undefined.


    @available(iOS 3.0, *)
    var decelerationRate: UIScrollView.DecelerationRate {get set}

    var indexDisplayMode: UIScrollView.IndexDisplayMode {get set}


    func setContentOffset(_ contentOffset: CGPoint, animated: Bool) // animate at constant velocity to new offset

    func scrollRectToVisible(_ rect: CGRect, animated: Bool) // scroll so rect is just visible (nearest edges). nothing if rect completely visible


    func flashScrollIndicators() // displays the scroll indicators for a short time. This should be done whenever you bring the scroll view to front.


    /*
     Scrolling with no scroll bars is a bit complex. on touch down, we don't know if the user will want to scroll or track a subview like a control.
     on touch down, we start a timer and also look at any movement. if the time elapses without sufficient change in position, we start sending events to
     the hit view in the content subview. if the user then drags far enough, we switch back to dragging and cancel any tracking in the subview.
     the methods below are called by the scroll view and give subclasses override points to add in custom behaviour.
     you can remove the delay in delivery of touchesBegan:withEvent: to subviews by setting delaysContentTouches to NO.
     */

    var isTracking: Bool { get } // returns YES if user has touched. may not yet have started dragging

    var isDragging: Bool { get } // returns YES if user has started scrolling. this may require some time and or distance to move to initiate dragging

    var isDecelerating: Bool { get } // returns YES if user isn't dragging (touch up) but scroll view is still moving


    var delaysContentTouches: Bool {get set} // default is YES. if NO, we immediately call -touchesShouldBegin:withEvent:inContentView:. this has no effect on presses

    var canCancelContentTouches: Bool {get set} // default is YES. if NO, then once we start tracking, we don't try to drag if the touch moves. this has no effect on presses


    // override points for subclasses to control delivery of touch events to subviews of the scroll view
    // called before touches are delivered to a subview of the scroll view. if it returns NO the touches will not be delivered to the subview
    // this has no effect on presses
    // default returns YES
    func touchesShouldBegin(_ touches: Set<UITouch>, with event: UIEvent?, in view: UIView) -> Bool

    // called before scrolling begins if touches have already been delivered to a subview of the scroll view. if it returns NO the touches will continue to be delivered to the subview and scrolling will not occur
    // not called if canCancelContentTouches is NO. default returns YES if view isn't a UIControl
    // this has no effect on presses
    func touchesShouldCancel(in view: UIView) -> Bool


    /*
     the following properties and methods are for zooming. as the user tracks with two fingers, we adjust the offset and the scale of the content. When the gesture ends, you should update the content
     as necessary. Note that the gesture can end and a finger could still be down. While the gesture is in progress, we do not send any tracking calls to the subview.
     the delegate must implement both viewForZoomingInScrollView: and scrollViewDidEndZooming:withView:atScale: in order for zooming to work and the max/min zoom scale must be different
     note that we are not scaling the actual scroll view but the 'content view' returned by the delegate. the delegate must return a subview, not the scroll view itself, from viewForZoomingInScrollview:
     */

    var minimumZoomScale: CGFloat {get set} // default is 1.0

    var maximumZoomScale: CGFloat {get set} // default is 1.0. must be > minimum zoom scale to enable zooming


    @available(iOS 3.0, *)
    var zoomScale: CGFloat {get set} // default is 1.0

    @available(iOS 3.0, *)
    func setZoomScale(_ scale: CGFloat, animated: Bool)

    @available(iOS 3.0, *)
    func zoom(to rect: CGRect, animated: Bool)


    var bouncesZoom: Bool {get set} // default is YES. if set, user can go past min/max zoom while gesturing and the zoom will animate to the min/max value at gesture end


    var isZooming: Bool { get } // returns YES if user in zoom gesture

    var isZoomBouncing: Bool { get } // returns YES if we are in the middle of zooming back to the min/max value


    // When the user taps the status bar, the scroll view beneath the touch which is closest to the status bar will be scrolled to top, but only if its `scrollsToTop` property is YES, its delegate does not return NO from `-scrollViewShouldScrollToTop:`, and it is not already at the top.
    // On iPhone, we execute this gesture only if there's one on-screen scroll view with `scrollsToTop` == YES. If more than one is found, none will be scrolled.
    var scrollsToTop: Bool {get set} // default is YES.


    // Use these accessors to configure the scroll view's built-in gesture recognizers.
    // Do not change the gestures' delegates or override the getters for these properties.

    // Change `panGestureRecognizer.allowedTouchTypes` to limit scrolling to a particular set of touch types.
    @available(iOS 5.0, *)
    var panGestureRecognizer: UIPanGestureRecognizer { get }

    // `pinchGestureRecognizer` will return nil when zooming is disabled.
    @available(iOS 5.0, *)
    var pinchGestureRecognizer: UIPinchGestureRecognizer? { get }

    // `directionalPressGestureRecognizer` is disabled by default, but can be enabled to perform scrolling in response to up / down / left / right arrow button presses directly, instead of scrolling indirectly in response to focus updates.
    var directionalPressGestureRecognizer: UIGestureRecognizer { get }


    @available(iOS 7.0, *)
    var keyboardDismissMode: UIScrollView.KeyboardDismissMode {get set} // default is UIScrollViewKeyboardDismissModeNone


    @available(iOS 10.0, *)
    var refreshControl: UIRefreshControl? {get set}
}

extension UIScrollView: RXCScrollViewLikeObjectProtocol {

}

#if (CanUseASDK || canImport(AsyncDisplayKit))
extension ASScrollNode: RXCScrollViewLikeObjectProtocol {
    public var contentOffset: CGPoint {
        get {
            return self.view.contentOffset
        }
        set {
            self.view.contentOffset = newValue
        }
    }

    public var contentSize: CGSize {
        get {
            return self.view.contentSize
        }
        set {
            self.view.contentSize = newValue
        }
    }

    public var contentInset: UIEdgeInsets {
        get {
            return self.view.contentInset
        }
        set {
            self.view.contentInset = newValue
        }
    }

    public var adjustedContentInset: UIEdgeInsets {
        return self.view.adjustedContentInset
    }

    public func adjustedContentInsetDidChange() {
        return self.view.adjustedContentInsetDidChange()
    }

    public var contentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior {
        get {
            return self.view.contentInsetAdjustmentBehavior
        }
        set {
            self.view.contentInsetAdjustmentBehavior = newValue
        }
    }

    @available(iOS 13.0, *)
    public var automaticallyAdjustsScrollIndicatorInsets: Bool {
        get {
            return self.view.automaticallyAdjustsScrollIndicatorInsets
        }
        set {
            self.view.automaticallyAdjustsScrollIndicatorInsets = newValue
        }
    }

    public var contentLayoutGuide: UILayoutGuide {
        return self.view.contentLayoutGuide
    }

    public var frameLayoutGuide: UILayoutGuide {
        return self.view.frameLayoutGuide
    }

    public var delegate: UIScrollViewDelegate? {
        get {
            return self.view.delegate
        }
        set {
            self.view.delegate = newValue
        }
    }

    public var isDirectionalLockEnabled: Bool {
        get {
            return self.view.isDirectionalLockEnabled
        }
        set {
            self.view.isDirectionalLockEnabled = newValue
        }
    }

    public var bounces: Bool {
        get {
            return self.view.bounces
        }
        set {
            self.view.bounces = newValue
        }
    }

    public var alwaysBounceVertical: Bool {
        get {
            return self.view.alwaysBounceVertical
        }
        set {
            self.view.alwaysBounceVertical = newValue
        }
    }

    public var alwaysBounceHorizontal: Bool {
        get {
            return self.view.alwaysBounceHorizontal
        }
        set {
            self.view.alwaysBounceHorizontal = newValue
        }
    }

    public var isPagingEnabled: Bool {
        get {
            return self.view.isPagingEnabled
        }
        set {
            self.view.isPagingEnabled = newValue
        }
    }

    public var isScrollEnabled: Bool {
        get {
            return self.view.isScrollEnabled
        }
        set {
            self.view.isScrollEnabled = newValue
        }
    }

    public var showsVerticalScrollIndicator: Bool {
        get {
            return self.view.showsVerticalScrollIndicator
        }
        set {
            self.view.showsVerticalScrollIndicator = newValue
        }
    }

    public var showsHorizontalScrollIndicator: Bool {
        get {
            return self.view.showsHorizontalScrollIndicator
        }
        set {
            self.view.showsHorizontalScrollIndicator = newValue
        }
    }

    public var indicatorStyle: UIScrollView.IndicatorStyle {
        get {
            return self.view.indicatorStyle
        }
        set {
            self.view.indicatorStyle = newValue
        }
    }

    @available(iOS 11.1, *)
    public var verticalScrollIndicatorInsets: UIEdgeInsets {
        get {
            return self.view.verticalScrollIndicatorInsets
        }
        set {
            self.view.verticalScrollIndicatorInsets = newValue
        }
    }

    @available(iOS 11.1, *)
    public var horizontalScrollIndicatorInsets: UIEdgeInsets {
        get {
            return self.view.horizontalScrollIndicatorInsets
        }
        set {
            self.view.horizontalScrollIndicatorInsets = newValue
        }
    }

    public var scrollIndicatorInsets: UIEdgeInsets {
        get {
            return self.view.scrollIndicatorInsets
        }
        set {
            self.view.scrollIndicatorInsets = newValue
        }
    }

    public var decelerationRate: UIScrollView.DecelerationRate {
        get {
            return self.view.decelerationRate
        }
        set {
            self.view.decelerationRate = newValue
        }
    }

    public var indexDisplayMode: UIScrollView.IndexDisplayMode {
        get {
            return self.view.indexDisplayMode
        }
        set {
            self.view.indexDisplayMode = newValue
        }
    }

    public func setContentOffset(_ contentOffset: CGPoint, animated: Bool) {
        self.view.setContentOffset(contentOffset, animated: animated)
    }

    public func scrollRectToVisible(_ rect: CGRect, animated: Bool) {
        self.view.scrollRectToVisible(rect, animated: animated)
    }

    public func flashScrollIndicators() {
        self.view.flashScrollIndicators()
    }

    public var isTracking: Bool {
        return self.view.isTracking
    }

    public var isDragging: Bool {
        return self.view.isDragging
    }

    public var isDecelerating: Bool {
        return self.view.isDecelerating
    }

    public var delaysContentTouches: Bool {
        get {
            return self.view.delaysContentTouches
        }
        set {
            self.view.delaysContentTouches = newValue
        }
    }

    public var canCancelContentTouches: Bool {
        get {
            return self.view.canCancelContentTouches
        }
        set {
            self.view.canCancelContentTouches = newValue
        }
    }

    public func touchesShouldBegin(_ touches: Set<UITouch>, with event: UIEvent?, in view: UIView) -> Bool {
        self.view.touchesShouldBegin(touches, with: event, in: view)
    }

    public func touchesShouldCancel(in view: UIView) -> Bool {
        return self.view.touchesShouldCancel(in: view)
    }

    public var minimumZoomScale: CGFloat {
        get {
            return self.view.minimumZoomScale
        }
        set {
            self.view.minimumZoomScale = newValue
        }
    }

    public var maximumZoomScale: CGFloat {
        get {
            return self.view.maximumZoomScale
        }
        set {
            self.view.maximumZoomScale = newValue
        }
    }

    public var zoomScale: CGFloat {
        get {
            return self.view.zoomScale
        }
        set {
            self.view.zoomScale = newValue
        }
    }

    public func setZoomScale(_ scale: CGFloat, animated: Bool) {
        self.view.setZoomScale(scale, animated: animated)
    }

    public func zoom(to rect: CGRect, animated: Bool) {
        self.view.zoom(to: rect, animated: animated)
    }

    public var bouncesZoom: Bool {
        get {
            return self.view.bouncesZoom
        }
        set {
            self.view.bouncesZoom = newValue
        }
    }

    public var isZooming: Bool {
        return self.view.isZooming
    }

    public var isZoomBouncing: Bool {
        return self.view.isZoomBouncing
    }

    public var scrollsToTop: Bool {
        get {
            return self.view.scrollsToTop
        }
        set {
            self.view.scrollsToTop = newValue
        }
    }

    public var panGestureRecognizer: UIPanGestureRecognizer {
        return self.view.panGestureRecognizer
    }

    public var pinchGestureRecognizer: UIPinchGestureRecognizer? {
        return self.view.pinchGestureRecognizer
    }

    public var directionalPressGestureRecognizer: UIGestureRecognizer {
        return self.view.directionalPressGestureRecognizer
    }

    public var keyboardDismissMode: UIScrollView.KeyboardDismissMode {
        get {
            return self.view.keyboardDismissMode
        }
        set {
            self.view.keyboardDismissMode = newValue
        }
    }

    public var refreshControl: UIRefreshControl? {
        get {
            return self.view.refreshControl
        }
        set {
            self.view.refreshControl = newValue
        }
    }

}

extension ASTableNode: RXCScrollViewLikeObjectProtocol {

    public var contentSize: CGSize {
        get {
            return self.view.contentSize
        }
        set {
            self.view.contentSize = newValue
        }
    }

    public var adjustedContentInset: UIEdgeInsets {
        return self.view.adjustedContentInset
    }

    public func adjustedContentInsetDidChange() {
        return self.view.adjustedContentInsetDidChange()
    }

    public var contentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior {
        get {
            return self.view.contentInsetAdjustmentBehavior
        }
        set {
            self.view.contentInsetAdjustmentBehavior = newValue
        }
    }

    @available(iOS 13.0, *)
    public var automaticallyAdjustsScrollIndicatorInsets: Bool {
        get {
            return self.view.automaticallyAdjustsScrollIndicatorInsets
        }
        set {
            self.view.automaticallyAdjustsScrollIndicatorInsets = newValue
        }
    }

    public var contentLayoutGuide: UILayoutGuide {
        return self.view.contentLayoutGuide
    }

    public var frameLayoutGuide: UILayoutGuide {
        return self.view.frameLayoutGuide
    }

    public var isDirectionalLockEnabled: Bool {
        get {
            return self.view.isDirectionalLockEnabled
        }
        set {
            self.view.isDirectionalLockEnabled = newValue
        }
    }

    public var bounces: Bool {
        get {
            return self.view.bounces
        }
        set {
            self.view.bounces = newValue
        }
    }

    public var alwaysBounceVertical: Bool {
        get {
            return self.view.alwaysBounceVertical
        }
        set {
            self.view.alwaysBounceVertical = newValue
        }
    }

    public var alwaysBounceHorizontal: Bool {
        get {
            return self.view.alwaysBounceHorizontal
        }
        set {
            self.view.alwaysBounceHorizontal = newValue
        }
    }

    public var isPagingEnabled: Bool {
        get {
            return self.view.isPagingEnabled
        }
        set {
            self.view.isPagingEnabled = newValue
        }
    }

    public var isScrollEnabled: Bool {
        get {
            return self.view.isScrollEnabled
        }
        set {
            self.view.isScrollEnabled = newValue
        }
    }

    public var showsVerticalScrollIndicator: Bool {
        get {
            return self.view.showsVerticalScrollIndicator
        }
        set {
            self.view.showsVerticalScrollIndicator = newValue
        }
    }

    public var showsHorizontalScrollIndicator: Bool {
        get {
            return self.view.showsHorizontalScrollIndicator
        }
        set {
            self.view.showsHorizontalScrollIndicator = newValue
        }
    }

    public var indicatorStyle: UIScrollView.IndicatorStyle {
        get {
            return self.view.indicatorStyle
        }
        set {
            self.view.indicatorStyle = newValue
        }
    }

    @available(iOS 11.1, *)
    public var verticalScrollIndicatorInsets: UIEdgeInsets {
        get {
            return self.view.verticalScrollIndicatorInsets
        }
        set {
            self.view.verticalScrollIndicatorInsets = newValue
        }
    }

    @available(iOS 11.1, *)
    public var horizontalScrollIndicatorInsets: UIEdgeInsets {
        get {
            return self.view.horizontalScrollIndicatorInsets
        }
        set {
            self.view.horizontalScrollIndicatorInsets = newValue
        }
    }

    public var scrollIndicatorInsets: UIEdgeInsets {
        get {
            return self.view.scrollIndicatorInsets
        }
        set {
            self.view.scrollIndicatorInsets = newValue
        }
    }

    public var decelerationRate: UIScrollView.DecelerationRate {
        get {
            return self.view.decelerationRate
        }
        set {
            self.view.decelerationRate = newValue
        }
    }

    public var indexDisplayMode: UIScrollView.IndexDisplayMode {
        get {
            return self.view.indexDisplayMode
        }
        set {
            self.view.indexDisplayMode = newValue
        }
    }

    public func scrollRectToVisible(_ rect: CGRect, animated: Bool) {
        self.view.scrollRectToVisible(rect, animated: animated)
    }

    public func flashScrollIndicators() {
        self.view.flashScrollIndicators()
    }

    public var isTracking: Bool {
        return self.view.isTracking
    }

    public var isDragging: Bool {
        return self.view.isDragging
    }

    public var isDecelerating: Bool {
        return self.view.isDecelerating
    }

    public var delaysContentTouches: Bool {
        get {
            return self.view.delaysContentTouches
        }
        set {
            self.view.delaysContentTouches = newValue
        }
    }

    public var canCancelContentTouches: Bool {
        get {
            return self.view.canCancelContentTouches
        }
        set {
            self.view.canCancelContentTouches = newValue
        }
    }

    public func touchesShouldBegin(_ touches: Set<UITouch>, with event: UIEvent?, in view: UIView) -> Bool {
        self.view.touchesShouldBegin(touches, with: event, in: view)
    }

    public func touchesShouldCancel(in view: UIView) -> Bool {
        return self.view.touchesShouldCancel(in: view)
    }

    public var minimumZoomScale: CGFloat {
        get {
            return self.view.minimumZoomScale
        }
        set {
            self.view.minimumZoomScale = newValue
        }
    }

    public var maximumZoomScale: CGFloat {
        get {
            return self.view.maximumZoomScale
        }
        set {
            self.view.maximumZoomScale = newValue
        }
    }

    public var zoomScale: CGFloat {
        get {
            return self.view.zoomScale
        }
        set {
            self.view.zoomScale = newValue
        }
    }

    public func setZoomScale(_ scale: CGFloat, animated: Bool) {
        self.view.setZoomScale(scale, animated: animated)
    }

    public func zoom(to rect: CGRect, animated: Bool) {
        self.view.zoom(to: rect, animated: animated)
    }

    public var bouncesZoom: Bool {
        get {
            return self.view.bouncesZoom
        }
        set {
            self.view.bouncesZoom = newValue
        }
    }

    public var isZooming: Bool {
        return self.view.isZooming
    }

    public var isZoomBouncing: Bool {
        return self.view.isZoomBouncing
    }

    public var scrollsToTop: Bool {
        get {
            return self.view.scrollsToTop
        }
        set {
            self.view.scrollsToTop = newValue
        }
    }

    public var panGestureRecognizer: UIPanGestureRecognizer {
        return self.view.panGestureRecognizer
    }

    public var pinchGestureRecognizer: UIPinchGestureRecognizer? {
        return self.view.pinchGestureRecognizer
    }

    public var directionalPressGestureRecognizer: UIGestureRecognizer {
        return self.view.directionalPressGestureRecognizer
    }

    public var keyboardDismissMode: UIScrollView.KeyboardDismissMode {
        get {
            return self.view.keyboardDismissMode
        }
        set {
            self.view.keyboardDismissMode = newValue
        }
    }

    public var refreshControl: UIRefreshControl? {
        get {
            return self.view.refreshControl
        }
        set {
            self.view.refreshControl = newValue
        }
    }

}

extension ASCollectionNode {

    public var contentSize: CGSize {
        get {
            return self.view.contentSize
        }
        set {
            self.view.contentSize = newValue
        }
    }

    public var adjustedContentInset: UIEdgeInsets {
        return self.view.adjustedContentInset
    }

    public func adjustedContentInsetDidChange() {
        return self.view.adjustedContentInsetDidChange()
    }

    public var contentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior {
        get {
            return self.view.contentInsetAdjustmentBehavior
        }
        set {
            self.view.contentInsetAdjustmentBehavior = newValue
        }
    }

    @available(iOS 13.0, *)
    public var automaticallyAdjustsScrollIndicatorInsets: Bool {
        get {
            return self.view.automaticallyAdjustsScrollIndicatorInsets
        }
        set {
            self.view.automaticallyAdjustsScrollIndicatorInsets = newValue
        }
    }

    public var contentLayoutGuide: UILayoutGuide {
        return self.view.contentLayoutGuide
    }

    public var frameLayoutGuide: UILayoutGuide {
        return self.view.frameLayoutGuide
    }

    public var isDirectionalLockEnabled: Bool {
        get {
            return self.view.isDirectionalLockEnabled
        }
        set {
            self.view.isDirectionalLockEnabled = newValue
        }
    }

    public var bounces: Bool {
        get {
            return self.view.bounces
        }
        set {
            self.view.bounces = newValue
        }
    }

    public var alwaysBounceVertical: Bool {
        get {
            return self.view.alwaysBounceVertical
        }
        set {
            self.view.alwaysBounceVertical = newValue
        }
    }

    public var alwaysBounceHorizontal: Bool {
        get {
            return self.view.alwaysBounceHorizontal
        }
        set {
            self.view.alwaysBounceHorizontal = newValue
        }
    }

    public var isPagingEnabled: Bool {
        get {
            return self.view.isPagingEnabled
        }
        set {
            self.view.isPagingEnabled = newValue
        }
    }

    public var isScrollEnabled: Bool {
        get {
            return self.view.isScrollEnabled
        }
        set {
            self.view.isScrollEnabled = newValue
        }
    }

    public var showsVerticalScrollIndicator: Bool {
        get {
            return self.view.showsVerticalScrollIndicator
        }
        set {
            self.view.showsVerticalScrollIndicator = newValue
        }
    }

    public var showsHorizontalScrollIndicator: Bool {
        get {
            return self.view.showsHorizontalScrollIndicator
        }
        set {
            self.view.showsHorizontalScrollIndicator = newValue
        }
    }

    public var indicatorStyle: UIScrollView.IndicatorStyle {
        get {
            return self.view.indicatorStyle
        }
        set {
            self.view.indicatorStyle = newValue
        }
    }

    @available(iOS 11.1, *)
    public var verticalScrollIndicatorInsets: UIEdgeInsets {
        get {
            return self.view.verticalScrollIndicatorInsets
        }
        set {
            self.view.verticalScrollIndicatorInsets = newValue
        }
    }

    @available(iOS 11.1, *)
    public var horizontalScrollIndicatorInsets: UIEdgeInsets {
        get {
            return self.view.horizontalScrollIndicatorInsets
        }
        set {
            self.view.horizontalScrollIndicatorInsets = newValue
        }
    }

    public var scrollIndicatorInsets: UIEdgeInsets {
        get {
            return self.view.scrollIndicatorInsets
        }
        set {
            self.view.scrollIndicatorInsets = newValue
        }
    }

    public var decelerationRate: UIScrollView.DecelerationRate {
        get {
            return self.view.decelerationRate
        }
        set {
            self.view.decelerationRate = newValue
        }
    }

    public var indexDisplayMode: UIScrollView.IndexDisplayMode {
        get {
            return self.view.indexDisplayMode
        }
        set {
            self.view.indexDisplayMode = newValue
        }
    }

    public func scrollRectToVisible(_ rect: CGRect, animated: Bool) {
        self.view.scrollRectToVisible(rect, animated: animated)
    }

    public func flashScrollIndicators() {
        self.view.flashScrollIndicators()
    }

    public var isTracking: Bool {
        return self.view.isTracking
    }

    public var isDragging: Bool {
        return self.view.isDragging
    }

    public var isDecelerating: Bool {
        return self.view.isDecelerating
    }

    public var delaysContentTouches: Bool {
        get {
            return self.view.delaysContentTouches
        }
        set {
            self.view.delaysContentTouches = newValue
        }
    }

    public var canCancelContentTouches: Bool {
        get {
            return self.view.canCancelContentTouches
        }
        set {
            self.view.canCancelContentTouches = newValue
        }
    }

    public func touchesShouldBegin(_ touches: Set<UITouch>, with event: UIEvent?, in view: UIView) -> Bool {
        self.view.touchesShouldBegin(touches, with: event, in: view)
    }

    public func touchesShouldCancel(in view: UIView) -> Bool {
        return self.view.touchesShouldCancel(in: view)
    }

    public var minimumZoomScale: CGFloat {
        get {
            return self.view.minimumZoomScale
        }
        set {
            self.view.minimumZoomScale = newValue
        }
    }

    public var maximumZoomScale: CGFloat {
        get {
            return self.view.maximumZoomScale
        }
        set {
            self.view.maximumZoomScale = newValue
        }
    }

    public var zoomScale: CGFloat {
        get {
            return self.view.zoomScale
        }
        set {
            self.view.zoomScale = newValue
        }
    }

    public func setZoomScale(_ scale: CGFloat, animated: Bool) {
        self.view.setZoomScale(scale, animated: animated)
    }

    public func zoom(to rect: CGRect, animated: Bool) {
        self.view.zoom(to: rect, animated: animated)
    }

    public var bouncesZoom: Bool {
        get {
            return self.view.bouncesZoom
        }
        set {
            self.view.bouncesZoom = newValue
        }
    }

    public var isZooming: Bool {
        return self.view.isZooming
    }

    public var isZoomBouncing: Bool {
        return self.view.isZoomBouncing
    }

    public var scrollsToTop: Bool {
        get {
            return self.view.scrollsToTop
        }
        set {
            self.view.scrollsToTop = newValue
        }
    }

    public var panGestureRecognizer: UIPanGestureRecognizer {
        return self.view.panGestureRecognizer
    }

    public var pinchGestureRecognizer: UIPinchGestureRecognizer? {
        return self.view.pinchGestureRecognizer
    }

    public var directionalPressGestureRecognizer: UIGestureRecognizer {
        return self.view.directionalPressGestureRecognizer
    }

    public var keyboardDismissMode: UIScrollView.KeyboardDismissMode {
        get {
            return self.view.keyboardDismissMode
        }
        set {
            self.view.keyboardDismissMode = newValue
        }
    }

    public var refreshControl: UIRefreshControl? {
        get {
            return self.view.refreshControl
        }
        set {
            self.view.refreshControl = newValue
        }
    }

}

#endif
