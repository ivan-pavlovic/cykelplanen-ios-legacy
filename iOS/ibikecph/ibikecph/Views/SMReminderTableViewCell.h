//
//  SMReminderTableViewCell.h
//  I Bike CPH
//
//  Created by Igor Jerković on 7/12/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SMReminder.h"
@interface SMReminderTableViewCell : UITableViewCell
- (void)setupWithTitle:(NSString*)title;

@property(nonatomic, assign) Day currentDay;

@end
