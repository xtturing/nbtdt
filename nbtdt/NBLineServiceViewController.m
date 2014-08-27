//
//  NBLineServiceViewController.m
//  tdtnb
//
//  Created by xtturing on 14-7-27.
//  Copyright (c) 2014年 xtturing. All rights reserved.
//

#import "NBLineServiceViewController.h"
#import <CoreLocation/CoreLocation.h> 
#import "dataHttpManager.h"
#import "NBRoute.h"
#import "NBLine.h"
#import "SVProgressHUD.h"
#import "CLLocation+Sino.h"
#import "NBLineDetailViewController.h"

//contants for data layers
#define kTiledNB @"http://60.190.2.120/wmts/nbmapall?service=WMTS&request=GetTile&version=1.0.0&layer=0&style=default&tileMatrixSet=nbmap&format=image/png&TILEMATRIX=%d&TILEROW=%d&TILECOL=%d"
#define KTiledTDT @"http://t0.tianditu.com/vec_c/wmts?SERVICE=WMTS&REQUEST=GetTile&VERSION=1.0.0&LAYER=vec&STYLE=default&TILEMATRIXSET=c&TILEMATRIX=%d&TILEROW=%d&TILECOL=%d&FORMAT=tiles"
#define KTiledTDTLabel  @"http://t0.tianditu.com/cva_c/wmts?SERVICE=WMTS&REQUEST=GetTile&VERSION=1.0.0&LAYER=cva&STYLE=default&TILEMATRIXSET=c&TILEMATRIX=%d&TILEROW=%d&TILECOL=%d&FORMAT=tiles"

@interface NBLineServiceViewController ()<AGSMapViewLayerDelegate,dataHttpDelegate,AGSMapViewTouchDelegate>{
    BOOL isBus;
    BOOL isStart;
    NSString *start;
    NSString *end;
    NSString *lineStyle;
    AGSGraphic * startGra;
    AGSGraphic * endGra;
}
@property (nonatomic, strong) CLGeocoder *geocoder;
@property (nonatomic, strong) NBRoute *route;
@property (nonatomic, strong) NSArray *lineList;
@property (nonatomic, strong) UIScrollView *scrollView ;
@end

@implementation NBLineServiceViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    if (nil == self.geocoder)
    {
        _geocoder = [[CLGeocoder alloc] init];
    }
    _segment.selectedSegmentIndex = 1;
    lineStyle = @"2";
    [_segment addTarget:self action:@selector(segmentStyleAction:) forControlEvents:UIControlEventValueChanged];
    [_segmentPoint addTarget:self action:@selector(segmentPointAction:) forControlEvents:UIControlEventValueChanged];
    _segmentPoint.enabled = NO;
    isStart =YES;
    UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"公交",@"自驾", nil]];
    seg.frame = CGRectMake(0, 7, 140, 30);
    seg.segmentedControlStyle = UISegmentedControlStyleBar;
    seg.selectedSegmentIndex = 0;
    isBus = YES;
    [seg addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = seg;
    
    UIBarButtonItem *right = [[UIBarButtonItem alloc]  initWithTitle:@"详情列表" style:UIBarButtonItemStylePlain target:self action:@selector(detailAction)];
    self.navigationItem.rightBarButtonItem = right;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    self.mapView.layerDelegate = self;
	self.mapView.touchDelegate = self;
	[self addTileLayer];
    [self zooMapToLevel:13 withCenter:[AGSPoint pointWithX:121.55629730245123 y:29.874820709509887 spatialReference:self.mapView.spatialReference]];
    self.graphicsLayer = [AGSGraphicsLayer graphicsLayer];
	[self.mapView addMapLayer:self.graphicsLayer withName:@"graphicsLayer"];
}
- (void)viewDidUnload {
    //Stop the GPS, undo the map rotation (if any)
    if(self.mapView.gps.enabled){
        [self.mapView.gps stop];
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [dataHttpManager getInstance].delegate = self;
}

-(void)viewWillDisappear:(BOOL)animated{
    [dataHttpManager getInstance].delegate =  nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void) mapViewDidLoad:(AGSMapView*)mapView {
    // comment to disable the GPS on start up
    [self.mapView.gps start];
    _segmentPoint.enabled =YES;
    
}
- (void)mapView:(AGSMapView *)mapView didClickAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint graphics:(NSDictionary *)graphics{
    
    if(!isStart){
        [self addEndPoint:mappoint];
        
        end = [NSString stringWithFormat:@"%lf,%lf",mappoint.x,mappoint.y];
        
        
    }else{
        isStart = YES;
        _segmentPoint.selectedSegmentIndex = 1;
        [self addStartPoint:mappoint];
        start = [NSString stringWithFormat:@"%lf,%lf",mappoint.x,mappoint.y];
        
    }
    
    CLLocation *loc = [[CLLocation alloc] initWithLatitude:mappoint.y longitude:mappoint.x] ;
    [self doGeo:loc];
    
    [self doLineSearch];
}
-(void)addStartPoint:(AGSPoint *)mappoint{
    if(startGra){
        [self.graphicsLayer removeGraphic:startGra];
        startGra = nil;
    }
    AGSPictureMarkerSymbol * dian = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImageNamed:@"qidian"];
    dian.size = CGSizeMake(22,36);
    if(mappoint.x == 0 || mappoint.y == 0 ){
        return;
    }
    startGra = [AGSGraphic graphicWithGeometry:mappoint symbol:nil attributes:nil infoTemplateDelegate:nil];
    dian.yoffset=18;
    startGra.symbol = dian;
    [self.graphicsLayer addGraphic:startGra];
    [self.graphicsLayer dataChanged];
}

