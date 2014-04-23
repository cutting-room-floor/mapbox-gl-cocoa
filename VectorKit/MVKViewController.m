//
//  MVKViewController.m
//  VectorKit
//
//  Created by Justin R. Miller on 4/23/14.
//  Copyright (c) 2014 Mapbox. All rights reserved.
//

#import "MVKViewController.h"

#import "MBXViewController.h"

@implementation MVKViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor orangeColor];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self presentViewController:[MBXViewController new] animated:NO completion:nil];
}

@end
