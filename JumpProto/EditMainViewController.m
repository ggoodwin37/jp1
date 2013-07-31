//
//  EditMainViewController.m
//  JumpProto
//
//  Created by gideong on 10/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EditMainViewController.h"
#import "EArchiveUtil.h"
#import "constants.h"
#import "SpriteManager.h"
#import "LevelUtil.h"
#import "RandomNameGenerator.h"

@interface EditMainViewController (private)

-(void)setEditToolButtonHighlightStateForCurrentToolMode;
-(void)setStringsForShowHideButtons;
+(NSString *)nextLevelName;
+(NSString *)sanitizeLevelName:(NSString *)nameIn;
@end


@implementation EditMainViewController

@synthesize worldView, currentToolView;
@synthesize editToolsDrawBlocksButton, editToolsEraseButton, editToolsBarView;
@synthesize editToolsGrabButton, editToolsGroupButton;
@synthesize editToolsBlockPaletteVC;
@synthesize showHideEditToolsButton, showHideGridButton, showHidePropsButton;
@synthesize docPropsVC, groupPickerVC, drawSettingsVC;

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if( self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil] )
    {
        m_doc = [[EGridDocument alloc] init];        
        
        [SpriteManager initGlobalInstance];
        [[SpriteManager instance] loadAllImages];

        self.editToolsBlockPaletteVC = [[EBlockPaletteViewController alloc] initWithNibName:@"EBlockPaletteViewController" bundle:nil];

        self.docPropsVC = [[EDocPropsViewController alloc] initWithNibName:@"EDocPropsViewController" bundle:nil doc:m_doc];
        
        self.groupPickerVC = [[GroupPickerViewController alloc] initWithNibName:@"GroupPickerViewController" bundle:nil];
        self.drawSettingsVC = [[DrawSettingsViewController alloc] initWithNibName:@"DrawSettingsViewController" bundle:nil];
    }
    return self;
}


-(void)dealloc
{
    self.worldView.document = nil;
    self.worldView = nil;
    self.currentToolView = nil;
    
    self.editToolsDrawBlocksButton = nil;
    self.editToolsEraseButton = nil;
    self.editToolsGrabButton = nil;
    self.editToolsGroupButton = nil;
    self.editToolsBarView = nil;
    
    self.docPropsVC = nil;
    self.editToolsBlockPaletteVC = nil;
    self.groupPickerVC = nil;
    self.drawSettingsVC = nil;
    
    self.showHidePropsButton = nil;
    self.showHideEditToolsButton = nil;
    self.showHideGridButton = nil;
    
    [m_doc release]; m_doc = nil;
    [m_startingLevel release]; m_startingLevel = nil;
    
    [SpriteManager releaseGlobalInstance];

    [super dealloc];
}


-(void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
    
    NSLog( @"EditMainViewController didReceiveMemoryWarning." );
}

#pragma mark - View lifecycle

-(CGRect)getInitialWorldViewRect
{
    const float initialZoomFactor = 0.25f;
    const float yardstick = GRID_SIZE_Fl;
    
    float w = self.worldView.frame.size.width / initialZoomFactor;
    float h = self.worldView.frame.size.height / initialZoomFactor;
    
    NSArray *markerList = [m_doc getValues];
    if( [markerList count] == 0 )
    {
        // since we don't allow negative values, start them pretty far from origin so they can build up/left a ways if they want.
        return CGRectMake( 4096.f * yardstick, 4096.f * yardstick, w, h );
    }
    
    int xMin = INT_MAX;
    int yMin = INT_MAX;
    for( int i = 0; i < [markerList count]; ++i )
    {
        EGridBlockMarker *thisMarker = (EGridBlockMarker *)[markerList objectAtIndex:i];
        if( thisMarker.shadowParent != nil )
        {
            continue;
        }
        if( thisMarker.preset == EBlockPreset_PlayerStart || thisMarker.preset == EBlockPreset_tiny_playerStart )
        {
            return CGRectMake( thisMarker.gridLocation.xGrid * yardstick - (w / 2.f),
                               thisMarker.gridLocation.yGrid * yardstick - (h / 2.f),
                               w, h );
        }
        xMin = MIN( xMin, thisMarker.gridLocation.xGrid );
        yMin = MIN( yMin, thisMarker.gridLocation.yGrid );
    }
    
    // if we never found a PlayerStart marker, just assign the starting point to some block somewhere.
    return CGRectMake( xMin * yardstick, yMin * yardstick, w, h );
}


