//
//  WorldView.m
//  JumpProto
//
//  Created by gideong on 7/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "WorldView.h"
#import "AspectController.h"
#import "SpriteStateDrawUtil.h"


@implementation FocalPointCamera

-(id)initWithTolerance:(CGSize)tolerance
{
    if( self = [super init] )
    {
        m_tolerance = tolerance;
    }
    return self;
}


-(void)dealloc
{
    [super dealloc];
}


-(void)reset
{
    m_hadFirstUpdate = NO;
}


-(void)updateForPoint:(CGPoint)p minY:(Emu)minY
{
    if( !m_hadFirstUpdate )
    {
        m_focalPoint = p;
        m_hadFirstUpdate = YES;
    }
    else
    {
        float x = m_focalPoint.x;
        if( x > p.x + m_tolerance.width )
        {
            x = p.x + m_tolerance.width; 
        }
        else if( x < p.x - m_tolerance.width )
        {
            x = p.x - m_tolerance.width; 
        }
        float y = m_focalPoint.y;
        if( y > p.y + m_tolerance.height )
        {
            y = p.y + m_tolerance.height; 
        }
        else if( y < p.y - m_tolerance.height )
        {
            y = p.y - m_tolerance.height; 
        }
        
        if( y < minY )
        {
            y = minY;
        }
        
        m_focalPoint = CGPointMake( x, y );
    }
    // TODO / REVERT: delete. this is here to give me a sense of the input values to parallax engine.
    //NSLog( @"camera focal point is %f x %f", m_focalPoint.x, m_focalPoint.y );
}


-(void)updateWithActorBlock:(ActorBlock *)playerBlock minY:(Emu)minY
{
    float px = EmuToFl( playerBlock.x + (playerBlock.w / 2.f) );
    float py = EmuToFl( playerBlock.y + (playerBlock.h / 2.f) );
    [self updateForPoint:CGPointMake( px, py ) minY:minY];
}


-(CGRect)getViewRectWithZoomOutFactor:(float)zoom
{
    // the zoom factor means smaller blocks (see more of level) as value goes higher. so values less than 1 will zoom in. TODO: backwards?
    
    float viewWidth = zoom * [AspectController instance].xPixel;
    float viewHeight = zoom * [AspectController instance].yPixel;
    
    float xCenter = viewWidth / 2.f;
    float yCenter = viewHeight / 2.f;

    return CGRectMake( m_focalPoint.x - xCenter, m_focalPoint.y - yCenter,
                       viewWidth, viewHeight );
}

-(CGPoint)getFocalPoint
{
    return m_focalPoint;
}

@end


@implementation WorldView

@synthesize world = m_world;

-(id)init
{
    if( self = [super init] )
    {
        m_world = nil;
        
        const float cameraToleranceFraction = 0.1f;
        CGSize cameraTolerance = CGSizeMake( cameraToleranceFraction * [AspectController instance].xPixel,
                                             cameraToleranceFraction * [AspectController instance].yPixel );
        m_camera = [[FocalPointCamera alloc] initWithTolerance:cameraTolerance];
        
        m_genericPlayerSpriteState = nil;

        // std_height * std_zoom = ypix * n
        // n = std_height * std_height / n
        m_standardZoom = VIEW_STANDARD_ZOOM * VIEW_STANDARD_HEIGHT / [AspectController instance].yPixel;
        
#ifdef TIME_WORLDVIEW
        m_timer_timeUntilNextReport = TIME_WORLDVIEW_REPORT_PERIOD;
        m_timer_timesDidDraw = 0;
        m_timer_millisecondsSpentDrawing = 0;
#endif
    }
    return self;
}


-(void)dealloc
{
    [m_genericPlayerSpriteState release]; m_genericPlayerSpriteState = nil;
    [m_camera release]; m_camera = nil;
    m_world = nil;  // weak
    [super dealloc];
}


