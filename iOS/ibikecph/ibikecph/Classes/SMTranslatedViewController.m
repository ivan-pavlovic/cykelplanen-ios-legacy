//
//  SMTranslatedViewController.m
//  iBike
//
//  Created by Ivan Pavlovic on 25/02/2013.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import "SMTranslatedViewController.h"

@interface SMTranslatedViewController ()

@end

@implementation SMTranslatedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [SMTranslation translateView:self.view];
}

@end