-(void)addEndPoint:(AGSPoint *)mappoint{
    if(endGra){
        [self.graphicsLayer removeGraphic:endGra];
        endGra = nil;
    }
    AGSPictureMarkerSymbol * dian = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImageNamed:@"point"];
    dian.size = CGSizeMake(22,36);
    if(mappoint.x == 0 || mappoint.y == 0 ){
        return;
    }
    endGra = [AGSGraphic graphicWithGeometry:mappoint symbol:nil attributes:nil infoTemplateDelegate:nil];
    dian.yoffset=18;
    endGra.symbol = dian;
    [self.graphicsLayer addGraphic:endGra];
    [self.graphicsLayer dataChanged];
}

- (void)doGeo:(CLLocation *)location{
    [_geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        if ([placemarks count] > 0 && !error)
        {
            CLPlacemark *mark = [placemarks objectAtIndex:0];
            if (mark) {
                NSString *address = [self getAddressFromPlacemark:mark];
                if(isStart){
                    if(start.length > 0){
                        _startField.placeholder = address;
                    }else{
                        _startField.placeholder = @"我的位置";
                    }
                }else{
                    if(end.length > 0){
                        _endField.placeholder = address;
                    }else{
                        _endField.placeholder = @"请选择目的地位置";
                    }
                }
            }
        }
        else if(!error)
        {
            if(isStart){
                _startField.placeholder = @"我的位置";
            }else{
                _endField.placeholder = @"请选择目的地位置";
            }
        }
        else
        {
        }
    }];
}

- (IBAction)changeStartEnd:(id)sender{
    NSString *sTemp = nil;
    NSString *eTemp = nil;
    if(start){
       sTemp = [NSString stringWithString:start];
    }
    if(end){
       eTemp = [NSString stringWithString:end];
    }
    if(sTemp.length > 0){
        end = sTemp;
        _endField.placeholder = end;
    }else{
        end = nil;
        _endField.placeholder =  @"请选择目的地位置";
    }
    if(eTemp.length > 0){
        start = eTemp;
        _startField.placeholder = start;
    }else{
        start = nil;
        _startField.placeholder = @"我的位置";
    }
    [self doLineSearch];
    
}