-(void)viewDidLoad
{
    [super viewDidLoad];

    // set rounded corners on editToolsContainerView.
    [[self.editToolsBarView layer] setCornerRadius:8.0f];
    [[self.editToolsBarView layer] setMasksToBounds:YES];
    [[self.editToolsBarView layer] setBorderWidth:1.0f];
    
    m_editToolButtonsActiveBorderColor = [[UIColor yellowColor] CGColor];
    m_editToolButtonsInactiveBorderColor = [self.editToolsEraseButton layer].borderColor;
    
    [[self.editToolsDrawBlocksButton layer] setBorderWidth:1.0f];
    [[self.editToolsEraseButton layer] setBorderWidth:1.0f];
    [[self.editToolsGrabButton layer] setBorderWidth:1.0f];
    [[self.editToolsGroupButton layer] setBorderWidth:1.0f];
    
    self.worldView.document = m_doc;
    self.worldView.currentToolMode = ToolModeDrawBlock;
    [self.worldView setPresetStateHolder:self];
    self.worldView.worldViewEventCallback = self;
    
    [self setEditToolButtonHighlightStateForCurrentToolMode];
    
    const BOOL fBlockPaletteInitiallyOpen = NO;
    m_fBlockPaletteOpen = fBlockPaletteInitiallyOpen;  
    self.editToolsBlockPaletteVC.view.hidden = !fBlockPaletteInitiallyOpen;
    
    const float kInset = 20.f;

    // this bit of manual layout will place the palette against the right edge, below the editToolBar.
    CGRect rBlockPalette = CGRectMake( self.view.frame.size.width - self.editToolsBlockPaletteVC.view.frame.size.width - kInset,
                                       self.editToolsBarView.frame.origin.y + self.editToolsBarView.frame.size.height + kInset,
                                       self.editToolsBlockPaletteVC.view.frame.size.width,
                                       self.editToolsBlockPaletteVC.view.frame.size.height );    
    [self.editToolsBlockPaletteVC.view setFrame:rBlockPalette];
    m_currentlySelectedPreset = [self.editToolsBlockPaletteVC getDefaultPreset];
    [self.editToolsBlockPaletteVC selectPreset:m_currentlySelectedPreset];
    [self.editToolsBlockPaletteVC setPresetStateHolder:self];
    [self.view addSubview: self.editToolsBlockPaletteVC.view];

    // place group picker in upper left. there must be a better way to do this.
    self.groupPickerVC.view.hidden = YES;
    CGRect rGroupPicker = CGRectMake( kInset,
                                      kInset,  // y-goes-down
                                      self.groupPickerVC.view.frame.size.width,
                                      self.groupPickerVC.view.frame.size.height );    
    [self.groupPickerVC.view setFrame:rGroupPicker];
    self.groupPickerVC.groupIdChangedDelegate = self;
    [[self.groupPickerVC.view layer] setCornerRadius:8.0f];
    [[self.groupPickerVC.view layer] setMasksToBounds:YES];
    [[self.groupPickerVC.view layer] setBorderWidth:1.0f];
    [self.view addSubview: self.groupPickerVC.view];
    
    // place draw settings
    self.drawSettingsVC.view.hidden = YES;
    CGRect rDrawSettings = CGRectMake( kInset,
                                       kInset,  // y-goes-down
                                       self.drawSettingsVC.view.frame.size.width,
                                       self.drawSettingsVC.view.frame.size.height );    
    [self.drawSettingsVC.view setFrame:rDrawSettings];
    self.drawSettingsVC.snapSelectionDelegate = self;
    [[self.drawSettingsVC.view layer] setCornerRadius:8.0f];
    [[self.drawSettingsVC.view layer] setMasksToBounds:YES];
    [[self.drawSettingsVC.view layer] setBorderWidth:1.0f];
    [self.view addSubview: self.drawSettingsVC.view];
    
    self.worldView.gridVisible = YES;
    
    if( m_startingLevel != nil )
    {
        [EArchiveUtil loadDoc:m_doc fromDiskForName:m_startingLevel];
        NSLog( @"Loaded %@", m_startingLevel );
    }
    else
    {
        // TODO: edit new level fixes/improvements here
        m_doc.levelName = [EditMainViewController nextLevelName];
        m_doc.levelDescription = @"No description";
    }
    self.worldView.worldRect = [self getInitialWorldViewRect];
    
    self.docPropsVC.view.hidden = YES;
    CGRect rDocProps = CGRectMake( 20.f, 20.f,
                                   self.docPropsVC.view.frame.size.width,
                                   self.docPropsVC.view.frame.size.height );    
    [self.docPropsVC.view setFrame:rDocProps];
    [self.view addSubview:self.docPropsVC.view];
    if( m_startingLevel == nil )
    {
        // show the doc props dialog if we are editing a new level.
        self.docPropsVC.view.hidden = NO;
    }

    self.docPropsVC.levelNameTextField.delegate = self;
    self.docPropsVC.tagsTextField.delegate = self;
    
    [self setStringsForShowHideButtons];
}


