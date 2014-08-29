//
//  NBLineDetailViewController.m
//  tdtnb
//
//  Created by xtturing on 14-7-27.
//  Copyright (c) 2014年 xtturing. All rights reserved.
//

#import "NBLineDetailViewController.h"
#import "NBLine.h"
#import "NBSegment.h"
#import "NBSegmentLine.h"
#import "NBRouteItem.h"
#import "NBStationStart.h"
#import "NBStationEnd.h"
#import "SVProgressHUD.h"
#import "dataHttpManager.h"
#import "NBLineServiceViewController.h"

@interface NBLineDetailViewController ()<dataHttpDelegate>{

}

@end

@implementation NBLineDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [dataHttpManager getInstance].delegate = self;
    [self doLineSearch];
}

-(void)viewWillDisappear:(BOOL)animated{
    [dataHttpManager getInstance].delegate =  nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    UIBarButtonItem *right = [[UIBarButtonItem alloc]  initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:@selector(favLine:)];
    self.navigationItem.rightBarButtonItem = right;
    if([self hasFavoriteLine]){
        [right setTitle:@"已收藏"];
        right.enabled = NO;
    }else{
        [right setTitle:@"收藏"];
        right.enabled = YES;
    }
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)favLine:(id)sender{
    if([self hasFavoriteLine]){
        return;
    }
    UIBarButtonItem *btn = (UIBarButtonItem *)sender;
    [btn setTitle:@"已收藏"];
    btn.enabled = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSArray *array = [defaults objectForKey:@"FAVORITES_LINE"];
        if(array == nil){
            array = [[NSMutableArray alloc] init];
        }
        NSMutableArray *mArray = [NSMutableArray arrayWithArray:array];
        NSArray *object = [NSArray arrayWithObjects:_start,_startAddress,_end,_endAddress,_lineStyle,[NSNumber numberWithBool:_isBus], nil];
        [mArray addObject:object];
        [defaults setObject:(NSArray *)mArray forKey:@"FAVORITES_LINE" ];
        [defaults synchronize];
    });
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if(_isBus){
        NBLine *line = (NBLine *)[_lineList objectAtIndex:section];
        return [line.segments count];
    }else{
        return [_route.routeItemList count];
    }
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    if(_isBus){
        return [_lineList count];
    }else{
        return 1;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 80;
    
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 44;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UIView *customView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 300.0, 44.0)];
    customView.backgroundColor = [UIColor clearColor];
    UILabel * headerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.opaque = NO;
    headerLabel.textColor = [UIColor orangeColor];
    headerLabel.font = [UIFont boldSystemFontOfSize:16];
    headerLabel.frame = CGRectMake(20.0, 5.0, 300.0, 18.0);
    
    UILabel * headerLabel2 = [[UILabel alloc] initWithFrame:CGRectZero];
    headerLabel2.backgroundColor = [UIColor clearColor];
    headerLabel2.opaque = NO;
    headerLabel2.textColor = [UIColor lightGrayColor];
    headerLabel2.font = [UIFont boldSystemFontOfSize:14];
    headerLabel2.frame = CGRectMake(20.0, 28.0, 300.0, 16.0);
    if(_isBus){
        NBLine *line = (NBLine *)[_lineList objectAtIndex:section];
        headerLabel.text =line.lineName;
        headerLabel.frame = CGRectMake(20.0, 5.0, 300.0, 34.0);
    }else{
        headerLabel.text = [NSString stringWithFormat:@"总里程:约%@公里",self.route.distance];
        headerLabel2.text = [NSString stringWithFormat:@"历时约%.2f分钟",[self.route.duration floatValue]/60];
    }
    [customView addSubview:headerLabel];
    [customView addSubview:headerLabel2];
    return customView;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *reuseIdetify = @"TableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdetify];
    if (!cell) {
        if(_isBus){
            
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdetify];
        }else{
            
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:reuseIdetify];
        }
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    cell.textLabel.backgroundColor = [UIColor clearColor];
    
    if(_isBus){
        NBLine *line = (NBLine *)[_lineList objectAtIndex:indexPath.section];
        NBSegment *segment = [line.segments objectAtIndex:indexPath.row];
        NSArray *segmentLines = segment.segmentLines;
        if([segment.segmentType intValue] == 1 && (segment.stationStart.name == nil || [segment.stationStart.name isEqualToString:@""])  && segment.stationEnd.name.length > 0){
            cell.textLabel.text = [NSString stringWithFormat:@"从起点步行至%@",segment.stationEnd.name];
            NBSegmentLine *segmentLine = (NBSegmentLine *)[segmentLines objectAtIndex:0];
            cell.detailTextLabel.text =[NSString stringWithFormat:@"%@米",segmentLine.segmentDistance];
        }
        else if([segment.segmentType intValue] == 1 && (segment.stationEnd.name == nil || [segment.stationEnd.name isEqualToString:@""])  && segment.stationStart.name.length > 0){
            cell.textLabel.text = [NSString stringWithFormat:@"从%@步行至目的地",segment.stationStart.name];
            NBSegmentLine *segmentLine = (NBSegmentLine *)[segmentLines objectAtIndex:0];
            cell.detailTextLabel.text =[NSString stringWithFormat:@"%@米",segmentLine.segmentDistance];
        }else if ([segment.segmentType intValue] == 1 && segment.stationEnd.name.length > 0 && segment.stationStart.name.length > 0){
            cell.textLabel.text = [NSString stringWithFormat:@"从%@步行至%@",segment.stationStart.name,segment.stationEnd.name];
            NBSegmentLine *segmentLine = (NBSegmentLine *)[segmentLines objectAtIndex:0];
            cell.detailTextLabel.text =[NSString stringWithFormat:@"%@米",segmentLine.segmentDistance];
        }else{
            NSMutableString *str = [[NSMutableString alloc] initWithString:@"乘坐"];
            NBSegmentLine *segmentLine = (NBSegmentLine *)[segmentLines objectAtIndex:0];
            [str appendString:segmentLine.lineName];
            cell.detailTextLabel.text =[NSString stringWithFormat:@"%@ 时间:%@ 经过%@站 约%.2f公里",segmentLine.direction,segmentLine.SEndTime,segmentLine.segmentStationCount,[segmentLine.segmentDistance floatValue]/1000];
            if(segmentLines.count > 1){
                [str appendString:@"("];
                for(int i =1; i< segmentLines.count;i++){
                    NBSegmentLine *sl = [segmentLines objectAtIndex:i];
                    [str appendString:@"或"];
                    [str appendString:sl.lineName];
                }
                [str appendString:@")"];
            }
            [str appendFormat:@"在%@下车",segment.stationEnd.name];
            cell.textLabel.text = str;
            
        }
        
    }else{
        NBRouteItem *item = (NBRouteItem *)[_route.routeItemList objectAtIndex:indexPath.row];
        cell.textLabel.text = item.streetName;
        cell.detailTextLabel.text = item.strguide;
        
    }
    cell.textLabel.font = [UIFont systemFontOfSize:14];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.minimumScaleFactor = 0.5;
    cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
    cell.detailTextLabel.minimumScaleFactor = 0.5;
    cell.detailTextLabel.numberOfLines = 0;
    cell.textLabel.numberOfLines = 0;
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UIViewController *viewController = [self.navigationController.viewControllers objectAtIndex:[self.navigationController.viewControllers count]-2];
    if([viewController isKindOfClass:[NBLineServiceViewController class] ]){
        if(_isBus){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"BusLineDetail" object:nil userInfo:[NSDictionary dictionaryWithObject:indexPath forKey:@"indexPath"]];
        }else{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"RouteLineDetail" object:nil userInfo:[NSDictionary dictionaryWithObject:indexPath forKey:@"indexPath"]];
        }
        [self.navigationController popViewControllerAnimated:YES];
    }else{
        NBLineServiceViewController *lineSeviceViewController = [[NBLineServiceViewController alloc] initWithNibName:@"NBLineServiceViewController" bundle:nil];
        if(_isBus){
            [lineSeviceViewController doLineSearchWithFav:YES lineList:_lineList];
        }else{
            [lineSeviceViewController doLineSearchWithFav:YES route:_route];
        }
        [self.navigationController pushViewController:lineSeviceViewController animated:YES];
    }
}

