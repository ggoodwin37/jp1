//
//  DpadInput.m
//  JumpProto
//
//  Created by gideong on 7/19/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DpadInput.h"
#import "CGPointW.h"
#import "AspectController.h"
#import "gutil.h"
#import "DebugLogLayerView.h"
#import "GlobalCommand.h"

// DpadEvent ////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface DpadEvent (private)
@end


@implementation DpadEvent

@synthesize type = m_buttonEventType, button = m_button, timeStamp = m_timeStamp, touchZone = m_touchZone;

-(id)initWithButton:(DpadButton)button eventType:(DpadEventType)eventType timeStamp:(NSTimeInterval)timeStamp touchZone:(TouchZone)touchZone;
{
    if( self = [super init] )
    {
        m_button = button;
        m_buttonEventType = eventType;
        m_timeStamp = timeStamp;
        m_touchZone = touchZone;
    }
    return self;
}


-(void)dealloc
{
    [super dealloc];
}


-(NSString *)debugString
{
    NSString *buttonStr;
    switch( m_button )
    {
        case DpadNotHandled:
            buttonStr = @"notHandled";
            break;
        case DpadUnknownButton:
            buttonStr = @"unknown";
            break;
        case DpadLeftButton:
            buttonStr = @"left";
            break;
        case DpadRightButton:
            buttonStr = @"right";
            break;
        default:
            buttonStr = @"unexpectedValue!";
            break;
            
    }
    
    NSString *eventStr;
    switch( m_buttonEventType )
    {
        case DpadPressed:
            eventStr = @"pressed";
            break;
        case DpadReleased:
            eventStr = @"released";
            break;
        default:
            eventStr = @"unexpectedValue!";
            break;
            
    }

    //return [NSString stringWithFormat:@"Dpad event button=%@, event=%@, time=%lf", buttonStr, eventStr, m_timeStamp];
    return [NSString stringWithFormat:@"Dpad event event=%@, button=%@", eventStr, buttonStr];
}


@end


// DpadTouchSorterStack ///////////////////////////////////////////////////////////////////////////////////////////////////////////////


@implementation DpadTouchSorterStack


-(id)initWithMaxDepth:(int)maxDepth
{
    if( self = [super init] )
    {
        m_stack = [[NSMutableArray alloc] initWithCapacity:(maxDepth * 2)];
        m_maxDepth = maxDepth;
        
        
    }
    return self;
    
}


-(void)dealloc
{
    [m_stack release]; m_stack = nil;
    [super dealloc];
}


-(void)pushTouchAt:(CGPoint)p
{
    [m_stack addObject:[CGPointW fromPoint:p]];
    
    while( [m_stack count] >= m_maxDepth )
    {
        [m_stack removeObjectAtIndex:0];
    }
}


-(CGPoint)calculateMeanPoint
{
    CGPoint runningSum = CGPointMake( 0.f, 0.f );
    if( [m_stack count] == 0 )
    {
        return runningSum;
    }

    for( int i = 0; i < [m_stack count]; ++i )
    {
        CGPointW *thisPointW = (CGPointW *)[m_stack objectAtIndex:i];
        runningSum.x += thisPointW.x;
        runningSum.y += thisPointW.y;
    }
    
    return CGPointMake( runningSum.x / [m_stack count], runningSum.y / [m_stack count] );
}


-(int)count
{
    return (int)[m_stack count];
}


@end



// DpadTouchLRSorter /////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// approach 1: keep "left" and "right" stacks. for each one, calculate mean point.
//  compare the distances between each mean point and the touch point to sort incoming
//  touches into l/r stack. then the mean points are updated to account for new
//  touches. this should handle drift ok. how far back does our history go?
// I think the initial phase where we have 1-3 touches only, is sort of a tricky
//  spot, how can we handle this gracefully?
// haven't really bothered to cache anything since this only runs at touch-time. caching
//  would also increase the complexity a lot.
// Result: this works well as long as the user doesn't shift their grip. Working on a way
//  to detect this case and reset meanPoints.

@interface DpadTouchLRSorter (private)
-(void)reassignStacks;
@end

@implementation DpadTouchLRSorter


