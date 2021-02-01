#import "DéjàVu.h"

// display dim

BOOL enabled;

%group DejaVu

%hook CSCoverSheetViewController

- (void)viewDidLoad { // add deja vu view

	%orig;

	isDejaVuActive = NO;

	if (!dejavuView) {
		dejavuView = [[UIView alloc] initWithFrame:[[self view] bounds]];
		[dejavuView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
		[dejavuView setBackgroundColor:[UIColor blackColor]];
		[dejavuView setAlpha:1.0];
		[dejavuView setHidden:YES];
		if (![dejavuView isDescendantOfView:[self view]]) [[self view] insertSubview:dejavuView atIndex:0];
	}

}

- (void)viewWillDisappear:(BOOL)animated { // deactivate deja vu view when swiping up

	%orig;

	if ([dejavuView isHidden]) return;

	[[NSNotificationCenter defaultCenter] postNotificationName:@"dejavuDeactivate" object:nil];

}

%end

%hook SBLockScreenManager

- (id)init { // register notification observers

	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activateDejaVu) name:@"dejavuActivate" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deactivateDejaVu) name:@"dejavuDeactivate" object:nil];

	return %orig;

}

- (void)lockUIFromSource:(int)arg1 withOptions:(id)arg2 { // set deja vu active when screen turned off

	%orig;
	
	if (!disableWhileChargingSwitch || (disableWhileChargingSwitch && ![[%c(SBUIController) sharedInstance] isOnAC])) {
		isDejaVuActive = YES;

		if ([dejavuView isHidden] && !onlyWhenChargingSwitch)
			[self activateDejaVu];
		else if ([dejavuView isHidden] && onlyWhenChargingSwitch && [[%c(SBUIController) sharedInstance] isOnAC])
			[self activateDejaVu];
		else
			[self deactivateDejaVu];
	}

}

%new
- (void)activateDejaVu { // enable deja vu

	[dejavuView setAlpha:1.0];
	[dejavuView setHidden:NO];
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		SpringBoard* springboard = (SpringBoard *)[objc_getClass("SpringBoard") sharedApplication];
		[springboard _simulateHomeButtonPress];
		
		if (disableBiometricsSwitch) {
			[[%c(SBLockScreenManager) sharedInstance] setBiometricAutoUnlockingDisabled:YES forReason:@"love.litten.dejavu"];
			[[%c(SBUIBiometricResource) sharedInstance] noteScreenDidTurnOff];
		}

		if (enableLowPowerModeSwitch) [[%c(_CDBatterySaver) sharedInstance] setPowerMode:1 error:nil];

		[[springboard proximitySensorManager] _enableProx];

		[[NSNotificationCenter defaultCenter] postNotificationName:@"dejavuUpdateIdleTimer" object:nil];
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.02 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			[[NSNotificationCenter defaultCenter] postNotificationName:@"dejavuHideElements" object:nil];
		});
	});

	if (deactivateAfterInactivitySwitch && !inactivityTimer) inactivityTimer = [NSTimer scheduledTimerWithTimeInterval:([inactivityAmountValue intValue] * 60) target:self selector:@selector(deactivateDueToInactivity) userInfo:nil repeats:NO];
	if (pixelShiftSwitch && !pixelShiftTimer) pixelShiftTimer = [NSTimer scheduledTimerWithTimeInterval:180.0 target:self selector:@selector(initiatePixelShift) userInfo:nil repeats:YES];

}

