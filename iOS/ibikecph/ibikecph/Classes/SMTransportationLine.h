//
//  SMTransportationLine.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMRelation.h"
@interface SMTransportationLine : NSObject<NSCoding>

@property(nonatomic, strong) NSArray * stations;
@property(nonatomic, strong, readonly) NSString * name;
@property(nonatomic, strong, readonly) NSString* lineType;

-(id) initWithFile:(NSString*)filePath;
-(id)initWithRelation:(SMRelation*)pRelation;
-(void) loadFromFile:(NSString*)filePath;

@end
