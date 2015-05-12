//
//  BTSwitchMallView.swift
//  BeaconTool
//
//  Created by YunTop on 14/12/8.
//  Copyright (c) 2014年 YunTop. All rights reserved.
//

import UIKit
let kBTDefaultTableViewHeight:CGFloat = 4 * 35;
class BTSwitchMallView: UIView,UITableViewDelegate,UITableViewDataSource {
    weak var dataSource: BTSwitchMallDataSource?;
    weak var delegate: BTSwitchMallDelegate?;
    
    private var backgroundView:UIView?;
    private var allRow:Int?;
    private var mallButton:UIButton?;
    private var promptLabel:UILabel?;
    private var tableViewMall:UITableView?;
    private var floorButton:UIButton?;
    private var tableViewFloor:UITableView?;
    private var screenBounds:CGRect = UIScreen.mainScreen().bounds;
    private var malls:NSMutableArray?;
    private var floors:NSMutableArray?;
    private var revise:Bool = false;
    private var zoomOutButton:UIButton?;
    
    init(defaultMall:BTMall){
        super.init(frame: CGRectMake(50, 0, CGRectGetWidth(self.screenBounds) - 100, 120));
        self.backgroundView = UIView(frame: CGRectMake(0, 10, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame)));
        self.floors = NSMutableArray(array: defaultMall.floos);
        self.addSubview(self.backgroundView!);
        
        self.mallButton = UIButton(frame: CGRectMake(10, 25, CGRectGetWidth(self.frame) - 20, 45));
        self.mallButton?.addTarget(self, action: "mallDownPull:", forControlEvents: UIControlEvents.TouchUpInside);
        self.mallButton?.setImage(UIImage(named: "Map_img_switchArrow_down"), forState: UIControlState.Normal);
        self.mallButton?.setImage(UIImage(named: "Map_img_switchArrow_up"), forState: UIControlState.Selected);
        self.mallButton?.setTitle(defaultMall.name as String, forState: UIControlState.Normal);
        self.addSubview(self.mallButton!);
        
        self.tableViewMall = UITableView(frame: CGRectMake(10, CGRectGetMaxY(self.mallButton!.frame) - 5, CGRectGetWidth(self.mallButton!.frame), kBTDefaultTableViewHeight));
        self.tableViewMall?.delegate = self;
        self.tableViewMall?.dataSource = self;
        self.tableViewMall?.hidden = true;
        self.insertSubview(self.tableViewMall!, belowSubview: self.mallButton!);
        
        self.zoomOutButton = UIButton(frame: CGRectMake(CGRectGetMaxX(self.backgroundView!.frame) - 15, 0, 20, 20));
        self.zoomOutButton?.addTarget(self, action: "zoomOut:", forControlEvents: UIControlEvents.TouchUpInside);
        self.addSubview(self.zoomOutButton!);
        
        self.floorButton = UIButton(frame: CGRectMake(20, CGRectGetMaxY(self.mallButton!.frame) + 10, CGRectGetWidth(self.mallButton!.frame) - 20, 35));
        self.floorButton?.setImage(UIImage(named: "Map_img_switchArrow_down"), forState: UIControlState.Normal);
        self.floorButton?.setImage(UIImage(named: "Map_img_switchArrow_up"), forState: UIControlState.Selected);
        self.floorButton?.setTitle((self.floors?.firstObject as! BTFloor).name as String, forState: UIControlState.Normal);
        self.floorButton?.addTarget(self, action: "floorDownPull:", forControlEvents: UIControlEvents.TouchUpInside);
        self.insertSubview(self.floorButton!, belowSubview: self.tableViewMall!);
        
        self.tableViewFloor = UITableView(frame: CGRectMake(20, CGRectGetMaxY(self.floorButton!.frame) - 5, CGRectGetWidth(self.floorButton!.frame),70));
        self.tableViewFloor?.delegate = self;
        self.tableViewFloor?.dataSource = self;
        self.tableViewFloor?.rowHeight = 35;
        self.tableViewFloor?.hidden = true;
        self.insertSubview(self.tableViewFloor!, belowSubview: self.floorButton!);
        