-(void)setupForSpriteBlocks
{
    [SpriteStateDrawUtil setupForSpriteDrawing];
}


-(void)drawSpriteBlock:(SpriteBlock *)block
{
    // tile the sprite based on worldSize property. Note: doesn't handle non-integral tiles (yet).
    // assume that the defaultSpriteState has same worldSize as all others in the map, since
    //  otherwise implies an uneven grid which doesn't make sense.
    CGSize worldSize = block.defaultSpriteState.worldSize;
    Emu tileW = fmaxf( 1.f, worldSize.width ) * ONE_BLOCK_SIZE_Emu;
    Emu tileH = fmaxf( 1.f, worldSize.height ) * ONE_BLOCK_SIZE_Emu;
    float tileWFl = EmuToFl( tileW );
    float tileHFl = EmuToFl( tileH );
    int xCount = block.spriteStateMap.size.width;
    int yCount = block.spriteStateMap.size.height;
    GLbyte a = 0xff, r, g, b;
    
    if( [m_world isBModeActive] )
    {
        if( block.props.isPlayerBlock )
        {
            r = 0xff; g = 0xff; b = 0xff;
        }
        else if( block.props.bModeActive )
        {
            r = 0xff; g = 0xff; b = 0x00;
        }
        else
        {
            r = g = b = 0x40;
        }
    }
    else
    {
        r = g = b = 0xff;
    }
    for( int iy = 0; iy < yCount; ++iy)
    {
        float y = EmuToFl( block.y + (iy * tileH) );
        for( int ix = 0; ix < xCount; ++ix)
        {
            float x = EmuToFl( block.x + (ix * tileW) );
            SpriteState *spriteState = [block.spriteStateMap getSpriteStateAtX:ix y:iy];
            [SpriteStateDrawUtil drawSpriteForState:spriteState x:x y:y w:tileWFl h:tileHFl a:a r:r g:g b:b];
        }
    }
}


-(BOOL)shouldDrawBlock:(Block *)block inViewRect:(CGRect)viewRect
{
    // TODO optimization: you can convert the viewRect to Emu and reuse it for entire frame, instead of
    //                    converting these four to Fl for each block in the frame. this func runs once
    //                    per frame for every block in the level, not just on screen.
    float x = EmuToFl( block.x );
    float w = EmuToFl( block.w );
    float y = EmuToFl( block.y );
    float h = EmuToFl( block.h );
    
    if( x > viewRect.origin.x + viewRect.size.width )
        return NO;
    if( x + w < viewRect.origin.x )
        return NO;
    if( y > viewRect.origin.y + viewRect.size.height )
        return NO;
    if( y + h < viewRect.origin.y )
        return NO;
    return YES;
}


float smoothRatio( float inputRatio )
{
    return sinf( inputRatio * M_PI_2 );
}


-(float)getZoomOutFactor
{
    // for now we just have a simple scheme where we start zoomed out, then quickly zoom in durin the "being born"
    //  state. The naming, scale etc of this part kind of bug me. a zoom factor of 1.f means unzoomed, 2.f means
    //  "twice as big" in each axis, etc.
    
    // future: could imagine this getting more interesting, zooming based on action, etc. could also have its own
    //  state so it wouldn't have to be coupled directly to an actor's timing state.
    float ratio;
    const float notBornYetZoom = PLAYER_BEINGBORN_ZOOMOUT_MAX_FACTOR * m_standardZoom;
    PlayerActor *playerActor = [m_world getPlayerActor];
    switch( playerActor.lifeState )
    {
        case ActorLifeState_NotBornYet:
            return notBornYetZoom;
            
        case ActorLifeState_BeingBorn:
            ratio = 1.f - (playerActor.lifeStateTimer / PLAYER_BEINGBORN_TIME);   // from 0 to 1
            ratio = smoothRatio( ratio );  // from 0 to 1, smoothed
            return notBornYetZoom + (ratio * (m_standardZoom - notBornYetZoom));
            
        default:
            return m_standardZoom;
    }
}


