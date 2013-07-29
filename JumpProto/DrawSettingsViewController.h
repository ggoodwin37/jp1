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


/////////////////////////////////////////////////////////////////////////////////////////////////////////// IBrushSizeChangedConsumer
@protocol IBrushSizeChangedConsumer

-(void)onBrushSizeChanged:(EGridPoint *)newSize;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// DrawSettingsViewController

@interface DrawSettingsViewController : UIViewController

-(IBAction)onSelectionChanged:(id)sender;
-(IBAction)valueChanged:(id)sender;

// snap
@property (nonatomic, retain) IBOutlet UISegmentedControl *segmentControl;
@property (nonatomic, assign) NSObject<ISnapSelectionChangedConsumer> *snapSelectionDelegate;  // weak

// brush size
@property (nonatomic, assign) NSObject<IBrushSizeChangedConsumer> *brushSizeDelegate;  // weak
@property (nonatomic, retain) IBOutlet UITextField *currentWidthTextField;
@property (nonatomic, retain) IBOutlet UIStepper *widthStepper;
@property (nonatomic, retain) IBOutlet UITextField *currentHeightTextField;
@property (nonatomic, retain) IBOutlet UIStepper *heightStepper;
@property (nonatomic, retain) IBOutlet UIButton *sizePresetButton_4x4;
@property (nonatomic, retain) IBOutlet UIButton *sizePresetButton_2x2;
@property (nonatomic, retain) IBOutlet UIButton *sizePresetButton_8x8;
@property (nonatomic, retain) IBOutlet UIButton *sizePresetButton_32x4;
@property (nonatomic, retain) IBOutlet UIButton *sizePresetButton_8x4;
@property (nonatomic, retain) IBOutlet UIButton *sizePresetButton_4x8;
@property (nonatomic, retain) IBOutlet UIButton *sizePresetButton_12x12;
@property (nonatomic, retain) IBOutlet UIButton *sizePresetButton_16x16;
@property (nonatomic, retain) IBOutlet UIStepper *width4Stepper;
@property (nonatomic, retain) IBOutlet UIStepper *height4Stepper;

-(void)updateTextFields;


@end
