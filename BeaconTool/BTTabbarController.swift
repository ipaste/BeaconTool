//
//  BTTabbarController.swift
//  BeaconTool
//
//  Created by YunTop on 14/12/6.
//  Copyright (c) 2014年 YunTop. All rights reserved.
//

import UIKit

class BTTabbarController: UITabBarController,UITabBarControllerDelegate {
    
    var selectedTintColor:UIColor? {
        set{
            self.tmpSelectedTintColor = newValue!;
            
            for icon in self.selectIcons {
                var icon = UIImage.image(icon as! UIImage, tintColor: newValue)!;
            }
            
            for (var index:Int = 0; index < self.selectIcons.count; index++){
                self.selectIcons[index] =  UIImage.image(self.selectIcons[index] as! UIImage, tintColor: newValue)!;
            }
            
            (titleLabels[self.selectedIndex] as! UILabel).textColor = newValue;
            (iconImageViews[self.selectedIndex] as! UIImageView).image = self.selectIcons[self.selectedIndex] as? UIImage;
            self.line?.backgroundColor = newValue;
            
        }
        get{
            return self.tmpSelectedTintColor;
        }
    }
    
    var tintColor:UIColor! {
        set{
            self.tmpTintColor = newValue;
            for (var index:Int = 0;index < self.titleLabels.count;index++) {
                if (index != self.selectedIndex){
                    (self.titleLabels[index] as! UILabel).textColor = newValue;
                }
                if (self.icons.count > 0 && index < self.icons.count){
                    var icon:UIImage = UIImage.image(self.icons[index] as! UIImage, tintColor: newValue)!
                    self.icons[index] = icon;
                    if (index != self.selectedIndex){
                        (iconImageViews[index] as! UIImageView).image = icon;
                    }
                }
                
            }
        }
        get{
            return self.tmpTintColor;
        }
    }
    
    private var icons:NSMutableArray = NSMutableArray();
    private var selectIcons:NSMutableArray = NSMutableArray();
    private var iconImageViews:NSMutableArray = NSMutableArray();
    private var titleLabels:NSMutableArray  = NSMutableArray();
    private var aItemWidth:CGFloat = 0;
    private var firstItemCenterX:CGFloat = 0;
    private var tmpSelectedTintColor:UIColor = UIColor.blueColor();
    private var tmpTintColor:UIColor = UIColor.whiteColor();
    private var currentSelectedIndex:Int = 0;
    private var line:UIView?;
    
    init(viewControllers:[AnyObject]!,names:[AnyObject]!,icons:[AnyObject]?){
        super.init(nibName:nil,bundle:nil);
        self.tabBar.backgroundImage = UIImage(named: "Tabbar_background");
        self.viewControllers = viewControllers;
        self.delegate = self;
        self.aItemWidth = CGRectGetWidth(self.tabBar.frame) / CGFloat(viewControllers.count);
        self.firstItemCenterX = self.aItemWidth / 2;
        for (var index:Int = 0;index < viewControllers.count;index++){
            let titleLabel:UILabel = UILabel(frame: CGRectMake(0, 0, self.aItemWidth, 20));
            titleLabel.text = names[index] as? String;
            titleLabel.center = CGPointMake(self.firstItemCenterX + self.aItemWidth * CGFloat(index), CGRectGetHeight(self.tabBar.frame) / 2);
            titleLabel.textAlignment = NSTextAlignment.Center;
            if (index == self.selectedIndex){
                titleLabel.textColor = self.selectedTintColor;

                self.currentSelectedIndex = self.selectedIndex;
            }else{
                titleLabel.textColor = self.tintColor;
            }
            titleLabel.font = UIFont.systemFontOfSize(10);
            self.tabBar.addSubview(titleLabel);
            self.titleLabels.addObject(titleLabel);
            if (icons != nil && index < icons!.count){
                let icon = icons![index] as! UIImage;
                let iconImageView = UIImageView(frame: CGRectMake(0, 10, icon.size.width, icon.size.height));
                iconImageView.center = CGPointMake(self.firstItemCenterX + self.aItemWidth * CGFloat(index), iconImageView.center.y);
                iconImageView.image = icon;
                titleLabel.frame.origin.y = CGRectGetMaxY(iconImageView.frame);
                self.tabBar.addSubview(iconImageView);
                self.iconImageViews.addObject(iconImageView);
                self.icons.addObject(icon);
                self.selectIcons.addObject(icon);
            }
          
        }
        self.line = UIView(frame: CGRectMake(CGFloat(self.selectedIndex) * self.aItemWidth, CGRectGetHeight(self.tabBar.frame) - 2, self.aItemWidth, 2));
        self.line?.backgroundColor = self.tmpSelectedTintColor;
        self.tabBar.addSubview(self.line!);
    }
    
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        var oldLabel:UILabel = self.titleLabels[self.currentSelectedIndex] as! UILabel;
        oldLabel.textColor = self.tintColor;
        
        var newLabel:UILabel = self.titleLabels[self.selectedIndex] as! UILabel;
        newLabel.textColor = self.selectedTintColor;
       
        if (self.icons.count > 0){
            var oldImageView:UIImageView = self.iconImageViews[self.currentSelectedIndex] as! UIImageView;
            oldImageView.image = self.icons[self.currentSelectedIndex] as? UIImage;
            
            var newImageView:UIImageView = self.iconImageViews[self.selectedIndex] as! UIImageView;
            newImageView.image = self.selectIcons[self.selectedIndex] as? UIImage;
        }
        
        self.line?.frame.origin.x = CGFloat(self.selectedIndex) * self.aItemWidth;
        
        self.currentSelectedIndex = self.selectedIndex;
    }
    
}