-(CGRect)setupCurrentView
{
    ActorBlock *playerBlock = [[m_world getPlayerActor] getDefaultActorBlock];
    if( [m_world getPlayerActor].lifeState == ActorLifeState_Alive && playerBlock != nil )
    {
        [m_camera updateWithActorBlock:playerBlock minY:m_world.yBottom];
    }
    else
    {
        if( [m_world getPlayerActor].lifeState == ActorLifeState_NotBornYet ||
            [m_world getPlayerActor].lifeState == ActorLifeState_BeingBorn )
        {
            EmuPoint ep = [m_world getPlayerActor].startingPoint;
            CGSize knownDims = CGSizeMake( EmuToFl( PLAYER_WIDTH ), EmuToFl( PLAYER_HEIGHT ) );  // TODO: using these constants here is cheating, should really get them from the actor.
            [m_camera reset];  // ensure player start point is centered in camera.
            [m_camera updateForPoint:CGPointMake( EmuToFl( ep.x ) + (knownDims.width / 2.f), EmuToFl( ep.y ) + (knownDims.height / 2.f) ) minY:m_world.yBottom];
        }
        
        // else don't move camera
    }
    
    float zoomOutFactor = [self getZoomOutFactor];
    CGRect viewRect = [m_camera getViewRectWithZoomOutFactor:zoomOutFactor];
    
	glMatrixMode( GL_PROJECTION );
	glLoadIdentity();
	glOrthof( floorf( viewRect.origin.x ), ceilf( viewRect.origin.x + viewRect.size.width ),
              floorf( viewRect.origin.y ), ceilf( viewRect.origin.y + viewRect.size.height ),
              -0.01 /*zNear*/, 0.01 /*zFar*/ );
	glMatrixMode( GL_MODELVIEW );

    return viewRect;
}


-(void)tryDrawOneSpriteBlock:(SpriteBlock *)block withViewRect:(CGRect)viewRect
{
    if( [self shouldDrawBlock:block inViewRect:viewRect] )
    {
        [self drawSpriteBlock:block];
    }
}


-(void)drawPlayerBeingBorn_cheezy1:(PlayerActor *)playerActor
{
    // just do a cheezy zoom-in thingie for now.
    NSAssert( playerActor.lifeState == ActorLifeState_BeingBorn, @"drawPlayerBeingBorn_cheezy1: unexpected life state." );
    
    float ratio = 1.f - (playerActor.lifeStateTimer / PLAYER_BEINGBORN_TIME);
    
    float targetWEm = 1.f * PLAYER_WIDTH;
    float targetHEm = ratio * PLAYER_HEIGHT;

    float targetXEm = playerActor.startingPoint.x + ((PLAYER_WIDTH - targetWEm) / 2.f);
    float targetYEm = playerActor.startingPoint.y + ((PLAYER_HEIGHT - targetHEm) / 2.f);
    
    if( m_genericPlayerSpriteState == nil )
    {
        m_genericPlayerSpriteState = [[StaticSpriteState alloc] initWithSpriteName:[playerActor getStaticFrameName]];
        NSAssert( m_genericPlayerSpriteState != nil, @"failed to make cheezy spriteState thingie." );
    }
    
    [SpriteStateDrawUtil drawSpriteForState:m_genericPlayerSpriteState x:EmuToFl( targetXEm ) y:EmuToFl( targetYEm ) w:EmuToFl( targetWEm ) h:EmuToFl( targetHEm ) a:0xff r:0xff g:0xff b:0xff];
}


