//
//  EDocPropsViewController.h
//  JumpProto
//
//  Created by Gideon Goodwin on 1/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LevelUtil.h"
#import "EDoc.h"

@interface EDocPropsViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>
{
    NSMutableArray *m_manifestNameList;
}

@property (nonatomic, retain) IBOutlet UITextField *levelNameTextField;
@property (nonatomic, retain) IBOutlet UITextField *tagsTextField;

@property (nonatomic, retain) IBOutlet UIPickerView *packPickerView;

@property (nonatomic, retain) EGridDocument *doc;

@property (nonatomic, retain) NSString *selectedManifestName;


-(id)initWithNibName:(NSString *)nibNameIn bundle:(NSBundle *)bundleIn doc:(EGridDocument *)docIn initialLevelPackName:(NSString *)levelPackName;

-(void)updateValuesFromDoc;

@end
