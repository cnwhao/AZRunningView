//
//  AZRunningView.swift
//  AZRunningView
//
//  Created by wanghaohao on 2019/8/21.
//  Copyright © 2019 whao. All rights reserved.
//

import UIKit

protocol AZRunningViewDataSource {
    func numberOfItemsAtRunningView(_ runningView:AZRunningView) -> Int
    func runningView(_ runningView:AZRunningView, itemAt index:Int) -> UIView
    func runningView(_ runningView:AZRunningView, widthOfItem index:Int) -> CGFloat
    func itemSpaceAtRunningView(_ runningView:AZRunningView) -> CGFloat
}

extension AZRunningViewDataSource {
    func runningView(_ runningView:AZRunningView, widthOfItem index:Int) -> CGFloat {
        return UIScreen.main.bounds.size.width
    }
    
    func itemSpaceAtRunningView(_ runningView:AZRunningView) -> CGFloat {
        return 30
    }
}

protocol AZRunningViewDelegate {
    func runningView(_ runningView:AZRunningView, didClickItemAt index:Int) -> Void
}

extension AZRunningViewDelegate {
    func runningView(_ runningView:AZRunningView, didClickItemAt index:Int) -> Void {
        //点击空实现，实现协议方法可选optional
    }
}

class AZRunningView: UIView {
    /// 每次动画时间内移动的距离
    var preTranslate:CGFloat = -1
    /// 事件源
    var dataSource:AZRunningViewDataSource?
    
    var delegate:AZRunningViewDelegate?
    
    /// 上一次的frame
    private var oldFrame:CGRect?
    
    /// 最后一个（动的）item下标
    private var lastAnimatedItemIndex:Int = 0
    
    /// 展示item最少超出屏幕距离
    private var beyondOffset:CGFloat = 100
    /// 注册过的item，才可以使用
    private var registedItems:[String:String] = [String:String]()
    /// 可见item数组
    private var visibleItems:Array<UIView> = Array<UIView>()
    /// 重用item数组
    private var reuseableItems:[String:AZQueue<UIView>] = [String:AZQueue<UIView>]()
    /// 帧率级别定时器
    private var timer:CADisplayLink?
    /// item宽度缓存
    private var itemWidthCache:[Int:CGFloat] = [Int:CGFloat]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.clipsToBounds = true
        self.run()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init() {
        self.init(frame:.zero)
    }
    
    override func layoutSubviews() {
        if oldFrame?.origin.x == frame.origin.x && frame.origin.y == oldFrame?.origin.y && frame.size.width == oldFrame?.size.width && frame.size.height == oldFrame?.size.height{
            return
        }
        oldFrame = frame
        self.reloadRunningViewData()
    }
    