-(void)drawPlayerDying_cheezy1:(PlayerActor *)playerActor
{
    ActorBlock *playerActorBlock = [playerActor getDefaultActorBlock];
    // just do a cheezy zoom-in thingie for now.
    NSAssert( playerActor.lifeState == ActorLifeState_Dying, @"drawPlayerDying_cheezy1: unexpected life state." );
    NSAssert( playerActorBlock != nil, @"need player's actorBlock" );
    
    float ratio = 1.f - playerActor.lifeStateTimer / PLAYER_DYING_TIME;   // 0 to 1
    ratio = 1.f - sinf( ratio * M_PI_2 );  // 1 to 0, smoothed
    
    float targetWEm = ratio * PLAYER_WIDTH;
    float targetHEm = ratio * 2.9f * PLAYER_HEIGHT;  // so ugly
    targetWEm = fmaxf( targetWEm, 1.f );
    targetHEm = fmaxf( targetHEm, 1.f );
    
    float targetXEm = playerActorBlock.x + ((PLAYER_WIDTH - targetWEm) / 2.f);
    float targetYEm = playerActorBlock.y + ((PLAYER_HEIGHT - targetHEm) / 2.f);
    
    [SpriteStateDrawUtil drawSpriteForState:playerActorBlock.defaultSpriteState x:EmuToFl( targetXEm ) y:EmuToFl( targetYEm ) w:EmuToFl( targetWEm ) h:EmuToFl( targetHEm ) a:0xff r:0xff g:0xff b:0xff];
}


-(void)drawPlayerWinning_cheezy1:(PlayerActor *)playerActor
{
    ActorBlock *playerActorBlock = [playerActor getDefaultActorBlock];
    // just do a cheezy zoom-in thingie for now.
    NSAssert( playerActor.lifeState == ActorLifeState_Winning, @"drawPlayerWinning_cheezy1: unexpected life state." );
    NSAssert( playerActorBlock != nil, @"need player's actorBlock" );
    
    float ratio = 1.f - playerActor.lifeStateTimer / PLAYER_WINNING_TIME;   // 0 to 1
    ratio = 1.f - cosf( ratio * M_PI_2 );  // 1 to 0, smoothed
    
    const float boomZoom = 8.f;
    float targetWEm = (boomZoom * ratio + 1.f ) * PLAYER_WIDTH;
    float targetHEm = (boomZoom * ratio + 1.f ) * PLAYER_HEIGHT;
    targetWEm = fmaxf( targetWEm, 1.f );
    targetHEm = fmaxf( targetHEm, 1.f );
    
    float targetXEm = playerActorBlock.x + ((PLAYER_WIDTH - targetWEm) / 2.f);
    float targetYEm = playerActorBlock.y + ((PLAYER_HEIGHT - targetHEm) / 2.f);
    
    [SpriteStateDrawUtil drawSpriteForState:playerActorBlock.defaultSpriteState x:EmuToFl( targetXEm ) y:EmuToFl( targetYEm ) w:EmuToFl( targetWEm ) h:EmuToFl( targetHEm ) a:0xff r:0xff g:0xff b:0xff];
}


#ifdef TIME_WORLDVIEW

-(void)worldViewTimer_pre
{
    m_timer_start = getUpTimeMs();
}


-(void)worldViewTimer_post
{
    int delta = (int)( getUpTimeMs() - m_timer_start );
    if( delta < 0 )
    {
        NSLog( @"worldViewTimer_post: wraparound case." );  // am I imagining this?
        return;
    }
    
    m_timer_millisecondsSpentDrawing += delta;
    ++m_timer_timesDidDraw;
    
    if( m_timer_timeUntilNextReport <= 0.f )
    {
        if( m_timer_timesDidDraw > 0 && m_timer_millisecondsSpentDrawing > 0 )
        {
            float avgMs = ((float)m_timer_millisecondsSpentDrawing) / ((float)m_timer_timesDidDraw);
            NSLog( @"worldView draw avg: %fms.", avgMs );
        }
        m_timer_timeUntilNextReport = TIME_WORLDVIEW_REPORT_PERIOD;
        m_timer_timesDidDraw = 0;
        m_timer_millisecondsSpentDrawing = 0;
    }
    
}
#endif


