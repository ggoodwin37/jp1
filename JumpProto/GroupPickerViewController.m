//
//  GroupPickerViewController.m
//  JumpProto
//
//  Created by Gideon Goodwin on 10/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GroupPickerViewController.h"

@interface GroupPickerViewController ()

@end

@implementation GroupPickerViewController

@synthesize currentGroupTextField, groupStepper;

@synthesize currentGroupId;

@synthesize groupIdChangedDelegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.currentGroupId = GROUPID_NONE;
        self.groupIdChangedDelegate = nil;  // weak
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self onGroupIdChanged];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    
    self.groupIdChangedDelegate = nil;

    self.currentGroupTextField = nil;
    self.groupStepper = nil;
}


-(void)onGroupIdChanged
{
    NSString *value;
    if( self.currentGroupId == GROUPID_NONE )
    {
        value = @"==";
    }
    else
    {
        char c = (char)(self.currentGroupId - GROUPID_FIRST + 'A');
        value = [NSString stringWithFormat:@"%c", c];
    }
    
    self.currentGroupTextField.text = value;
}


- (IBAction)valueChanged:(UIStepper *)sender {
    int value = (int)floorf( [sender value] );
    value = MAX( 0, MIN( value, 99) );
    
    self.currentGroupId = value;
    [self onGroupIdChanged];
    
    if( self.groupIdChangedDelegate != nil )
        [self.groupIdChangedDelegate onCurrentGroupIdChanged:self.currentGroupId];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsLandscape( interfaceOrientation );
}

@end
