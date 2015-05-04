//
//  ViewController.swift
//  BeaconTool
//
//  Created by YunTop on 14/12/5.
//  Copyright (c) 2014年 YunTop. All rights reserved.
//

import UIKit

let BIGGER_THEN_IPHONE5:Bool = UIScreen.mainScreen().currentMode?.size.height >= 1136.0 ? true : false;
class BTMapViewController: UIViewController,BTSwitchMallDataSource,BTSwitchMallDelegate,RMMapViewDelegate,BTBeaconManagerDelegate,CBCentralManagerDelegate {
    var mapView:RMMapView?;
    var switchMallView:BTSwitchMallView?;
    var userFloor:BTFloor?;
    var allMall:NSMutableArray = NSMutableArray();
    var background:UIImageView?;
    var currentDisplayFloor:BTFloor?;
    var leftBarButton:UIButton?;
    var beaconManager:BTBeaconManager?;
    var currentBeacons:NSMutableArray = NSMutableArray();
    var bluetoothManager:CBCentralManager?;
    var switchFloor:Bool = true;
    var bluetoothOn:Bool = false;
    var lock:NSLock = NSLock();
    var locationManager:CLLocationManager = CLLocationManager();
    init() {
        super.init(nibName:nil,bundle:nil);
        var result:FMResultSet =  dataBase.executeQuery("select * from Mall", withArgumentsInArray: nil);
        while (result.next()){
            var tmpMall:BTMall = BTMall(result: result);
            allMall.addObject(tmpMall);
        }
        self.beaconManager = BTBeaconManager.sharedBeaconManager();
        self.beaconManager?.startRangeBeacon();
        self.beaconManager?.delegate = self;
        self.bluetoothManager = CBCentralManager(delegate: self, queue: nil)

        if(UIDevice.currentDevice().systemName.hasPrefix("8")){
            self.locationManager.requestAlwaysAuthorization();
            self.locationManager.requestWhenInUseAuthorization();
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.background = UIImageView(frame: self.view.bounds);
        if (BIGGER_THEN_IPHONE5){
            self.background?.image = UIImage(named: "home_bg1136.jpg");
        }else{
            self.background?.image = UIImage(named: "home_bg960.jpg");
        }
        self.view.addSubview(self.background!);
        
        var defaultMall:BTMall = self.allMall[0] as! BTMall;
        var defaultFloor:BTFloor = defaultMall.floos.firstObject as! BTFloor;
        self.mapView = RMMapView(frame: CGRectMake(10, CGRectGetMaxY(self.navigationController!.navigationBar.frame), CGRectGetWidth(self.view.frame) - 20, CGRectGetHeight(self.view.frame) - CGRectGetHeight(self.navigationController!.navigationBar.frame) - 30));
        self.mapView?.showLogoBug = false;
        self.mapView?.hideAttribution = true;
        self.mapView?.zoom = self.mapView!.minZoom;
        self.mapView?.delegate = self;
        self.mapView?.centerCoordinate = CLLocationCoordinate2DMake(0, 0);
        self.mapView?.layer.cornerRadius = 10;
        self.mapView?.layer.masksToBounds = true;
        self.view.addSubview(self.mapView!);
        
        self.switchMap(defaultFloor);
        
        self.navigationItem.title = NSString(string: defaultMall.name + " - " + defaultFloor.name);
        self.navigationController?.navigationBar.barStyle = UIBarStyle.BlackTranslucent;
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.rightBarButtonItem());
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: self.leftBarButtonItem());
        
        self.switchMallView = BTSwitchMallView(defaultMall:defaultMall);
        self.switchMallView?.delegate = self;
        self.switchMallView?.dataSource = self;
        
