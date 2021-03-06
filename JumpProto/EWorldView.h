//
//  EWorldView.h
//  JumpProto
//
//  Created by gideong on 10/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QuartzView.h"
#import "ArchiveFormat.h"
#import "EDoc.h"
#import "EBlockMRUList.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////// EToolMode
enum EToolModeEnum
{
    ToolModeDrawBlock = 0,
    ToolModeErase,
    ToolModeGrab,
    ToolModeGroup,
    NumToolModes,
};

typedef enum EToolModeEnum EToolMode;


/////////////////////////////////////////////////////////////////////////////////////////////////////////// IPanZoomResultConsumer
@protocol IPanZoomResultConsumer <NSObject>
-(void)onZoomByFactor:(float)factor centeredOnViewPoint:(CGPoint)pCenter;
-(void)onPanByViewUnits:(CGPoint)vector;
@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// IPanZoomProcessor
@protocol IPanZoomProcessor <NSObject>
-(void)registerConsumer:(id<IPanZoomResultConsumer>) consumer;
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event inView:(UIView *)view;
-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event inView:(UIView *)view;
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event inView:(UIView *)view;
-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event inView:(UIView *)view;
@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// IWorldViewEventCallback
@protocol IWorldViewEventCallback <NSObject>
-(void)onGrabbedPreset;
@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// EWorldView

@class EExtentView;

@interface EWorldView : QuartzView<IPanZoomResultConsumer, ICurrentBlockPresetStateConsumer>
{
    id<IPanZoomProcessor> m_panZoomGestureProcessor;
    id<ICurrentBlockPresetStateHolder> m_blockPresetStateHolder;
    id<IWorldViewEventCallback> m_worldViewEventCallback;
}

@property (nonatomic, assign) AFLevel *level;  // weak
@property (nonatomic, assign) CGRect worldRect;
@property (nonatomic, assign) EToolMode currentToolMode;
@property (nonatomic, assign) EGridDocument *document;  // weak
@property (nonatomic, assign) BOOL gridVisible;
@property (nonatomic, assign) BOOL geoModeVisible;
@property (nonatomic, assign) id<IWorldViewEventCallback> worldViewEventCallback;  // weak
@property (nonatomic, assign) BOOL docDirty;
@property (nonatomic, retain) UILabel *groupOverlayDrawer;
@property (nonatomic, assign) BOOL drawGroupOverlay;
@property (nonatomic, assign) GroupId activeGroupId;
@property (nonatomic, assign) BOOL cursorVisible;
@property (nonatomic, assign) int currentSnap;
@property (nonatomic, assign) BOOL currentTouchEventPanZoomed;
@property (nonatomic, retain) EBlockMRUList *blockMRUList;
@property (nonatomic, assign) CGPoint freeDrawStartPointWorld;
@property (nonatomic, assign) CGPoint freeDrawEndPointWorld;
@property (nonatomic, readonly) id<IPanZoomProcessor> zoomSource;
@property (nonatomic, assign) EExtentView *extentView;  // weak

-(void)setCenterPoint:(CGPoint)centerPoint;
-(void)selectMRUEntryAtIndex:(int)index;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// EPanZoomProcessor
@interface EPanZoomProcessor : NSObject<IPanZoomProcessor>
{
    NSMutableArray *m_consumers;
}

@end


// could save one mult or divide each by prefactoring if needed.
#define viewToWorld( input_viewcoord, worldorig, worldsize, viewsize ) ( (worldorig) + (((input_viewcoord)/(viewsize)) * (worldsize) ) )
#define worldToView( input_worldcoord, worldorig, worldsize, viewsize )  ( ((input_worldcoord) - (worldorig)) * (viewsize) / (worldsize) )
