//
//  DebugLogLayerView.h
//  JumpProto
//
//  Created by gideong on 7/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LayerView.h"
#import "HitZone.h"

// DebugTextBuffer /////////////////////////////////////////////////////////////////

@interface DebugTextBuffer : NSObject {
    NSMutableArray          *m_entries;
    
}

@property (nonatomic, readonly, getter=getCount) UInt32 count;

-(void)addEntry:(NSString *)entry;
-(void)clear;
-(NSString *)getNthNewestEntry:(UInt32)n;  // zero-based

@end



// DebugPaneBackgroundDrawer ///////////////////////////////////////////////////////


@interface DebugPaneBackgroundDrawer : NSObject {
    
}

-initWithArgs:(id)args;
-(void)drawToRect:(CGRect)rect;

@end



// DebugPaneTextDrawerArgsStruct ///////////////////////////////////////////////////////

@interface DebugPaneTextDrawerArgs : NSObject {

}

@property (nonatomic, copy) NSString *fontName;
@property (nonatomic, assign) float fontSize;
@property (nonatomic, assign) int numTextColumns;
@property (nonatomic, assign) int numTextRows;

@end


// DebugPaneTextDrawer /////////////////////////////////////////////////////////////


@interface DebugPaneTextDrawer : NSObject {
    
    DebugPaneTextDrawerArgs         *m_args;
    DebugTextBuffer                 *m_buffer;

    size_t              m_trueWidth;
    size_t              m_trueHeight;
    size_t              m_paddedWidth;
    size_t              m_paddedHeight;
    GLubyte            *m_rawBitmapData;
    CGContextRef        m_cgContext;
    
    GLuint          m_texName;
    GLfloat         m_texCoords[8];

}

@property (nonatomic, readonly) float oneCharWidth;
@property (nonatomic, readonly) float oneCharHeight;

-(id)initWithTextBuffer:(DebugTextBuffer *)buffer args:(DebugPaneTextDrawerArgs *)args;
-(void)drawToRect:(CGRect)rect;

-(void)updateRaster;

@end



// DebugLogLayerView ///////////////////////////////////////////////////////////////


@interface DebugLogLayerView : LayerView {
    
    DebugPaneBackgroundDrawer       *m_backgroundDrawer;
    DebugPaneTextDrawer             *m_textDrawer;
    DebugTextBuffer                 *m_textBuffer;
    
    BOOL                            m_fullSize;
    
    CGRect                           m_fullSizeRect;
    CGRect                           m_minSizeRect;
    
    HitZone                         *m_hitZone;
   
    
}

+(DebugLogLayerView *)anyInstance;  // going to programmer hell

-(void)writeLine:(NSString *)str;
-(void)receivedTouchAt:(CGPoint)p;

@end

//#define DEBUG_LOG_LAYER_ACTIVE

// should we additionally NSLog everything when pane is active?
#define ECHO_TO_CONSOLE

// TODO: only in ship
// kind of weird that this causes a texture upload...

#ifdef DEBUG_LOG_LAYER_ACTIVE
#define DebugOut( s )  [[DebugLogLayerView anyInstance] writeLine:s]
#else
#define DebugOut( s ) NSLog( @"%@", s )
#endif


