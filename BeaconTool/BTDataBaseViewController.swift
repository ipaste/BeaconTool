//
//  BTDataBaseViewController.swift
//  BeaconTool
//
//  Created by YunTop on 14/12/26.
//  Copyright (c) 2014年 YunTop. All rights reserved.
//

import UIKit

class BTDataBaseViewController: UIViewController {
    let sourcePath:NSString = "/Users/YunTop/Desktop/highGuangDB"
    let dbPath:NSString = "/Users/YunTop/Desktop/beaconDB"
    var sourceDataBase:FMDatabase!;
    var db:FMDatabase!;
    var sourceBeacon:NSMutableArray = NSMutableArray();
    override func viewDidLoad() {
        if (NSFileManager.defaultManager().fileExistsAtPath(sourcePath)){
            sourceDataBase = FMDatabase(path: sourcePath);
            sourceDataBase.open();
            if (sourceDataBase != nil){
                var result:FMResultSet = sourceDataBase.executeQuery("select * from beacon", withArgumentsInArray: nil);
                while (result.next()){
                    var beacon:BTSourceBeacon = BTSourceBeacon();
                    beacon.ID = NSString(string: result.stringForColumn("beaconId")).integerValue;
                    beacon.major = Int(result.intForColumn("major"));
                    beacon.minor = Int(result.intForColumn("minor"));
                    beacon.comment = result.stringForColumn("comment");
                    let minorAreaId = result.intForColumn("minorAreaId");
                    var minorAreaResult:FMResultSet = sourceDataBase.executeQuery("select * from minorArea where minorAreaId = \(minorAreaId)", withArgumentsInArray: nil);
                    minorAreaResult.next();
                    beacon.latitude = minorAreaResult.doubleForColumn("latitude");
                    beacon.longtitude = minorAreaResult.doubleForColumn("longtitude");
                    beacon.floorId = minorAreaResult.stringForColumn("majorAreaId");
                    self.sourceBeacon.addObject(beacon);
                }
                self.sourceDataBase.close();
            }
        }
        
        if(NSFileManager.defaultManager().fileExistsAtPath(dbPath)){
            db = FMDatabase(path: dbPath);
            db.open();
            db.executeUpdate("delete from beacon", withArgumentsInArray: nil);
            for beacon in self.sourceBeacon {
                var beacon:BTSourceBeacon = beacon as BTSourceBeacon;
                db.executeUpdate("insert into beacon(ID,uniId,minor,major,latitude,longtitude,floorId,comment) values(?,?,?,?,?,?,?,?)", withArgumentsInArray: [beacon.ID,beacon.uniId,beacon.minor,beacon.major,beacon.latitude,beacon.longtitude,beacon.floorId,beacon.comment]);
            }
        }
        self.view.backgroundColor = UIColor.whiteColor();
    }
    
    override func didReceiveMemoryWarning() {
        
    }
    
}

class BTSourceBeacon: NSObject {
    var ID:NSInteger = 0;
    var uniId:NSString = "";
    var minor:NSInteger = 0;
    var major:NSInteger = 0;
    var latitude:Double = 0.0;
    var longtitude:Double = 0.0;
    var floorId:NSString = "";
    var comment:NSString = "";
}

