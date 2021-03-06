#import <QuartzCore/QuartzCore.h>

#import "JumpProtoLaunchViewControllerBase.h"
#import "JumpProtoViewController.h"
#import "EditMainViewController.h"
#import "LevelUtil.h"

@interface JumpProtoLaunchViewControllerBase (private)

-(void)populateLevelPickerView;

@end


@implementation JumpProtoLaunchViewControllerBase

@synthesize levelPickerView, deleteArmedSwitch;
@synthesize dpadInput;

@synthesize exitedLevelName;

-(id)init
{
    if( self = [super init] )
    {
        m_childViewController = nil;
        m_lastPickedLevelRow = 0;
        self.exitedLevelName = nil;
    }
    return self;
}


-(id)initWithCoder:(NSCoder *)aDecoder
{
   if( self = [super initWithCoder:aDecoder] )
    {
        m_childViewController = nil;
        m_lastPickedLevelRow = 0;
        self.exitedLevelName = nil;
    }
    return self;
}


-(void)dealloc
{
    self.dpadInput = nil;
    self.deleteArmedSwitch = nil;
    self.levelPickerView = nil;
    self.exitedLevelName = nil;
    [m_levelPickerViewContents release]; m_levelPickerViewContents = nil;
    [m_childViewController release]; m_childViewController = nil;
    [LevelFileUtil releaseGlobalInstance];
    [AspectController releaseGlobalInstance];
    [super dealloc];
}


#ifdef AUTOLOAD_FIRST_LEVEL
// for testing background drawing.
-(void)temp_autoPlayFirstLevel
{
    m_lastPickedLevelRow = [self shouldShowCreateNewLevelOption] ? 1 : 0;
    JumpProtoViewController *jumpVC = [[JumpProtoViewController alloc] initWithNibName:@"JumpProtoViewController" bundle:nil];
    jumpVC.dpadInput = self.dpadInput;
    jumpVC.loadFromDisk = YES;
    m_childViewController = jumpVC;
    [self addChildViewWithTransition:NO];
}
#endif


-(void)onAwake
{
    // this is authority on current coordinate system, in terms of aspect ratio and pixels.

    // dude this part feels super home grown, there must be a more best practicey way to do this.
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    self.view.frame = CGRectMake(screenRect.origin.x, screenRect.origin.y,
                                 MAX( screenRect.size.width, screenRect.size.height ),
                                 MIN( screenRect.size.width, screenRect.size.height ) );
    NSLog( @"initializing AspectController with screenRect %f,%f %fx%f", self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height );
    [AspectController initGlobalInstanceWithRect:self.view.frame flipCoords:NO];
    
    [LevelFileUtil initGlobalInstance];
    
    self.dpadInput = [[DpadInput alloc] init];
    
    [self populateLevelPickerView];
    self.deleteArmedSwitch.on = NO;
    
#ifdef AUTOLOAD_FIRST_LEVEL
    // testing: just load the first level without requiring any user input for testing purposes.
    [self temp_autoPlayFirstLevel];
#endif
}


-(void)awakeFromNib
{
    [self onAwake];
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


- (BOOL)shouldAutorotate
{
    // even though we only want to work in landscape mode, still return YES here so that we can autorotate to
    //  the most appropriate (left hand, right hand) landscape depending on how device is held. The restriction
    //  to landscape mode is actually enforced by settings in the plist file and our implementations of
    //  supportedInterfaceOrientations.
    return YES;
}


- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
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
    if( ![self shouldShowCreateNewLevelOption] || m_lastPickedLevelRow > 0 )  // row 0 is "new level" if enabled
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


-(IBAction)onPlayButtonTouched:(id)sender
{
    if( [self shouldShowCreateNewLevelOption] && m_lastPickedLevelRow == 0 )
    {
        NSLog( @"choose something besides \"new level\"." );
        return;
    }
    JumpProtoViewController *jumpVC = [[JumpProtoViewController alloc] initWithNibName:@"JumpProtoViewController" bundle:nil];
    jumpVC.dpadInput = self.dpadInput;
    jumpVC.loadFromDisk = [self shouldLoadFromDisk];
    m_childViewController = jumpVC;
    [self addChildViewWithTransition:NO];
}


-(BOOL)shouldLoadFromDisk
{
    return YES;
}


-(BOOL)shouldShowCreateNewLevelOption
{
    return YES;
}


-(IBAction)onEditButtonTouched:(id)sender
{
    EditMainViewController *editVC = [[EditMainViewController alloc] initWithNibName:@"EditMainViewController" bundle:nil];
    m_childViewController = editVC;
    [self addChildViewWithTransition:YES];
}


-(IBAction)onDeleteButtonTouched:(id)sender
{
    if( self.deleteArmedSwitch.on == NO )
    {
        return;
    }
    
    if( [self shouldShowCreateNewLevelOption] && m_lastPickedLevelRow == 0 )
    {
        NSLog( @"choose something besides \"new level\"." );
        return;
    }
    
    NSString *deleteName = (NSString *)[m_levelPickerViewContents objectAtIndex:m_lastPickedLevelRow];
    NSString *deletePath = [[LevelFileUtil instance] getPathForLevelName:deleteName];
    NSAssert( [[LevelFileUtil instance] doesFileExistAtPath:deletePath], @"got a bad path (assume it came from the picker?)" );
    [[LevelFileUtil instance] deleteFileAtPath:deletePath];
    
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
    [self populateLevelPickerView];
}


-(void)populateLevelPickerView
{
    NSMutableArray *mutableContents = [[NSMutableArray arrayWithCapacity:50] retain];
    
    // zero'th entry is special, corresponding to "new level"
    if( [self shouldShowCreateNewLevelOption] )
    {
        [mutableContents addObject:@"Create new level..."];
    }

    [[LevelFileUtil instance] addAllLevelNamesTo:mutableContents];
    
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

    startingIndex = (int)MIN( startingIndex, [m_levelPickerViewContents count] - 1 );
    [self.levelPickerView selectRow:startingIndex inComponent:0 animated:NO];
}


// UIPickerViewDataSource

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    NSAssert( pickerView == self.levelPickerView, @"what pickerView is talking to me?" );
    return 1;
}


-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    NSAssert( pickerView == self.levelPickerView, @"what pickerView is talking to me?" );
    NSAssert( component == 0, @"called with bad component number?" );

    if( pickerView == self.levelPickerView )
    {
        return (int)[m_levelPickerViewContents count];
    }
    
    return 0;
}


// UIPickerViewDelegate

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSAssert( pickerView == self.levelPickerView, @"what pickerView is talking to me?" );
    NSAssert( component == 0, @"called with bad component number?" );
    if( pickerView == self.levelPickerView )
    {
        NSAssert( row < [m_levelPickerViewContents count], @"bad row?" );
        m_lastPickedLevelRow = (int)row;
    }
}


-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSAssert( pickerView == self.levelPickerView, @"what pickerView is talking to me?" );
    NSAssert( component == 0, @"called with bad component number?" );
    if( pickerView == self.levelPickerView )
    {
        NSAssert( row < [m_levelPickerViewContents count], @"bad row?" );
        NSString *resultString = (NSString *)[m_levelPickerViewContents objectAtIndex:row];
        return resultString;
    }
    return @"unknown pickerView problem?";
}


@end
