//
//  BTSettingViewController.swift
//  BeaconTool
//
//  Created by YunTop on 14/12/6.
//  Copyright (c) 2014年 YunTop. All rights reserved.
//

import UIKit

class BTSettingViewController: UIViewController {
    override func viewDidLoad() {
        self.navigationItem.title = "设置";
        self.navigationController?.navigationBar.tintColor = UIColor(string: "e95e37", alpha: 1.0);
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor(string: "e95e37", alpha: 1.0)!];
    }
    
    override func viewWillLayoutSubviews() {
        self.view.backgroundColor = UIColor.whiteColor();
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning();
    }
}