-(id)initWithBounds:(CGRect)bounds
{
    if( self = [super init] )
    {
        m_bounds = bounds;
        
        const int maxDepth = 10;  // TODO tune        
        m_leftStack = [[DpadTouchSorterStack alloc] initWithMaxDepth:maxDepth];
        m_rightStack = [[DpadTouchSorterStack alloc] initWithMaxDepth:maxDepth];
        
        // this is a radius threshold used when guessing if one of the earliest touches is different or not.
        m_lowCountGuessThreshold = 10.f;  // TODO tune
        
        m_hitZone = [[RectHitZone alloc] initWithRect:m_bounds];
    }
    return self;
    
}


-(void)dealloc
{
    [m_hitZone release]; m_hitZone = nil;
    [m_leftStack release]; m_leftStack = nil;
    [m_rightStack release]; m_rightStack = nil;
    [super dealloc];
}


-(DpadButton)detectButtonFromTouchPoint:(CGPoint)p eventType:(DpadEventType)eventType affectsMeanPoint:(BOOL)affectsMeanPoint
{
    if( ![m_hitZone containsPoint:p] )
        return DpadNotHandled;
    
    // TODO: can this be refactored to be a little less verbose?

    DpadButton result = DpadUnknownButton;
    
    BOOL leftEmpty = [m_leftStack count] == 0;
    BOOL rightEmpty = [m_rightStack count] == 0;
    
    if( leftEmpty && rightEmpty )        // case 1
    {
        // just stick it anywhere. this can be swapped in case 2.
        // make a (probably bad) guess.
        if( p.x < m_bounds.origin.x + (m_bounds.size.width / 2) )
        {
            //DebugOut( @"zero case: guessed left" );
            if( affectsMeanPoint ) [m_leftStack pushTouchAt:p];
        }
        else
        {
            //DebugOut( @"zero case: guessed right" );
            if( affectsMeanPoint ) [m_rightStack pushTouchAt:p];
        }
        result = DpadUnknownButton;  // no confidence in guess            
    }
    else if( leftEmpty || rightEmpty )   // case 2
    {
        // decide if this is close enough to stick in non-empty bin or not
        CGPoint compareTo;
        if( leftEmpty )
        {
            compareTo = [m_rightStack calculateMeanPoint];
        }
        else
        {
            compareTo = [m_leftStack calculateMeanPoint];
        }
        
        float distance = sqDist( p, compareTo );
        if( distance <= m_lowCountGuessThreshold )
        {
            if( leftEmpty )
            {
                //DebugOut( @"lowCountCloser (saw right)" );
                if( affectsMeanPoint ) [m_rightStack pushTouchAt:p];
                result = DpadRightButton;
            }
            else
            {
                //DebugOut( @"lowCountCloser (saw left)" );
                if( affectsMeanPoint ) [m_leftStack pushTouchAt:p];
                result = DpadLeftButton;
            }
        }
        else
        {
            if( leftEmpty )
            {
                // check if our previous right(s) was actually a left(s)
                if( p.x > compareTo.x )
                {
                    //DebugOut( @"lowCountFurther: bad guess, swapping (saw right)" );
                    DpadTouchSorterStack *dtssTemp = m_leftStack;
                    m_leftStack = m_rightStack;
                    m_rightStack = dtssTemp;
                    
                    if( affectsMeanPoint ) [m_rightStack pushTouchAt:p];
                    result = DpadRightButton;
                    
                }
                else
                {
                    //DebugOut( @"lowCountFurther: ok guess (saw left)" );
                    if( affectsMeanPoint ) [m_leftStack pushTouchAt:p];
                    result = DpadLeftButton;
                }
            }
            else
            {
                // check if our previous left(s) was actually a right(s)
                if( p.x < compareTo.x )
                {
                    //DebugOut( @"lowCountFurther: bad guess, swapping (saw left)" );
                    DpadTouchSorterStack *dtssTemp = m_leftStack;
                    m_leftStack = m_rightStack;
                    m_rightStack = dtssTemp;
                    
                    if( affectsMeanPoint ) [m_leftStack pushTouchAt:p];
                    result = DpadLeftButton;
                    
                }
                else
                {
                    //DebugOut( @"lowCountFurther: ok guess (saw right)" );
                    if( affectsMeanPoint ) [m_rightStack pushTouchAt:p];
                    result = DpadRightButton;
                }
            }
        }
        
    }
    else                                 // case 3
    {
        CGPoint leftMean = [m_leftStack calculateMeanPoint];
        CGPoint rightMean = [m_rightStack calculateMeanPoint];
        
        if( sqDist( p, leftMean ) < sqDist( p, rightMean ) )
        {
            //DebugOut( ([NSString stringWithFormat:@"stdCase: l %fx%f r %fx%f, saw left", leftMean.x, leftMean.y, rightMean.x, rightMean.y ]) );
            if( affectsMeanPoint ) [m_leftStack pushTouchAt:p];
            result = DpadLeftButton;            
        }
        else
        {
            //DebugOut( ([NSString stringWithFormat:@"stdCase: l %fx%f r %fx%f, saw right", leftMean.x, leftMean.y, rightMean.x, rightMean.y ]) );
            if( affectsMeanPoint ) [m_rightStack pushTouchAt:p];
            result = DpadRightButton;
        }
        
        //[self reassignStacks];  // when should you call this?
    }
    return result;

}


