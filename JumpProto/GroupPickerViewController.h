//
//  GroupPickerViewController.h
//  JumpProto
//
//  Created by Gideon Goodwin on 10/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "sharedTypes.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////// ICurrentGroupIdChangedConsumer
@protocol ICurrentGroupIdChangedConsumer

-(void)onCurrentGroupIdChanged:(GroupId)newGroupId;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// GroupPickerViewController

@interface GroupPickerViewController : UIViewController

@property (nonatomic, retain) IBOutlet UITextField *currentGroupTextField;
@property (nonatomic, retain) IBOutlet UIStepper *groupStepper;

@property (nonatomic, assign) GroupId currentGroupId;

@property (nonatomic, assign) NSObject<ICurrentGroupIdChangedConsumer> *groupIdChangedDelegate;  // weak

@end
