//
//  SMBreakRouteViewController.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMBreakRouteViewController.h"
#import "SMSingleRouteInfo.h"

#import "SMTransportationCell.h"
#import "SMBikeWaypointCell.h"
#import "SMBreakRouteHeader.h"
#import "SMBreakRouteButtonCell.h"
#import "SMGeocoder.h"
#import "SMTransportation.h"
#import "SMRouteInfoViewController.h"
@interface SMBreakRouteViewController (){
    NSArray* sourceStations;
    NSArray* sourceStationsFiltered;
    NSArray* destinationStations;
    NSArray* pickerModel;
    SMAddressPickerView* addressPickerView;
    
    SMRoute* tempStartRoute;
    SMRoute* tempFinishRoute;
    
    float startDistance ;
    int startTime;
    float endDistance;
    int endTime;
}

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) NSMutableArray* stationNames;
@property (strong, nonatomic) NSMutableArray* destStationNames;

@end

@implementation SMBreakRouteViewController{
    BOOL breakRouteFailed;
    BOOL displayed;
}

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
	// Do any additional setup after loading the view.
    
    breakRouteFailed= NO;
    displayed= NO;
    
    NSString* title= translateString(@"break_route_title");
    [self.titleLabel setText:title];
    
    self.tableView.separatorStyle= UITableViewCellSeparatorStyleNone;
    
    // initialize AddressPickerView
    addressPickerView= [[SMAddressPickerView alloc] initWithFrame:self.view.bounds];
    addressPickerView.pickerView.delegate= addressPickerView;
    addressPickerView.pickerView.dataSource= self;
    addressPickerView.delegate= self;
    
    [self.view addSubview:addressPickerView];
    CGRect frm= addressPickerView.frame;
    frm.origin.y= self.view.frame.size.height;
    addressPickerView.frame= frm;
    
    if(self.tripRoute){
        self.tripRoute.delegate= self;
        
        [self.tripRoute breakRoute];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"breakRouteToRouteInfo"]){
        SMRouteInfoViewController* destVC= segue.destinationViewController;
        
        NSArray* st= [sourceStations filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.sourceStation == %@ AND SELF.destStation == %@", self.sourceStation, self.destinationStation]];
        NSAssert(st.count==1, @"Invalid route");
        SMSingleRouteInfo* singleRouteInfo= st[0];
        
        destVC.singleRouteInfo= singleRouteInfo;
        
    }
}