        self.center = CGPointMake(CGRectGetWidth(self.screenBounds) / 2, CGRectGetHeight(self.screenBounds) / 2 - 25);
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    internal override func layoutSubviews() {
        self.backgroundView!.layer.cornerRadius = 10;
        self.backgroundView!.backgroundColor = UIColor(string: "000000", alpha: 0.7);
        
        self.mallButton?.backgroundColor = UIColor(string: "505050", alpha: 1.0);
        self.mallButton?.layer.cornerRadius = 5;
        self.mallButton?.setTitleColor(UIColor(string: "ffffff", alpha: 1.0), forState: UIControlState.Normal);
        self.mallButton?.titleEdgeInsets = UIEdgeInsetsMake(0, -10, 0, 0);
        self.mallButton?.imageEdgeInsets = UIEdgeInsetsMake(0, CGRectGetWidth(self.mallButton!.frame) - 30, 0, 0);
        self.mallButton?.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left;
        
        self.floorButton?.backgroundColor = UIColor(string: "505050", alpha: 1.0);
        self.floorButton?.layer.cornerRadius = 5;
        self.floorButton?.setTitleColor(UIColor(string: "ffffff", alpha: 1.0), forState: UIControlState.Normal);
        self.floorButton?.titleEdgeInsets = UIEdgeInsetsMake(0, -10, 0, 0);
        self.floorButton?.imageEdgeInsets = UIEdgeInsetsMake(0, CGRectGetWidth(self.floorButton!.frame) - 30, 0, 0);
        self.floorButton?.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left;
        
        
        self.tableViewMall?.backgroundColor = UIColor.clearColor();
        self.tableViewMall?.showsVerticalScrollIndicator = false;
        self.tableViewMall?.layer.cornerRadius = 5;
        
        self.tableViewFloor?.backgroundColor = UIColor.clearColor();
        self.tableViewFloor?.showsVerticalScrollIndicator = false;
        self.tableViewFloor?.layer.cornerRadius = 5;
        
        self.zoomOutButton?.setTitle("-", forState: UIControlState.Normal);
        self.zoomOutButton?.titleEdgeInsets = UIEdgeInsets(top: -3, left: 2, bottom: 0, right: 0);
        self.zoomOutButton?.titleLabel?.font = UIFont.systemFontOfSize(24);
        self.zoomOutButton?.backgroundColor = UIColor(string: "505050", alpha: 1.0);
        self.zoomOutButton!.layer.cornerRadius = CGRectGetWidth(self.zoomOutButton!.frame) / 2;
    
    }
    