%new
- (void)deactivateDejaVu { // disable deja vu

	isDejaVuActive = NO;

	[UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
		[dejavuView setAlpha:0.0];
	} completion:^(BOOL finished) {
		[dejavuView setHidden:YES];
	}];

	if (disableBiometricsSwitch) {
		[[%c(SBLockScreenManager) sharedInstance] setBiometricAutoUnlockingDisabled:NO forReason:@"love.litten.dejavu"];
		[[%c(SBUIBiometricResource) sharedInstance] noteScreenWillTurnOn];
	}

	if (enableLowPowerModeSwitch) [[%c(_CDBatterySaver) sharedInstance] setPowerMode:0 error:nil];

	SpringBoard* springboard = (SpringBoard *)[objc_getClass("SpringBoard") sharedApplication];
	[[springboard proximitySensorManager] _disableProx];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"dejavuUpdateIdleTimer" object:nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"dejavuUnhideElements" object:nil];

	if (enableHapticFeedbackSwitch) {
		if (!generator) {
			if ([hapticFeedbackStrengthValue intValue] == 0)
				generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
			else if ([hapticFeedbackStrengthValue intValue] == 1)
				generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
			else if ([hapticFeedbackStrengthValue intValue] == 2)
				generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
		}

		[generator prepare];
		[generator impactOccurred];
	}

	if (deactivateAfterInactivitySwitch) {
		[inactivityTimer invalidate];
		inactivityTimer = nil;
	}

	if (pixelShiftSwitch) {
		[pixelShiftTimer invalidate];
		pixelShiftTimer = nil;
		[[NSNotificationCenter defaultCenter] postNotificationName:@"dejavuResetShift" object:nil];
	}

}

%new
- (void)deactivateDueToInactivity { // deactivate when inactivity timer is up

	SpringBoard* springboard = (SpringBoard *)[objc_getClass("SpringBoard") sharedApplication];
	[springboard _simulateLockButtonPress];

	[inactivityTimer invalidate];
	inactivityTimer = nil;

}

%new
- (void)initiatePixelShift { // send pixel shift notification

	[[NSNotificationCenter defaultCenter] postNotificationName:@"dejavuPixelShift" object:nil];

}

%end

%hook SBProximitySensorManager

- (void)_disableProx { // prevent proximity sensor from disabling itself

	if (!isDejaVuActive || !pocketDetectionSwitch)
		%orig;
	else
		return;

}

%end

%hook NCNotificationListView

- (void)touchesBegan:(id)arg1 withEvent:(id)arg2 { // hide deja vu on tap

	%orig;

	if (!deactivateWithTapSwitch) return;
	if ([dejavuView isHidden]) return;

	[[NSNotificationCenter defaultCenter] postNotificationName:@"dejavuDeactivate" object:nil];

}

%end

%hook SBLiftToWakeController

- (void)wakeGestureManager:(id)arg1 didUpdateWakeGesture:(long long)arg2 orientation:(int)arg3 { // disable deja vu with raise to wake

	%orig;

	if (deactivateWithRaiseToWakeSwitch && isDejaVuActive) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[[NSNotificationCenter defaultCenter] postNotificationName:@"dejavuDeactivate" object:nil];
		});
	}

}

%end

%hook SBUIController

- (BOOL)isOnAC { // deactivate when charging

	BOOL isCharging = %orig;

	if (isCharging && disableWhileChargingSwitch)
		[[NSNotificationCenter defaultCenter] postNotificationName:@"dejavuDeactivate" object:nil];

	return isCharging;

}

%end

%hook SBDashBoardIdleTimerProvider

- (id)initWithDelegate:(id)arg1 { // add notification observer

	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateIdleTimer) name:@"dejavuUpdateIdleTimer" object:nil];

	return %orig;

}

%new
- (void)updateIdleTimer { // toggle idle timer

	if (isDejaVuActive)
		[self addDisabledIdleTimerAssertionReason:@"love.litten.dejavu"];
	else
		[self removeDisabledIdleTimerAssertionReason:@"love.litten.dejavu"];

}

%end

%hook SBReachabilityManager

- (BOOL)reachabilityEnabled { // disable reachability

	if (isDejaVuActive)
		return NO;
	else
		return %orig;

}

%end

%hook SBControlCenterController

- (BOOL)_shouldAllowControlCenterGesture { // disable control center

	if (isDejaVuActive)
		return NO;
	else
		return %orig;

}

%end

%hook SBMainDisplayPolicyAggregator

