//
//  LauncherNewPackDialog.m
//  JumpProto
//
//  Created by Gideon Goodwin on 2/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LauncherNewPackDialog.h"

@implementation LauncherDialogBase

-(void)setParent:(NSObject<ILauncherUIParent> *)parentWeakRef
{
    m_parentWeakRef = parentWeakRef;
}


-(void)setLabel:(LauncherUILabelId)label toString:(NSString *)labelString
{
    NSLog( @"LauncherDialogBase setLabel: ignored." );
}

@end


@implementation LauncherNewPackDialog

@synthesize theNewNameTextView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if( self )
    {
    }
    return self;
}

-(void)dealloc
{
    self.theNewNameTextView = nil;
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


-(IBAction)onCreateButtonPressed:(id)sender
{
    if( self.theNewNameTextView.text != nil && ![self.theNewNameTextView.text isEqualToString:@""] )
    {
        [m_parentWeakRef onDialogClosed:LauncherUIDialog_NewPack withStringInput:self.theNewNameTextView.text buttonSelection:LauncherUIButton_1];
    }
}


-(IBAction)onCancelButtonPressed:(id)sender
{
    [m_parentWeakRef onDialogClosed:LauncherUIDialog_NewPack withStringInput:nil buttonSelection:LauncherUIButton_2];
}


@end
