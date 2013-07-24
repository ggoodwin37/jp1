//
//  LevelManifest.m
//  JumpProto
//
//  Created by Gideon Goodwin on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LevelManifest.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////// LevelManifest

@implementation LevelManifest

-(id)initWithName:(NSString *)name
{
    if( self = [super init] )
    {
        m_manifestName = [name retain];
        m_levelNames = [[NSMutableArray arrayWithCapacity:16] retain];
    }
    return self;
}


-(void)dealloc
{
    [m_manifestName release]; m_manifestName = nil;
    [m_levelNames release]; m_levelNames = nil;
    [super dealloc];
}


-(NSString *)getName
{
    return m_manifestName;
}


-(int)getLevelNameCount
{
    return [m_levelNames count];
}


-(NSString *)getLevelName:(int)i
{
    NSAssert( i < [self getLevelNameCount], @"Bad level index" );
    return (NSString *)[m_levelNames objectAtIndex:i];
}


-(BOOL)tryRemoveLevelName:(NSString *)levelName
{
    for( int i = 0; i < [self getLevelNameCount]; ++i )
    {
        if( [[self getLevelName:i] isEqualToString:levelName] )
        {
            [m_levelNames removeObjectAtIndex:i];
            return YES;
        }
    }
    return NO;
}


-(void)addLevelName:(NSString *)levelName
{
    [m_levelNames addObject:levelName];
}


-(id)initWithCoder:(NSCoder *)decoder
{
    if( self = [super init] )
    {
        m_manifestName =               [[decoder decodeObjectForKey:@"manifestName"] retain];
        NSArray *immutableLevelNames =  [decoder decodeObjectForKey:@"levelNames"];
        m_levelNames = [[NSMutableArray arrayWithArray:immutableLevelNames] retain];
    }
    return self;
}


-(void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:m_manifestName        forKey:@"manifestName"];
    NSArray *immutableLevelNames = [NSArray arrayWithArray:m_levelNames];
    [encoder encodeObject:immutableLevelNames   forKey:@"levelNames"];
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// LevelManifestManager

@implementation LevelManifestManager

-(id)init
{
    if( self = [super init] )
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES );
        m_documentsDirectoryPath = [[paths objectAtIndex:0] retain];
        
        m_manifestList = nil;
        m_levelToManifestMap = nil;

        // temp: cleanup junk levels/manifests that were created due to bugs or testing.
        //[self deleteAllLevelsOnDisk];
        //[self deleteAllManifestsOnDisk];
        
        [self refreshManifestView];

        [self collectStrayLevelsToManifestNamed:@"strayLevels"];
    }
    return self;
}


-(void)dealloc
{
    [m_manifestList release]; m_manifestList = nil;
    [m_levelToManifestMap release]; m_levelToManifestMap = nil;
    [m_documentsDirectoryPath release]; m_documentsDirectoryPath = nil;
    [super dealloc];
}


static LevelManifestManager *globalLevelManifestManagerInstance = nil;

+(void)initGlobalInstance
{
    NSAssert( globalLevelManifestManagerInstance == nil, @"initializing global LevelManifestManager more than once is BAD." );
    globalLevelManifestManagerInstance = [[LevelManifestManager alloc] init];
}


+(void)releaseGlobalInstance
{
    [globalLevelManifestManagerInstance release]; globalLevelManifestManagerInstance = nil;
}


+(LevelManifestManager *)instance
{
    return globalLevelManifestManagerInstance;
}


-(void)deleteAllFilesWithExtension:(NSString *)ext
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *allFiles = [fileManager contentsOfDirectoryAtPath:m_documentsDirectoryPath error:NULL];
    NSMutableArray *targetPathList = [NSMutableArray arrayWithCapacity:128];
    for( int i = 0; i < [allFiles count]; ++i )
    {
        NSString *thisPath = (NSString *)[allFiles objectAtIndex:i];
        if( [thisPath hasSuffix:ext] )
        {
            [targetPathList addObject:thisPath];
        }
    }
    
    NSLog( @"deleteAllFilesWithExtension: deleting %d files with extension %@.", [targetPathList count], ext );
    for( int i = 0; i < [targetPathList count]; ++i )
    {
        NSString *thisFilenameWithExtension = (NSString *)[targetPathList objectAtIndex:i];
        NSArray *pathComponents = [NSArray arrayWithObjects: m_documentsDirectoryPath, thisFilenameWithExtension, nil];
        NSString *thisPath = [[NSString pathWithComponents:pathComponents] stringByStandardizingPath];
        NSLog( @"deleteAllFilesWithExtension: deleting %@", thisPath );
        if( ![[NSFileManager defaultManager] removeItemAtPath:thisPath error:NULL] )
        {
            NSLog( @"deleteAllFilesWithExtension: !!failed to delete %@", thisPath );
        }
    }
}


