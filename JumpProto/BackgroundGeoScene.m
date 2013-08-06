//
//  BackgroundGeoScene.m
//  BASICPROJECT
//
//  Created by gideong on 2013.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//

#import "BackgroundGeoScene.h"

// ------------------------
@implementation BDNode
@synthesize next, prev, data;

-(id)init {
    if( self = [super init] ) {
        self.next = nil;
        self.prev = nil;
        self.data = nil;
    }
    return self;
}

-(void)dealloc {
    self.next = nil;
    self.prev = nil;
    self.data = nil;
    [super dealloc];
}

@end


// ------------------------
@implementation BDQueue
/*
 @interface BDQueue {
 BDNode *m_ptr;
 }
 
 -(void)reset;
 -(NSObject *) next;
*/
@end


// ------------------------
@implementation BaseStrip
/*@interface BaseStrip
 @property (nonatomic, assign) float depth;
 -(id)initWithDepth:(float)depth;
 -(void)drawWithXOffs:(CGFloat)xOffs yOffs:(CGFloat)yOffs;
 
 @end
*/
@end


// ------------------------
@implementation Test1Strip
/*@interface BaseStrip
 @property (nonatomic, assign) float depth;
 -(id)initWithDepth:(float)depth;
 -(void)drawWithXOffs:(CGFloat)xOffs yOffs:(CGFloat)yOffs;
 
 @end
 */
@end


// ------------------------
@implementation StripScene
/*
 @interface StripScene
 
 -(void)addStrip:(BaseStrip *)strip;
 -(void)drawAllStripsWithXOffs:(Emu)xOffs yOffs:(Emu)yOffs;
 
 @end
*/
@end


// ------------------------
@interface BackgroundGeoSceneLayerView (private)


@end

@implementation BackgroundGeoSceneLayerView

/*
 @interface BackgroundGeoSceneLayerView : LayerView {
 StripScene *m_stripScene;
 
 }
 
 @end
 */

-(void)buildScene
{
    // TODO: wouldn't mind seeing a gradient rectangle here instead. can't be that much slower.
	glClearColor(0.1f, 0.1f, 0.3f, 1.0f);
	glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
}


-(void)updateWithTimeDelta:(float)timeDelta
{
}

@end


