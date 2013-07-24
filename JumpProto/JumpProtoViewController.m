//
//  JumpProtoViewController.m
//  JumpProto
//
//  Created by gideong on 7/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "JumpProtoViewController.h"
#import "WorldTest.h"


@interface JumpProtoViewController (private)

-(void)handleTouchesForEvent:(UIEvent *)event;

@end



@implementation JumpProtoViewController

@synthesize mainGlView = m_mainGlView;
@synthesize dpadInput = m_dpadInput;
@synthesize loadFromDisk;


-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if( self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil] )
    {
        m_dpadInput = nil;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


-(void)onGlobalCommand_exitPlay
{
    NSString *levelName = @"unknown";
    if( m_world != nil )
    {
        levelName = m_world.levelName;
    }
    [m_parentVC onChildClosing:self withOptionalLevelName:levelName];
}

#pragma mark - View lifecycle


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];

    NSLog( @"MainWindowViewController viewDidLoad. interface orientation is %@.",
          UIInterfaceOrientationIsLandscape( self.interfaceOrientation ) ? @"landscape" : @"portrait" );
    
    // this assumes that any orientation change support is implemented manually (i.e. this view doesn't autorotate)
	m_mainGlView = [[EAGLView alloc] initWithFrame: self.view.frame];
    
    [self.view addSubview:m_mainGlView];
    
	// manages rendering the scene.
	m_mainDrawController = [[MainDrawController alloc] init];
	[m_mainGlView setRenderDelegate: m_mainDrawController];
    m_mainGlView.touchHandlerDelegate = self;
	[m_mainGlView setAnimationFrameInterval:ANIMATION_FRAME_INTERVAL];

    DebugOut( @"--== Welcome to Jump Proto ==--" );

    [m_mainGlView becomeFirstResponder];
    [m_mainGlView startAnimation];
    
    NSAssert( m_dpadInput != nil, @"JumpProtoVC: no dpad input set :(" );
    [m_dpadInput resetEventDelegates];    
    [m_dpadInput registerEventDelegate:self];  // weak
    
    // feels like these should be wrapped in a container or something.
    m_mainDrawController.dpadFeedbackLayerViewLeft.dpadInput = m_dpadInput;  // weak
    m_mainDrawController.dpadFeedbackLayerViewRight.dpadInput = m_dpadInput;  // weak
    [m_dpadInput registerEventDelegate:m_mainDrawController.dpadFeedbackLayerViewLeft];
    [m_dpadInput registerEventDelegate:m_mainDrawController.dpadFeedbackLayerViewRight];
    
    [SpriteManager initGlobalInstance];
    [[SpriteManager instance] loadAllSpriteTextures];
    
    m_world = [[World alloc] init];
    m_mainDrawController.worldView.world = m_world;  // weak
    [m_dpadInput registerEventDelegate:m_world];
    
    m_globalButtonManager = [[GlobalButtonManager alloc] init];
    m_mainDrawController.globalButtonView.buttonManager = m_globalButtonManager;  // weak
    
    NSLog( @"Skipping misc tests." );
    //[WorldTest runMiscTests];

    NSLog( @"Skipping ElbowRoom tests." );  // leaving ElbowRoom in a stable state for now.
    //[WorldTest runTestsOnWorld:m_world];
    
    [m_world showTestWorld:m_startingLevel loadFromDisk:self.loadFromDisk];
    
    [GlobalCommand registerObject:self forNotification:GLOBAL_COMMAND_NOTIFICATION_EXITPLAY  withSel:@selector(onGlobalCommand_exitPlay)];
}


-(void)dealloc
{
    [GlobalCommand unregisterObject:self];

    [m_globalButtonManager release]; m_globalButtonManager = nil;
    [m_mainGlView stopAnimation]; [m_mainGlView release]; m_mainGlView = nil;
    [m_mainDrawController release]; m_mainDrawController = nil;
    self.dpadInput = nil;
    [m_world release]; m_world = nil;
    [SpriteManager releaseGlobalInstance];
    m_parentVC = nil;  // weak
    [m_startingLevel release]; m_startingLevel = nil;
    
    [super dealloc];
}


- (void)viewDidUnload
{
    NSLog( @"UNEXPECTED: JumpProtoViewController viewDidUnload was called, should you do something intelligent here?" );  // TODO: figure this out.
    [super viewDidUnload];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsLandscape( interfaceOrientation );
}


-(void)handleTouchesForEvent:(UIEvent *)event
{
    [m_mainDrawController.touchFeedbackLayer clearTouches];
    
    NSEnumerator *enumerator = [[event allTouches] objectEnumerator];
    UITouch *touch;
    
    while( touch = (UITouch *)[enumerator nextObject] )
    {
        // TODO: organize this better
        CGPoint p = [touch locationInView:self.view];
        p.y = [AspectController instance].yPixel - p.y;
        
        if( touch.phase == UITouchPhaseBegan | touch.phase == UITouchPhaseMoved | touch.phase == UITouchPhaseStationary )
        {
            [m_mainDrawController.touchFeedbackLayer pushTouchAt:p];
        }
        if( touch.phase == UITouchPhaseBegan )
        {
            [m_mainDrawController.debugLogLayer receivedTouchAt:p];
        }
        [m_dpadInput handleTouch:touch at:p];
        [m_globalButtonManager handleTouch:touch at:p];

    }
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self handleTouchesForEvent: event];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self handleTouchesForEvent: event];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self handleTouchesForEvent: event];
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self handleTouchesForEvent: event];
}


-(void)onDpadEvent:(DpadEvent *)event
{
    // unneeded?
}


-(void)onAppStart
{
    [m_mainGlView startAnimation];
}


-(void)onAppStop
{
    [m_mainGlView stopAnimation];
}


-(void)setParentDelegate:(id<IParentVC>)parent
{
    m_parentVC = parent;  // weak
}


-(void)setStartingLevel:(NSString *)levelName
{
    m_startingLevel = [levelName retain];
}


@end
