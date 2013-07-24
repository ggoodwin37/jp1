//
//  LauncherExportPackDialog.m
//  JumpProto
//
//  Created by Gideon Goodwin on 2/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LauncherExportPackDialog.h"

@implementation LauncherExportPackDialog

@synthesize theEmailAddressTextView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.theEmailAddressTextView.text = @"TODO theEmailAddressTextView";
    }
    return self;
}

-(void)dealloc
{
    self.theEmailAddressTextView = nil;
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


-(IBAction)onExportButtonPressed:(id)sender
{
    if( self.theEmailAddressTextView.text != nil && ![self.theEmailAddressTextView.text isEqualToString:@""] )
    {
        [m_parentWeakRef onDialogClosed:LauncherUIDialog_ExportPack withStringInput:self.theEmailAddressTextView.text buttonSelection:LauncherUIButton_1];
    }
}


-(IBAction)onCancelButtonPressed:(id)sender
{
    [m_parentWeakRef onDialogClosed:LauncherUIDialog_ExportPack withStringInput:nil buttonSelection:LauncherUIButton_2];
}


@end
