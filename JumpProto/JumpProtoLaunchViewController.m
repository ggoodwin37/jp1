//
//  JumpProtoLaunchViewController.m
//  JumpProto
//
//  Created by gideong on 9/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "JumpProtoLaunchViewController.h"
#import "JumpProtoViewController.h"
#import "EditMainViewController.h"
#import "LevelUtil.h"
#import "LauncherNewPackDialog.h"
#import "LauncherDeletePackDialog.h"
#import "LauncherExportPackDialog.h"

@interface JumpProtoLaunchViewController (private)

-(void)populatePackPickerView;
-(void)populateLevelPickerView;

@end


@implementation JumpProtoLaunchViewController

@synthesize levelPickerView, deleteArmedSwitch, loadFromDiskSwitch;
@synthesize dpadInput;
@synthesize packPickerView;

@synthesize exitedLevelName;

@synthesize currentManifestName;

-(id)initWithCoder:(NSCoder *)aDecoder
{
   if( self = [super initWithCoder:aDecoder] )
    {
        m_childViewController = nil;
        m_lastPickedLevelRow = 0;
        m_currentLauncherDialog = nil;
        self.exitedLevelName = nil;
    }
    return self;
}


-(void)dealloc
{
    self.dpadInput = nil;
    self.deleteArmedSwitch = nil;
    self.loadFromDiskSwitch = nil;
    self.levelPickerView = nil;
    self.exitedLevelName = nil;
    [m_packPickerViewContents release]; m_packPickerViewContents = nil;
    [m_levelPickerViewContents release]; m_levelPickerViewContents = nil;
    [m_childViewController release]; m_childViewController = nil;
    [m_currentLauncherDialog release]; m_currentLauncherDialog = nil;
    [LevelManifestManager releaseGlobalInstance];
    [AspectController releaseGlobalInstance];
    [super dealloc];
}


-(void)awakeFromNib
{
    // this is authority on current coordinate system, in terms of aspect ratio and pixels (used only where needed to interface with events).
    // why flipCoords? Not sure. Originally this was called with the openGLView's rect and the coords didn't need to be flipped. But now that
    // we are using this quartz view's frame, this seems to be required. There's a better explanation out there somewhere but frankly who cares.
    //  IT'S NOT LIKE THIS WILL EVER COME BACK TO BITE ME IN THE ASS.
    [AspectController initGlobalInstanceWithRect:self.view.frame flipCoords:YES];
    
    [LevelManifestManager initGlobalInstance];
    m_lastPickedPackRow = 0;
    [self populatePackPickerView];

    NSAssert( [m_packPickerViewContents count] > m_lastPickedPackRow, @"not enough manifests, can't handle this." );  // TODO: could handle this by generating one on the spot.
    self.currentManifestName = (NSString *)[m_packPickerViewContents objectAtIndex:m_lastPickedPackRow];
    
    self.dpadInput = [[DpadInput alloc] init];
    
    [self populateLevelPickerView];
    self.deleteArmedSwitch.on = NO;
    self.loadFromDiskSwitch.on = YES;
}


-(void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // note of historical interest: I put init code here and found that
    //   this method is called multiple times during launch, maybe
    //   something to do with the way connections are configured to
    //   this object in MainWindow.xib, or the rootViewController property.
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsLandscape( interfaceOrientation );
}


-(void)addTransitionEntrDir:(BOOL)fEntrance
{
	CATransition *transition = [CATransition animation];
	transition.duration = 0.4f;
	transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = fEntrance ? kCATransitionMoveIn : kCATransitionReveal;
    transition.subtype = fEntrance ? kCATransitionFromRight : kCATransitionFromLeft;  // these act as if you were in portrait mode.
	transition.delegate = self;
	[self.view.layer addAnimation:transition forKey:nil];
}


-(void)addChildViewWithTransition:(BOOL)fTrans
{
    [m_childViewController setParentDelegate:self];
    
    NSString *startingLevel = nil;    
    if( m_lastPickedLevelRow > 0 )  // row 0 is "new level"
    {
        startingLevel = (NSString *)[m_levelPickerViewContents objectAtIndex:m_lastPickedLevelRow];
    }
    [m_childViewController setStartingLevel:startingLevel];
    
    m_childViewController.view.hidden = YES;
    [self.view addSubview:m_childViewController.view];
    
    if( fTrans )
    {
        [self addTransitionEntrDir:YES];
    }
    m_childViewController.view.hidden = NO;
}


