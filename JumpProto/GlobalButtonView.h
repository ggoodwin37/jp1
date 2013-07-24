//
//  GlobalButtonView.h
//  JumpProto
//
//  Created by gideong on 7/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LayerView.h"
#import "GlobalCommand.h"


@interface GlobalButtonView : LayerView {
}

@property (nonatomic, assign) GlobalButtonManager *buttonManager;  // weak

@end
