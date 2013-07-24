//
//  LauncherDeletePackDialog.m
//  JumpProto
//
//  Created by Gideon Goodwin on 2/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LauncherDeletePackDialog.h"

@implementation LauncherDeletePackDialog

@synthesize theLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
    }
    return self;
}

-(void)dealloc
{
    self.theLabel = nil;
    [super dealloc];
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}


// ILauncherUIChild

-(void)setLabel:(LauncherUILabelId)label toString:(NSString *)labelString
{
    self.theLabel.text = labelString;
}


-(IBAction)onYesButtonPressed:(id)sender
{
    [m_parentWeakRef onDialogClosed:LauncherUIDialog_DeletePack withStringInput:nil buttonSelection:LauncherUIButton_1];
}


-(IBAction)onNoButtonPressed:(id)sender
{
    [m_parentWeakRef onDialogClosed:LauncherUIDialog_DeletePack withStringInput:nil buttonSelection:LauncherUIButton_2];
}


-(IBAction)onCancelButtonPressed:(id)sender
{
    [m_parentWeakRef onDialogClosed:LauncherUIDialog_DeletePack withStringInput:nil buttonSelection:LauncherUIButton_3];
}


@end