-(void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
    // if child view is now hidden, we should remove it.
    if( m_childViewController != nil && m_childViewController.view.hidden )
    {
        [m_childViewController.view removeFromSuperview];
        [m_childViewController release]; m_childViewController = nil;
    }
}


-(void)addCurrentLauncherDialog
{
    [m_currentLauncherDialog setParent:self];
    m_currentLauncherDialog.view.hidden = NO;
    CGRect rDocProps = CGRectMake( 20.f, 20.f,
                                  m_currentLauncherDialog.view.frame.size.width,
                                  m_currentLauncherDialog.view.frame.size.height );    
    [m_currentLauncherDialog.view setFrame:rDocProps];
    [self.view addSubview:m_currentLauncherDialog.view];
}


-(IBAction)onNewPackButtonTouched:(id)sender
{
    if( m_currentLauncherDialog != nil )
    {
        NSLog( @"already a LauncherDialog exists, go away." );
        return;
    }
    m_currentLauncherDialog = [[LauncherNewPackDialog alloc] initWithNibName:@"LauncherNewPackDialog" bundle:nil];
    [self addCurrentLauncherDialog];
}


-(IBAction)onDeletePackButtonTouched:(id)sender
{
    if( m_currentLauncherDialog != nil )
    {
        NSLog( @"already a LauncherDialog exists, go away." );
        return;
    }
    if( [m_packPickerViewContents count] < 2 )
    {
        NSLog( @"can't delete last pack." );
        return;
    }
    
    LauncherDeletePackDialog *dialog = [[LauncherDeletePackDialog alloc] initWithNibName:@"LauncherDeletePackDialog" bundle:nil];
    m_currentLauncherDialog = dialog;
    [self addCurrentLauncherDialog];
    
    int cLevels = 0;
    LevelManifest *currentManifest = [[LevelManifestManager instance] getExistingManifestNamed:self.currentManifestName];
    if( currentManifest != nil )
    {
        cLevels = [currentManifest getLevelNameCount];
    }
    
    dialog.theLabel.text = [NSString stringWithFormat:@"Pack contains %d levels, do you want to delete them too?", cLevels];
}


-(IBAction)onExportPackButtonTouched:(id)sender
{
    if( m_currentLauncherDialog != nil )
    {
        NSLog( @"already a LauncherDialog exists, go away." );
        return;
    }
    m_currentLauncherDialog = [[LauncherExportPackDialog alloc] initWithNibName:@"LauncherExportPackDialog" bundle:nil];
    [self addCurrentLauncherDialog];
}


-(IBAction)onPlayButtonTouched:(id)sender
{
    if( m_lastPickedLevelRow == 0 )
    {
        NSLog( @"choose something besides \"new level\"." );
        return;
    }
    JumpProtoViewController *jumpVC = [[JumpProtoViewController alloc] initWithNibName:@"JumpProtoViewController" bundle:nil];
    jumpVC.dpadInput = self.dpadInput;
    jumpVC.loadFromDisk = self.loadFromDiskSwitch.on;
    m_childViewController = jumpVC;
    [self addChildViewWithTransition:NO];
}


-(IBAction)onEditButtonTouched:(id)sender
{
    EditMainViewController *editVC = [[EditMainViewController alloc] initWithNibName:@"EditMainViewController" bundle:nil defaultManifestName:self.currentManifestName];
    m_childViewController = editVC;
    [self addChildViewWithTransition:YES];
}


-(IBAction)onDeleteButtonTouched:(id)sender
{
    if( self.deleteArmedSwitch.on == NO )
    {
        return;
    }
    
    if( m_lastPickedLevelRow == 0 )
    {
        NSLog( @"choose something besides \"new level\"." );
        return;
    }
    
    NSString *deleteName = (NSString *)[m_levelPickerViewContents objectAtIndex:m_lastPickedLevelRow];
    NSString *deletePath = [[LevelManifestManager instance] getPathForLevelName:deleteName];
    NSAssert( [[LevelManifestManager instance] doesFileExistAtPath:deletePath], @"got a bad path (assume it came from the picker?)" );
    [[LevelManifestManager instance] deleteFileAtPath:deletePath];
    
    LevelManifest *currentManifest = [[LevelManifestManager instance] getExistingManifestNamed:self.currentManifestName];
    NSAssert( currentManifest != nil, @"bad current manifest?" );
    [currentManifest tryRemoveLevelName:deleteName];
    [[LevelManifestManager instance] writeManifest:currentManifest];
    
    [self populateLevelPickerView];
    self.deleteArmedSwitch.on = NO;
}


