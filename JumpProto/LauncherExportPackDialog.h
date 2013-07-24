//
//  LauncherExportPackDialog.h
//  JumpProto
//
//  Created by Gideon Goodwin on 2/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ILauncherUI.h"
#import "LauncherNewPackDialog.h"  // LauncherDialogBase

@interface LauncherExportPackDialog : LauncherDialogBase

@property (nonatomic, retain) IBOutlet UITextField *theEmailAddressTextView;

-(IBAction)onExportButtonPressed:(id)sender;
-(IBAction)onCancelButtonPressed:(id)sender;


@end
