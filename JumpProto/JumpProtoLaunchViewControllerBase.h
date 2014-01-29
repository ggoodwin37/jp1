#import <UIKit/UIKit.h>

#import "JumpProtoAppDelegate.h"
#import "DpadInput.h"
#import "IParentChildVC.h"

@interface JumpProtoLaunchViewControllerBase : UIViewController <IAppStartStop, IParentVC, UIPickerViewDataSource, UIPickerViewDelegate> {
    UIViewController<IChildVC> *m_childViewController;
    
    NSArray *m_levelPickerViewContents;
    int m_lastPickedLevelRow;
}

@property (nonatomic, retain) IBOutlet UIPickerView *levelPickerView;
@property (nonatomic, retain) IBOutlet UISwitch *deleteArmedSwitch;

@property (nonatomic, retain) IBOutlet UISwitch *loadFromDiskSwitch;

@property (nonatomic, retain) NSString *exitedLevelName;

@property (nonatomic, retain) DpadInput *dpadInput;

-(IBAction)onPlayButtonTouched:(id)sender;
-(IBAction)onEditButtonTouched:(id)sender;
-(IBAction)onDeleteButtonTouched:(id)sender;

-(void)onAppStart;
-(void)onAppStop;

@end