-(void)reassignStacks
{
    // TODO
    
    // This could be interesting if we figure out a good way to regression plot the combined collection of points
    //  such that we choose the two most likely center points. Not sure what this looks like right now, though.

}


-(CGPoint)calculateMeanPointLeft
{
    return [m_leftStack calculateMeanPoint];
}


-(CGPoint)calculateMeanPointRight
{
    return [m_rightStack calculateMeanPoint];
}


@end




// DpadInput ////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface DpadInput (private)

-(void)reset;
-(DpadButton)detectButtonFromTouchPoint:(CGPoint)p eventType:(DpadEventType)eventType affectsMeanPoint:(BOOL)affectsMeanPoint;
-(void)onGlobalCommand_resetDpad;
-(void)initSorters;
@end


@implementation DpadInput

@synthesize bModeHolder = m_bModeHolder;

-(id)init
{
    if( self = [super init] )
    {
        m_eventDelegates = nil;
        [self resetEventDelegates];

        [self initSorters];
        
        [GlobalCommand registerObject:self forNotification:GLOBAL_COMMAND_NOTIFICATION_RESETDPAD withSel:@selector(onGlobalCommand_resetDpad)];
        
        m_stateCache_LL = m_stateCache_LR = m_stateCache_RL = m_stateCache_RR = NO;
        m_bModeHolder = nil;  // weak
    }
    return self;
}


-(void)dealloc
{
    m_bModeHolder = nil;  // weak
    [GlobalCommand unregisterObject:self];
    
    [m_rightTouchLRSorter release]; m_rightTouchLRSorter = nil;
    [m_leftTouchLRSorter release]; m_leftTouchLRSorter = nil;
    [m_eventDelegates release]; m_eventDelegates = nil;
    [super dealloc];
}



-(void)initSorters
{
    const float deadSpaceAtBottom = 75.f;
    AspectController *ac = [AspectController instance];
    CGRect leftRect = CGRectMake ( 0.f, deadSpaceAtBottom, ac.xPixel / 2.f, ac.yPixel - deadSpaceAtBottom );
    CGRect rightRect = CGRectMake( ac.xPixel / 2.f, deadSpaceAtBottom, ac.xPixel, ac.yPixel - deadSpaceAtBottom );
    m_leftTouchLRSorter =  [[DpadTouchLRSorter alloc] initWithBounds:leftRect];
    m_rightTouchLRSorter = [[DpadTouchLRSorter alloc] initWithBounds:rightRect];
}


-(void)reset
{
    [m_rightTouchLRSorter release]; m_rightTouchLRSorter = nil;
    [m_leftTouchLRSorter release]; m_leftTouchLRSorter = nil;
    [self initSorters];
    m_stateCache_LL = m_stateCache_LR = m_stateCache_RL = m_stateCache_RR = NO;
}


