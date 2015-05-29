//
//  BTDataModel.swift
//  BeaconTool
//
//  Created by YunTop on 14/12/5.
//  Copyright (c) 2014年 YunTop. All rights reserved.
//

import Foundation
import CoreBluetooth
let defaultUUID = "5A4BCFCE-174E-4BAC-A814-092E77F6B7E5";
let weiChatUUID = "FDA50693-A4E2-4FB1-AFCF-C6EB07647825";
let password = "Zzyt1602zzyt";
let kBTDataBaseFilePath:String = NSBundle.mainBundle().pathForAuxiliaryExecutable("beaconDB")!;
var dataBase:FMDatabase {
get{
    var token:dispatch_once_t = 0;
    var DBInstance:FMDatabase?;
    dispatch_once(&token, { () -> Void in
        DBInstance = FMDatabase(path: kBTDataBaseFilePath as String);
        DBInstance?.open();
    });
    return DBInstance!;
}
}
//MARK: Mall
class BTMall: NSObject {
    var uniId:String{
        get{
            return self.tmpUniId!;
        }
    }
    
    var name:String {
        get{
            return self.tmpName!;
        }
    }
    
    var floos:NSArray{
        get{
            if(self.tmpFloors.count <= 0 ){
                var floorResult = dataBase.executeQuery("select * from Floor where mallId = " + self.tmpUniId!, withArgumentsInArray: nil);
                while (floorResult.next()){
                    self.tmpFloors.addObject(BTFloor(result: floorResult));
                }
            }
            return self.tmpFloors.copy() as! NSArray;
        }
    }
    
    private var tmpUniId:String?;
    private var tmpName:String?;
    private var tmpFloors:NSMutableArray = NSMutableArray();
    init(result:FMResultSet!) {
        self.tmpUniId = result.stringForColumn("uniId");
        self.tmpName = result.stringForColumn("name");
    }
}
//MARK: Floor
class BTFloor: NSObject {
    var uniId:NSString {
        get{
            return self.tmpUniId!;
        }
    }
    
    var name:NSString {
        get{
            return self.tmpName!;
        }
    }
    
    var mapName:NSString{
        get{
            return self.tmpMapName!;
        }
    }
    
    var mall:BTMall {
        get{
            if (self.tmpMall == nil){
                var mallResult = dataBase.executeQuery("select * from Mall where uniId = \(self.tmpMallId!)", withArgumentsInArray: nil);
                mallResult.next();
                self.tmpMall = BTMall(result: mallResult);
            }
            return self.tmpMall!;
        }
    }
    var beacons:NSArray {
        get{
            if(self.tmpBeacons.count <= 0 ){
                var beaconResult:FMResultSet =  dataBase.executeQuery("select * from Beacon where floorId = " + self.tmpUniId!, withArgumentsInArray: nil);
                while (beaconResult.next()){
                    self.tmpBeacons.addObject(BTBeacon(result: beaconResult));
                }
            }
            return self.tmpBeacons.copy() as! NSArray;
        }
    }
    private var tmpUniId:String?;
    private var tmpName:String?;
    private var tmpMall:BTMall?;
    private var tmpMallId:String?;
    private var tmpMapName:String?;
    private var tmpBeacons:NSMutableArray = NSMutableArray();
    
    init(result:FMResultSet!) {
        self.tmpUniId = result.stringForColumn("uniId");
        self.tmpName = result.stringForColumn("name");
        self.tmpMallId = result.stringForColumn("mallId");
        self.tmpMapName = result.stringForColumn("mapName");
    }
}
//MARK: Beacon
class BTBeacon: NSObject {
    var minor:NSInteger {
        get{
            return self.tmpMinor!;
        }
    }
    
    var major:NSInteger {
        get{
            return self.tmpMajor!;
        }
    }
    
    var coordinate:CLLocationCoordinate2D{
        get{
            return CLLocationCoordinate2D(latitude: self.tmpLatitude!, longitude: self.tmpLongtitude!);
        }
    }
    