- (BOOL)_allowsCapabilityLockScreenCameraWithExplanation:(id *)arg1 { // disable camera swipe

    if (isDejaVuActive)
		return NO;
	else
		return %orig;

}

- (BOOL)_allowsCapabilityTodayViewWithExplanation:(id *)arg1 { // disable widgets swipe

	if (isDejaVuActive)
		return NO;
	else
		return %orig;

}

%end

%end

%group DejaVuPixelShiftAndVisibility

%hook UIStatusBar_Modern

- (void)setFrame:(CGRect)arg1 { // add notification observer

	if (hideStatusBarSwitch) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setVisibility:) name:@"dejavuHideElements" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setVisibility:) name:@"dejavuUnhideElements" object:nil];
	}

	return %orig;

}

%new
- (void)setVisibility:(NSNotification *)notification { // hide or unhide status bar

	if ([notification.name isEqual:@"dejavuHideElements"]) {
		[UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			[[self statusBar] setAlpha:0.0];
		} completion:nil];
	} else if ([notification.name isEqual:@"dejavuUnhideElements"]) {
		[UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			[[self statusBar] setAlpha:1.0];
		} completion:nil];
	}

}

%end

%hook SBUIProudLockIconView

- (id)initWithFrame:(CGRect)frame { // add notification observer

	if (hideFaceIDLockSwitch) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setVisibility:) name:@"dejavuHideElements" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setVisibility:) name:@"dejavuUnhideElements" object:nil];
	}

	return %orig;

}

%new
- (void)setVisibility:(NSNotification *)notification { // hide or unhide faceid lock

	if ([notification.name isEqual:@"dejavuHideElements"]) {
		[UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			[self setAlpha:0.0];
		} completion:nil];
	} else if ([notification.name isEqual:@"dejavuUnhideElements"]) {
		[UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			[self setAlpha:1.0];
		} completion:nil];
	}

}

%end

%hook SBFLockScreenDateView

- (id)initWithFrame:(CGRect)frame { // add notification observer

	if (hideTimeAndDateSwitch) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setVisibility:) name:@"dejavuHideElements" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setVisibility:) name:@"dejavuUnhideElements" object:nil];
	}

	if (pixelShiftSwitch && !hideTimeAndDateSwitch) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shift) name:@"dejavuPixelShift" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetShift) name:@"dejavuResetPixelShift" object:nil];
	}

	return %orig;

}

%new
- (void)setVisibility:(NSNotification *)notification { // hide or unhide time and date

	if ([notification.name isEqual:@"dejavuHideElements"]) {
		[UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			[self setAlpha:0.0];
		} completion:nil];
	} else if ([notification.name isEqual:@"dejavuUnhideElements"]) {
		[UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			[self setAlpha:1.0];
		} completion:nil];
	}

}

%new
- (void)shift { // slight movement

	if (!loadedTimeAndDateFrame) originalTimeAndDateFrame = [self frame];
	loadedTimeAndDateFrame = YES;

	int direction = arc4random_uniform(2);
	CGRect newFrame = originalTimeAndDateFrame;
	
	if (direction == 0)
		newFrame.origin.x += arc4random_uniform(10);
	else if (direction == 1)
		newFrame.origin.y += arc4random_uniform(10);

	[self setFrame:newFrame];
	
}

%new
- (void)resetShift { // reset frame

	[self setFrame:originalTimeAndDateFrame];

}

%end

%hook CSQuickActionsButton

- (id)initWithFrame:(CGRect)frame { // add notification observer

	if (hideQuickActionsSwitch) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setVisibility:) name:@"dejavuHideElements" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setVisibility:) name:@"dejavuUnhideElements" object:nil];
	}

	return %orig;

}

%new
- (void)setVisibility:(NSNotification *)notification { // hide or unhide quick actions

	if ([notification.name isEqual:@"dejavuHideElements"]) {
		[UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			[self setAlpha:0.0];
		} completion:nil];
	} else if ([notification.name isEqual:@"dejavuUnhideElements"]) {
		[UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			[self setAlpha:1.0];
		} completion:nil];
	}

}

