//
//  ZTTableViewController.swift
//  ZTTableViewTest
//
//  Created by 络威信 on 2018/8/7.
//  Copyright © 2018年 周涛. All rights reserved.
//

import Foundation
import UIKit


class ZTTableViewController: UITableViewController, SwipeBtnAndDragDelegate {
    private var cellArray1 = [1,2,3,4,5,6,7,8,9]
    private var cellArray2 = [1,2,3,4,5,6,7,8,9]
    private var cellArray3 = [1,2,3,4,5,6,7,8,9]
    private var sectionArray = [1,2,3]
    //MARK:- private property
   // private var swipBtns:[UIButton] = [UIButton]()
   // weak var swipeBtnDelegate: SwipeBtnDelegate?
    private let cellHeight: CGFloat = 100
    override func viewDidLoad() {
        (self.tableView as! ZTTableView).configSwipeDelegate = self
        (self.tableView as! ZTTableView).isCanDragSrot = true
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return self.cellArray1.count
        } else if section == 1 {
            return self.cellArray2.count
        } else {
            return self.cellArray3.count
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.sectionArray.count
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        var headerView: UIView?
        let headerID = "header"
        headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerID)
        if headerView == nil {
            headerView = UITableViewHeaderFooterView(reuseIdentifier: headerID)
        }
        if headerView != nil {
            let titleLabel = UILabel(frame: CGRect(x: 10, y: 10, width: 100, height: 25))
            titleLabel.text = "head: \(self.sectionArray[section])"
            headerView?.addSubview(titleLabel)
        }
        return headerView
    }
    
    /*@available(iOS 11.0, *)
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: UIContextualAction.Style.normal, title: "delete") { (_, _, _) in
            print("delete")
        }
        let okAction = UIContextualAction(style: UIContextualAction.Style.normal, title: "ok") { (_, _, _) in
            print("ok")
        }
        let actions = UISwipeActionsConfiguration(actions: [deleteAction, okAction])
        actions.performsFirstActionWithFullSwipe = false
        return actions
    }*/
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "testCell")
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "testCell")
        }
        let tmp:[Int]
        let tmpSection = self.sectionArray[indexPath.section]
        if tmpSection == 1 {
            tmp = self.cellArray1
        } else if tmpSection == 2 {
            tmp = self.cellArray2
        } else {
            tmp = self.cellArray3
        }
        cell?.alpha = 0
        cell?.textLabel?.text = "testcell: \(sectionArray[indexPath.section]) --- \(tmp[indexPath.row])"
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: "delete") { (_, _) in
            print("delete")
        }
        let okAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: "ok") { (_, _) in
            print("ok")
        }
        return [deleteAction, okAction]
    }
    
    override func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        (self.tableView as! ZTTableView).editingIndexPath = indexPath
        self.tableView.setNeedsLayout() //触发layoutSubviews方法
    }
    
    override func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        (self.tableView as! ZTTableView).editingIndexPath = nil
    }
    
    
    //MARK:- Delegate
    func setupSwipeBtns(_ btns: [UIButton]) {
        for (n,btn) in btns.enumerated() {
            
            
            if n == 0 {
                btn.backgroundColor = UIColor.red
                btn.setImage(#imageLiteral(resourceName: "light"), for: UIControlState.normal)
            } else {
                btn.backgroundColor = UIColor.blue
                btn.setImage(#imageLiteral(resourceName: "light"), for: UIControlState.normal)
            }
            
            btn.imageView?.backgroundColor = UIColor.green
            //btn.titleLabel?.backgroundColor = UIColor.yellow
            //ios11中不用设置图像和文字的位置，自动文字在下，图片在上，设置了也无效果
            if #available(iOS 11.0, *) {
               continue
            }
            setImageAndTextOnButton(btn)
        }
    }
    //更新数据源
    func updateDataSource(isHeader: Bool, orignalIndexPath: IndexPath, destIndexPath: IndexPath) {
        if isHeader {
            let orign = orignalIndexPath.section
            let dest = destIndexPath.section
            self.sectionArray.swapAt(orign, dest)
        } else {
           // let tmp:[Int]
            if orignalIndexPath.section == 0 {
                self.cellArray1.swapAt(orignalIndexPath.row, destIndexPath.row)
            } else if orignalIndexPath.section == 1 {
                self.cellArray2.swapAt(orignalIndexPath.row, destIndexPath.row)
            } else {
                self.cellArray3.swapAt(orignalIndexPath.row, destIndexPath.row)
            }
        }
    }
    
    //MARK:- Private
    
    //设置button中的图片和文字
    private func setImageAndTextOnButton(_ button: UIButton) {
        let space: CGFloat = 5
        let btnW = button.bounds.width
        let btnH = button.bounds.height
        
        let imageSize = button.imageView?.bounds.size //图片大小
        //获取文字size
        let titleSize = (button.titleLabel!.text! as NSString).size(withAttributes: [NSAttributedStringKey.font : button.titleLabel!.font])
        
        //设置居中
        button.imageView?.frame.origin.x = (btnW - imageSize!.width) / 2
        button.imageView?.frame.origin.y = (btnH - imageSize!.height - space - titleSize.height ) / 2
        
        button.titleLabel?.frame.origin.x = (btnW - titleSize.width) / 2
        button.titleLabel?.frame.origin.y = (button.imageView?.frame.maxY)! + space
        
        
        /*
         Note: imageview可以通过button.imageEdgeInsets修改位置
         但titleLael不能通过button.titleEdgeInsets修改位置；原因不明（6s,ios 9.2下测试）
         */
        
        //button.imageView?.bounds = CGRect(x: 0, y: 0, width: cellHeight/2, height: cellHeight/2)
        //button.contentVerticalAlignment = .bottom
        
       
        //button.imageEdgeInsets = UIEdgeInsetsMake(0,0, titleSize.height + space, -titleSize.width)
        
        
       // button.titleEdgeInsets = UIEdgeInsetsMake(imageSize!.height + space, -imageSize!.width,0 ,0)
        //button.titleLabel?.frame.origin.y += space
        
        //let edgeOffset = (cellHeight - titleSize.height - imageSize!.height) / 2.0
        //button.contentEdgeInsets = UIEdgeInsetsMake(30, 0, 0, 0)
    }
    
   
}
