//
//  ARISAppDelegate.h
//  ARIS
//
//  Created by Ben Longoria on 2/11/09.
//  Copyright University of Wisconsin 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "model/AppModel.h";

#import "LoginViewController.h";
#import "MyCLController.h"

#import "model/Game.h"

#import "NearbyObjectsViewController.h"

#import "Item.h"
#import "ItemDetailsViewController.h"
#import "QuestsViewController.h"
#import "GPSViewController.h"
#import "InventoryListViewController.h"
#import "CameraViewController.h"
#import "AudioRecorderViewController.h"
#import "ARViewViewControler.h"
#import "QRScannerViewController.h"
#import "GamePickerViewController.h"
#import "LogoutViewController.h"
#import "StartOverViewController.h"
#import "DeveloperViewController.h"
#import "WaitingIndicatorViewController.h"
#import "WaitingIndicatorView.h"
#import "AudioToolbox/AudioToolbox.h"
#import "Reachability.h"
#import "TutorialViewController.h"
#import <MessageUI/MFMailComposeViewController.h>



@interface ARISAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate, UINavigationControllerDelegate, MFMailComposeViewControllerDelegate> {
	AppModel *appModel;
	UIWindow *window;
    UITabBarController *tabBarController;
    TutorialViewController *tutorialViewController;

	UINavigationController *nearbyObjectsNavigationController;
	MyCLController *myCLController;
	LoginViewController *loginViewController;
	UINavigationController *loginViewNavigationController;
	GamePickerViewController *gamePickerViewController;
	UINavigationController *gamePickerNavigationController;
	UINavigationController *nearbyObjectNavigationController;
	WaitingIndicatorViewController *waitingIndicator;
	WaitingIndicatorView *waitingIndicatorView;
	
	UIAlertView *networkAlert;
	UIAlertView *serverAlert;
	TutorialPopupView *tutorialPopupView; 
	
	UIWindow* tvOutWindow;
	UIImageView *tvOutMirrorView;
	BOOL tvOutDone;
	
}

@property (nonatomic, retain) AppModel *appModel;
@property (nonatomic, retain) MyCLController *myCLController;
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;
@property (nonatomic, retain) IBOutlet TutorialViewController *tutorialViewController;

@property (nonatomic, retain) IBOutlet LoginViewController *loginViewController;
@property (nonatomic, retain) IBOutlet UINavigationController *loginViewNavigationController;
@property (nonatomic, retain) IBOutlet GamePickerViewController *gamePickerViewController;
@property (nonatomic, retain) IBOutlet UINavigationController *gamePickerNavigationController;
@property (nonatomic, retain) IBOutlet UINavigationController *nearbyObjectsNavigationController;

@property (nonatomic, retain) IBOutlet UINavigationController *nearbyObjectNavigationController;
@property (nonatomic, retain) WaitingIndicatorViewController *waitingIndicator;
@property (nonatomic, retain) WaitingIndicatorView *waitingIndicatorView;

@property (nonatomic, retain) UIAlertView *networkAlert;
@property (nonatomic, retain) UIAlertView *serverAlert;


- (void)attemptLoginWithUserName:(NSString *)userName andPassword:(NSString *)password;
- (void) displayNearbyObjectView:(UIViewController *)nearbyObjectsNavigationController;
- (void) showWaitingIndicator:(NSString *)message displayProgressBar:(BOOL)yesOrNo;
- (void) showNewWaitingIndicator:(NSString *)message displayProgressBar:(BOOL)displayProgressBar;
- (void) showServerAlertWithEmail:(NSString *)title message:(NSString *)message details:(NSString*)detail;
- (void) removeWaitingIndicator;
- (void) removeNewWaitingIndicator;
- (void) showNetworkAlert;
- (void) removeNetworkAlert;
- (void) showNearbyTab: (BOOL) yesOrNo;
- (void) returnToHomeView;
- (void) playAudioAlert:(NSString*)wavFileName shouldVibrate:(BOOL)shouldVibrate;
- (void) checkForDisplayCompleteNode;
- (void) displayIntroNode;

@end
