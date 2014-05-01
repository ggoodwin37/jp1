//
//  EExtentView.h
//

#import <Foundation/Foundation.h>
#import "QuartzView.h"
#import "EWorldView.h"


/////////////////////////////////////////////////////////////////////////////////////////////////////////// EExtentView.h
@interface EExtentView : QuartzView<IPanZoomResultConsumer>

@property (nonatomic, assign) float currentZoomFactor;

@end