-(void)deleteAllManifestsOnDisk
{
    [self deleteAllFilesWithExtension:LEVEL_MANIFEST_EXTENSION];
}


-(void)deleteAllLevelsOnDisk
{
    [self deleteAllFilesWithExtension:LEVEL_EXTENSION];
}


-(void)refreshManifestView
{
    [m_manifestList release];  // in case this existed already
    m_manifestList = [[NSMutableArray arrayWithCapacity:10] retain];
    
    [m_levelToManifestMap release]; // in case this existed already
    m_levelToManifestMap = [[NSMutableDictionary dictionaryWithCapacity:128] retain];
    
    NSMutableArray *levelPathList = [NSMutableArray arrayWithCapacity:128];
    NSMutableArray *manifestPathList = [NSMutableArray arrayWithCapacity:128];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *allFiles = [fileManager contentsOfDirectoryAtPath:m_documentsDirectoryPath error:NULL];
    for( int i = 0; i < [allFiles count]; ++i )
    {
        NSString *thisPath = (NSString *)[allFiles objectAtIndex:i];
        if( [thisPath hasSuffix:LEVEL_EXTENSION] )
        {
            [levelPathList addObject:thisPath];
        }
        if( [thisPath hasSuffix:LEVEL_MANIFEST_EXTENSION] )
        {
            [manifestPathList addObject:thisPath];
        }
    }
    
    // deserialize all manifests
    for( int i = 0; i < [manifestPathList count]; ++i )
    {
        NSString *thisManifestFilenameWithExtension = (NSString *)[manifestPathList objectAtIndex:i];
        NSArray *pathComponents = [NSArray arrayWithObjects: m_documentsDirectoryPath, thisManifestFilenameWithExtension, nil];
        NSString *thisManifestPath = [[NSString pathWithComponents:pathComponents] stringByStandardizingPath];
        
        NSDictionary *rootObject = [NSKeyedUnarchiver unarchiveObjectWithFile:thisManifestPath];
        if( rootObject == nil )
        {
            NSAssert( NO, @"bad manifest from path %@", thisManifestPath );
            continue;
        }
        LevelManifest *thisManifest = (LevelManifest *)[rootObject valueForKey:@"levelManifest"];
        NSAssert( [self getExistingManifestNamed:thisManifest.name] == nil, @"duplicate manifests?" );
        [m_manifestList addObject:thisManifest];
        NSLog( @"refreshManifestView: loaded manifest %@ which owns %d levels.", thisManifestPath, [thisManifest getLevelNameCount] );
        
        // add levels in this manifest to the reverse map
        for( int j = 0; j < [thisManifest getLevelNameCount]; ++j )
        {
            NSString *thisLevelName = [thisManifest getLevelName:j];
            if( [m_levelToManifestMap valueForKey:thisLevelName] != nil )
            {
                NSLog( @"level named %@ exists in more than one manifest?", thisLevelName );
                continue;
            }
            [m_levelToManifestMap setValue:thisManifest forKey:thisLevelName];
        }
    }
}


-(int)getManifestCount
{
    return [m_manifestList count];
}


-(LevelManifest *)getManifest:(int)i
{
    NSAssert( i < [self getManifestCount], @"bad manifest index" );
    return (LevelManifest *)[m_manifestList objectAtIndex:i];
}


-(LevelManifest *)getExistingManifestNamed:(NSString *)name
{
    for( int i = 0; i < [self getManifestCount]; ++i )
    {
        LevelManifest *thisManifest = [self getManifest:i];
        
        if( [thisManifest.name isEqualToString:name] )
        {
            return thisManifest;
        }
    }
    return nil;
}


