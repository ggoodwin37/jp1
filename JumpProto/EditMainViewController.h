//
//  EditMainViewController.h
//  JumpProto
//
//  Created by gideong on 10/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "IParentChildVC.h"
#import "EWorldView.h"
#import "EExtentView.h"
#import "EDoc.h"
#import "EBlockPaletteViewController.h"
#import "EDocPropsViewController.h"
#import "GroupPickerViewController.h"
#import "DrawSettingsViewController.h"

@interface EditMainViewController : UIViewController<IChildVC, ICurrentBlockPresetStateHolder,
                                                     IWorldViewEventCallback, UITextFieldDelegate,
                                                     ICurrentGroupIdChangedConsumer, ISnapSelectionChangedConsumer > {

    id<IParentVC> m_parentVC;
    
    BOOL m_fDirty;
    
    CGColorRef m_editToolButtonsActiveBorderColor;
    CGColorRef m_editToolButtonsInactiveBorderColor;
    
    BOOL m_fBlockPaletteOpen;
    
    EGridDocument *m_doc;
    
    NSString *m_startingLevel;
    
    EBlockPreset m_currentlySelectedPreset;

}

@property (nonatomic, retain) IBOutlet EWorldView *worldView;
@property (nonatomic, retain) IBOutlet EExtentView *extentView;
@property (nonatomic, retain) IBOutlet UIImageView *currentToolView;

@property (nonatomic, retain) IBOutlet UIView   *editToolsBarView;
@property (nonatomic, retain) IBOutlet UIButton *editToolsDrawBlocksButton;
@property (nonatomic, retain) IBOutlet UIButton *editToolsEraseButton;
@property (nonatomic, retain) IBOutlet UIButton *editToolsGrabButton;
@property (nonatomic, retain) IBOutlet UIButton *editToolsGroupButton;

@property (nonatomic, retain) IBOutlet UIBarButtonItem *showHideEditToolsButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *showHideGridButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *showHideGeoModeButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *showHidePropsButton;

@property (nonatomic, retain) EBlockPaletteViewController *editToolsBlockPaletteVC;
@property (nonatomic, retain) EDocPropsViewController *docPropsVC;
@property (nonatomic, retain) GroupPickerViewController *groupPickerVC;
@property (nonatomic, retain) DrawSettingsViewController *drawSettingsVC;

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;

-(void)setParentDelegate:(id<IParentVC>)parent;
-(void)setStartingLevel:(NSString *)levelName;

-(IBAction)onMasterToolsExitButtonPressed:(id)sender;

-(IBAction)onEditToolsBlockPressed:(id)sender;
-(IBAction)onEditToolsErasePressed:(id)sender;
-(IBAction)onEditToolsGrabPressed:(id)sender;
-(IBAction)onEditToolsGroupPressed:(id)sender;

-(IBAction)onShowHideEditToolsButtonPressed:(id)sender;
-(IBAction)onShowHideGridButtonPressed:(id)sender;
-(IBAction)onShowHideGeoModeButtonPressed:(id)sender;

-(IBAction)onDocPropsButtonPressed:(id)sender;

-(IBAction)onMasterToolsSaveButtonPressed:(id)sender;

@end
