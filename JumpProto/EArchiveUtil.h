//
//  EArchiveUtil.h
//  JumpProto
//
//  Created by gideong on 10/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EDoc.h"

@interface EArchiveUtil : NSObject {
    
}

+(void)loadDoc:(EGridDocument *)doc fromDiskForName:(NSString *)levelName;
+(void)saveToDisk:(EGridDocument *)doc;

@end