-(void)onAppStart
{
    [m_childViewController onAppStart];
}


-(void)onAppStop
{
    [m_childViewController onAppStop];
}


-(void)onChildClosing:(id)child withOptionalLevelName:(NSString *)optLevelName
{
    self.exitedLevelName = optLevelName;
    
    [self addTransitionEntrDir:NO];
    m_childViewController.view.hidden = YES;

    // refresh pickerViews in case something changed (eg new level).
    [self populatePackPickerView];
    [self populateLevelPickerView];
}


-(void)populatePackPickerView
{
    NSMutableArray *mutableContents = [[NSMutableArray arrayWithCapacity:50] retain];
    
    [[LevelManifestManager instance] addManifestNamesTo:mutableContents];
    
    [m_packPickerViewContents release];
    m_packPickerViewContents = mutableContents;
    
    [self.packPickerView reloadAllComponents];
}


-(void)populateLevelPickerView
{
    NSMutableArray *mutableContents = [[NSMutableArray arrayWithCapacity:50] retain];
    
    // zero'th entry is special, corresponding to "new level"
    [mutableContents addObject:@"Create new level..."];
    
    [[LevelManifestManager instance] addLevelNamesForManifestName:self.currentManifestName to:mutableContents];
    
    [m_levelPickerViewContents release];
    m_levelPickerViewContents = mutableContents;

    [self.levelPickerView reloadAllComponents];
    
    // if present, use the last exited level as starting point in the picker list.
    int startingIndex = 0;
    if( self.exitedLevelName != nil && [m_levelPickerViewContents count] > 1 )
    {
        for( int i = 1; i < [m_levelPickerViewContents count]; ++i )
        {
            NSString *thisName = (NSString *)[m_levelPickerViewContents objectAtIndex:i];
            if( [self.exitedLevelName isEqualToString:thisName] )
            {
                startingIndex = i;
                break;
            }
        }
    }
    m_lastPickedLevelRow = startingIndex;

    startingIndex = MIN( startingIndex, [m_levelPickerViewContents count] - 1 );
    [self.levelPickerView selectRow:startingIndex inComponent:0 animated:NO];
}


// UIPickerViewDataSource

-(int)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    NSAssert( pickerView == self.levelPickerView || pickerView == self.packPickerView, @"what pickerView is talking to me?" );
    return 1;
}


-(int)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    NSAssert( pickerView == self.levelPickerView || pickerView == self.packPickerView, @"what pickerView is talking to me?" );
    NSAssert( component == 0, @"called with bad component number?" );

    if( pickerView == self.levelPickerView )
    {
        return [m_levelPickerViewContents count];
    }
    else if( pickerView == self.packPickerView )
    {
        return [m_packPickerViewContents count];
    }
    
    return 0;
}


// UIPickerViewDelegate

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSAssert( pickerView == self.levelPickerView || pickerView == self.packPickerView, @"what pickerView is talking to me?" );
    NSAssert( component == 0, @"called with bad component number?" );
    if( pickerView == self.packPickerView )
    {
        NSAssert( row < [m_packPickerViewContents count], @"bad row?" );
        m_lastPickedPackRow = row;
        self.currentManifestName = (NSString *)[m_packPickerViewContents objectAtIndex:m_lastPickedPackRow];
        [self populateLevelPickerView]; // update level picker with contents of newly selected manifest.
    }
    else if( pickerView == self.levelPickerView )
    {
        NSAssert( row < [m_levelPickerViewContents count], @"bad row?" );
        m_lastPickedLevelRow = row;
    }
}


-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSAssert( pickerView == self.levelPickerView || pickerView == self.packPickerView, @"what pickerView is talking to me?" );
    NSAssert( component == 0, @"called with bad component number?" );
    if( pickerView == self.packPickerView )
    {
        NSAssert( row < [m_packPickerViewContents count], @"bad row?" );
        NSString *resultString = (NSString *)[m_packPickerViewContents objectAtIndex:row];
        return resultString;
    }
    else if( pickerView == self.levelPickerView )
    {
        NSAssert( row < [m_levelPickerViewContents count], @"bad row?" );
        NSString *resultString = (NSString *)[m_levelPickerViewContents objectAtIndex:row];
        return resultString;
    }
    return @"unknown pickerView problem?";
}