-(void)addManifestWithName:(NSString *)name
{
    if( [self getExistingManifestNamed:name] != nil )
    {
        NSLog( @"tried to add a duplicate manifest with name %@, ignoring.", name );
        return;
    }
    
    LevelManifest *newManifest = [[[LevelManifest alloc] initWithName:name] autorelease];
    [m_manifestList addObject:newManifest];
    
    [self cleanUp];
    [self writeManifest:newManifest];
    [self refreshManifestView];
}


-(NSString *)getPathForLevelName:(NSString *)levelName
{
    NSString *filenameWithExtension = [NSString stringWithFormat:@"%@%@", levelName, LEVEL_EXTENSION];
    NSArray *pathComponents = [NSArray arrayWithObjects: m_documentsDirectoryPath, filenameWithExtension, nil];
    return [[NSString pathWithComponents:pathComponents] stringByStandardizingPath];
}


-(NSString *)getPathForManifest:(LevelManifest *)manifest
{
    NSString *filenameWithExtension = [NSString stringWithFormat:@"%@%@", manifest.name, LEVEL_MANIFEST_EXTENSION];
    NSArray *pathComponents = [NSArray arrayWithObjects: m_documentsDirectoryPath, filenameWithExtension, nil];
    return [[NSString pathWithComponents:pathComponents] stringByStandardizingPath];
}


-(void)deleteFileAtPath:(NSString *)path
{
    if( ![[NSFileManager defaultManager] removeItemAtPath:path error:NULL] )
    {
        NSLog( @"deleteFileAtPath %@ failed!", path );
    }
}


-(BOOL)doesFileExistAtPath:(NSString *)path
{
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}


-(void)deleteManifestWithName:(NSString *)name alsoDeleteOwnedLevels:(BOOL)deleteLevels
{
    LevelManifest *targetManifest = nil;
    for( int i = 0; i < [self getManifestCount]; ++i )
    {
        if( [[self getManifest:i].name isEqualToString:name] )
        {
            targetManifest = [self getManifest:i];
            break;
        }
    }
    if( targetManifest == nil )
    {
        NSLog( @"couldn't find manifest with name %@ for deletion.", name );
        return;
    }
    
    if( deleteLevels )
    {
        for( int i = 0; i < [targetManifest getLevelNameCount]; ++i )
        {
            NSString *thisLevelName = [targetManifest getLevelName:i];
            [self deleteFileAtPath:[self getPathForLevelName:thisLevelName]];
        }
    }
    
    NSString *thisPath = [self getPathForManifest:targetManifest];
    [self deleteFileAtPath:thisPath];

    [self refreshManifestView];
}


-(void)cleanUp
{
    NSMutableDictionary *ownedLevelMap = [NSMutableDictionary dictionaryWithCapacity:128];
    
    for( int i = 0; i < [self getManifestCount]; ++i )
    {
        LevelManifest *thisManifest = [self getManifest:i];
        for( int j = [thisManifest getLevelNameCount] - 1; j >= 0; --j )  // go backwards since these can be removed.
        {
            NSString *thisLevelName = [thisManifest getLevelName:j];
            if( [ownedLevelMap valueForKey:thisLevelName] == nil )
            {
                // verify that thisLevelName corresponds to an actual file on disk.
                if( [self doesFileExistAtPath:[self getPathForLevelName:thisLevelName]] )
                {
                    [ownedLevelMap setValue:thisManifest forKey:thisLevelName];
                }
                else
                {
                    [thisManifest tryRemoveLevelName:thisLevelName];
                    NSLog( @"removed stale levelName %@ from manifest %@.", thisLevelName, thisManifest.name );
                }
            }
            else
            {
                NSLog( @"level named %@ was owned by more than one manifest.", thisLevelName );
                [thisManifest tryRemoveLevelName:thisLevelName];
            }
        }
    }
}