- (void)detailAction{
    if(isBus){
        NBLineDetailViewController *lineDetailViewController = [[NBLineDetailViewController alloc ] initWithNibName:@"NBLineDetailViewController" bundle:nil];
        lineDetailViewController.isBus = YES;
        lineDetailViewController.lineList = _lineList;
        [self.navigationController pushViewController:lineDetailViewController animated:YES];
    }else{
        NBLineDetailViewController *lineDetailViewController = [[NBLineDetailViewController alloc ] initWithNibName:@"NBLineDetailViewController" bundle:nil];
        lineDetailViewController.isBus = NO;
        lineDetailViewController.route = _route;
        [self.navigationController pushViewController:lineDetailViewController animated:YES];
    }
    
}
- (void)addTileLayer{
    AGSGoogleMapLayer *tileMapLayer=[[AGSGoogleMapLayer alloc] initWithGoogleMapSchema:kTiledNB tdPath:KTiledTDT envelope:[AGSEnvelope envelopeWithXmin:119.65171432515596 ymin:29.021148681921858 xmax:123.40354537984406  ymax:30.441131592078335  spatialReference:self.mapView.spatialReference] level:@"9"];
	[self.mapView insertMapLayer:tileMapLayer withName:@"tiledLayer" atIndex:0];
    AGSGoogleMapLayer *tileLabelLayer = [[AGSGoogleMapLayer alloc] initWithGoogleMapSchema:nil tdPath:KTiledTDTLabel envelope:[AGSEnvelope envelopeWithXmin:119.65171432515596 ymin:29.021148681921858 xmax:123.40354537984406  ymax:30.441131592078335  spatialReference:self.mapView.spatialReference] level:@"9"];
    [self.mapView insertMapLayer:tileLabelLayer withName:@"tiledLabelLayer" atIndex:1];
}
- (void)zooMapToLevel:(int)level withCenter:(AGSPoint *)point{
    AGSGoogleMapLayer *layer = (AGSGoogleMapLayer *)[self.mapView.mapLayers objectAtIndex:0];
    AGSLOD *lod = [layer.tileInfo.lods objectAtIndex:level];
    [self.mapView zoomToResolution:lod.resolution withCenterPoint:point animated:YES];
}

- (NSString *)pointToAddress:(CLLocation *)location{
    CLGeocoder *geocoder=[[CLGeocoder alloc]init];
    __block NSString *address= nil;
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemark,NSError *error)
     {
         CLPlacemark *mark=[placemark objectAtIndex:0];
         address = [NSString stringWithFormat:@"%@%@%@",mark.subLocality,mark.thoroughfare,mark.subThoroughfare];
     } ];
    return address;
}
-(void)segmentAction:(UISegmentedControl *)Seg{
    if(Seg.selectedSegmentIndex == 0){
        [_segment setTitle:@"较快捷" forSegmentAtIndex:0];
        [_segment setTitle:@"少换乘" forSegmentAtIndex:1];
        [_segment setTitle:@"少步行" forSegmentAtIndex:2];
        isBus = YES;
        lineStyle = @"2";
    }else{
        [_segment setTitle:@"最快线路" forSegmentAtIndex:0];
        [_segment setTitle:@"最短线路" forSegmentAtIndex:1];
        [_segment setTitle:@"少走高速" forSegmentAtIndex:2];
        isBus = NO;
        lineStyle = @"1";
    }
    _segment.selectedSegmentIndex = 1;
    [self doLineSearch];
}
-(void)segmentStyleAction:(UISegmentedControl *)Seg{
    if(isBus){
        switch (Seg.selectedSegmentIndex) {
            case 0:
                lineStyle = @"1";
                break;
            case 1:
                lineStyle = @"2";
                break;
            case 2:
                lineStyle = @"4";
                break;
            default:
                break;
        }
    }else{
        switch (Seg.selectedSegmentIndex) {
            case 0:
                lineStyle = @"0";
                break;
            case 1:
                lineStyle = @"1";
                break;
            case 2:
                lineStyle = @"2";
                break;
            default:
                break;
        }
    }
    [self doLineSearch];
    
}
-(void)segmentPointAction:(UISegmentedControl *)Seg{
    switch (Seg.selectedSegmentIndex) {
        case 0:
        {
            isStart = YES;
            if(self.mapView.gps.enabled){
                CLLocation *loc = [self.mapView.gps.currentLocation locationMarsFromEarth];
                if(loc.coordinate.longitude >0 && loc.coordinate.latitude > 0){
                    if(startGra){
                        [self.graphicsLayer removeGraphic:startGra];
                        startGra = nil;
                    }
                    AGSPictureMarkerSymbol * dian = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImageNamed:@"qidian"];
                    dian.size = CGSizeMake(22,36);
                    AGSPoint *mappoint = [[AGSPoint alloc] initWithX:loc.coordinate.longitude y:loc.coordinate.latitude spatialReference:self.mapView.spatialReference];
                    startGra = [AGSGraphic graphicWithGeometry:mappoint symbol:nil attributes:nil infoTemplateDelegate:nil];
                    dian.yoffset=18;
                    startGra.symbol = dian;
                    [self.graphicsLayer addGraphic:startGra];
                    [self.graphicsLayer dataChanged];
                    start = [NSString stringWithFormat:@"%lf,%lf",loc.coordinate.longitude,loc.coordinate.latitude];
                    
                    [self doGeo:loc];
                    [self doLineSearch];
                }
            }else{
                UIAlertView *alert;
                alert = [[UIAlertView alloc]
                         initWithTitle:@"天地图宁波"
                         message:@"周边查询需要你的位置信息,请开启GPS"
                         delegate:nil cancelButtonTitle:nil
                         otherButtonTitles:@"确定", nil];
                [alert show];
                return;
            }
            
        }
            break;
        case 1:
        {
            isStart = YES;
        }
            break;
        case 2:
        {
            isStart = NO;
        }
            break;
        default:
            break;
    }
}

