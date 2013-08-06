//
//  BackgroundGeoScene.h
//  BASICPROJECT
//
//  Created by gideong on 7/16/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LayerView.h"
#import "LinkedList.h"
#import "Emu.h"


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
{
    NSMutableArray *m_stripList;
}

-(void)addStrip:(BaseStrip *)strip;
-(void)drawAllStripsWithXOffs:(Emu)xOffs yOffs:(Emu)yOffs;

@end


// ------------------------

@interface BackgroundGeoSceneLayerView : LayerView {
    StripScene *m_stripScene;
    
}

@end
