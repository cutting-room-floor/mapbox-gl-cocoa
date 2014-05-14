//
//  MVKViewController.m
//  VectorKit
//
//  Created by Justin R. Miller on 4/23/14.
//  Copyright (c) 2014 Mapbox. All rights reserved.
//

#import "MVKViewController.h"

#import "MVKMapView.h"

@implementation MVKViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor orangeColor];

    [self.view addSubview:[[MVKMapView alloc] initWithFrame:CGRectMake(50, 50, 512, 512)]];
}

@end
