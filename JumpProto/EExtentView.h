//
//  EExtentView.h
//

#import <Foundation/Foundation.h>
#import "QuartzView.h"
#import "EWorldView.h"


/////////////////////////////////////////////////////////////////////////////////////////////////////////// EExtentView.h
@interface EExtentView : QuartzView
{
    CGSize m_worldSize;
    BOOL m_active;
}

-(void)setActive:(BOOL)active;

@property (nonatomic, assign, setter = setWorldViewSize:) CGSize worldViewSize;
@property (nonatomic, assign) CGSize viewportSize;
@property (nonatomic, getter = getActive, setter = setActive:) BOOL active;

@end