- (BOOL)hasFavoriteLine{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *array = [defaults objectForKey:@"FAVORITES_LINE"];
    if(array == nil){
        return NO;
    }
    for(NSArray *data in array){
        if([[data objectAtIndex:0] isEqualToString:_start] && [[data objectAtIndex:2]  isEqualToString:_end] && [[data objectAtIndex:4] isEqualToString:_lineStyle] && [[data objectAtIndex:5] intValue] == [[NSNumber numberWithBool:_isBus] intValue]){
            return YES;
        }
    }
    return NO;
}

- (void)doLineSearch{
    if(_start.length > 0 && _end.length > 0 && _lineStyle.length > 0  && !_lineList && !_route){
        [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if(_isBus){
                [[dataHttpManager getInstance] letDoBusSearchWithStartposition:_start endposition:_end linetype:_lineStyle];
            }else{
                [[dataHttpManager getInstance] letDoLineSearchWithOrig:_start dest:_end style:_lineStyle];
            }
            
        });
    }
}

-(void)didGetRoute:(NBRoute *)route{
    [SVProgressHUD dismiss];
    _route = route;
    [self.table reloadData];
}

- (void)didGetFailed{
    [SVProgressHUD dismiss];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    UIAlertView *view = [[UIAlertView alloc] initWithTitle:@"天地图宁波" message:@"路线服务发生异常" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [view show];
}

- (void)didGetBusLines:(NSArray *)lineList{
    [SVProgressHUD dismiss];
    _lineList = lineList;
    [self.table reloadData];
}
@end
