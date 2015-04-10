//
//  BTAnnotation.swift
//  BeaconTool
//
//  Created by YunTop on 14/12/10.
//  Copyright (c) 2014年 YunTop. All rights reserved.
//

import UIKit

class BTBeaconAnnotation:RMAnnotation {
    var beacon:BTBeacon?;
    var detectedState:Bool = false;
    var beaconLayer:RMMarker{
        get{
            return self.tmpLayer!;
        }
    }
    private var tmpLayer:RMMarker?;
    init!(mapView aMapView: RMMapView!, coordinate aCoordinate: CLLocationCoordinate2D, andTitle aTitle: String!,beacon:BTBeacon!) {
        super.init(mapView: aMapView, coordinate: aCoordinate, andTitle: aTitle);
        self.beacon = beacon;
        self.tmpLayer = RMMarker(detectedBeacon: beacon);
    }
    func changeAsMark(distance:NSNumber!){
        self.detectedState = true;
        self.tmpLayer?.updateLayer(true, changeDistance: distance);
    }
    
}
