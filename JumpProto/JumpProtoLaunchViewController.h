//
//  JumpProtoLaunchViewController.h
//  JumpProto
//
//  Created by gideong on 9/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "JumpProtoAppDelegate.h"
#import "DpadInput.h"
#import "IParentChildVC.h"

@interface JumpProtoLaunchViewController : UIViewController <IAppStartStop, IParentVC, UIPickerViewDataSource, UIPickerViewDelegate> {
    UIViewController<IChildVC> *m_childViewController;
    
    NSArray *m_levelPickerViewContents;
    int m_lastPickedLevelRow;
}

@property (nonatomic, retain) IBOutlet UIPickerView *levelPickerView;
@property (nonatomic, retain) IBOutlet UISwitch *deleteArmedSwitch;

@property (nonatomic, retain) IBOutlet UISwitch *loadFromDiskSwitch;

@property (nonatomic, retain) NSString *exitedLevelName;

@property (nonatomic, retain) DpadInput *dpadInput;

-(IBAction)onPlayButtonTouched:(id)sender;
-(IBAction)onEditButtonTouched:(id)sender;
-(IBAction)onDeleteButtonTouched:(id)sender;

-(void)onAppStart;
-(void)onAppStop;

@end
