#import <UIKit/UIKit.h>
#import <Cephei/HBPreferences.h>

HBPreferences* preferences;

extern BOOL enabled;

BOOL isDejaVuActive = NO;

UIView* dejavuView;
UIImpactFeedbackGenerator* generator;
NSTimer* inactivityTimer;
NSTimer* pixelShiftTimer;
BOOL loadedTimeAndDateFrame = NO;
CGRect originalTimeAndDateFrame;

// behavior
BOOL onlyWhenChargingSwitch = NO;
BOOL disableWhileChargingSwitch = YES;
BOOL deactivateWithTapSwitch = YES;
BOOL deactivateWithRaiseToWakeSwitch = YES;
BOOL deactivateAfterInactivitySwitch = YES;
NSString* inactivityAmountValue = @"15";
BOOL enableHapticFeedbackSwitch = NO;
NSString* hapticFeedbackStrengthValue = @"0";
BOOL disableBiometricsSwitch = YES;
BOOL pocketDetectionSwitch = YES;
BOOL pixelShiftSwitch = YES;
BOOL enableLowPowerModeSwitch = YES;

// customization
BOOL hideStatusBarSwitch = YES;
BOOL hideFaceIDLockSwitch = YES;
BOOL hideTimeAndDateSwitch = NO;
BOOL hideQuickActionsSwitch = YES;
BOOL hideUnlockTextSwitch = YES;
BOOL hideHomebarSwitch = YES;

@interface CSCoverSheetViewController : UIViewController
@end

@interface SBLockScreenManager : NSObject
- (BOOL)isLockScreenVisible;
- (void)setBiometricAutoUnlockingDisabled:(BOOL)arg1 forReason:(id)arg2;
- (void)activateDejaVu;
- (void)deactivateDejaVu;
- (void)initiatePixelShift;
@end

@interface SBProximitySensorManager : NSObject
- (void)_enableProx;
- (void)_disableProx;
@end

@interface SpringBoard : UIApplication
- (void)_simulateHomeButtonPress;
- (void)_simulateLockButtonPress;
- (SBProximitySensorManager *)proximitySensorManager;
@end

@interface _CDBatterySaver : NSObject
+ (id)sharedInstance;
- (BOOL)setPowerMode:(long long)arg1 error:(id *)arg2;
@end

@interface SBUIController : NSObject
+ (id)sharedInstance;
- (BOOL)isOnAC;
@end

@interface SBDashBoardIdleTimerProvider : NSObject
- (void)addDisabledIdleTimerAssertionReason:(id)arg1;
- (void)removeDisabledIdleTimerAssertionReason:(id)arg1;
@end

@interface SBUIBiometricResource : NSObject
+ (id)sharedInstance;
- (void)noteScreenDidTurnOff;
- (void)noteScreenWillTurnOn;
@end

@interface _UIStatusBar : UIView
@end

@interface UIStatusBar_Modern : UIView
- (_UIStatusBar *)statusBar;
- (void)setVisibility:(NSNotification *)notification;
@end

@interface SBUIProudLockIconView : UIView
- (void)setVisibility:(NSNotification *)notification;
@end

@interface SBFLockScreenDateView : UIView
- (void)setVisibility:(NSNotification *)notification;
- (void)shift;
- (void)resetShift;
@end

@interface UICoverSheetButton : UIControl
@end

@interface CSQuickActionsButton : UICoverSheetButton
- (void)setVisibility:(NSNotification *)notification;
@end

@interface CSHomeAffordanceView : UIView
- (void)setVisibility:(NSNotification *)notification;
@end

@interface CSTeachableMomentsContainerView : UIView
- (void)setVisibility:(NSNotification *)notification;
@end