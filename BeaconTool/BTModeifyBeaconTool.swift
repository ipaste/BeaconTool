//
//  BTChangeBeacon.swift
//  BeaconTool
//
//  Created by YunTop on 15/5/6.
//  Copyright (c) 2015年 YunTop. All rights reserved.
//

import UIKit

var modifyDB:FMDatabase {
get{
    var modifyDBPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first as! String + "/modifyDB";
    var db:FMDatabase?;
    if (!NSFileManager.defaultManager().fileExistsAtPath(modifyDBPath)){
        db = FMDatabase(path: modifyDBPath);
        db!.open();
        db!.executeUpdate("CREATE TABLE Beacon('identify' TEXT PRIMARY KEY,'major' INTERGER , 'minor' INTERGER,'comment' TEXT,'beaconName' TEXT)", withArgumentsInArray: nil);
    }else{
        db = FMDatabase(path: modifyDBPath);
        db!.open();
    }
    return db!;
}
}

class BTModeifyBeaconTool: NSObject,ABBeaconDelegate,ABBeaconManagerDelegate {
    
    private var connectionFlag = 0;//connect new beacon flag;
    
    private var beaconManager = ABBeaconManager();
    private var getBeaconList = NSMutableArray();
    private var modifyBeacons = NSMutableArray();
    private var whiteList = NSMutableDictionary();
    
    weak var delegate:BTModeifyBeaconToolDelegate?;
    
    
    class func shareBeaconTool() -> BTModeifyBeaconTool{
        var beaconTool:BTModeifyBeaconTool?;
        var token:dispatch_once_t = 0;
        dispatch_once(&token, { () -> Void in
            beaconTool = BTModeifyBeaconTool();
        })
        return beaconTool!;
    }
    
    override init() {
        super.init();
        var result =  dataBase.executeQuery("SELECT * FROM Beacon", withArgumentsInArray: nil);
        while (result.next()){
            var major = result.intForColumn("major");
            var minor = result.intForColumn("minor");
            var identifer = "\(major)-\(minor)";
            self.whiteList.setObject("", forKey: identifer);
        }
        
        result = modifyDB.executeQuery("SELECT count(*) FROM Beacon", withArgumentsInArray: nil);
        result.next()
        if(result.intForColumnIndex(0) <= 0){
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                var content:NSString?;
                var csvPath = NSBundle.mainBundle().pathForResource("Beaconlist", ofType: "csv");
                if(csvPath != nil){
                    content = NSString(contentsOfFile: csvPath!, encoding: CFStringConvertEncodingToNSStringEncoding(0x0632), error: nil);
                    if (content == nil){
                        content = NSString(contentsOfFile: csvPath!, encoding: NSUTF8StringEncoding, error: nil);
                    }
                }
                
                if (content != nil){
                    var datas = content!.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet());
                    (datas as NSArray).enumerateObjectsUsingBlock({ (obj, idx, stop) -> Void in
                        var tempLine:NSArray = obj.componentsSeparatedByString(";");
                        modifyDB.executeUpdate("INSERT INTO Beacon(identify,major,minor) VALUES(?,?,?)", withArgumentsInArray: [tempLine[0],tempLine[2],tempLine[3]]);
                    });
                }
            });
        }
    }
    
    func startModifyBeacon(){
        self.beaconManager.delegate = self;
        
        self.beaconManager.startAprilBeaconsDiscovery();
    }
    
    func beaconManager(manager: ABBeaconManager!, didDiscoverBeacon beacon: ABBeacon!) {
        if (beacon.rssi > -90 && beacon.rssi != 0){
            var result = modifyDB.executeQuery("SELECT beaconName FROM Beacon where beaconName = ? ", withArgumentsInArray: [beacon.peripheral.name]);
            
            if (!result.next()){
                if(self.getBeaconList.count <= 0){
                    beacon.connectToBeacon(ABConnectedReadState.StatedAllInfo);
                    beacon.delegate = self;
                }
                
                self.getBeaconList.addObject(beacon);
            }
        }
        
    }
    
    func beaconDidConnected(beacon: ABBeacon!, withError error: NSError!) {
        
        if(error != nil){
            println("connection error!");
            return;
        }
        
        if (self.delegate != nil && self.delegate!.respondsToSelector("modeifyBeaconTool:sourceBeacon:")){
            self.delegate?.modeifyBeaconTool!(self, sourceBeacon: beacon);
        }
        
        var uuid = beacon.proximityUUID.UUIDString;
        var identify = "\(beacon.major)-\(beacon.minor)";
        var beaconName = beacon.peripheral.name;
        
        if (uuid == defaultUUID && self.whiteList.objectForKey(identify) != nil){
            var result =  modifyDB.executeQuery("select major,minor from Beacon where comment is null limit 1", withParameterDictionary: nil);
            if(result.next()){
                var major = NSNumber(int: result.intForColumn("major"));
                var minor = NSNumber(int: result.intForColumn("minor"));
                let txPower = NSNumber(integer: 1);
                let advInterval = NSNumber(integer: 5);
                let measurePower = NSNumber(integer: -58);
                beacon.writeBeaconInfoByPassword(password, uuid: weiChatUUID, major: major, minor: minor, txPower: txPower, advInterval: advInterval, measuredPower: measurePower, newpassword: password, autoRestart: true, withCompletion: { (error) -> Void in
                    if(error != nil){
                        println(error);
                        return;
                    }
                    modifyDB.executeUpdate("UPDATE Beacon SET comment = ? , beaconName = ? WHERE major = ? and minor = ?", withArgumentsInArray: [identify,beaconName,major,minor]);
                    self.modifyBeacons.addObject(beacon);
                    beacon.disconnectBeacon();
                    println("更新成功 ：major = \(major) minor = \(minor) name = \(beaconName) identify : \(identify)");
                });
                
            }else{
                UIAlertView(title: "挺萌的", message: "找你微信哥哥去吧", delegate: nil, cancelButtonTitle: "真的挺萌的").show();
                self.modifyBeacons.addObject(beacon);
                beacon.disconnectBeacon();
            }
        }else{
            println("更新失败 ：identify = \(identify)");
            self.modifyBeacons.addObject(beacon);
            
            beacon.disconnectBeacon();
        }
        
    }
    
    
    func beaconDidDisconnect(beacon: ABBeacon!, withError error: NSError!) {
        println("disConnected");
        var index = self.getBeaconList.indexOfObject(beacon);
        if (index + 1 < self.getBeaconList.count){
            var beacon = self.getBeaconList[index + 1] as! ABBeacon;
            beacon.delegate = self;
            beacon.connectToBeacon(ABConnectedReadState.StatedAllInfo);
        }else{
            self.getBeaconList.removeAllObjects();
            
            self.beaconManager.stopAprilBeaconDiscovery();
            self.beaconManager.delegate = nil;
            self.beaconManager = ABBeaconManager();
            self.beaconManager.delegate = self;  
            self.beaconManager.startAprilBeaconsDiscovery();
        }
    }
}

@objc protocol BTModeifyBeaconToolDelegate:NSObjectProtocol {
    optional func modeifyBeaconTool(BeaconTool:BTModeifyBeaconTool,sourceBeacon beacon:ABBeacon);
}
