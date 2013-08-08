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
@interface BaseStrip : NSObject

@property (nonatomic, assign) float depth;

-(id)initWithDepth:(float)depth;
-(void)drawWithXOffs:(float)xOffs yOffs:(float)yOffs;

@end


// ------------------------
@interface BaseStripScene : NSObject
{
    NSMutableArray *m_stripList;
}

-(void)drawAllStripsWithXOffs:(float)xOffs yOffs:(float)yOffs;

@end


// ------------------------
@interface BackgroundGeoSceneLayerView : LayerView {
    BaseStripScene *m_stripScene;
    
}

@end