    internal func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        if (tableView.isEqual(self.tableViewMall)){
            self.allRow = self.dataSource!.switchMall(self);
            if (self.malls == nil){
                var malls:NSArray = self.dataSource!.switchMall(self, sectionAtIndex: section);
                
                self.malls = NSMutableArray(array: malls);
            }
            return self.allRow!;
        }else{
            return self.floors!.count;
        }
    }

    
    internal func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        var cell:UITableViewCell? = nil;
        if (tableView.isEqual(self.tableViewMall)){
            cell = tableView.dequeueReusableCellWithIdentifier("MallCell") as? UITableViewCell;
            if  (cell == nil){
                cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "MallCell");
                cell!.backgroundColor = UIColor(string: "606060", alpha: 1.0);
                cell!.textLabel?.textColor = UIColor(string: "f1f1f1", alpha: 1.0);
                cell!.textLabel?.font = UIFont.systemFontOfSize(16);
            }
            
            
            var tmpMall:BTMall = self.malls![indexPath.row] as! BTMall;
            
            cell!.textLabel?.text = tmpMall.name as String;
        }else{
            cell = tableView.dequeueReusableCellWithIdentifier("FloorCell") as? UITableViewCell;
            if  (cell == nil){
                cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "FloorCell");
                cell!.backgroundColor = UIColor(string: "606060", alpha: 1.0);
                cell!.textLabel?.textColor = UIColor(string: "f1f1f1", alpha: 1.0);
                cell!.textLabel?.font = UIFont.systemFontOfSize(16);
            }
            var tmpFloor:BTFloor = self.floors![indexPath.row] as! BTFloor;
            cell!.textLabel?.text = tmpFloor.name as String;
        }
       
        return cell!;
    }
    
    internal func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (tableView.isEqual(self.tableViewMall)){
            tableView.deselectRowAtIndexPath(indexPath, animated: false);
            self.mallDownPull(self.mallButton!);
            var tmpMall:BTMall?;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                tmpMall = self.malls![indexPath.row] as? BTMall;
                self.floors?.removeAllObjects();
                self.floors = NSMutableArray(array: tmpMall!.floos);
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.mallButton?.setTitle(tmpMall!.name as String, forState: UIControlState.Normal);
                    self.floorButton?.setTitle((tmpMall!.floos.firstObject as! BTFloor).name as String, forState: UIControlState.Normal);
                    
                    self.tableViewFloor?.reloadData();
                    self.tableViewFloor?.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: UITableViewScrollPosition.Top, animated: false);
                    if (self.delegate!.respondsToSelector("switchMall:selectFloor:")){
                        self.delegate!.switchMall!(self, selectFloor: self.floors?.firstObject as! BTFloor);
                    }
                })
            })
            
        }else{
            self.floorDownPull(self.floorButton!);
            var tmpFloor:BTFloor = self.floors![indexPath.row] as! BTFloor;
            tableView.deselectRowAtIndexPath(indexPath, animated: false);
            if (self.delegate!.respondsToSelector("switchMall:selectFloor:")){
                self.delegate!.switchMall!(self, selectFloor: tmpFloor);
            }
            self.floorButton?.setTitle(tmpFloor.name as String, forState: UIControlState.Normal);
        }
    }
    
    internal func mallDownPull(sender:UIButton){
        sender.selected = !sender.selected;
        if (sender.selected){
            self.tableViewMall?.hidden = false;
            self.frame.size.height += 100;
        }else{
            self.tableViewMall?.hidden = true;
            self.frame.size.height -= 100;
        }
    }
    
    internal func floorDownPull(sender:UIButton){
        sender.selected = !sender.selected;
        if (sender.selected){
            self.tableViewFloor?.hidden = false;
            self.frame.size.height += 100;
        }else{
            self.tableViewFloor?.hidden = true;
            self.frame.size.height -= 100;
        }
    }
    
    internal func zoomOut(sender:UIButton){
         var point:CGPoint = CGPointMake(0 - self.center.x, 0 - self.center.y);
        if (self.dataSource!.respondsToSelector("switchMall:defaultPosistion:")){
            var poisiton:CGPoint = self.dataSource!.switchMall!(self, defaultPosistion: point);
            point = CGPointMake(poisiton.x - self.center.x, poisiton.y - self.center.y);
        }
        UIView.animateWithDuration(0.5, animations: { () -> Void in
        self.transform = CGAffineTransformMake(0, 0, 0, 0, point.x, point.y);
        }) { (completion) -> Void in
            if (self.delegate!.respondsToSelector("switchMall:zoomOutButtonClicked:")){
                self.delegate!.switchMall!(self, zoomOutButtonClicked: true);
            }
            self.hidden = true;
        }
    }

    
    func zoomIn(){
        self.hidden = false;
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.transform = CGAffineTransformIdentity;
            }) { (completion) -> Void in
                
        }
    }
    
    func switchMallView(changeMall mall:BTMall,changeFloor floor:BTFloor){
        self.mallButton?.setTitle(mall.name as String, forState: UIControlState.Normal);
        self.floorButton?.setTitle(floor.name as String, forState: UIControlState.Normal);
        self.floors?.removeAllObjects();
        self.floors = nil;
        self.floors = NSMutableArray(array: mall.floos);
        self.tableViewFloor?.reloadData();
    }
    
    func enjoinSwitchMall(prohibit:Bool){
        if (prohibit){
            self.mallButton?.enabled = false;
        }else{
            self.mallButton?.enabled = true;
        }
    }
}

@objc protocol BTSwitchMallDelegate : NSObjectProtocol{
    optional func switchMall(switchMall:BTSwitchMallView,selectFloor floor:BTFloor);
    optional func switchMall(switchMall:BTSwitchMallView,zoomOutButtonClicked clicked:Bool);
}

@objc protocol BTSwitchMallDataSource: NSObjectProtocol{
    func switchMall(switchMall:BTSwitchMallView) -> Int;
    func switchMall(switchMall:BTSwitchMallView,sectionAtIndex index:Int) ->NSArray;
    optional func switchMall(switchMall:BTSwitchMallView,defaultPosistion:CGPoint) -> CGPoint;
}
