//
//  DrawSettingsViewController.m
//  JumpProto
//
//  Created by Gideon Goodwin on 11/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DrawSettingsViewController.h"

@interface DrawSettingsViewController ()

@end

@implementation DrawSettingsViewController

@synthesize segmentControl, snapSelectionDelegate;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.snapSelectionDelegate = nil;
    }
    return self;
}


-(void)viewDidLoad
{
    [super viewDidLoad];

    [self.segmentControl removeAllSegments];
    [self.segmentControl insertSegmentWithTitle:@"1" atIndex:0 animated:NO];
    [self.segmentControl insertSegmentWithTitle:@"2" atIndex:1 animated:NO];
    [self.segmentControl insertSegmentWithTitle:@"4" atIndex:2 animated:NO];
    [self.segmentControl insertSegmentWithTitle:@"8" atIndex:3 animated:NO];
}


- (void)viewDidUnload
{
    [super viewDidUnload];

    self.segmentControl = nil;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsLandscape( interfaceOrientation );
}

-(IBAction)onSelectionChanged:(id)sender
{
    if( sender == self.segmentControl )
    {
        if( self.snapSelectionDelegate != nil )
        {
            [self.snapSelectionDelegate onSnapSelectionChanged:(int)self.segmentControl.selectedSegmentIndex];
        }
    }
}

@end
