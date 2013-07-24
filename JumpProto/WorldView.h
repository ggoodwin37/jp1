//
//  WorldView.h
//  JumpProto
//
//  Created by gideong on 7/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LayerView.h"
#import "World.h"


@interface FocalPointCamera : NSObject
{
    CGPoint m_focalPoint;
    BOOL m_hadFirstUpdate;
    CGSize m_tolerance;
}

// tolerance is how far the focal point can get from the player before moving.
-(id)initWithTolerance:(CGSize)tolerance;

-(void)reset;

-(void)updateWithActorBlock:(ActorBlock *)playerBlock minY:(Emu)minY;
-(void)updateForPoint:(CGPoint)p minY:(Emu)minY;
-(CGRect)getViewRectWithZoomOutFactor:(float)zoom;

@end


@interface WorldView : LayerView {
    FocalPointCamera *m_camera;
    
    SpriteState *m_genericPlayerSpriteState;  // used to draw player even though player's block hasn't been created yet.
    
// takes 3-4ms on typical levels and up to 11ms on levels that fill almost the entire screen with blocks.
// this will only get worse as more layers and background stuff gets added.
#define TIME_WORLDVIEW
#define TIME_WORLDVIEW_REPORT_PERIOD (10.f)
    
#ifdef TIME_WORLDVIEW
    float m_timer_timeUntilNextReport;
    int m_timer_timesDidDraw;
    int m_timer_millisecondsSpentDrawing;
    long m_timer_start;
#endif
    
}

@property (nonatomic, assign) World *world;  // weak

@end

