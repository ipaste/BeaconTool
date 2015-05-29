//
//  BTExpansionModel.swift
//  BeaconTool
//
//  Created by YunTop on 14/12/6.
//  Copyright (c) 2014年 YunTop. All rights reserved.
//

import UIKit

extension UIImage {
    
    convenience init?(sourceImage:UIImage,inRect:CGRect) {
        var sourceImageRef:CGImageRef = sourceImage.CGImage!;
        var newImageRef:CGImageRef = CGImageCreateWithImageInRect(sourceImageRef, inRect)!;
        self.init(CGImage: newImageRef);
    }
    convenience init?(inRect:CGRect,var tintColor:UIColor?) {
        UIGraphicsBeginImageContext(inRect.size);
        var context:CGContextRef = UIGraphicsGetCurrentContext();
        if (tintColor == nil){
            tintColor = UIColor(white: 1.0, alpha: 0.5);
        }
        CGContextSetFillColorWithColor(context, tintColor!.CGColor);
        CGContextFillRect(context, inRect);
        var tmpCGImage:CGImageRef =  UIGraphicsGetImageFromCurrentImageContext().CGImage;
        UIGraphicsEndImageContext();
        self.init(CGImage: tmpCGImage);
        
    }
    
    class func image(image:UIImage!,tintColor:UIColor!) -> UIImage?{
        UIGraphicsBeginImageContextWithOptions(image.size, false, 0.0);
        tintColor.setFill();
        var bounds:CGRect = CGRectMake(0, 0, image.size.width, image.size.height);
        UIRectFill(bounds);
        [image.drawInRect(bounds, blendMode: kCGBlendModeDestinationIn, alpha: 1.0)];
        var image:UIImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return image;
    }
}

extension UIColor {
    convenience init?(string:String!,alpha:CGFloat?){
        var tmpString = string;
        var tmpAlpha:CGFloat! = alpha;
        var red:UInt32 = 0;
        var green:UInt32 = 0
        var blue:UInt32 = 0;
        if (tmpAlpha == nil){
            tmpAlpha = 1.0;
        }
        
        if((tmpString as NSString).length >= 6){
            if (!tmpString.hasPrefix("#")){
                tmpString = "#" + tmpString;
            }
            
            var range:NSRange = NSRange(location: 1,length: 2);
            NSScanner.localizedScannerWithString((tmpString as NSString).substringWithRange(range)).scanHexInt(&red);
            range.location = 3;
            NSScanner.localizedScannerWithString((tmpString as NSString).substringWithRange(range)).scanHexInt(&green);
            range.location = 5;
            NSScanner.localizedScannerWithString((tmpString as NSString).substringWithRange(range)).scanHexInt(&blue);
            
        }
        
        self.init(red:CGFloat(red)/255, green:CGFloat(green)/255, blue:CGFloat(blue)/255, alpha:tmpAlpha!);
    }
    
}

extension RMMarker {
    convenience init!(detectedBeacon beacon:BTBeacon){
        self.init();
        self.bounds = CGRectMake(0, 0, 10, 10);
        self.backgroundColor = UIColor.redColor().CGColor;
        self.cornerRadius = 5;
        self.masksToBounds = false;
        let majorString:NSString = NSString(string: String(beacon.major));
        
        
        var textSize:CGSize = majorString.boundingRectWithSize(CGSizeMake(CGFloat(MAXFLOAT), 50), options: NSStringDrawingOptions.TruncatesLastVisibleLine, attributes: [NSFontAttributeName:UIFont.systemFontOfSize(10)], context: nil).size;

        var textLayer:CATextLayer = CATextLayer();
        textLayer.frame = CGRectMake(0, 0, textSize.width, textSize.height * 2);
        textLayer.foregroundColor = UIColor.redColor().CGColor;
        textLayer.string = "\(beacon.major)\n\(beacon.minor)\n";
        textLayer.name = "beaconName";
        textLayer.fontSize = 10;
        textLayer.alignmentMode = kCAAlignmentCenter;
        textLayer.anchorPoint = CGPointMake(0.5, 0);
        self.addSublayer(textLayer);
        
        var distanceLayer:CATextLayer = CATextLayer();
        distanceLayer.frame = CGRectMake(0,textSize.height * 2, textSize.width, textSize.width);
        distanceLayer.foregroundColor = UIColor.redColor().CGColor;
        distanceLayer.string = "0";
        distanceLayer.alignmentMode = kCAAlignmentCenter;
        distanceLayer.fontSize = 10;
        distanceLayer.anchorPoint = CGPointMake(0.5, 0);
        distanceLayer.name = "distance";
        self.addSublayer(distanceLayer);
        
    }
    
    func updateLayer(changeColor:UIColor?,changeDistance:NSNumber?,beaconIdentify:String?){
        for sublayer in self.sublayers {
            if ((sublayer as! CATextLayer).name != nil && (sublayer as! CATextLayer).name == "distance"){
                if(changeDistance != nil){
                    var distance:Double =  floor(changeDistance!.doubleValue);
                    (sublayer as! CATextLayer).string = NSString(format: "%.0lf", distance);
                }
            }
           
            if (beaconIdentify != nil && sublayer.name == "beaconName"){
                var major = beaconIdentify?.componentsSeparatedByString("-")[0];
                var minor = beaconIdentify?.componentsSeparatedByString("-")[1];
                 (sublayer as! CATextLayer).string = "\(major)\n\(minor)\n";
            }
            (sublayer as! CATextLayer).foregroundColor = UIColor.greenColor().CGColor;
            self.backgroundColor = changeColor!.CGColor;
        }
    
    }
    
    convenience init!(graph:NSArray,mapView:RMMapView) {
        self.init();
        var shape = CAShapeLayer();
        shape.frame = mapView.bounds;
        shape.lineWidth = 3;
        shape.lineCap = kCALineCapRound;
        shape.strokeColor = UIColor.orangeColor().CGColor;
        
        var paths = CGPathCreateMutable();
        CGPathMoveToPoint(paths, nil, 0, 0);
        CGPathAddLineToPoint(paths, nil, 100, 100);
        
        shape.path = paths;
        self.addSublayer(shape);
    }

}