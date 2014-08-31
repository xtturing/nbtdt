//
//  NBLineServiceViewController.h
//  tdtnb
//
//  Created by xtturing on 14-7-27.
//  Copyright (c) 2014年 xtturing. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AGSGoogleMapLayer.h"
@class NBRoute;
@interface NBLineServiceViewController : UIViewController

@property (nonatomic, strong) IBOutlet AGSMapView *mapView;
@property (nonatomic, strong) IBOutlet UISegmentedControl *segment;
@property (nonatomic, strong) IBOutlet UISegmentedControl *segmentPoint;
@property (nonatomic, strong) IBOutlet UITextField *startField;
@property (nonatomic, strong) IBOutlet UITextField *endField;
@property (nonatomic, strong) AGSGraphicsLayer *graphicsLayer;

- (IBAction)changeStartEnd:(id)sender;

-(void)doLineSearchWithFav:(BOOL )isfav route:(NBRoute *)route index:(int)index;
-(void)doLineSearchWithFav:(BOOL )isfav lineList:(NSArray *)lines index:(int)index;

@end