%end

%hook CSTeachableMomentsContainerView

- (id)initWithFrame:(CGRect)frame { // add notification observer

	if (hideUnlockTextSwitch) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setVisibility:) name:@"dejavuHideElements" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setVisibility:) name:@"dejavuUnhideElements" object:nil];
	}

	return %orig;

}

%new
- (void)setVisibility:(NSNotification *)notification { // hide or unhide unlock label and control center indicator

	if ([notification.name isEqual:@"dejavuHideElements"]) {
		[UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			[self setAlpha:0.0];
		} completion:nil];
	} else if ([notification.name isEqual:@"dejavuUnhideElements"]) {
		[UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			[self setAlpha:1.0];
		} completion:nil];
	}

}

%end

%hook CSHomeAffordanceView

- (id)initWithFrame:(CGRect)frame { // add notification observer

	if (hideHomebarSwitch) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setVisibility:) name:@"dejavuHideElements" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setVisibility:) name:@"dejavuUnhideElements" object:nil];
	}

	return %orig;

}

%new
- (void)setVisibility:(NSNotification *)notification { // hide or unhide homebar

	if ([notification.name isEqual:@"dejavuHideElements"]) {
		[UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			[self setAlpha:0.0];
		} completion:nil];
	} else if ([notification.name isEqual:@"dejavuUnhideElements"]) {
		[UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			[self setAlpha:1.0];
		} completion:nil];
	}

}

%end

%end

%ctor {

	preferences = [[HBPreferences alloc] initWithIdentifier:@"love.litten.déjàvupreferences"];

	[preferences registerBool:&enabled default:nil forKey:@"Enabled"];

	// behavior
	[preferences registerBool:&onlyWhenChargingSwitch default:NO forKey:@"onlyWhenCharging"];
	[preferences registerBool:&disableWhileChargingSwitch default:YES forKey:@"disableWhileCharging"];
	[preferences registerBool:&deactivateWithTapSwitch default:YES forKey:@"deactivateWithTap"];
	[preferences registerBool:&deactivateWithRaiseToWakeSwitch default:YES forKey:@"deactivateWithRaiseToWake"];
	[preferences registerBool:&deactivateAfterInactivitySwitch default:YES forKey:@"deactivateAfterInactivity"];
	[preferences registerObject:&inactivityAmountValue default:@"15" forKey:@"inactivityAmount"];
	[preferences registerBool:&enableHapticFeedbackSwitch default:NO forKey:@"enableHapticFeedback"];
	[preferences registerObject:&hapticFeedbackStrengthValue default:@"0" forKey:@"hapticFeedbackStrength"];
	[preferences registerBool:&disableBiometricsSwitch default:YES forKey:@"disableBiometrics"];
	[preferences registerBool:&pocketDetectionSwitch default:YES forKey:@"pocketDetection"];
	[preferences registerBool:&pixelShiftSwitch default:YES forKey:@"pixelShift"];
	[preferences registerBool:&enableLowPowerModeSwitch default:YES forKey:@"enableLowPowerMode"];

	// customization
	[preferences registerBool:&hideStatusBarSwitch default:YES forKey:@"hideStatusBar"];
	[preferences registerBool:&hideFaceIDLockSwitch default:YES forKey:@"hideFaceIDLock"];
	[preferences registerBool:&hideTimeAndDateSwitch default:NO forKey:@"hideTimeAndDate"];
	[preferences registerBool:&hideQuickActionsSwitch default:YES forKey:@"hideQuickActions"];
	[preferences registerBool:&hideUnlockTextSwitch default:YES forKey:@"hideUnlockText"];
	[preferences registerBool:&hideHomebarSwitch default:YES forKey:@"hideHomebar"];

	if (enabled) {
		%init(DejaVu);
		%init(DejaVuPixelShiftAndVisibility);
	}

}