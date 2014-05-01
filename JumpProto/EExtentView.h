//
//  EExtentView.h
//

#import <Foundation/Foundation.h>
#import "QuartzView.h"
#import "EWorldView.h"


/////////////////////////////////////////////////////////////////////////////////////////////////////////// EExtentView.h
@interface EExtentView.h : QuartzView<IPanZoomResultConsumer>
{
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

-(void)setCenterPoint:(CGPoint)centerPoint;
-(void)selectMRUEntryAtIndex:(int)index;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// EPanZoomProcessor
@interface EPanZoomProcessor : NSObject<IPanZoomProcessor>
{
    id<IPanZoomResultConsumer> m_consumer;
}

@end
