//
//  MVKViewController.m
//  MVKMapKit
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

    MVKMapView *mapView = [[MVKMapView alloc] initWithFrame:CGRectMake(50, 50, 512, 512)];
    [self.view addSubview:mapView];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void)
    {
        [mapView setCenterCoordinate:CLLocationCoordinate2DMake(45, -122) animated:YES];
    });
}

@end