-(void)viewDidUnload
{
    [super viewDidUnload];

    // TODO: I probably don't need this here and at dealloc...
    self.worldView = nil;
    self.currentToolView = nil;
}


-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsLandscape( interfaceOrientation );
}


-(void)setParentDelegate:(id<IParentVC>)parent
{
    m_parentVC = parent;  // weak
}


-(void)setStartingLevel:(NSString *)levelName
{
    m_startingLevel = [levelName retain];
}


-(void)onAppStart
{
}


-(void)onAppStop
{
}


#pragma mark UI handlers

-(void)sendClosingMessage
{
    NSString *levelName = @"unknown";
    if( m_doc != nil )
    {
        levelName = m_doc.levelName;
    }
    [m_parentVC onChildClosing:self withOptionalLevelName:m_doc.levelName];
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // 0 == cancel, 1 == confirm exit
    if( buttonIndex == 1 )
    {
        [self sendClosingMessage];
    }
}


-(IBAction)onMasterToolsExitButtonPressed:(id)sender
{
    if( self.worldView.docDirty )
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unsaved work" message:@"Exit anyways?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        [alert show];
        [alert release];
    }
    else
    {
        [self sendClosingMessage];
    }
}


-(void)setEditToolButtonHighlightStateForCurrentToolMode
{
    // TODO: these buttons look pretty ghetto but there's no simple way to programmatically change a button's
    //       visible state to indicate "active".
    //       You may be able to insert a custom CALayer to change the fill color, but probably need to subclass
    //       UIButton to do this cleanly, may try this later. See following URL:
    //         http://www.cimgf.com/2010/01/28/fun-with-uibuttons-and-core-animation-layers/
    // TODO: segmentedControl instead?
    
    switch( self.worldView.currentToolMode )
    {
        case ToolModeDrawBlock:
            [self.editToolsDrawBlocksButton layer].borderColor = m_editToolButtonsActiveBorderColor;
            [self.editToolsEraseButton layer].borderColor = m_editToolButtonsInactiveBorderColor;
            [self.editToolsGrabButton layer].borderColor = m_editToolButtonsInactiveBorderColor;
            [self.editToolsGroupButton layer].borderColor = m_editToolButtonsInactiveBorderColor;
            break;
        case ToolModeErase:
            [self.editToolsDrawBlocksButton layer].borderColor = m_editToolButtonsInactiveBorderColor;
            [self.editToolsEraseButton layer].borderColor = m_editToolButtonsActiveBorderColor;
            [self.editToolsGrabButton layer].borderColor = m_editToolButtonsInactiveBorderColor;
            [self.editToolsGroupButton layer].borderColor = m_editToolButtonsInactiveBorderColor;
            break;
        case ToolModeGrab:
            [self.editToolsDrawBlocksButton layer].borderColor = m_editToolButtonsInactiveBorderColor;
            [self.editToolsEraseButton layer].borderColor = m_editToolButtonsInactiveBorderColor;
            [self.editToolsGrabButton layer].borderColor = m_editToolButtonsActiveBorderColor;
            [self.editToolsGroupButton layer].borderColor = m_editToolButtonsInactiveBorderColor;
            break;
        case ToolModeGroup:
            [self.editToolsDrawBlocksButton layer].borderColor = m_editToolButtonsInactiveBorderColor;
            [self.editToolsEraseButton layer].borderColor = m_editToolButtonsInactiveBorderColor;
            [self.editToolsGrabButton layer].borderColor = m_editToolButtonsInactiveBorderColor;
            [self.editToolsGroupButton layer].borderColor = m_editToolButtonsActiveBorderColor;
            break;
        default:
            NSLog( @"setEditToolButtonHighlightStateForCurrentToolMode: unrecognized tool mode." );
            break;
    }
    
}