-(void)resetEventDelegates
{
    [m_eventDelegates release]; m_eventDelegates = nil;
    m_eventDelegates = [[NSMutableSet alloc] initWithCapacity:5];
}


-(void)registerEventDelegate:(id<DpadEventDelegate>)theDelegate
{
    // TODO: this smells, why are we doing fancy stuff here?
    // we want to store weak references in the set, so wrap it with an NSValue
    NSValue *value = [NSValue valueWithNonretainedObject:theDelegate];    
    [m_eventDelegates addObject:value];
}


-(void)setBModeHolder:(id<IBModeHolder>)holder
{
    m_bModeHolder = holder;  // weak
}


-(DpadButton)detectButtonFromTouchPoint:(CGPoint)p eventType:(DpadEventType)eventType affectsMeanPoint:(BOOL)affectsMeanPoint
{
    DpadButton result;
    result = [m_leftTouchLRSorter detectButtonFromTouchPoint:p eventType:eventType affectsMeanPoint:affectsMeanPoint];
    if( result == DpadNotHandled )
    {
        result = [m_rightTouchLRSorter detectButtonFromTouchPoint:p eventType:eventType affectsMeanPoint:affectsMeanPoint];
    }
    return result;
}


// FUTURE: this is very hardcoded for the two zone/ two button setup. Could make this more flexible.
-(void)updateCachedStateForEvent:(DpadEvent *)event
{
    if( event.touchZone == LeftTouchZone )
    {
        if( event.button == DpadLeftButton )
        {
            m_stateCache_LL = (event.type == DpadPressed);
        }
        if( event.button == DpadRightButton )
        {
            m_stateCache_LR = (event.type == DpadPressed);
        }
    }
    if( event.touchZone == RightTouchZone )
    {
        if( event.button == DpadLeftButton )
        {
            m_stateCache_RL = (event.type == DpadPressed);
        }
        if( event.button == DpadRightButton )
        {
            m_stateCache_RR = (event.type == DpadPressed);
        }
        
    }
}


-(DpadEvent *)generateMutexEventForEvent:(DpadEvent *)event timeStamp:(NSTimeInterval)timeStamp
{
    DpadEvent *mutexEvent = nil;
    if( event.touchZone == LeftTouchZone )
    {
        if( event.button == DpadLeftButton )
        {
            if( m_stateCache_LR )
            {
                mutexEvent = [[DpadEvent alloc] initWithButton:DpadRightButton eventType:DpadReleased timeStamp:timeStamp touchZone:LeftTouchZone];
            }
        }
        if( event.button == DpadRightButton )
        {
            if( m_stateCache_LL )
            {
                mutexEvent = [[DpadEvent alloc] initWithButton:DpadLeftButton eventType:DpadReleased timeStamp:timeStamp touchZone:LeftTouchZone];
            }
        }
    }
    if( event.touchZone == RightTouchZone )
    {
        if( event.button == DpadLeftButton )
        {
            if( m_stateCache_RR )
            {
                mutexEvent = [[DpadEvent alloc] initWithButton:DpadRightButton eventType:DpadReleased timeStamp:timeStamp touchZone:RightTouchZone];
            }
        }
        if( event.button == DpadRightButton )
        {
            if( m_stateCache_RL )
            {
                mutexEvent = [[DpadEvent alloc] initWithButton:DpadLeftButton eventType:DpadReleased timeStamp:timeStamp touchZone:RightTouchZone];
            }
        }
        
    }
    return mutexEvent;
}


-(BOOL)shouldIgnoreMoveTouchButton:(DpadButton)button touchZone:(TouchZone)touchZone
{
    if( touchZone == LeftTouchZone )
    {
        if( button == DpadLeftButton )
        {
            return m_stateCache_LL;
        }
        if( button == DpadRightButton )
        {
            return m_stateCache_LR;
        }
    }
    if( touchZone == RightTouchZone )
    {
        if( button == DpadLeftButton )
        {
            return m_stateCache_RL;
        }
        if( button == DpadRightButton )
        {
            return m_stateCache_RR;
        }
    }
    NSLog( @"that's interesting, I see an unexpected DpadInput combo. zone: %d, button: %d.", touchZone, button );
    return NO;
}


