//
//  DrawSettingsViewController.h
//  JumpProto
//
//  Created by Gideon Goodwin on 11/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EDoc.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////// ISnapSelectionChangedConsumer
@protocol ISnapSelectionChangedConsumer

-(void)onSnapSelectionChanged:(int)newSelection;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// DrawSettingsViewController

@interface DrawSettingsViewController : UIViewController

-(IBAction)onSelectionChanged:(id)sender;

// snap
@property (nonatomic, retain) IBOutlet UISegmentedControl *segmentControl;
@property (nonatomic, assign) NSObject<ISnapSelectionChangedConsumer> *snapSelectionDelegate;  // weak


@end
