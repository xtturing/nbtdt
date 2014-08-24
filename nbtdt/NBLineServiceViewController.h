//
//  NBLineServiceViewController.h
//  tdtnb
//
//  Created by xtturing on 14-7-27.
//  Copyright (c) 2014年 xtturing. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AGSGoogleMapLayer.h"

@interface NBLineServiceViewController : UIViewController

@property (nonatomic, strong) IBOutlet AGSMapView *mapView;
@property (nonatomic, strong) IBOutlet UISegmentedControl *segment;
@property (nonatomic, strong) IBOutlet UISegmentedControl *segmentPoint;
@property (nonatomic, strong) IBOutlet UITextField *startField;
@property (nonatomic, strong) IBOutlet UITextField *endField;
@property (nonatomic, strong) AGSGraphicsLayer *graphicsLayer;

- (IBAction)changeStartEnd:(id)sender;
@end