-(void)displayBreakRouteError{
    UIAlertView* noRouteAlertView= [[UIAlertView alloc] initWithTitle:translateString(@"break_route_no_route") message:translateString(@"break_route_cant_break") delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [noRouteAlertView show];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    if(breakRouteFailed){
        [self displayBreakRouteError];
    }else{
        [self.tableView reloadData];
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    switch (indexPath.row) {
        case 0:
            return 94;
        case 2:
            return 82;
        case 1:
            return 132;
        case 3:
            return 80;
    }
    
    return 52;
}

-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    if ( section == 0 ) {
        SMBreakRouteHeader* header = [tableView dequeueReusableCellWithIdentifier:@"breakRouteHeader"];
        [header.title setText:translateString(@"break_route_header_title")];
        [header.title sizeToFit];
        CGRect frame = header.title.frame;
        CGRect newFrame = header.routeDistance.frame;
        newFrame.origin.x = frame.origin.x + frame.size.width;
        
        float breakRouteDistance = startDistance + endDistance;
        //self.appDelegate.breakRouteDistance = breakRouteDistance;
        float tripDistance = self.tripRoute.fullRoute.estimatedRouteDistance;
        if ( breakRouteDistance < self.tripRoute.fullRoute.estimatedRouteDistance && breakRouteDistance > 0 ) {
            tripDistance = breakRouteDistance;
        }
        
        NSString* routeDistanceFormat = @" %4.1f km";
        if (tripDistance / 1000 < 10) {
            routeDistanceFormat = @"%4.1f km";
        }
        
        NSLog(@"Break route distance: %f", breakRouteDistance);
        NSString* routeDistance = [NSString stringWithFormat:routeDistanceFormat, tripDistance / 1000.0];
              
        [header.routeDistance setText:routeDistance];
        [header.routeDistance setFrame:newFrame];
        return header;
    }
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 42.0f;
}

-(int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 4;
}

-(int)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString* CellId;
    switch (indexPath.row) {
        case 0:
        {
            CellId= @"SourceCell";
            SMBikeWaypointCell* wpCell= [tableView dequeueReusableCellWithIdentifier:CellId];
            [wpCell setupWithString:self.sourceName];
            
            float fDistance = startDistance / 1000.0;
            int fTime = startTime  / 60;
            NSString* distance= @"";
            if(fDistance!=0 || fTime!=0){
                distance= [NSString stringWithFormat:@"%4.1f km  %d min.", fDistance, fTime];
            }
            [wpCell.labelDistance setText:distance];
            
            NSString* strAddress = @"address";
            
                        
            //[wpCell.labelAddressBottom setText:strAddress];
            [wpCell.labelAddressBottom setText:self.sourceAddress];
            
            return wpCell;
        }
        case 1:{
            CellId= @"TransportCell";
            SMTransportationCell* tCell= [tableView dequeueReusableCellWithIdentifier:CellId];
            tCell.selectionStyle= UITableViewCellSelectionStyleNone;
            
            // Translatations
            [tCell.buttonAddressInfo setTitle:translateString(@"route_plan_button") forState:UIControlStateNormal];
            

            CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(self.sourceStation.latitude, self.sourceStation.longitude); 
            [SMGeocoder reverseGeocode:coord completionHandler:^(NSDictionary *response, NSError *error) {
                NSString* streetName = [response objectForKey:@"title"];
                
                //NSLog(@"Response: %@", response);
                
                if ([streetName isEqualToString:@""]) {
                    streetName = [NSString stringWithFormat:@"%f, %f", coord.latitude, coord.longitude];
                }
                //[tCell.buttonAddressSource setTitle:streetName forState:UIControlStateNormal];
            }];
            
            coord = CLLocationCoordinate2DMake(self.destinationStation.latitude, self.destinationStation.longitude);
            [SMGeocoder reverseGeocode:coord completionHandler:^(NSDictionary *response, NSError *error) {
                NSString* streetName = [response objectForKey:@"title"];
                if ([streetName isEqualToString:@""]) {
                    streetName = [NSString stringWithFormat:@"%f, %f", coord.latitude, coord.longitude];
                }
                //[tCell.buttonAddressDestination setTitle:streetName forState:UIControlStateNormal];
            }];

            
            UIImage* sourceIcon = [UIImage imageNamed:@"metro_icon.png"];
            if (self.sourceStation.type == SMStationInfoTypeTrain) {
                sourceIcon = [UIImage imageNamed:@"station_icon.png"];
            } else if (self.sourceStation.type == SMStationInfoTypeMetro) {
                sourceIcon = [UIImage imageNamed:@"metro_logo_pin.png"];
            } else if (self.sourceStation.type == SMStationInfoTypeLocalTrain) {
                sourceIcon = [UIImage imageNamed:@"local_train_icon.png"];
            } else if (self.sourceStation.type == SMStationInfoTypeUndefined) {
                sourceIcon = [UIImage imageNamed:@"metro_icon.png"];
            }
            
            UIImage* destIcon = nil;
            if (self.destinationStation.type == SMStationInfoTypeTrain) {
                destIcon = [UIImage imageNamed:@"station_icon.png"];
            } else if (self.sourceStation.type == SMStationInfoTypeMetro) {
                destIcon = [UIImage imageNamed:@"metro_logo_pin.png"];
            } else if (self.sourceStation.type == SMStationInfoTypeLocalTrain) {
                destIcon = [UIImage imageNamed:@"local_train_icon.png"];
            } else if (self.sourceStation.type == SMStationInfoTypeUndefined) {
                destIcon = [UIImage imageNamed:@"metro_icon.png"];
            }
            
            if(self.sourceStation){
                [tCell.buttonAddressSource setEnabled:YES];
                [tCell.buttonAddressSource setTitle:self.sourceStation.name forState:UIControlStateNormal];
                [tCell.sourceActivityIndicator setHidden:YES];
                [tCell.sourceStationIcon setImage:sourceIcon];
            }else{
                [tCell.buttonAddressSource setEnabled:NO];
                [tCell.buttonAddressSource setTitle:@"" forState:UIControlStateNormal];
                [tCell.sourceActivityIndicator setHidden:NO];
                [tCell.sourceActivityIndicator startAnimating];
            }
            
            if(self.destinationStation){
                [tCell.buttonAddressDestination setEnabled:YES];
                [tCell.buttonAddressDestination setTitle:self.destinationStation.name forState:UIControlStateNormal];
                [tCell.destinationActivityIndicator setHidden:YES];
                [tCell.destStationIcon setImage:destIcon];
            }else{
                [tCell.buttonAddressDestination setEnabled:NO];
                [tCell.buttonAddressDestination setTitle:@"" forState:UIControlStateNormal];
                [tCell.destinationActivityIndicator setHidden:NO];
                [tCell.destinationActivityIndicator startAnimating];
            }

            
            [tCell.buttonAddressInfo setEnabled:(self.sourceStation && self.destinationStation)];

            return tCell;
        }
        case 2:{
            CellId= @"DestinationCell";
            SMBikeWaypointCell* wpCell= [tableView dequeueReusableCellWithIdentifier:CellId];
            [wpCell setupWithString:self.destinationName];
            //            [wpCell.labelAddressBottom setText:self.destinationName];
            
            float fDistance = endDistance / 1000.0;;
            int fTime = endTime  / 60;
            NSString* distance= @"";
            if(fDistance!=0 || fTime!=0){
                distance= [NSString stringWithFormat:@"%4.1f km  %d min.", fDistance, fTime];
            }else{
                distance= @"";
            }
            [wpCell.labelDistance setText:distance];
            //[wpCell.labelAddressBottom setText:@"Address"];
            [wpCell.labelAddressBottom setText:self.destinationAddress];
            
            return wpCell;
            
        }
        case 3:{
            CellId= @"ButtonCell";
            SMBreakRouteButtonCell* cell= [tableView dequeueReusableCellWithIdentifier:CellId];
            [cell.btnBreakRoute setTitle:translateString(@"break_route_title") forState:UIControlStateNormal];
            [cell.btnBreakRoute setEnabled:(self.sourceStation && self.destinationStation)];
            return cell;
        }
        default:
            break;
    }
    
    return nil;
}

