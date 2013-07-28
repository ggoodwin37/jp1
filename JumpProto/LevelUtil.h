//
//  LevelUtil.h
//  JumpProto
//
//  Created by Gideon Goodwin on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define LEVEL_EXTENSION @".jlevel"
#define LEVEL_MANIFEST_EXTENSION @".jlevelman"

/////////////////////////////////////////////////////////////////////////////////////////////////////////// LevelManifest
// a serializable level manifest, which represents a group of levels on disk.

@interface LevelManifest : NSObject<NSCoding>
{
    NSMutableArray *m_levelNames;
    NSString *m_manifestName;
    
}

@property (nonatomic, readonly, getter=getName) NSString *name;

-(id)initWithName:(NSString *)name;

-(int)getLevelNameCount;
-(NSString *)getLevelName:(int)i;

-(BOOL)tryRemoveLevelName:(NSString *)levelName;
-(void)addLevelName:(NSString *)levelName;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// LevelFileUtil
// a singleton that offers level-file utilities.

@interface LevelFileUtil : NSObject
{
    NSString *m_documentsDirectoryPath;
    NSMutableArray *m_manifestList;
    NSMutableDictionary *m_levelToManifestMap;
}

+(void)initGlobalInstance;
+(void)releaseGlobalInstance;
+(LevelFileUtil *)instance;

-(void)refreshManifestView;
-(int)getManifestCount;
-(LevelManifest *)getManifest:(int)i;
-(LevelManifest *)getExistingManifestNamed:(NSString *)name;

-(void)addManifestWithName:(NSString *)name;
-(void)deleteManifestWithName:(NSString *)name alsoDeleteOwnedLevels:(BOOL)deleteLevels;
-(void)cleanUp;
-(void)collectStrayLevelsToManifestNamed:(NSString *)name;
-(void)deleteAllManifestsOnDisk;

-(NSString *)getPathForLevelName:(NSString *)levelName;
-(NSString *)getPathForManifest:(LevelManifest *)manifest;
-(void)deleteFileAtPath:(NSString *)path;
-(BOOL)doesFileExistAtPath:(NSString *)path;

-(LevelManifest *)getOwningManifestForLevelName:(NSString *)levelName;
-(void)removeLevelName:(NSString *)levelName fromManifest:(LevelManifest *)manifest;
-(void)addLevelName:(NSString *)levelName toManifest:(LevelManifest *)manifest;

-(void)writeManifest:(LevelManifest *)manifest;

// launcher UI calls these to populate pickers
-(void)addManifestNamesTo:(NSMutableArray *)array;
-(void)addLevelNamesForManifestName:(NSString *)manifestName to:(NSMutableArray *)array;


// TODO: API for importing and exporting manifests via email. should be able to import from bundle too.

@end
