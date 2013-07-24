//
//  EBlockPaletteViewController.h
//  JumpProto
//
//  Created by gideong on 10/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EBlockPreset.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////// EBPPresetEntry
@interface EBPPresetEntry : NSObject
{
}
@property (nonatomic, readonly) EBlockPreset preset;
@property (nonatomic, readonly) NSString *presetName;
@property (nonatomic, readonly) NSString *presetDescription;

-(id)initWithPreset:(EBlockPreset)preset name:(NSString *)name description:(NSString *)description;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// EBPPresetCategory
@interface EBPPresetCategory : NSObject
{
    NSMutableArray *m_presetList;
}
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly, getter = getPresetList) NSArray *presetList;

-(id)initWithName:(NSString *)name;
-(void)addPresetEntry:(EBPPresetEntry *)entry;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// EBlockPaletteViewController
@interface EBlockPaletteViewController : UIViewController<UITableViewDelegate, UITableViewDataSource,ICurrentBlockPresetStateConsumer> {
    
    NSArray *m_presetCategoryList;
    id<ICurrentBlockPresetStateHolder> m_blockPresetStateHolder;
    
}

@property (nonatomic, retain) IBOutlet UITableView *paletteTableView;

-(void)selectPreset:(EBlockPreset)preset;

@end