-(void)restoreBasicState
{
    self.editToolsBlockPaletteVC.view.hidden = YES;
    self.worldView.drawGroupOverlay = NO;    
    [self.worldView setNeedsDisplay];  // since we might have to hide an overlay that was visible.
    self.groupPickerVC.view.hidden = YES;
    self.drawSettingsVC.view.hidden = YES;
}


-(IBAction)onEditToolsBlockPressed:(id)sender
{
    BOOL fPaletteHidden = self.editToolsBlockPaletteVC.view.hidden;  // since this gets reset by restoreBasicState.
    [self restoreBasicState];
    
    if( self.worldView.currentToolMode == ToolModeDrawBlock )
    {
        // if we are already in Draw mode, toggle the visibility of the palette when they hit the Draw button again.
        self.editToolsBlockPaletteVC.view.hidden = !fPaletteHidden;
        m_fBlockPaletteOpen = !self.editToolsBlockPaletteVC.view.hidden;
    }
    else
    {
        // if not yet in Draw mode, restore the last known visibility of the palette.
        self.worldView.currentToolMode = ToolModeDrawBlock;
        [self setEditToolButtonHighlightStateForCurrentToolMode];
        self.editToolsBlockPaletteVC.view.hidden = !m_fBlockPaletteOpen;
    }
    
    // draw settings tags along with palette
    self.drawSettingsVC.segmentControl.selectedSegmentIndex = self.worldView.currentSnap;
    self.drawSettingsVC.view.hidden = self.editToolsBlockPaletteVC.view.hidden;
}


-(IBAction)onEditToolsErasePressed:(id)sender
{
    [self restoreBasicState];
    self.worldView.currentToolMode = ToolModeErase;
    [self setEditToolButtonHighlightStateForCurrentToolMode];
}


-(IBAction)onEditToolsGrabPressed:(id)sender
{
    [self restoreBasicState];
    self.worldView.currentToolMode = ToolModeGrab;
    [self setEditToolButtonHighlightStateForCurrentToolMode];
}


-(IBAction)onEditToolsGroupPressed:(id)sender
{
    [self restoreBasicState];
    self.worldView.currentToolMode = ToolModeGroup;
    self.worldView.drawGroupOverlay = YES;
    [self setEditToolButtonHighlightStateForCurrentToolMode];
    self.groupPickerVC.view.hidden = NO;
    self.worldView.activeGroupId = self.groupPickerVC.currentGroupId;
}


-(void)onGrabbedPreset
{
    [self onEditToolsBlockPressed:nil];
}


-(void)setStringsForShowHideButtons
{
    if( self.worldView.gridVisible )
    {
        self.showHideGridButton.title = @"Hide Grid";
    }
    else
    {
        self.showHideGridButton.title = @"Show Grid";
    }
    if( !self.editToolsBarView.hidden )
    {
        self.showHideEditToolsButton.title = @"Hide Edit Tools";
    }
    else
    {
        self.showHideEditToolsButton.title = @"Show Edit Tools";
    }
    if( !self.docPropsVC.view.hidden )
    {
        self.showHidePropsButton.title = @"Hide Props";
    }
    else
    {
        self.showHidePropsButton.title = @"Show Props";
    }
}


-(IBAction)onShowHideEditToolsButtonPressed:(id)sender
{
    if( self.editToolsBarView.hidden )
    {
        self.editToolsBarView.hidden = NO;
        if( self.worldView.currentToolMode == ToolModeDrawBlock )
        {
            self.editToolsBlockPaletteVC.view.hidden = !m_fBlockPaletteOpen;
        }
        else
        {
            self.editToolsBlockPaletteVC.view.hidden = YES;
        }
    }
    else
    {
        self.editToolsBarView.hidden = YES;
        self.editToolsBlockPaletteVC.view.hidden = YES;
    }
    [self setStringsForShowHideButtons];
}


-(IBAction)onShowHideGridButtonPressed:(id)sender
{
    self.worldView.gridVisible = !self.worldView.gridVisible;
    [self.worldView setNeedsDisplay];
    [self setStringsForShowHideButtons];
}


