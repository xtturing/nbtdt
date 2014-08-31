//
//  NBDownLoadViewController.m
//  tdtnb
//
//  Created by xtturing on 14-7-31.
//  Copyright (c) 2014年 xtturing. All rights reserved.
//

#import "NBDownLoadViewController.h"
#import "NBDownLoadManagerViewController.h"
#import "dataHttpManager.h"
#import "NBTpk.h"
#import "SVProgressHUD.h"
#import "Reachability.h"
#import "DownloadManager.h"
#import "DowningCell.h"
#import "Utility.h"

@interface NBDownLoadViewController ()<dataHttpDelegate>

@property (nonatomic ,strong) NSMutableDictionary *tpkList;

@end

@implementation NBDownLoadViewController

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
    self.navigationItem.title = @"离线地图";
    
    UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithTitle:@"下载管理" style:UIBarButtonItemStylePlain target:self action:@selector(downloadManager)];
    self.navigationItem.rightBarButtonItem = right;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[dataHttpManager getInstance] letDoTpkList];
    });
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(downloadNotification:) name:kDownloadManagerNotification object:nil];
    // Do any additional setup after loading the view from its nib.
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [dataHttpManager getInstance].delegate = self;
}

-(void)viewWillDisappear:(BOOL)animated{
    [dataHttpManager getInstance].delegate =  nil;
}
- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)downloadManager{
    NBDownLoadManagerViewController *manager = [[NBDownLoadManagerViewController alloc]initWithNibName:@"NBDownLoadManagerViewController" bundle:nil];
     manager.tpkList = _tpkList;
    [self.navigationController pushViewController:manager animated:YES];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)didgetTpkList:(NSMutableDictionary *)tokList{
    [SVProgressHUD dismiss];
    _tpkList = tokList;
    if(_tpkList.count > 0){
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    [self.table reloadData];
}

-(void)updateCell:(DowningCell *)cell withDownItem:(DownloadItem *)downItem
{
    DownloadItem *findItem=[_tpkList objectForKey:[downItem.url description]];
    cell.lblTitle.text=[findItem.tpk.title description];
    cell.lblPercent.text=[NSString stringWithFormat:@"大小:%0.2fMB  进度:%0.2f%@",[findItem.tpk.size doubleValue]/(1024*1024),downItem.downloadPercent*100,@"%"];
    [cell.btnOperate setTitle:downItem.downloadStateDescription forState:UIControlStateNormal];
}
-(void)updateUIByDownloadItem:(DownloadItem *)downItem
{
    DownloadItem *findItem=[_tpkList objectForKey:[downItem.url description]];
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
    
    
    int index=[_tpkList.allKeys indexOfObject:[downItem.url description]];
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
    DownloadItem *downItem = [_tpkList.allValues objectAtIndex:indexPath.row];
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
            NSString *desPath=[[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",downItem.tpk?downItem.tpk.name:[NSString stringWithFormat:@"%@.tpk",[[Utility sharedInstance] md5HexDigest:url]]]];
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
    return [_tpkList count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    Reachability *r = [Reachability reachabilityForInternetConnection];
    switch ([r currentReachabilityStatus]) {
        case NotReachable:{
            UIAlertView *view = [[UIAlertView alloc] initWithTitle:@"天地图宁波" message:@"网络无法链接" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [view show];
        }
            break;
        case ReachableViaWWAN:{
            UIAlertView *view = [[UIAlertView alloc] initWithTitle:@"天地图宁波" message:@"使用2G/3G 网络,会产生运营商流量费用，请选择WIFI环境使用下载功能" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [view show];
        }
            // 使用3G网络
            break;
        case ReachableViaWiFi:{
            
            NBDownLoadManagerViewController *manager = [[NBDownLoadManagerViewController alloc]initWithNibName:@"NBDownLoadManagerViewController" bundle:nil];
            manager.tpkList = _tpkList;
            [self.navigationController pushViewController:manager animated:YES];
        }
            // 使用WiFi网络
            break;
    }
    
   
}


@end