- (void)doLineSearch{
    if(start.length > 0 && end.length > 0 && lineStyle.length > 0){
        [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if(isBus){
                [[dataHttpManager getInstance] letDoBusSearchWithStartposition:start endposition:end linetype:lineStyle];
            }else{
                [[dataHttpManager getInstance] letDoLineSearchWithOrig:start dest:end style:lineStyle];
            }
            
        });
    }    
}

#pragma -mark
- (void)didGetFailed{
    [SVProgressHUD dismiss];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    UIAlertView *view = [[UIAlertView alloc] initWithTitle:@"天地图宁波" message:@"路线服务发生异常" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [view show];
    self.navigationItem.rightBarButtonItem.enabled = NO;
}
-(void)didGetRoute:(NBRoute *)route{
    [SVProgressHUD dismiss];
    _route = route;
    if(_route && _route.routeItemList.count > 0){
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }else{
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    
    AGSPictureMarkerSymbol * jingguo = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImageNamed:@"jingguo.png"];
    AGSSimpleLineSymbol* lineSymbol = [AGSSimpleLineSymbol simpleLineSymbol];
    lineSymbol.color =[UIColor colorWithRed:45.0/255.0 green:140.0/255.0  blue:58.0/255.0 alpha:1.0];
    lineSymbol.width = 6;
 
    NSMutableArray *points = [[NSMutableArray alloc] initWithCapacity:0];
    NSMutableArray *lines = [[NSMutableArray alloc] initWithCapacity:0];
    [self.graphicsLayer removeAllGraphics];
    [self.mapView.callout removeFromSuperview];
    [self.graphicsLayer dataChanged];
    [_scrollView removeFromSuperview];
    _scrollView = nil;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        for(NBSimpleRoute *item in _route.simpleRouteList){
            if(item.turnlatlon.length > 0 && item.streetLatLon.length > 0){
                AGSGraphic * pointgra= nil;
                AGSGraphic * linegra=nil;
                AGSMutablePolyline* poly = [[AGSMutablePolyline alloc] initWithSpatialReference:self.mapView.spatialReference];
                [poly addPathToPolyline];
                
                NSArray *array = [item.turnlatlon componentsSeparatedByString:@","];
                if(array.count == 2){
                    AGSPoint *point = [AGSPoint pointWithX:[[array objectAtIndex:0] doubleValue] y:[[array objectAtIndex:1] doubleValue] spatialReference:self.mapView.spatialReference];
                    pointgra = [AGSGraphic graphicWithGeometry:point symbol:nil attributes:nil infoTemplateDelegate:nil];
                    pointgra.symbol = jingguo;
                    [points addObject:pointgra];
                }
                
                NSArray *latlon=[item.streetLatLon componentsSeparatedByString:@";"];
                for (int i=0; i<latlon.count; i++) {
                    NSString *str=[latlon objectAtIndex:i];
                    NSArray *coor=[str componentsSeparatedByString:@","];
                    if(coor.count==2){
                        AGSPoint *point =	[AGSPoint pointWithX:[[coor objectAtIndex:0] doubleValue]  y: [[coor objectAtIndex:1] doubleValue] spatialReference:nil];
                        [poly addPointToPath:point];
                    }
                }
                linegra = [AGSGraphic graphicWithGeometry:poly symbol:lineSymbol attributes:nil infoTemplateDelegate:nil];
                [lines addObject:linegra];
                
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.graphicsLayer addGraphics:lines];
            [self.graphicsLayer addGraphics:points];
            NSArray *array = [_route.orig componentsSeparatedByString:@","];
            if(array.count == 2){
                [self addStartPoint:[AGSPoint pointWithX:[[array objectAtIndex:0] doubleValue] y:[[array objectAtIndex:1] doubleValue] spatialReference:nil]];
            }
            array = [_route.dest componentsSeparatedByString:@","];
            if(array.count == 2){
                [self addEndPoint:[AGSPoint pointWithX:[[array objectAtIndex:0] doubleValue] y:[[array objectAtIndex:1] doubleValue] spatialReference:nil]];
            }
            [self.graphicsLayer dataChanged];
            if(_route.scale.length>0 && _route.center.length > 0){
                array = [_route.center componentsSeparatedByString:@","];
                [self zooMapToLevel:[_route.scale intValue]+2 withCenter:[AGSPoint pointWithX:[[array objectAtIndex:0] doubleValue] y:[[array objectAtIndex:1] doubleValue] spatialReference:nil]];
            }
        });
    });
}

