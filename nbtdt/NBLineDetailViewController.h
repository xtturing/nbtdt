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

@property (nonatomic, strong) NBRoute *route;

@property (nonatomic, assign) BOOL isBus;

@property (nonatomic, strong) NSArray *lineList;

@property (nonatomic, strong) NSString *start;

@property (nonatomic, strong) NSString *startAddress;

@property (nonatomic, strong) NSString *end;

@property (nonatomic, strong) NSString *endAddress;

@property (nonatomic, strong) NSString *lineStyle;

@property (nonatomic, strong) IBOutlet UITableView *table;

- (void)doLineSearch;


@end
