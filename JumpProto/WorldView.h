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

@property (nonatomic, readonly, getter=getFocalPoint) CGPoint focalPoint;
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
    
    float m_standardZoom;

#define TIME_WORLDVIEW
#define TIME_WORLDVIEW_REPORT_PERIOD (10.f)
    
#ifdef TIME_WORLDVIEW
    float m_timer_timeUntilNextReport;
    int m_timer_timesDidDraw;
    int m_timer_millisecondsSpentDrawing;
    long m_timer_start;
#endif
    
}

@property (nonatomic, readonly, getter=getCameraFocalPoint) CGPoint cameraFocalPoint;
@property (nonatomic, assign) World *world;  // weak

@end