-(NSString*)formatAddressComponent:(NSString*)comp{
    NSString* trimmed= [comp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    int i = 0;
    
    while ((i < [trimmed length])
           && [[NSCharacterSet whitespaceCharacterSet] characterIsMember:[trimmed characterAtIndex:i]]) {
        i++;
    }
    return [trimmed substringFromIndex:i];
}

- (IBAction)onBack:(id)sender {
    [self dismiss];
}

-(void)dismiss{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{}

- (void)viewDidUnload {
    [self setTitle:nil];
    [self setButtonAddressSource:nil];
    [self setButtonAddressDestination:nil];
    [super viewDidUnload];
}

-(IBAction)onSourceAddressButtonTap:(id)sender {
    [self displayAddressViewWithAddressType:AddressTypeSource model:sourceStationsFiltered];
}

-(void)displayAddressViewWithAddressType:(AddressType)pAddressType model:(NSArray*)pModel{
    addressPickerView.addressType= pAddressType;
    //pickerModel= pModel;
    
    pickerModel = [pModel sortedArrayUsingComparator:^NSComparisonResult(id a, id b)
    {
        if (![a isKindOfClass:[SMStationInfo class]] || ![b isKindOfClass:[SMStationInfo class]]) {
            return NO;
        } else {
            SMStationInfo* stationA = (SMStationInfo*)a;
            SMStationInfo* stationB = (SMStationInfo*)b;
            return [stationA.name compare:stationB.name];
        }
    }];
    
    [addressPickerView displayAnimated];
}

-(IBAction)onDestinationAddressButtonTap:(id)sender {
    [self displayAddressViewWithAddressType:AddressTypeDestination model:destinationStations];
}

-(IBAction)onInfoTap:(id)sender{}

#pragma mark - picker view

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return pickerModel.count;
}

- (IBAction)onBreakRoute:(id)sender {
    SMBrokenRouteInfo* brokenRouteInfo= [[SMBrokenRouteInfo alloc] init];
    brokenRouteInfo.sourceStation= self.sourceStation;;
    brokenRouteInfo.destinationStation= self.destinationStation;
    
    NSArray* st= [sourceStations filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.sourceStation == %@ AND SELF.destStation == %@", self.sourceStation, self.destinationStation]];
    NSAssert(st.count==1, @"Invalid route");
    SMSingleRouteInfo* singleRouteInfo= st[0];
    brokenRouteInfo.transportationLine= singleRouteInfo.transportationLine;
    
    self.tripRoute.brokenRouteInfo= brokenRouteInfo;
}

-(NSString*)addressView:(SMAddressPickerView *)pAddressPickerView titleForRow:(int)row{
    SMStationInfo* info= [pickerModel objectAtIndex:row];
    return info.name;
}

- (void)didFinishBreakingRoute:(SMTripRoute*)route{
    [self.tableView reloadData];
    [SMUser user].tripRoute= self.tripRoute;
    [SMUser user].route= self.fullRoute;
    [self dismiss];
}

-(void)addressView:(SMAddressPickerView*)pAddressPickerView didSelectItemAtIndex:(int)index forAddressType:(AddressType)pAddressType{
    NSAssert(pAddressType!=AddressTypeUndefined, @"Address type is undefined");
    if(pAddressType==AddressTypeDestination){
        self.destinationStation= pickerModel[index];
        
    }else if(pAddressType==AddressTypeSource){
        self.sourceStation= pickerModel[index];
        
        addressPickerView.destinationCurrentIndex= 0;
        destinationStations= [self endStationsForSourceStation:self.sourceStation];
        self.destinationStation= destinationStations[0];
        
    }
    [self.tableView reloadData];
}


#pragma mark - break route delegate

-(void)didStartBreakingRoute:(SMTripRoute*)route{}

-(void)didFailBreakingRoute:(SMTripRoute*)route{}

-(void)didCalculateRouteDistances:(SMTripRoute*)route{
    //    sourceStationsFiltered= [[NSSet setWithArray:arr] allObjects];
    NSArray* arr=[route.transportationRoutes valueForKey:@"sourceStation"];
    NSMutableArray* temp= [NSMutableArray new];
    for(int i=0; i<arr.count; i++){
        SMStationInfo* station= [arr objectAtIndex:i];
        if(![temp containsObject:station]){
            [temp addObject:station];
        }
    }
    sourceStationsFiltered= [NSArray arrayWithArray:temp];
    sourceStations= [NSArray arrayWithArray:route.transportationRoutes];
    
    for(SMSingleRouteInfo* routeInfo in route.transportationRoutes){
        NSLog(@"%@ - %@ - %lf",routeInfo.sourceStation.name, routeInfo.destStation.name, routeInfo.bikeDistance);
    }
    
    if(route.transportationRoutes.count > 0){
        SMSingleRouteInfo* routeInfo= [route.transportationRoutes objectAtIndex:0];
        
        destinationStations= [self endStationsForSourceStation:routeInfo.sourceStation];
        [self performSelectorOnMainThread:@selector(setSourceStation:) withObject:routeInfo.sourceStation waitUntilDone:YES];
        
        //        routeInfo=[destinationStations objectAtIndex:0];
        
        [self performSelectorOnMainThread:@selector(setDestinationStation:) withObject:routeInfo.destStation waitUntilDone:YES];
    }else{
        if(displayed){
            [self displayBreakRouteError];
        }else{
            breakRouteFailed= YES;
        }
    }
    
    [self.tableView reloadData];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    [self dismiss];
}

-(NSArray*)endStationsForSourceStation:(SMStationInfo*)pSourceStation{
    
    return [[self.tripRoute.transportationRoutes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.sourceStation == %@",pSourceStation]] valueForKey:@"destStation"] ;
}

#pragma mark - getters and setters

-(void)setSourceStation:(SMStationInfo *)pSourceStation{
    _sourceStation= pSourceStation;
    
    if(pSourceStation.type==SMStationInfoTypeLocalTrain){
        NSLog(@"LocalTrain");
    }
    
    CLLocationCoordinate2D start= self.tripRoute.start.coordinate;
    CLLocationCoordinate2D end= pSourceStation.location.coordinate;
    
    if(tempStartRoute){
        [tempStartRoute removeObserver:self forKeyPath:@"estimatedRouteDistance"];
        [tempStartRoute removeObserver:self forKeyPath:@"estimatedTimeForRoute"];
    }
    
    tempStartRoute= [[SMRoute alloc] initWithRouteStart:start andEnd:end andDelegate:nil];
    [tempStartRoute addObserver:self
                     forKeyPath:@"estimatedRouteDistance"
                        options:NSKeyValueObservingOptionNew
                        context:(__bridge void *)(tempStartRoute)];
    [tempStartRoute addObserver:self
                     forKeyPath:@"estimatedTimeForRoute"
                        options:NSKeyValueObservingOptionNew
                        context:(__bridge void *)(tempStartRoute)];
    
    addressPickerView.sourceCurrentIndex= [sourceStationsFiltered indexOfObject:pSourceStation];
}

-(void)setDestinationStation:(SMStationInfo *)pDestinationStation{
    _destinationStation= pDestinationStation;
    NSLog(@"Destination station set to %@",self.destinationStation.name);
    CLLocationCoordinate2D start= pDestinationStation.location.coordinate;
    CLLocationCoordinate2D end= self.tripRoute.end.coordinate;
    if(tempFinishRoute){
        [tempFinishRoute removeObserver:self forKeyPath:@"estimatedRouteDistance"];
        [tempFinishRoute removeObserver:self forKeyPath:@"estimatedTimeForRoute"];
    }
    
    tempFinishRoute= [[SMRoute alloc] initWithRouteStart:start andEnd:end andDelegate:nil];
    [tempFinishRoute addObserver:self
                      forKeyPath:@"estimatedRouteDistance"
                         options:NSKeyValueObservingOptionNew
                         context:(__bridge void *)(tempFinishRoute)];
    [tempFinishRoute addObserver:self
                      forKeyPath:@"estimatedTimeForRoute"
                         options:NSKeyValueObservingOptionNew
                         context:(__bridge void *)(tempFinishRoute)];
    
    addressPickerView.destinationCurrentIndex= [destinationStations indexOfObject:pDestinationStation];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"estimatedRouteDistance"]){
        // distance changedΩΩ
        
        if(context==(__bridge void *)(tempStartRoute)){
            NSLog(@"Start route distance changed to %d",tempStartRoute.estimatedRouteDistance);
            startDistance= tempStartRoute.estimatedRouteDistance;
        }else if(context==(__bridge void *)(tempFinishRoute)){
            NSLog(@"Finish route distance changed to %d",tempFinishRoute.estimatedRouteDistance);
            endDistance= tempFinishRoute.estimatedRouteDistance;
        }
        
        [self distanceChanged];
    }else if([keyPath isEqualToString:@"estimatedTimeForRoute"]){
        // time changed
        
        if(context==(__bridge void *)(tempStartRoute)){
            NSLog(@"Start route distance changed to %d",tempStartRoute.estimatedRouteDistance);
            startTime= tempStartRoute.estimatedTimeForRoute;
        }else if(context==(__bridge void *)(tempFinishRoute)){
            NSLog(@"Finish route distance changed to %d",tempFinishRoute.estimatedRouteDistance);
            endTime= tempFinishRoute.estimatedTimeForRoute;
        }
        
        [self timeChanged];
        
    }
}

-(void)timeChanged{
    [self.tableView reloadData];
}

-(void)distanceChanged{
    [self.tableView reloadData];
}

-(void)dealloc{
    [tempFinishRoute removeObserver:self forKeyPath:@"estimatedRouteDistance"];
    [tempFinishRoute removeObserver:self forKeyPath:@"estimatedTimeForRoute"];
    [tempStartRoute removeObserver:self forKeyPath:@"estimatedRouteDistance"];
    [tempStartRoute removeObserver:self forKeyPath:@"estimatedTimeForRoute"];
    
    tempStartRoute= nil;
    tempFinishRoute= nil;
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

@end