    var floor:BTFloor {
        get{
            if(self.tmpFloor == nil){
                var floorResult:FMResultSet = dataBase.executeQuery("select * from Floor where uniId = \(self.tmpFloorId!)" , withArgumentsInArray: nil);
                floorResult.next();
                self.tmpFloor = BTFloor(result: floorResult);
            }
            return self.tmpFloor!;
        }
    }
    var name:NSString {
        get{
            return "\(self.major)-\(self.minor)";
        }
    }
    
 
    private var tmpMinor:NSInteger?;
    private var tmpMajor:NSInteger?;
    private var tmpLatitude:Double?;
    private var tmpLongtitude:Double?;
    private var tmpFloorId:NSString?;
    private var tmpFloor:BTFloor?;
    init(result:FMResultSet!) {
        self.tmpMajor = NSInteger(result.intForColumn("major"));
        self.tmpMinor = NSInteger(result.intForColumn("minor"));
        self.tmpLatitude = result.doubleForColumn("latitude");
        self.tmpLongtitude = result.doubleForColumn("longtitude");
        self.tmpFloorId = result.stringForColumn("floorId");
    }
}

class BTBeaconManager:NSObject,ABBeaconManagerDelegate,ABBeaconDelegate {
    weak var delegate:BTBeaconManagerDelegate?;
    
    private let beaconManager:ABBeaconManager = ABBeaconManager();
    
    private var lock:NSLock = NSLock();
    private var whitelistDictionary:NSMutableDictionary = NSMutableDictionary();
    private var beaconList = NSMutableArray();
    private var getBeaconList:NSMutableArray =  NSMutableArray();
    override init() {
        super.init();
        
        self.beaconManager.delegate = self;
    }
    
    class func sharedBeaconManager()->BTBeaconManager{
        var token:dispatch_once_t = 0;
        var beaconManager:BTBeaconManager?;
        dispatch_once(&token, { () -> Void in
            beaconManager = BTBeaconManager();
        })
        return beaconManager!;
    }
    
    internal func beaconManager(manager: ABBeaconManager!, didRangeBeacons beacons: [AnyObject]!, inRegion region: ABBeaconRegion!) {
        if(beacons.count <= 0){
            return;
        }
        
        if (self.lock.tryLock()){
            //上锁
            var whitelist:NSMutableArray = NSMutableArray();
            var beaconDistance:NSMutableArray = NSMutableArray();
            var number = 0;
            for beacon in beacons {
                let tmpBeacon = beacon as! ABBeacon;
                if (tmpBeacon.distance != -1){
                    var whitelistKey:String = "\(tmpBeacon.major)-\(tmpBeacon.minor)";
                    var result = modifyDB.executeQuery("select comment from Beacon where major = \(tmpBeacon.major) and minor = \(tmpBeacon.minor) and comment is not null", withArgumentsInArray: nil);
                    if (result.next()){
                        var identifier = result.stringForColumn("comment") as NSString;
                        var major = identifier.componentsSeparatedByString("-").first as! NSString;
                        var minor = identifier.componentsSeparatedByString("-").last as! NSString;
                        
                        var tmpResult = dataBase.executeQuery("SELECT * FROM Beacon WHERE major = ? and minor = ?", withArgumentsInArray: [NSNumber(integer: major.integerValue),NSNumber(integer: minor.integerValue)]);
                        if  (tmpResult.next()){
                            var beacon = BTBeacon(result: tmpResult);
                            whitelist.addObject(beacon);
                            beaconDistance.addObject(tmpBeacon.distance);
                        }
                    }
                }
            }
            if(self.delegate?.respondsToSelector("beaconManager:rangeBeacons:beaconDistances:")  != nil){
                self.delegate?.beaconManager!(self, rangeBeacons: whitelist.copy() as! NSArray, beaconDistances: beaconDistance.copy() as! NSArray);
            }
            self.lock.unlock();
        }
    }
    
    func startRangeBeacon(){
        self.beaconManager.startRangingBeaconsInRegion(ABBeaconRegion(proximityUUID: NSUUID(UUIDString: weiChatUUID), identifier: "Yuntop"));
    }
}

@objc protocol BTBeaconManagerDelegate:NSObjectProtocol {
    optional func beaconManager(beaconManager:BTBeaconManager,rangeBeacons beacons:NSArray,beaconDistances distances:NSArray);
}