-(IBAction)onDocPropsButtonPressed:(id)sender
{
    if( self.docPropsVC.view.hidden )
    {
        [self.docPropsVC updateValuesFromDoc];
        self.docPropsVC.view.hidden = NO;
    }
    else
    {
        self.docPropsVC.view.hidden = YES;
        // any updated values were grabbed when Enter was pressed on the corresponding textField.
    }
    [self setStringsForShowHideButtons];
}


+(NSString *)nextLevelName
{
    int currentTry = 0;
    NSString *result;
    
    NSString *randomName = [EditMainViewController sanitizeLevelName:[RandomNameGenerator generateRandomNameLooselyBasedOnCurrentTime]];
    while( YES )
    {
        NSString *levelPath;
        if( currentTry == 0 )
        {
            result = randomName;
            levelPath = [[LevelFileUtil instance] getPathForLevelName:result];
        }
        else
        {
            result = [NSString stringWithFormat:@"%@-%d", randomName, currentTry];
            levelPath = [[LevelFileUtil instance] getPathForLevelName:result];
        }
        if( ![[LevelFileUtil instance] doesFileExistAtPath:levelPath] )
        {
            break;
        }
        ++currentTry;
    }
    return result;
}


+(NSString *)sanitizeLevelName:(NSString *)nameIn
{
    NSMutableString *ret = [NSMutableString stringWithString:nameIn];

    [ret replaceOccurrencesOfString:@" " withString:@"-" options:0 range:NSMakeRange( 0, [ret length] ) ];
    [ret replaceOccurrencesOfString:@"'" withString:@"-" options:0 range:NSMakeRange( 0, [ret length] ) ];
    [ret replaceOccurrencesOfString:@"," withString:@"-" options:0 range:NSMakeRange( 0, [ret length] ) ];
    [ret replaceOccurrencesOfString:@"." withString:@"-" options:0 range:NSMakeRange( 0, [ret length] ) ];
    [ret replaceOccurrencesOfString:@":" withString:@"-" options:0 range:NSMakeRange( 0, [ret length] ) ];
    [ret replaceOccurrencesOfString:@";" withString:@"-" options:0 range:NSMakeRange( 0, [ret length] ) ];
    [ret replaceOccurrencesOfString:@"(" withString:@"-" options:0 range:NSMakeRange( 0, [ret length] ) ];
    [ret replaceOccurrencesOfString:@")" withString:@"-" options:0 range:NSMakeRange( 0, [ret length] ) ];

    return ret;
}


-(IBAction)onMasterToolsSaveButtonPressed:(id)sender
{
    [EArchiveUtil saveToDisk:m_doc];
    self.worldView.docDirty = NO;
    NSLog( @"saved doc to disk: %@", m_doc.levelName );
}


-(void)currentBlockPresetUpdated:(EBlockPreset)preset
{
    m_currentlySelectedPreset = preset;
}


-(EBlockPreset)getCurrentBlockPreset
{
    return m_currentlySelectedPreset;
}


// UITextViewDelegate methods

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    if( textField == self.docPropsVC.levelNameTextField )
    {
        NSString *oldName = m_doc.levelName;
        m_doc.levelName = [EditMainViewController sanitizeLevelName:self.docPropsVC.levelNameTextField.text];
        if( ![oldName isEqualToString:m_doc.levelName] )
        {
            self.worldView.docDirty = YES;
            
            NSString *oldPath = [[LevelFileUtil instance] getPathForLevelName:oldName];
            if( [[LevelFileUtil instance] doesFileExistAtPath:oldPath] )
            {
                NSLog( @"rename: deleting old file at %@", oldPath );
                [[LevelFileUtil instance] deleteFileAtPath:oldPath];
            }
            else
            {
                NSLog( @"renaming file, old path doesn't exist (wasn't saved yet?)" );
            }
        
        }
        
        // now that editing is done, hide the keyboard by asking it to resign firstResponder
        if( [textField isFirstResponder] )
        {
            [textField resignFirstResponder];
        }
    }
}


#pragma mark protocol ICurrentGroupIdChangedConsumer

-(void)onCurrentGroupIdChanged:(GroupId)newGroupId
{
    self.worldView.activeGroupId = newGroupId;
}


#pragma mark protocol ISnapSelectionChangedConsumer

-(void)onSnapSelectionChanged:(int)newSelection
{
    self.worldView.currentSnap = newSelection;
    [self.worldView setNeedsDisplay];  // in case the grid wants to redraw on snap setting change.
}

@end
