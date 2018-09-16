//
//  ZTTableView.swift
//  ZTTableViewTest
//
//  Created by 络威信 on 2018/8/7.
//  Copyright © 2018年 周涛. All rights reserved.
//

import Foundation
import UIKit

protocol SwipeBtnAndDragDelegate: NSObjectProtocol {
    func setupSwipeBtns(_ btns: [UIButton])
    func updateDataSource(isHeader: Bool, orignalIndexPath: IndexPath, destIndexPath: IndexPath)
}

class ZTTableView: UITableView {
    enum SnapShootMovingDirection {
        case up
        case down
    }
    
    private var autoScrollDirection: SnapShootMovingDirection! //自动滚动方向
    
    var sectionArray: [Any]?
    var cellArray:[Any]?
    var editingIndexPath: IndexPath?//正编辑的indexPath(ios 8-10可用)
    
    var isCanDragSrot: Bool = false {
        didSet{
            if self.isCanDragSrot == false {
                if self.longPressGesture != nil {
                    self.longPressGesture.isEnabled = false
                }
            } else {
                if self.longPressGesture == nil {
                    self.longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressAction(_:)))
                    self.longPressGesture.minimumPressDuration = 1
                    self.addGestureRecognizer(self.longPressGesture)
                    
                }
                self.longPressGesture.isEnabled = true
            }
        }
    } //指示是否可以拖动排序
    
    private var snapShoot: UIView! //截图
    private var orignalView: UIView! //源视图
    private var orignalIndexPath: IndexPath?
    //private var destIndexPath: IndexPath!
    private var isHeader: Bool = false //指示是否是分组头
    private var longPressGesture: UILongPressGestureRecognizer!
    private var autoScrollTimer: CADisplayLink!
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.configSwipeBtns()
    }
    
    
    weak var configSwipeDelegate: SwipeBtnAndDragDelegate?
    
    
    //MARK:- selector
    @objc private func longPressAction(_ gesture: UILongPressGestureRecognizer){
        let gestureState = gesture.state
        let currentPoint = gesture.location(in: self)
        switch gestureState {
        case UIGestureRecognizerState.began:
            let orignalPoint = currentPoint
            self.orignalIndexPath = self.indexPathForRow(at: orignalPoint)
            //第一个分组头获取的orignalPath为空，第二个分组头获取的originalPath为（section,0）
            //判读为cell还是section
            
            for index in 0 ..< self.numberOfSections {
                guard let view = self.headerView(forSection: index) else {
                    continue
                }
                
                if view.frame.contains(orignalPoint) {
                    self.isHeader = true
                    self.orignalView = view
                    self.orignalIndexPath = IndexPath(row: 0, section: index)
                    break
                }
            }
            //若为cell
            if !self.isHeader && orignalIndexPath != nil {
                let cell = self.cellForRow(at: orignalIndexPath!)
                self.orignalView = cell
            }
            guard (self.orignalView != nil) else {
                return
            }
            self.selectViewAtIndexPath(self.orignalView)
            
            break
        case UIGestureRecognizerState.changed:
            guard self.snapShoot != nil else {
                return
            }
            var center = snapShoot.center
            center.y = currentPoint.y
            snapShoot.center = center
            if checkIfMeetEdge() {
                self.startAutoScrollTimer()
            } else {
                self.stopAutoScrollTimer()
            }
            
            if isHeader {
                for index in 0 ..< self.numberOfSections {
                    guard let view = self.headerView(forSection: index) else {
                        continue
                    }
                    
                    if view.frame.contains(currentPoint) {
                        let destIndexPath = IndexPath(row: 0, section: index)
                        self.refreshView(indexPath: destIndexPath)
                        
                        break
                    }
                }
            } else {
                guard let destIndexPath = self.indexPathForRow(at: currentPoint) else {
                   return
                }
                self.refreshView(indexPath: destIndexPath)
                
            }
            
            break
        case UIGestureRecognizerState.ended:
            guard self.snapShoot != nil else {
                return
            }
            self.stopAutoScrollTimer()
            self.didEndDrag()
            break
        default:
            break
        }
    }
    
    //MARK:- Private
    
    private func refreshView(indexPath: IndexPath) {
        if self.configSwipeDelegate == nil {
            return
        }
        if self.isHeader {
            //更新数据源
            self.configSwipeDelegate?.updateDataSource(isHeader: true, orignalIndexPath: self.orignalIndexPath!, destIndexPath: indexPath)
            self.moveSection(self.orignalIndexPath!.section, toSection: indexPath.section)
        } else if indexPath.section == self.orignalIndexPath!.section {
            self.configSwipeDelegate?.updateDataSource(isHeader: false, orignalIndexPath: self.orignalIndexPath!, destIndexPath: indexPath)
            self.moveRow(at: self.orignalIndexPath!, to: indexPath)
        }
        self.orignalIndexPath = indexPath
    }
    
    private func startAutoScrollTimer() {
        if self.autoScrollTimer == nil {
            self.autoScrollTimer = CADisplayLink(target: self, selector: #selector(startAutoScroll))
            self.autoScrollTimer.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
        }
    }
    
    private func stopAutoScrollTimer() {
        if self.autoScrollTimer != nil {
            self.autoScrollTimer.invalidate()
            self.autoScrollTimer = nil
        }
    }
    
    @objc private func startAutoScroll() {
        let speed: CGFloat = 4.0
        if self.autoScrollDirection == SnapShootMovingDirection.up {
            //向上滚动
            if self.contentOffset.y > 0 {
                self.contentOffset = CGPoint(x: 0, y: self.contentOffset.y - speed)
                let center = self.snapShoot.center
                self.snapShoot.center = CGPoint(x: center.x, y: center.y - speed)
            }
        } else {
            //向下滚动
            if self.contentOffset.y + self.frame.height < self.snapShoot.frame.maxY {
                self.contentOffset = CGPoint(x: 0, y: self.contentOffset.y + speed)
                let center = self.snapShoot.center
                self.snapShoot.center = CGPoint(x: center.x, y: center.y + speed)
            }
        }
        let center = self.snapShoot.center
        /*  当把截图拖动到边缘，开始自动滚动，如果这时手指完全不动，则不会触发‘UIGestureRecognizerStateChanged’，对应的代码就不会执行，导致虽然截图在tableView中的位置变了，但并没有移动那个隐藏的cell，用下面代码可解决此问题，cell会随着截图的移动而移动
         */
        if isHeader {
            for index in 0 ..< self.numberOfSections {
                guard let view = self.headerView(forSection: index) else {
                    continue
                }
                
                if view.frame.contains(center) {
                    let destIndexPath = IndexPath(row: 0, section: index)
                    self.refreshView(indexPath: destIndexPath)
                    
                    break
                }
            }
        } else {
            guard let destIndexPath = self.indexPathForRow(at: center) else {
                return
            }
            self.refreshView(indexPath: destIndexPath)
            
        }
        
    }
    
    //检测是否碰到边界
    private func checkIfMeetEdge() -> Bool {
        let minY = self.snapShoot.frame.minY
        let maxY = self.snapShoot.frame.maxY
        if minY < self.contentOffset.y {
            self.autoScrollDirection = SnapShootMovingDirection.up
            return true
        }
        if maxY > self.contentOffset.y + self.bounds.size.height {
            self.autoScrollDirection = SnapShootMovingDirection.down
            return true
        }
        return false
    }
    
    
    private func selectViewAtIndexPath(_ inputView: UIView){
        self.snapShoot = self.getSnapShootFromView(self.orignalView)
        
        self.addSubview(self.snapShoot)
        self.bringSubview(toFront: self.snapShoot)
        self.orignalView.isHidden = true
        
        UIView.animate(withDuration: 0.2) {
            self.snapShoot.transform = CGAffineTransform.init(scaleX: 1.03, y: 1.03)
            
        }
        
    }
    
    //结束拖动
    private func didEndDrag() {
        self.orignalView.isHidden = false
        self.orignalView.alpha = 0
        UIView.animate(withDuration: 0.2, animations: {
            self.snapShoot.center = self.orignalView.center
            self.snapShoot.alpha = 0
            self.transform = CGAffineTransform.identity
            self.orignalView.alpha = 1
        }) { (_) in
            self.orignalView?.isHidden = false
            self.snapShoot.removeFromSuperview()
            self.snapShoot = nil
            self.orignalIndexPath = nil
            //self.destIndexPath = nil
            self.orignalView = nil
            self.isHeader = false
        }
    }
    
    //从给定视图获取截图
    private func getSnapShootFromView(_ view: UIView) -> UIView {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let snapShot = UIImageView(image: image)
        snapShot.center = view.center
        snapShot.layer.shadowRadius = 4
        snapShot.layer.shadowOpacity = 0.4
        return snapShot
    }
    
    private func configSwipeBtns(){
        if #available(iOS 11.0, *) {
            /*uitableview视图层级：
             uitableview->UISwipeActionPullView->UISwipeActionStandardButton(左滑显示的按钮)
             */
            for subView in self.subviews {
                if subView.isKind(of: NSClassFromString("UISwipeActionPullView")!) && subView.subviews.count >= 1{
                    var tmpBtns = [UIButton]()
                    for i in 0 ..< subView.subviews.count {
                        if subView.subviews[i].isKind(of: UIButton.self) {
                            /*if !self.swipBtns.contains(subView.subviews[i] as! UIButton) {
                             self.swipBtns.append(subView.subviews[i] as! UIButton)
                             }*/
                            let btn = subView.subviews[i] as! UIButton
                            tmpBtns.append(btn)
                        }
                    }
                    if self.configSwipeDelegate != nil {
                        self.configSwipeDelegate?.setupSwipeBtns(tmpBtns)
                    }
                    tmpBtns.removeAll()
                }
            }
        }
        else {
            //ios 8-10
            /*
             uitableview->UITableViewWrapperView->UITableViewCell->UITableViewCellDeleteConfirmationView->_UITableViewCellActionButton
             */
            
            if self.editingIndexPath == nil {
                return
            }
            
            guard let cell = self.cellForRow(at: self.editingIndexPath!) else {return}
            
            for subview in cell.subviews {
                if subview.isKind(of: NSClassFromString("UITableViewCellDeleteConfirmationView")!) {
                    var tmpBtns = [UIButton]()
                    for i in 0 ..< subview.subviews.count {
                        if subview.subviews[i].isKind(of: UIButton.self) {

                            let btn = subview.subviews[i] as! UIButton
                           // btn.imageView?.bounds = CGRect(x: 0, y: 0, width: self.rowHeight/2, height: self.rowHeight/2)
                            tmpBtns.append(btn)
                        }
                    }
                    if self.configSwipeDelegate != nil {
                        self.configSwipeDelegate?.setupSwipeBtns(tmpBtns)
                    }
                    tmpBtns.removeAll()
                }
            }
            
        }
    }
}
