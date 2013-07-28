//
//  LevelUtil.h
//  JumpProto
//
//  Created by Gideon Goodwin on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define LEVEL_EXTENSION @".jlevel"

// TODO remove manifest
#define LEVEL_MANIFEST_EXTENSION @".jlevelman"

/////////////////////////////////////////////////////////////////////////////////////////////////////////// LevelFileUtil
// a singleton that offers level-file utilities.

@interface LevelFileUtil : NSObject
{
    NSString *m_documentsDirectoryPath;
}

+(void)initGlobalInstance;
+(void)releaseGlobalInstance;
+(LevelFileUtil *)instance;

// TODO remove manifest
-(void)deleteAllManifestsOnDisk;

-(NSString *)getPathForLevelName:(NSString *)levelName;
-(void)deleteFileAtPath:(NSString *)path;
-(BOOL)doesFileExistAtPath:(NSString *)path;

// launcher UI calls this to populate main level picker
-(void)addAllLevelNamesTo:(NSMutableArray *)array;

@end