    // MARK: 添加定时器到主Runloop
    func run() {
        self.stop()
        timer?.invalidate()
        timer = CADisplayLink(target: self, selector: #selector(timerAction))
        timer?.add(to: RunLoop.main, forMode: .tracking)
        timer?.add(to: RunLoop.main, forMode: .common)
    }
    
    // MARK: 从主Runloop移除定时器
    func stop() {
        if timer == nil {return}
        timer?.remove(from: RunLoop.main, forMode: .tracking)
        timer?.remove(from: RunLoop.main, forMode: .common)
        timer?.invalidate()
        timer = nil
    }
    
    //MARK:  注册View
    func registerItemClasse(classType:AnyClass,reuseIdentifier:String){
        registedItems[String(describing: classType)] = reuseIdentifier
    }
    
    //MARK: 获取重用item
    func dequeueItemViewResueIdentity(resueIdentity : String) -> UIView?{
        let quene = reuseableItems[resueIdentity]
        let view = quene?.dequeue()
        //        if let pro = view as? UIRunHouseItemProtocol{
        //            pro.prepareForReuse()
        //        }
        return view
    }
    
    // MARK: 定时器执行事件
    @objc private func timerAction() {
        self.visibleItems.forEach { (item) in
            item.transform = item.transform.translatedBy(x: preTranslate, y: 0)
            self.updateSubItems()
        }
    }
    
    // MARK: 更新items视图
    private func updateSubItems() {
        guard let firstItem = visibleItems.first, let lastItem = visibleItems.last else {
            return
        }
        
        // 如果第一个item移出了屏幕
        if firstItem.frame.origin.x + firstItem.frame.size.width < 0 {
            visibleItems.removeFirst()
            self.reuseableAdd(item: firstItem)
        }
        let selfWidth = self.frame.size.width
        let lastItemRight = lastItem.frame.origin.x + lastItem.frame.size.width
        // 下一个item可以跑（动画）了
        if lastItemRight <= selfWidth + beyondOffset {
            if lastAnimatedItemIndex + 1 == (dataSource?.numberOfItemsAtRunningView(self) ?? 0) {
                lastAnimatedItemIndex = 0
            } else {
                lastAnimatedItemIndex += 1
            }
            _ = self.addItemView(originX: lastItemRight + (dataSource?.itemSpaceAtRunningView(self) ?? 0))
        }
    }
    
    // MARK: 重载runningview
    private func reloadRunningViewData() {
        self.subviews.forEach { (item) in
            item.removeFromSuperview()
        }
        reuseableItems.removeAll()
        itemWidthCache.removeAll()
        guard let dataSource = dataSource else {
            print("\(self.classForCoder) error: dataSource is nil")
            return
        }
        if dataSource.numberOfItemsAtRunningView(self) == 0 {
            return
        }
        let selfWidth = frame.size.width
        var currentWidth:CGFloat = 0.0
        let itemSpace = dataSource.itemSpaceAtRunningView(self)
        
        lastAnimatedItemIndex = -1
        while currentWidth < selfWidth + itemSpace {
            if lastAnimatedItemIndex + 1 == dataSource.numberOfItemsAtRunningView(self) {
                lastAnimatedItemIndex = 0
            } else {
                lastAnimatedItemIndex += 1
            }
            let itemWidth = self.addItemView(originX: currentWidth)
            currentWidth += (itemWidth + itemSpace)
        }
    }
    
    // MARK: 重用数组添加item
    ///
    /// - Parameter item: 跑马灯里的item
    private func reuseableAdd(item:UIView) {
        guard let reuseIdentify = registedItems[String(describing: type(of: item.self))] else {
            print("\(self.classForCoder) saveError:\(item.classForCoder) reuseIdentity no regist")
            return
        }
        
        guard let itemQueue = reuseableItems[reuseIdentify] else {
            self.reuseableItems[reuseIdentify] = AZQueue(item)
            return
        }
        itemQueue.enqueue(item)
    }
    
    // MARK: 添加itemview
    ///
    /// - Parameter originX: itemview frame origin x
    /// - Returns: itemview 宽度
    private func addItemView(originX:CGFloat) -> CGFloat {
        let selfHeight = self.frame.size.height
        var itemWidth:CGFloat? = itemWidthCache[lastAnimatedItemIndex]
        guard let dataSource = self.dataSource else {
            print("\(self.classForCoder) error: dataSource is nil")
            return 0
        }
        if itemWidth == nil || itemWidth == 0 {
            itemWidth = dataSource.runningView(self, widthOfItem: lastAnimatedItemIndex)
            itemWidthCache[lastAnimatedItemIndex] = itemWidth ?? 0
        }
        
        let item = dataSource.runningView(self, itemAt: lastAnimatedItemIndex)
        item.az_setViewIndex(index: lastAnimatedItemIndex)
        item.frame = CGRect(x: originX, y: 0, width: itemWidth ?? 0, height: selfHeight)
        
        var hasGestuer:Bool = false
        item.gestureRecognizers?.forEach({ (gestureRecognizer) in
            if gestureRecognizer.view == item {
                hasGestuer = true
            }
        })
        
        if hasGestuer == false {
            let tapGesture:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGestureTapped(tapGesture:)))
            tapGesture.numberOfTapsRequired = 1
            item.addGestureRecognizer(tapGesture)
            item.isUserInteractionEnabled = true
        }
        self.addSubview(item)
        self.visibleItems.append(item)
        return itemWidth ?? 0
    }
    
    @objc private func tapGestureTapped(tapGesture:UITapGestureRecognizer) {
        if tapGesture.view == nil { return}
        let index:Int? = tapGesture.view!.az_getViewIndex()
        if index == nil {return}
        self.delegate?.runningView(self, didClickItemAt: index!)
    }
}

var AZViewIndexKey = "com.azrunningview.viewindex"
extension UIView {
    fileprivate func az_setViewIndex(index:Int) {
        objc_setAssociatedObject(self, &AZViewIndexKey, index, .OBJC_ASSOCIATION_ASSIGN)
    }
    
    fileprivate func az_getViewIndex() -> Int? {
        let index = objc_getAssociatedObject(self, &AZViewIndexKey)
        return index as? Int
    }
}