-(void)handleTouchMovedAt:(CGPoint)p timeStamp:(NSTimeInterval)timeStamp
{
    TouchZone touchZone = p.x < [AspectController instance].xPixel / 2.f ? LeftTouchZone : RightTouchZone;
    DpadButton newButton = [self detectButtonFromTouchPoint:p eventType:DpadPressed affectsMeanPoint:NO];   // don't affect meanpoints, prevents sliding.
    if( newButton == DpadNotHandled )
    {
        return;
    }
    
    // if this touch doesn't change our state (e.g. just moving finger after a normal jump), do nothing.
    if( [self shouldIgnoreMoveTouchButton:newButton touchZone:touchZone] )
        return;

    DpadEvent *thisEvent = [[DpadEvent alloc] initWithButton:newButton eventType:DpadPressed timeStamp:timeStamp touchZone:touchZone];

    // potentially generate the off event for the mutex'd button 
    DpadEvent *offEvent = [self generateMutexEventForEvent:thisEvent timeStamp:timeStamp];
   
    // distribute to all registered delegates
    NSEnumerator *enumerator = [m_eventDelegates objectEnumerator];
    NSValue *thisValue;
    id<DpadEventDelegate> thisDelegate;
    
    while( thisValue = (NSValue *)[enumerator nextObject] )
    {
        thisDelegate = (id<DpadEventDelegate>)[thisValue nonretainedObjectValue];
        if( offEvent != nil )
        {
            [thisDelegate onDpadEvent:offEvent];
        }
        [thisDelegate onDpadEvent:thisEvent];
    }
    
    if( offEvent != nil )
    {
        [self updateCachedStateForEvent:offEvent];
    }
    [self updateCachedStateForEvent:thisEvent];
    
    [offEvent release];
    [thisEvent release];
}


-(void)handleTouch:(UITouch *)touch at:(CGPoint)p
{
    // if b-mode is active, dpad doesn't listen.
    if( [m_bModeHolder isBModeActive] ) return;
    
    // first generate the DpadEvent

    DpadEventType eventType;
    switch( touch.phase )
    {
        case UITouchPhaseBegan:
            eventType = DpadPressed;
            break;
            
        case UITouchPhaseEnded:
        case UITouchPhaseCancelled:
            eventType = DpadReleased;
            break;
            
        case UITouchPhaseMoved:
            // touchMoved is a special case: may have moved to other button, in which case we should generate a released/pressed pair.
            [self handleTouchMovedAt:p timeStamp:touch.timestamp];
            return;            
            
        case UITouchPhaseStationary:
            // stationary phase has no effect on dpad recognition.
            return;
            
        default:
            NSAssert( NO, @"Unexpected touch phase?" );
            return;
            
    }
    
    TouchZone touchZone = p.x < [AspectController instance].xPixel / 2.f ? LeftTouchZone : RightTouchZone;

    DpadButton button = [self detectButtonFromTouchPoint:p eventType:eventType affectsMeanPoint:YES];
    if( button == DpadNotHandled )
    {
        return;
    }
    
    DpadEvent *thisEvent = [[DpadEvent alloc] initWithButton:button eventType:eventType timeStamp:touch.timestamp touchZone:touchZone];
    
    // then distribute it to all registered delegates
    NSEnumerator *enumerator = [m_eventDelegates objectEnumerator];
    NSValue *thisValue;
    id<DpadEventDelegate> thisDelegate;
    
    [self updateCachedStateForEvent:thisEvent];
    
    while( thisValue = (NSValue *)[enumerator nextObject] )
    {
        thisDelegate = (id<DpadEventDelegate>)[thisValue nonretainedObjectValue];
        [thisDelegate onDpadEvent:thisEvent];
    }
    
    [thisEvent release];
    
}


-(DpadTouchLRSorter *)sorterForZone:(TouchZone)touchZone
{
    switch( touchZone )
    {
        case LeftTouchZone:
            return m_leftTouchLRSorter;
            break;
            
        case RightTouchZone:
            return m_rightTouchLRSorter;
            break;
            
        default:
            return nil;
            break;
    }
}

-(void)onGlobalCommand_resetDpad
{
    [self reset];
}



@end


