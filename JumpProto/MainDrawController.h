//
//  MainDrawController.h
//  Created by gideong on DATE.
//  Copyright GoodGuyApps.com 2010. All rights reserved.

#import <Foundation/Foundation.h>
#import "ES1RenderDelegate.h"
#import "AspectController.h"
#import "LogStopWatch.h"
#import "LayerView.h"

#import "TouchFeedbackLayerView.h"
#import "DebugLogLayerView.h"
#import "DpadFeedbackLayerView.h"
#import "WorldView.h"
#import "GlobalButtonView.h"

@interface MainDrawController : NSObject <ES1RenderDelegate>
{
	CFTimeInterval				m_timeOfLastFrame;
	float						m_timeSinceLastFrame;
	
	NSArray						*m_layerList;
}

@property (nonatomic, readonly) TouchFeedbackLayerView *touchFeedbackLayer;
@property (nonatomic, readonly) DebugLogLayerView *debugLogLayer;
@property (nonatomic, readonly) DpadFeedbackLayerView *dpadFeedbackLayerViewLeft;
@property (nonatomic, readonly) DpadFeedbackLayerView *dpadFeedbackLayerViewRight;
@property (nonatomic, readonly) WorldView *worldView;
@property (nonatomic, readonly) GlobalButtonView *globalButtonView;

@end