- (void)didGetBusLines:(NSArray *)lineList{
    [SVProgressHUD dismiss];
    _lineList = lineList;
    if(_lineList && _lineList.count > 0){
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }else{
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    [self.graphicsLayer removeAllGraphics];
    [self.mapView.callout removeFromSuperview];
    [self.graphicsLayer dataChanged];
    
    if(!_scrollView){
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height- 44, self.view.frame.size.width, 44)];
        _scrollView.backgroundColor = [UIColor whiteColor];
        _scrollView.userInteractionEnabled = YES;
    }
    [self.view addSubview:_scrollView];
    _scrollView.contentSize = CGSizeMake(_lineList.count * 120 , 44);
    for(int i = 0; i<_lineList.count; i++){
        NBLine *line = [_lineList objectAtIndex:i];
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        btn.backgroundColor = [UIColor clearColor];
        btn.frame = CGRectMake((20+i*100), 8, 80, 28);
        btn.titleLabel.font = [UIFont systemFontOfSize:14];
        [btn setTitle:line.lineName forState:UIControlStateNormal];
        [btn setUserInteractionEnabled:YES];
        [_scrollView addSubview:btn];
    }
}

- (NSString*)getAddressFromPlacemark:(CLPlacemark*)mark
{
    // for English Language
    NSString *tmp = nil;
    if (mark) {
        // check name isEqual to @[subToroughfare thoroughfare]
        BOOL bUseName = YES;
        if (mark.name) {
            if (mark.thoroughfare) {
                if (mark.subThoroughfare) {
                    bUseName = ![mark.name isEqualToString:[NSString stringWithFormat:@"%@ %@", mark.subThoroughfare, mark.thoroughfare]];
                } else {
                    bUseName = ![mark.name isEqualToString:mark.thoroughfare];
                }
            }
        }
        
        tmp = [NSString stringWithFormat:@"%@%@%@",
               (mark.name.length && bUseName) ? [NSString stringWithFormat:@"%@, ", mark.name]:@"",
               mark.subThoroughfare.length ? [NSString stringWithFormat:@"%@ ", mark.subThoroughfare]:@"",
               mark.thoroughfare.length ? [NSString stringWithFormat:@"%@, ", mark.thoroughfare]:@""];
    }
    
    return tmp;
}



@end
