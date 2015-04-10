//
//  BTDataModel.swift
//  BeaconTool
//
//  Created by YunTop on 14/12/5.
//  Copyright (c) 2014年 YunTop. All rights reserved.
//

import Foundation
import CoreBluetooth

let kBTDataBaseFilePath:NSString = NSBundle.mainBundle().pathForAuxiliaryExecutable("beaconDB")!;
var dataBase:FMDatabase {
    get{
        var token:dispatch_once_t = 0;
        var DBInstance:FMDatabase?;
        dispatch_once(&token, { () -> Void in
            DBInstance = FMDatabase(path: kBTDataBaseFilePath);
            DBInstance?.open();
        });
        return DBInstance!;
    }
}
//MARK: Mall
class BTMall: NSObject {
    var uniId:NSString{
        get{
            return self.tmpUniId!;
        }
    }
    
    var name:NSString {
        get{
            return self.tmpName!;
        }
    }
    
    var floos:NSArray{
        get{
            if(self.tmpFloors.count <= 0 ){
                var floorResult:FMResultSet =  dataBase.executeQuery("select * from Floor where mallId = " + self.tmpUniId!, withArgumentsInArray: nil);
                while (floorResult.next()){
                    self.tmpFloors.addObject(BTFloor(result: floorResult));
                }
            }
            return self.tmpFloors.copy() as NSArray;
        }
    }
    
    private var tmpUniId:NSString?;
    private var tmpName:NSString?;
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
                var mallResult:FMResultSet = dataBase.executeQuery("select * from Mall where uniId = " + self.tmpMallId!, withArgumentsInArray: nil);
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
            return self.tmpBeacons.copy() as NSArray;
        }
    }
    private var tmpUniId:NSString?;
    private var tmpName:NSString?;
    private var tmpMall:BTMall?;
    private var tmpMallId:NSString?;
    private var tmpMapName:NSString?;
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

class BTBeaconManager:NSObject,ESTBeaconManagerDelegate {
    weak var delegate:BTBeaconManagerDelegate?;
    
    private let beaconManager:ESTBeaconManager = ESTBeaconManager();
    private let region:ESTBeaconRegion = ESTBeaconRegion(proximityUUID: NSUUID(UUIDString: "5A4BCFCE-174E-4BAC-A814-092E77F6B7E5"), identifier: "beaconTool");
    private var lock:NSLock = NSLock();
    private var whitelistDictionary:NSMutableDictionary = NSMutableDictionary();
    
    
    override init() {
        super.init();
        var beaconResult:FMResultSet? = dataBase.executeQuery("select * from Beacon", withArgumentsInArray: nil);
        if (beaconResult != nil){
            while(beaconResult!.next()){
                var beacon:BTBeacon = BTBeacon(result: beaconResult);
                self.whitelistDictionary.setObject(beacon, forKey: beacon.name);
            }
        }
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
    internal func beaconManager(manager: ESTBeaconManager!, didRangeBeacons beacons: [AnyObject]!, inRegion region: ESTBeaconRegion!) {
        if(beacons.count <= 0){
            return;
        }
        
        if (self.lock.tryLock()){
           //上锁
            var whitelist:NSMutableArray = NSMutableArray();
            var beaconDistance:NSMutableArray = NSMutableArray();
            var number = 0;
            for beacon in beacons {
                let tmpBeacon:ESTBeacon = beacon as ESTBeacon;
                let whitelistKey:String = "\(tmpBeacon.major)-\(tmpBeacon.minor)";
                var localBeacon:BTBeacon? = self.whitelistDictionary.objectForKey(whitelistKey) as? BTBeacon;
                if (localBeacon != nil && tmpBeacon.distance != -1){
                    //在白名单内
                    whitelist.addObject(localBeacon!);
                    beaconDistance.addObject(tmpBeacon.distance);
                }
            }
            if(self.delegate?.respondsToSelector("beaconManager:rangeBeacons:beaconDistances:")  != nil){
                self.delegate?.beaconManager!(self, rangeBeacons: whitelist.copy() as NSArray, beaconDistances: beaconDistance.copy() as NSArray);
            }
            self.lock.unlock();
        }
    }
    
    func startRangeBeacon(){
        self.beaconManager.startRangingBeaconsInRegion(self.region);
    }
}

@objc protocol BTBeaconManagerDelegate:NSObjectProtocol {
    optional func beaconManager(beaconManager:BTBeaconManager,rangeBeacons beacons:NSArray,beaconDistances distances:NSArray);
}

