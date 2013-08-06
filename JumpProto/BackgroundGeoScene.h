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


// ------------------------
@interface BDNode : NSObject

@property (nonatomic, retain) BDNode *next;
@property (nonatomic, retain) BDNode *prev;
@property (nonatomic, retain) NSObject *data;

@end


// ------------------------
@interface BDQueue : NSObject {
    BDNode *m_ptr;
}

-(void)reset;
-(NSObject *) next;
@end


// ------------------------
@interface BaseStrip : NSObject

@property (nonatomic, assign) float depth;

-(id)initWithDepth:(float)depth;
-(void)drawWithXOffs:(CGFloat)xOffs yOffs:(CGFloat)yOffs;

@end


// ------------------------
@interface Test1Strip : BaseStrip
@end


// ------------------------
@interface StripScene : NSObject

-(void)addStrip:(BaseStrip *)strip;
-(void)drawAllStripsWithXOffs:(Emu)xOffs yOffs:(Emu)yOffs;

@end


// ------------------------

@interface BackgroundGeoSceneLayerView : LayerView {
    StripScene *m_stripScene;
    
}

@end
