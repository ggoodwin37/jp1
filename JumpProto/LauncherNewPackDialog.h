//
//  LauncherNewPackDialog.h
//  JumpProto
//
//  Created by Gideon Goodwin on 2/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ILauncherUI.h"

// didn't feel like putting this in a separate file.
@interface LauncherDialogBase : UIViewController<ILauncherUIChild>
{
    NSObject<ILauncherUIParent> *m_parentWeakRef;
}

@end


@interface LauncherNewPackDialog : LauncherDialogBase
{
}

@property (nonatomic, retain) IBOutlet UITextField *theNewNameTextView;

-(IBAction)onCreateButtonPressed:(id)sender;
-(IBAction)onCancelButtonPressed:(id)sender;

@end


