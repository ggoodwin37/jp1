//
//  LevelUtil.h
//  JumpProto
//
//  Created by Gideon Goodwin on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define LEVEL_EXTENSION @".jlevel"

/////////////////////////////////////////////////////////////////////////////////////////////////////////// LevelFileUtil
// a singleton that offers level-file utilities.

@interface LevelFileUtil : NSObject
{
    NSString *m_documentsDirectoryPath;
}

+(void)initGlobalInstance;
+(void)releaseGlobalInstance;
+(LevelFileUtil *)instance;

-(NSString *)getPathForLevelName:(NSString *)levelName;
-(void)deleteFileAtPath:(NSString *)path;
-(BOOL)doesFileExistAtPath:(NSString *)path;

// launcher UI calls this to populate main level picker
-(void)addAllLevelNamesTo:(NSMutableArray *)array;

@end
