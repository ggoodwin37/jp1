//
//  WorldArchiveUtil.h
//  JumpProto
//
//  Created by gideong on 10/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "World.h"


@interface WorldArchiveUtil : NSObject {
    
}

+(void)loadWorld:(World *)world fromDiskForName:(NSString *)levelName;
+(void)saveToDisk:(World *)world;

@end
