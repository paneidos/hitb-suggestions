//
//  PDDetailViewController.m
//  HITB Suggestions
//
//  Created by Sernin van de Krol on 29/05/14.
//  Copyright (c) 2014 Paneidos Desu. All rights reserved.
//

#import "PDDetailViewController.h"

@interface PDDetailViewController ()
- (void)configureView;
@end

@implementation PDDetailViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }
}

- (void)configureView
{
    // Update the user interface for the detail item.

    if (self.detailItem) {
        self.detailDescriptionLabel.text = [self.detailItem description];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