// ILauncherUIParent

-(void)onDialogClosed:(LauncherUIDialogId)dialogId withStringInput:(NSString *)stringInput buttonSelection:(LauncherUIButtonSelection)button
{
    NSAssert( m_currentLauncherDialog != nil, @"m_currentLauncherDialog fail." );

    if( dialogId == LauncherUIDialog_NewPack )
    {
        if( button == LauncherUIButton_1 )
        {
            // create new manifest
            if( stringInput != nil )
            {
                NSLog( @"Adding a manifest called %@", stringInput );
                [[LevelManifestManager instance] addManifestWithName:stringInput];
                self.currentManifestName = stringInput;
                
                // update pickers based on newly created pack (which is now selected)
                [self populatePackPickerView];
                m_lastPickedPackRow = 0;
                for( int i = 0; i < [m_packPickerViewContents count]; ++i )
                {
                    NSString *thisContentsString = (NSString *)[m_packPickerViewContents objectAtIndex:i];
                    if( [thisContentsString isEqualToString:self.currentManifestName] )
                    {
                        m_lastPickedPackRow = i;
                        break;
                    }
                }
                [self.packPickerView selectRow:m_lastPickedPackRow inComponent:0 animated:NO];
                [self populateLevelPickerView];
                
                NSLog( @"created manifest, current manifest name is now %@", self.currentManifestName );
            }
        }
        else if( button == LauncherUIButton_2 )
        {
            // cancel, do nothing
        }
        else
        {
            NSLog( @"onDialogClosed: unexpected button for DialogNew" );
        }
    }
    else if( dialogId == LauncherUIDialog_DeletePack )
    {
        LevelManifest *currentManifest = [[LevelManifestManager instance] getExistingManifestNamed:self.currentManifestName];
        if( currentManifest == nil )
        {
            NSLog (@"onDeleteDialogClosed: bad currentManifestName." );
        }
        else
        {
            BOOL fDeleteCurrentManifest = NO;
            if( button == LauncherUIButton_1 )
            {
                // yes, delete levels
                for( int i = 0; i < [currentManifest getLevelNameCount]; ++i )
                {
                    NSString *thisLevelPath = [[LevelManifestManager instance] getPathForLevelName:[currentManifest getLevelName:i]];
                    NSAssert( [[LevelManifestManager instance] doesFileExistAtPath:thisLevelPath], @"where did my file go?" );
                    [[LevelManifestManager instance] deleteFileAtPath:thisLevelPath];
                }
                fDeleteCurrentManifest = YES;
            }
            else if( button == LauncherUIButton_2 )
            {
                // no, don't delete levels, only remove manifest
                fDeleteCurrentManifest = YES;
            }
            else if( button == LauncherUIButton_3 )
            {
                // cancel, do nothing
            }
            else
            {
                NSLog( @"onDialogClosed: unexpected button for DialogDelete" );
            }
            if( fDeleteCurrentManifest )
            {
                NSString *thisManifestPath = [[LevelManifestManager instance] getPathForManifest:currentManifest];
                [[LevelManifestManager instance] deleteFileAtPath:thisManifestPath];
                [[LevelManifestManager instance] refreshManifestView];
                m_lastPickedPackRow = 0;
                [self populatePackPickerView];
                self.currentManifestName = (NSString *)[m_packPickerViewContents objectAtIndex:m_lastPickedPackRow];
                [self populateLevelPickerView];
            }
        }
    }
    else if( dialogId == LauncherUIDialog_ExportPack )
    {
        if( button == LauncherUIButton_1 )
        {
            NSLog( @"exportPack NYI" );
        }
        else if( button == LauncherUIButton_2 )
        {
            // cancel, do nothing
        }
        else
        {
            NSLog( @"onDialogClosed: unexpected button for DialogExport" );
        }
    }
    else
    {
        NSLog( @"onDialogClosed: Unrecognized dialogId." );
    }
    
    [m_currentLauncherDialog.view removeFromSuperview];
    [m_currentLauncherDialog removeFromParentViewController]; // what's the diff between this and m_currentLauncherDialog.view removeFromSuperview?
    [m_currentLauncherDialog release]; m_currentLauncherDialog = nil;
}

@end
