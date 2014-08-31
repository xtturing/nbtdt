//
//  NBDownLoadManagerViewController.m
//  tdtnb
//
//  Created by xtturing on 14-7-31.
//  Copyright (c) 2014年 xtturing. All rights reserved.
//

#import "NBDownLoadManagerViewController.h"
#import "DownloadItem.h"
#import "DownloadManager.h"
#import "Utility.h"
#import "DowningCell.h"

@interface NBDownLoadManagerViewController (){
    NSMutableDictionary *_downlist;
}

@end

@implementation NBDownLoadManagerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    UISegmentedControl *segment = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"正在下载",@"已完成", nil]];
    segment.frame = CGRectMake(0, 7, 140, 30);
    segment.segmentedControlStyle = UISegmentedControlStyleBar;
    segment.selectedSegmentIndex = 0;
    _downlist = [[DownloadManager sharedInstance]getDownloadingTask];
    [segment addTarget:self action:@selector(segmentAction:)forControlEvents:UIControlEventValueChanged];
    
    self.navigationItem.titleView = segment;
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(downloadNotification:) name:kDownloadManagerNotification object:nil];
    // Do any additional setup after loading the view from its nib.
}
- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)segmentAction:(UISegmentedControl *)Seg{
    if(Seg.selectedSegmentIndex == 0){
        _downlist = [[DownloadManager sharedInstance]getDownloadingTask];
    }else{
         _downlist = [[DownloadManager sharedInstance]getFinishedTask];
    }
    [self.table reloadData];
}
-(void)updateCell:(DowningCell *)cell withDownItem:(DownloadItem *)downItem
{
    
    DownloadItem *findItem=[_tpkList objectForKey:[downItem.url description]];
    if(findItem.tpk.title.length > 0 ){
        cell.lblTitle.text=[findItem.tpk.title description];
        cell.lblPercent.text=[NSString stringWithFormat:@"大小:%0.2fMB  进度:%0.2f%@",[findItem.tpk.size doubleValue]/(1024*1024),downItem.downloadPercent*100,@"%"];
        [cell.btnOperate setTitle:downItem.downloadStateDescription forState:UIControlStateNormal];
    }else{
        cell.lblTitle.text=[downItem.url description];
        cell.lblPercent.text=[NSString stringWithFormat:@"大小:%0.2fMB  进度:%0.2f%@",downItem.totalLength/(1024*1024),downItem.downloadPercent*100,@"%"];
        [cell.btnOperate setTitle:downItem.downloadStateDescription forState:UIControlStateNormal];
    }
    
}
-(void)updateUIByDownloadItem:(DownloadItem *)downItem
{
    DownloadItem *findItem=[_downlist objectForKey:[downItem.url description]];
    if(findItem==nil)
    {
        return;
    }
    findItem.downloadStateDescription=downItem.downloadStateDescription;
    findItem.downloadPercent=downItem.downloadPercent;
    findItem.downloadState=downItem.downloadState;
    switch (downItem.downloadState) {
        case DownloadFinished:
        {
            
        }
            break;
        case DownloadFailed:
        {
            
        }
            break;
            
        default:
            break;
    }
    
    
    int index=[_downlist.allKeys indexOfObject:[downItem.url description]];
    DowningCell *cell=(DowningCell *)[self.table cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    [self updateCell:cell withDownItem:downItem];
}

-(void)downloadNotification:(NSNotification *)notif
{
    DownloadItem *notifItem=notif.object;
    //    NSLog(@"%@,%d,%f",notifItem.url,notifItem.downloadState,notifItem.downloadPercent);
    [self updateUIByDownloadItem:notifItem];
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 66;
    
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    DownloadItem *downItem = [_downlist.allValues objectAtIndex:indexPath.row];
    
    DownloadItem *findItem=[_tpkList objectForKey:[downItem.url description]];
    
    NSString *url=[downItem.url description];
    
    static NSString *cellIdentity=@"DowningCell";
    DowningCell *cell=[tableView dequeueReusableCellWithIdentifier:cellIdentity];
    if(cell==nil)
    {
        cell=[[[NSBundle mainBundle]loadNibNamed:@"DowningCell" owner:self options:nil] lastObject];
        cell.DowningCellOperateClick=^(DowningCell *cell){
            
            if([[DownloadManager sharedInstance]isExistInDowningQueue:url])
            {
                [[DownloadManager sharedInstance]pauseDownload:url];
                return;
            }
            NSString *desPath=[[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",findItem.tpk?findItem.tpk.name:[NSString stringWithFormat:@"%@.tpk",[[Utility sharedInstance] md5HexDigest:url]]]];
            [[DownloadManager sharedInstance]startDownload:url withLocalPath:desPath];
        };
        cell.DowningCellCancelClick=^(DowningCell *cell)
        {
            [[DownloadManager sharedInstance]cancelDownload:url];
        };
    }
    [self updateCell:cell withDownItem:downItem];
    
    
    return cell;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [_downlist count];
}

@end
