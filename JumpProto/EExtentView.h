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
}

@property (nonatomic, assign, setter = setWorldViewSize:) CGSize worldViewSize;
@property (nonatomic, assign) CGSize viewportSize;

@end