// override
-(void)buildScene
{
    if( /*hi*/ m_world == nil )
        return;
    
#ifdef TIME_WORLDVIEW
    [self worldViewTimer_pre];
#endif
    
    [SpriteStateDrawUtil beginFrame];
    
    CGRect viewRect = [self setupCurrentView];
    
    [self setupForSpriteBlocks];
    int count = [m_world worldSOCount];
    for( int i = 0; i < count; ++i )
    {
        ASolidObject *thisSO = [m_world getWorldSO:i];

        // TODO: need to validate that thisBlock really is a SpriteBlock? how to do that cheaply? can just trust myself not to put other stuff in there??
        
        if( [thisSO isGroup] )
        {
            BlockGroup *thisGroup = (BlockGroup *)thisSO;
            for( int i = 0; i < [thisGroup.blocks count]; ++i )
            {
                SpriteBlock *thisBlock = (SpriteBlock *)[thisGroup.blocks objectAtIndex:i];
                [self tryDrawOneSpriteBlock:thisBlock withViewRect:viewRect];
            }
        }
        else
        {
            SpriteBlock *thisBlock = (SpriteBlock *)thisSO;
            [self tryDrawOneSpriteBlock:thisBlock withViewRect:viewRect];
        }
    }
    
    for( int i = 0; i < [m_world.npcActors count]; ++i )
    {
        Actor *thisNpc = (Actor *)[m_world.npcActors objectAtIndex:i];
        
        for( int j = 0; j < [thisNpc.actorBlockList count]; ++j )
        {
            ActorBlock *thisActorBlock = [thisNpc.actorBlockList objectAtIndex:j];
            switch( thisNpc.lifeState )
            {
                case ActorLifeState_Alive:
                    if( thisActorBlock != nil )
                    {
                        SpriteBlock *thisBlock = (SpriteBlock *)thisActorBlock;
                        [self tryDrawOneSpriteBlock:thisBlock withViewRect:viewRect];
                    }
                    break;
                    
                case ActorLifeState_BeingBorn:
                    // TODO
                    break;
                
                case ActorLifeState_Dying:
                    // TODO
                    break;                
                    
                default:
                    // don't draw anything for this state.
                    break;
            }
        }
    }

    ActorLifeState playerLifeState = [m_world getPlayerActor].lifeState;
    ActorBlock *playerActorBlock;
    switch( playerLifeState )
    {
        case ActorLifeState_Alive:
            playerActorBlock = [[m_world getPlayerActor] getDefaultActorBlock];
            if( playerActorBlock != nil )
            {
                [self tryDrawOneSpriteBlock:playerActorBlock withViewRect:viewRect];
            }
            break;
        
        case ActorLifeState_BeingBorn:
            [self drawPlayerBeingBorn_cheezy1:[m_world getPlayerActor]];
            break;

        case ActorLifeState_Dying:
            if( ![m_world getPlayerActor].isGibbed )
            {
                [self drawPlayerDying_cheezy1:[m_world getPlayerActor]];
            }
            // else gibs are drawn as blocks
            break;
            
        case ActorLifeState_Winning:
            [self drawPlayerWinning_cheezy1:[m_world getPlayerActor]];
            break;
            
        default:
            break;
    }
    
    [SpriteStateDrawUtil endFrame];
    
#ifdef TIME_WORLDVIEW
    [self worldViewTimer_post];
#endif

}


// override
-(void)updateWithTimeDelta:(float)timeDelta
{
    if( m_world == nil )
        return;
    
    [m_world updateWithTimeDelta:timeDelta];


#ifdef TIME_WORLDVIEW
    m_timer_timeUntilNextReport -= timeDelta;
#endif
}


-(CGPoint)getCameraFocalPoint
{
    return m_camera.focalPoint;
}

@end
