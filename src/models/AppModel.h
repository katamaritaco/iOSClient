//
//  AppModel.h
//  ARIS
//
//  Created by Ben Longoria on 2/17/09.
//  Copyright 2009 University of Wisconsin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocation.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreData/CoreData.h>

#define _MODEL_ [AppModel sharedAppModel]
#define _MODEL_PLAYER_ [AppModel sharedAppModel].player
#define _MODEL_USERS_ [AppModel sharedAppModel].usersModel
#define _MODEL_GAMES_ [AppModel sharedAppModel].gamesModel
#define _MODEL_MEDIA_ [AppModel sharedAppModel].mediaModel
#define _MODEL_GAME_ [AppModel sharedAppModel].game
#define _MODEL_SCENES_ [AppModel sharedAppModel].game.scenesModel
#define _MODEL_GROUPS_ [AppModel sharedAppModel].game.groupsModel
#define _MODEL_PLAQUES_ [AppModel sharedAppModel].game.plaquesModel
#define _MODEL_ITEMS_ [AppModel sharedAppModel].game.itemsModel
#define _MODEL_DIALOGS_ [AppModel sharedAppModel].game.dialogsModel
#define _MODEL_WEB_PAGES_ [AppModel sharedAppModel].game.webPagesModel
#define _MODEL_NOTES_ [AppModel sharedAppModel].game.notesModel
#define _MODEL_TAGS_ [AppModel sharedAppModel].game.tagsModel
#define _MODEL_EVENTS_ [AppModel sharedAppModel].game.eventsModel
#define _MODEL_REQUIREMENTS_ [AppModel sharedAppModel].game.requirementsModel
#define _MODEL_TRIGGERS_ [AppModel sharedAppModel].game.triggersModel
#define _MODEL_FACTORIES_ [AppModel sharedAppModel].game.factoriesModel
#define _MODEL_OVERLAYS_ [AppModel sharedAppModel].game.overlaysModel
#define _MODEL_INSTANCES_ [AppModel sharedAppModel].game.instancesModel
#define _MODEL_PLAYER_INSTANCES_ [AppModel sharedAppModel].game.playerInstancesModel
#define _MODEL_GAME_INSTANCES_ [AppModel sharedAppModel].game.gameInstancesModel
#define _MODEL_GROUP_INSTANCES_ [AppModel sharedAppModel].game.groupInstancesModel
#define _MODEL_TABS_ [AppModel sharedAppModel].game.tabsModel
#define _MODEL_QUESTS_ [AppModel sharedAppModel].game.questsModel
#define _MODEL_LOGS_ [AppModel sharedAppModel].game.logsModel
#define _MODEL_DISPLAY_QUEUE_ [AppModel sharedAppModel].game.displayQueueModel

#import "UsersModel.h"
#import "GamesModel.h"
#import "MediaModel.h"
#import "ARISPusherHandler.h"

@class ARISServiceGraveyard;

@interface AppModel : NSObject
{
  NSString *serverURL;
  BOOL showPlayerOnMap;

  BOOL leave_game_enabled;
  BOOL auto_profile_enabled;
  BOOL hidePlayers;

  User *player;
  Game *game;
  UsersModel *usersModel;
  GamesModel *gamesModel;
  MediaModel *mediaModel;
  CLLocation *deviceLocation;

  //CORE Data
  NSManagedObjectContext *mediaManagedObjectContext;
  NSManagedObjectContext *requestsManagedObjectContext;
  NSPersistentStoreCoordinator *persistentStoreCoordinator;
  ARISServiceGraveyard *servicesGraveyard;
}

@property(nonatomic, strong) NSString *serverURL;
@property(nonatomic, assign) BOOL showPlayerOnMap;

@property(nonatomic, assign) long preferred_game_id;
@property(nonatomic, assign) BOOL leave_game_enabled;
@property(nonatomic, assign) BOOL auto_profile_enabled;
@property(nonatomic, assign) BOOL hidePlayers;

@property(nonatomic, strong) User *player;
@property(nonatomic, strong) Game *game;
@property(nonatomic, strong) UsersModel *usersModel;
@property(nonatomic, strong) GamesModel *gamesModel;
@property(nonatomic, strong) MediaModel *mediaModel;
@property(nonatomic, strong) CLLocation *deviceLocation;

  //CORE Data
@property(nonatomic, strong) NSManagedObjectContext *mediaManagedObjectContext;
@property(nonatomic, strong) NSManagedObjectContext *requestsManagedObjectContext;
@property(nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property(nonatomic, strong) ARISServiceGraveyard *servicesGraveyard;

+ (AppModel *) sharedAppModel;

- (void) attemptLogInWithUserName:(NSString *)user_name password:(NSString *)password;
- (void) attemptLogInWithUserID:(long)user_id authToken:(NSString *)auth_token;
- (void) createAccountWithUserName:(NSString *)user_name displayName:(NSString *)display_name groupName:(NSString *)group_name email:(NSString *)email password:(NSString *)password;
- (void) generateUserFromGroup:(NSString *)group_name;
- (void) resetPasswordForEmail:(NSString *)email;
- (void) changePasswordFrom:(NSString *)oldp to:(NSString *)newp;
- (void) updatePlayerName:(NSString *)display_name;
- (void) updatePlayerMedia:(Media *)media;
- (void) logInPlayer:(User *)user;
- (void) logOut;

- (void) chooseGame:(Game *)game;
- (void) downloadGame:(Game *)game;
- (void) beginGame;
- (void) leaveGame;

- (void) setPlayerLocation:(CLLocation *)newLocation;

- (void) commitCoreDataContexts;
- (NSString *) applicationDocumentsDirectory;

- (void) storeGame;
- (void) restoreGame;
- (void) restoreGameData;
- (void) restorePlayerData;

@end

