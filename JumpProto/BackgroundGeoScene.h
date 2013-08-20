//
//  BackgroundGeoScene.h
//  BASICPROJECT
//
//  Created by gideong on 7/16/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LayerView.h"
#import "Emu.h"
#import "RectCoordBuffer.h"

#define TIME_STRIPDRAW
#define TIME_STRIPDRAW_REPORT_PERIOD (10.f)


// ------------------------
@interface BaseStrip : NSObject

@property (nonatomic, assign) float depth;

-(id)initWithDepth:(float)depth;
-(float)scaleXForDepth:(float)xIn;
-(void)drawWithXOffs:(float)xOffs yOffs:(float)yOffs;

@end


// ------------------------
@interface BaseStripScene : NSObject
{
    NSMutableArray *m_stripList;
}
@property (nonatomic, retain) RectCoordBuffer *sharedRectBuf;

-(void)setupView;  // (protected)
-(void)drawAllStripsWithXOffs:(float)xOffs yOffs:(float)yOffs;

@end


// ------------------------
@interface BackgroundGeoSceneLayerView : LayerView {
    BaseStripScene *m_stripScene;
    CGPoint m_fakeWorldOffset;
    
#ifdef TIME_STRIPDRAW
    float m_timer_timeUntilNextReport;
    int m_timer_timesDidDraw;
    int m_timer_millisecondsSpentDrawing;
    long m_timer_start;
#endif
}

@end