        self.view.addSubview(self.switchMallView!);
    }
    
    override func viewWillLayoutSubviews() {
        self.navigationController?.navigationBar.clipsToBounds = true;
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(inRect: self.navigationController!.navigationBar.bounds, tintColor: UIColor.clearColor()), forBarMetrics: UIBarMetrics.Default);
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
//MARK: switchMall
    func switchMall(switchMall:BTSwitchMallView) -> Int{
        return self.allMall.count;
    }
    
    func switchMall(switchMall: BTSwitchMallView, zoomOutButtonClicked clicked: Bool) {
        self.leftBarButton?.hidden = false;
    }
    
    func switchMall(switchMall: BTSwitchMallView, sectionAtIndex index: Int) -> NSArray {
      return self.allMall;
    }
    
    func switchMall(switchMall: BTSwitchMallView, selectFloor floor: BTFloor) {
        self.switchFloor = false;
        self.switchMap(floor);
    }
    
    func rightBarButtonItem() -> UIView{
        var rightImage:UIImage = UIImage(named: "home_ico_set")!;
        var rightBackgroundView:UIView = UIView(frame: CGRectMake(0, 0, 30, 30));
        var rightButton:UIButton = UIButton(frame: CGRectMake(10, 5, rightImage.size.width, rightImage.size.height));
        rightButton.setImage(rightImage, forState: UIControlState.Normal);
        rightButton.addTarget(self, action: "test", forControlEvents: UIControlEvents.TouchUpInside);
        rightBackgroundView.addSubview(rightButton);
        return rightBackgroundView;
    }
    
    func leftBarButtonItem()->UIView{
        var leftImage:UIImage = UIImage(named: "home_zoomIn")!;
        var leftBackgroundView:UIView = UIView(frame: CGRectMake(0, 0, 30, 30));
        self.leftBarButton = UIButton(frame: CGRectMake(0, 7, leftImage.size.width, leftImage.size.height));
        self.leftBarButton?.setImage(leftImage, forState: UIControlState.Normal);
        self.leftBarButton?.addTarget(self, action: "zoomIn", forControlEvents: UIControlEvents.TouchUpInside);
        self.leftBarButton?.hidden = true;
        leftBackgroundView.addSubview(self.leftBarButton!);
        return leftBackgroundView;
    }
    
    func zoomIn(){
        self.switchMallView?.zoomIn();
        self.leftBarButton?.hidden = true;
    }

    func switchMap(floor:BTFloor){
        self.mapView?.removeAllAnnotations();
        var tilesource:RMMBTilesSource = RMMBTilesSource(tileSetResource: floor.mapName);
        self.switchMallView?.switchMallView(changeMall: floor.mall, changeFloor: floor);
        self.navigationItem.title = floor.mall.name + " - " + (floor.name as String);
        self.mapView?.tileSource = tilesource;
        self.mapView?.maxZoom = tilesource.maxZoom;
        for beacon in floor.beacons{
            var annotation:BTBeaconAnnotation = BTBeaconAnnotation(mapView: self.mapView, coordinate: (beacon as BTBeacon).coordinate, andTitle: (beacon as BTBeacon).name, beacon: beacon as BTBeacon);
            self.mapView?.addAnnotation(annotation);
        }

        self.currentDisplayFloor = floor;
    }
    
//MARK: mapViewDelegate
    func mapView(mapView: RMMapView!, layerForAnnotation annotation: RMAnnotation!) -> RMMapLayer! {
        if (annotation.isMemberOfClass(BTBeaconAnnotation)){
           return  (annotation as BTBeaconAnnotation).beaconLayer;
        }
        return annotation.layer;
    }
    
//MARK: beaconDelegate
    func beaconManager(beaconManager: BTBeaconManager, rangeBeacons beacons: NSArray, beaconDistances distances: NSArray) {
        if (beacons.count <= 0){
            return;
        }
        if(self.bluetoothOn == true && self.lock.tryLock()){
            self.switchMallView?.enjoinSwitchMall(true);
            var switchFloor:BTFloor;
    
            if (beacons.count >= 2){
                switchFloor =  self.floorVoting(beacons);
            }else{
                var beacon:BTBeacon? =  beacons.firstObject as? BTBeacon;
                if (beacon != nil){
                    switchFloor = beacon!.floor;
                }else{
                    switchFloor = self.floorVoting(beacons);
                }
                
            }
            
            if ((self.switchFloor || switchFloor.mall.uniId.isEqualToString(self.currentDisplayFloor!.mall.uniId))){
                if (!switchFloor.uniId.isEqualToString(self.currentDisplayFloor!.uniId) && self.switchFloor){
                    self.switchMap(switchFloor);
                }
                self.switchFloor = false;
            }else{

            }
        
            
            for (var index:Int = 0;index < beacons.count;index++){
                var beacon:BTBeacon = beacons[index] as BTBeacon;
                var distance:NSNumber = distances[index] as NSNumber;
                for annotation in self.mapView!.annotations {
                    if ((annotation as BTBeaconAnnotation).title == beacon.name){
                        (annotation as BTBeaconAnnotation).changeAsMark(distance);
                    }
                }
            }
            self.lock.unlock();
        }
    }
    
    func floorVoting(beacons:NSArray) -> BTFloor{
        var floorDictionary:NSMutableDictionary = NSMutableDictionary();
        for beacon in beacons{
            var floorKey:NSString = (beacon as BTBeacon).floor.uniId;
            if (floorDictionary.valueForKey (floorKey) == nil){
                floorDictionary.setValue("1", forKey: floorKey);
            }else{
                var number:NSString = floorDictionary.valueForKey(floorKey) as NSString;
                number = NSString(format: "%d", number.integerValue + 1);
                floorDictionary.setValue(number, forKey: floorKey);
            }
        }
        var result:NSArray = floorDictionary.keysSortedByValueUsingComparator { (obj1, obj2) -> NSComparisonResult in
            return obj1.compare(obj2 as NSString, options: NSStringCompareOptions.NumericSearch);
        }
        var floor:BTFloor?;
        for beacon in beacons{
            if ((beacon as BTBeacon).floor.uniId.isEqualToString(result.firstObject as NSString)){
                floor = (beacon as BTBeacon).floor;
            }
        }
        return floor!;
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        if(central.state == CBCentralManagerState.PoweredOff){
            //蓝牙关闭
            self.bluetoothOn = false;
            self.switchMallView?.enjoinSwitchMall(false);
            
        }else if (central.state == CBCentralManagerState.PoweredOn){
            //蓝牙打开
            self.bluetoothOn = true;
            
        }
    }
    
    func test(){
       // self.presentViewController( BTDataBaseViewController(), animated: false, completion: nil);

    }
}