// helper to get levels into manifests for the first time.
-(void)collectStrayLevelsToManifestNamed:(NSString *)name
{
    NSMutableArray *levelPathList = [NSMutableArray arrayWithCapacity:128];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *allFiles = [fileManager contentsOfDirectoryAtPath:m_documentsDirectoryPath error:NULL];
    for( int i = 0; i < [allFiles count]; ++i )
    {
        NSString *thisPath = (NSString *)[allFiles objectAtIndex:i];
        if( [thisPath hasSuffix:LEVEL_EXTENSION] )
        {
            [levelPathList addObject:thisPath];
        }
    }
    
    BOOL fNeedSave = NO;
    
    LevelManifest *targetManifest = [self getExistingManifestNamed:name];
    if( targetManifest == nil )
    {
        targetManifest = [[[LevelManifest alloc] initWithName:name] autorelease];
        [m_manifestList addObject:targetManifest];  // may remain empty though if no strays
        NSLog( @"collectStrayLevelsToManifestNamed: created new manifest with name %@", name );
    }
    else
    {
        NSLog( @"collectStrayLevelsToManifestNamed: using existing manifest with name %@", name );
    }
    
    for( int i = 0; i < [levelPathList count]; ++i )
    {
        NSString *thisPath = (NSString *)[levelPathList objectAtIndex:i];
        NSString *thisName = [[thisPath lastPathComponent] stringByDeletingPathExtension];
        if( [m_levelToManifestMap valueForKey:thisName] == nil )
        {
            [targetManifest addLevelName:thisName];
            [m_levelToManifestMap setValue:targetManifest forKey:thisName];
            fNeedSave = YES;
            NSLog( @"collectStrayLevelsToManifestNamed: stray level named %@", thisName );
        }
    }
    
    if( [targetManifest getLevelNameCount] > 0 )
    {
        NSLog( @"assigned %d stray levels to manifest named %@.", [targetManifest getLevelNameCount], name );
        
        [self cleanUp];
        if( fNeedSave )
        {
            [self writeManifest:targetManifest];
        }
    }
    else
    {
        NSLog( @"didn't find any stray levels to collect." );
    }
}


-(LevelManifest *)getOwningManifestForLevelName:(NSString *)levelName
{
    return (LevelManifest *)[m_levelToManifestMap valueForKey:levelName];
}


-(void)removeLevelName:(NSString *)levelName fromManifest:(LevelManifest *)manifest
{
    LevelManifest *tempMan = [self getOwningManifestForLevelName:levelName];
    NSAssert( tempMan == manifest, @"removeLevelName:fromManifest: mismatch." );
    BOOL result = [manifest tryRemoveLevelName:levelName];
    if( result == NO )
    {
        NSLog( @"removeLevelName: level %@ not in manifest %@?", levelName, manifest.name );
    }

    [m_levelToManifestMap removeObjectForKey:levelName];
}


-(void)addLevelName:(NSString *)levelName toManifest:(LevelManifest *)manifest
{
    [manifest addLevelName:levelName];
    [m_levelToManifestMap setValue:manifest forKey:levelName];
}


-(void)writeManifest:(LevelManifest *)manifest
{
    NSMutableDictionary *rootObject = [NSMutableDictionary dictionary];
    [rootObject setValue:manifest forKey:@"levelManifest"];
    NSString *pathForManifest = [self getPathForManifest:manifest];
    [NSKeyedArchiver archiveRootObject:rootObject toFile:pathForManifest];
    NSLog( @"writeManifest: writing %@", pathForManifest );
}


-(void)addManifestNamesTo:(NSMutableArray *)array
{
    for( int i = 0; i < [self getManifestCount]; ++i )
    {
        [array addObject:[self getManifest:i].name];
    }
}


-(void)addLevelNamesForManifestName:(NSString *)manifestName to:(NSMutableArray *)array
{
    LevelManifest *targetManifest = nil;
    for( int i = 0; i < [self getManifestCount]; ++i )
    {
        if( [[self getManifest:i].name isEqualToString:manifestName] )
        {
            targetManifest = [self getManifest:i];
            break;
        }
    }
    if( targetManifest == nil )
    {
        NSLog( @"addLevelNamesForManifestName: couldn't find manifest with name %@.", manifestName );
        return;
    }
    
    for( int i = 0; i < [targetManifest getLevelNameCount]; ++i )
    {
        [array addObject:[targetManifest getLevelName:i]];
    }
}

@end
