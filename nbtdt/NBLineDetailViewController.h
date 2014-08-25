//
//  NBLineDetailViewController.h
//  tdtnb
//
//  Created by xtturing on 14-7-27.
//  Copyright (c) 2014年 xtturing. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NBRoute.h"


@interface NBLineDetailViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic, retain) NBRoute *route;

@property (nonatomic, assign) BOOL isBus;

@property (nonatomic, retain) NSArray *lineList;

@end
