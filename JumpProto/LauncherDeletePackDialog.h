//
//  LauncherDeletePackDialog.h
//  JumpProto
//
//  Created by Gideon Goodwin on 2/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ILauncherUI.h"
#import "LauncherNewPackDialog.h"  // LauncherDialogBase

@interface LauncherDeletePackDialog : LauncherDialogBase


@property (nonatomic, retain) IBOutlet UILabel *theLabel;

-(IBAction)onYesButtonPressed:(id)sender;
-(IBAction)onNoButtonPressed:(id)sender;
-(IBAction)onCancelButtonPressed:(id)sender;

@end
