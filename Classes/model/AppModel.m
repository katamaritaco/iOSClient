//
//  AppModel.m
//  ARIS
//
//  Created by Ben Longoria on 2/17/09.
//  Copyright 2009 University of Wisconsin. All rights reserved.
//

#import "AppModel.h"
#import "ARISAppDelegate.h"
#import "Media.h"
#import "NodeOption.h"
#import "Quest.h"
#import "JSONConnection.h"
#import "JSONResult.h"
#import "JSON.h"
#import "ASIFormDataRequest.h"

static NSString *const nearbyLock = @"nearbyLock";
static NSString *const locationsLock = @"locationsLock";
static const int kDefaultCapacity = 10;
static const int kEmptyValue = -1;

@interface AppModel()

- (NSInteger) validIntForKey:(NSString *const)aKey inDictionary:(NSDictionary *const)aDictionary;
- (id) validObjectForKey:(NSString *const)aKey inDictionary:(NSDictionary *const)aDictionary;

@end


@implementation AppModel
@synthesize serverURL;
@synthesize loggedIn, username, password, playerId, currentModule;
@synthesize currentGame, gameList, locationList, playerList;
@synthesize playerLocation, inventory, questList, networkAlert;
@synthesize gameMediaList, gameItemList, gameNodeList, gameNpcList;
@synthesize locationListHash, questListHash, inventoryHash;

@synthesize nearbyLocationsList;
@synthesize hasSeenNearbyTabTutorial,hasSeenQuestsTabTutorial,hasSeenMapTabTutorial,hasSeenInventoryTabTutorial;
@synthesize currentlyFetchingLocationList, currentlyFetchingInventory, currentlyFetchingQuestList, currentlyUpdatingServerWithPlayerLocation;
@synthesize currentlyUpdatingServerWithMapViewed, currentlyUpdatingServerWithQuestsViewed, currentlyUpdatingServerWithInventoryViewed;

#pragma mark Init/dealloc
-(id)init {
    self = [super init];
    if (self) {
		//Init USerDefaults
		defaults = [NSUserDefaults standardUserDefaults];
		gameMediaList = [[NSMutableDictionary alloc] initWithCapacity:kDefaultCapacity];
	}
			 
    return self;
}

- (void)dealloc {
	[gameMediaList release];
	[gameList release];
	[serverURL release];
	[username release];
	[password release];
	[currentModule release];
    [super dealloc];
}

-(void)loadUserDefaults {
	NSLog(@"Model: Loading User Defaults");
	[defaults synchronize];
	
	//Load the base App URL
	NSString *baseServerString = [defaults stringForKey:@"baseServerString"];
	self.serverURL = [NSURL URLWithString: baseServerString ];
	
	if ([defaults integerForKey:@"gameId"] > 0) {
		self.currentGame = [[Game alloc]init];
		self.currentGame.gameId = [defaults integerForKey:@"gameId"];
		self.currentGame.pcMediaId = [defaults integerForKey:@"gamePcMediaId"];
	}
		
	if ([defaults boolForKey:@"resetTutorial"]) {
		self.hasSeenNearbyTabTutorial = NO;
		self.hasSeenQuestsTabTutorial = NO;
		self.hasSeenMapTabTutorial = NO;
		self.hasSeenInventoryTabTutorial = NO;
		[defaults setBool:hasSeenNearbyTabTutorial forKey:@"hasSeenNearbyTabTutorial"];
		[defaults setBool:hasSeenQuestsTabTutorial forKey:@"hasSeenQuestsTabTutorial"];
		[defaults setBool:hasSeenMapTabTutorial forKey:@"hasSeenMapTabTutorial"];
		[defaults setBool:hasSeenInventoryTabTutorial forKey:@"hasSeenInventoryTabTutorial"];
		[defaults setBool:NO forKey:@"resetTutorial"];

	}
	else {
		self.hasSeenNearbyTabTutorial = [defaults boolForKey:@"hasSeenNearbyTabTutorial"];
		self.hasSeenQuestsTabTutorial = [defaults boolForKey:@"hasSeenQuestsTabTutorial"];
		self.hasSeenMapTabTutorial = [defaults boolForKey:@"hasSeenMapTabTutorial"];
		self.hasSeenInventoryTabTutorial = [defaults boolForKey:@"hasSeenInventoryTabTutorial"];
	}

	self.loggedIn = [defaults boolForKey:@"loggedIn"];
	if (loggedIn) {
		self.username = [defaults stringForKey:@"username"];
		self.password = [defaults stringForKey:@"password"];
		self.playerId = [defaults integerForKey:@"playerId"];
		NSLog(@"Model: Player Was logged in and defaults were found. Use URL: '%@' User: '%@' Password: '%@' PlayerId: '%d' GameId: '%d'", 
			  serverURL, username, password, playerId, self.currentGame.gameId);
	}
	
	NSURL *lastServerURL = [NSURL URLWithString:[defaults objectForKey:@"lastServerString"]];
	NSLog(@"AppModel: Last Base Server URL:%@ Current:%@",lastServerURL,self.serverURL);
	if (![[self.serverURL absoluteString] isEqualToString:[lastServerURL absoluteString]]) {
		NSLog(@"Model: Server URL changed since last execution. Throw out Defaults and use server URL:%@", serverURL);
		
		[defaults setObject:[self.serverURL absoluteString]  forKey:@"lastServerString"];
		[defaults synchronize];		
		
		NSNotification *loginNotification = [NSNotification notificationWithName:@"LogoutRequested" object:self userInfo:nil];
		[[NSNotificationCenter defaultCenter] postNotification:loginNotification];

	}
	
}


-(void)clearUserDefaults {
	NSLog(@"Model: Clearing User Defaults");
	
	[defaults removeObjectForKey:@"loggedIn"];	
	[defaults removeObjectForKey:@"username"];
	[defaults removeObjectForKey:@"password"];
	[defaults removeObjectForKey:@"playerId"];
	[defaults removeObjectForKey:@"gameId"];
	[defaults removeObjectForKey:@"gamePcMediaId"];
	
	[defaults synchronize];		
	//Don't clear the baseAppURL
}

-(void)saveUserDefaults {
	NSLog(@"Model: Saving User Defaults");
	
	[defaults setBool:loggedIn forKey:@"loggedIn"];
	[defaults setObject:username forKey:@"username"];
	[defaults setObject:password forKey:@"password"];
	[defaults setInteger:playerId forKey:@"playerId"];
	[defaults setInteger:self.currentGame.pcMediaId forKey:@"gamePcMediaId"];
	[defaults setInteger:self.currentGame.gameId forKey:@"gameId"];
	[defaults setObject:[serverURL absoluteString]  forKey:@"lastServerString"];
	[defaults setObject:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] forKey:@"appVerison"];
	[defaults setObject:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBuildNumber"] forKey:@"buildNum"];

	[defaults setBool:hasSeenNearbyTabTutorial forKey:@"hasSeenNearbyTabTutorial"];
	[defaults setBool:hasSeenQuestsTabTutorial forKey:@"hasSeenQuestsTabTutorial"];
	[defaults setBool:hasSeenMapTabTutorial forKey:@"hasSeenMapTabTutorial"];
	[defaults setBool:hasSeenInventoryTabTutorial forKey:@"hasSeenInventoryTabTutorial"];


}

-(void)initUserDefaults {	
	
	//Load the settings bundle data into an array
	NSString *pathStr = [[NSBundle mainBundle] bundlePath];
	NSString *settingsBundlePath = [pathStr stringByAppendingPathComponent:@"Settings.bundle"];
	NSString *finalPath = [settingsBundlePath stringByAppendingPathComponent:@"Root.plist"];
	NSDictionary *settingsDict = [NSDictionary dictionaryWithContentsOfFile:finalPath];
	NSArray *prefSpecifierArray = [settingsDict objectForKey:@"PreferenceSpecifiers"];
	
	//Find the Defaults
	NSString *baseAppURLDefault = [NSString stringWithString:@"Unknown Default"];
	NSDictionary *prefItem;
	for (prefItem in prefSpecifierArray)
	{
		NSString *keyValueStr = [prefItem objectForKey:@"Key"];
		id defaultValue = [prefItem objectForKey:@"DefaultValue"];
		
		if ([keyValueStr isEqualToString:@"baseServerString"])
		{
			baseAppURLDefault = defaultValue;
		}
		//More defaults would go here
	}
	
	// since no default values have been set (i.e. no preferences file created), create it here
	NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys: 
								 baseAppURLDefault,  @"baseServerString", 
								 nil];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark Seters/Geters

- (void)setPlayerLocation:(CLLocation *) newLocation{
	NSLog(@"AppModel: setPlayerLocation");
	
	playerLocation = newLocation;
	[playerLocation retain];
	
	//Tell the model to update the server and fetch any nearby locations
	[self updateServerWithPlayerLocation];	
	
	//Tell the other parts of the client
	NSNotification *updatedLocationNotification = [NSNotification notificationWithName:@"PlayerMoved" object:nil];
	[[NSNotificationCenter defaultCenter] postNotification:updatedLocationNotification];
}

#pragma mark Communication with Server
- (void)login {
	NSLog(@"AppModel: Login Requested");
	NSArray *arguments = [NSArray arrayWithObjects:self.username, self.password, nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc] initWithServer:self.serverURL 
																	andServiceName: @"players" 
																	andMethodName:@"loginPlayer"
																	andArguments:arguments]; 

	[jsonConnection performAsynchronousRequestWithParser:@selector(parseLoginResponseFromJSON:)]; 
	[jsonConnection release];
	
}

- (void)registerNewUser:(NSString*)userName password:(NSString*)pass 
			  firstName:(NSString*)firstName lastName:(NSString*)lastName email:(NSString*)email {
	NSLog(@"AppModel: New User Registration Requested");
	//createPlayer($strNewUserName, $strPassword, $strFirstName, $strLastName, $strEmail)
	NSArray *arguments = [NSArray arrayWithObjects:userName, pass, firstName, lastName, email, nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc] initWithServer:self.serverURL 
																	 andServiceName: @"players" 
																	  andMethodName:@"createPlayer"
																	   andArguments:arguments]; 
	
	[jsonConnection performAsynchronousRequestWithParser:@selector(parseSelfRegistrationResponseFromJSON:)]; 
	[jsonConnection release];
	
}

- (void)updateServerNodeViewed: (int)nodeId {
	NSLog(@"Model: Node %d Viewed, update server", nodeId);
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",self.currentGame.gameId],
						  [NSString stringWithFormat:@"%d",playerId],
						  [NSString stringWithFormat:@"%d",nodeId],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:self.serverURL 
																	andServiceName:@"players" 
																	 andMethodName:@"nodeViewed" 
																	  andArguments:arguments];
	[jsonConnection performAsynchronousRequestWithParser:@selector(fetchAllPlayerLists)]; 
	[jsonConnection release];
}

- (void)updateServerItemViewed: (int)itemId {
	NSLog(@"Model: Item %d Viewed, update server", itemId);
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
						  [NSString stringWithFormat:@"%d",self.currentGame.gameId],
						  [NSString stringWithFormat:@"%d",playerId],
						  [NSString stringWithFormat:@"%d",itemId],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:self.serverURL 
																	andServiceName:@"players" 
																	 andMethodName:@"itemViewed" 
																	  andArguments:arguments];
	[jsonConnection performAsynchronousRequestWithParser:@selector(fetchAllPlayerLists)]; 
	[jsonConnection release];

}

- (void)updateServerNpcViewed: (int)npcId {
	NSLog(@"Model: Npc %d Viewed, update server", npcId);
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",self.currentGame.gameId],
						  [NSString stringWithFormat:@"%d",playerId],
						  [NSString stringWithFormat:@"%d",npcId],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:self.serverURL 
																	andServiceName:@"players" 
																	 andMethodName:@"npcViewed" 
																	  andArguments:arguments];
	[jsonConnection performAsynchronousRequestWithParser:@selector(fetchAllPlayerLists)]; 
	[jsonConnection release];

}


- (void)updateServerGameSelected{
	NSLog(@"Model: Game %d Selected, update server", self.currentGame.gameId);
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects: 
						  [NSString stringWithFormat:@"%d",self.playerId],
						  [NSString stringWithFormat:@"%d",self.currentGame.gameId],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:self.serverURL 
																	andServiceName:@"players" 
																	 andMethodName:@"updatePlayerLastGame" 
																	  andArguments:arguments];
	[jsonConnection performAsynchronousRequestWithParser:nil]; 
	[jsonConnection release];

}

- (void)updateServerMapViewed{
	NSLog(@"Model: Map Viewed, update server");
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
						  [NSString stringWithFormat:@"%d",self.currentGame.gameId],
						  [NSString stringWithFormat:@"%d",playerId],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:self.serverURL 
																	andServiceName:@"players" 
																	 andMethodName:@"mapViewed" 
																	  andArguments:arguments];
	[jsonConnection performAsynchronousRequestWithParser:nil];
	[jsonConnection release];

}

- (void)updateServerQuestsViewed{
	NSLog(@"Model: Quests Viewed, update server");
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
						  [NSString stringWithFormat:@"%d",self.currentGame.gameId],
						  [NSString stringWithFormat:@"%d",playerId],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:self.serverURL 
																	andServiceName:@"players" 
																	 andMethodName:@"questsViewed" 
																	  andArguments:arguments];
	[jsonConnection performAsynchronousRequestWithParser:nil]; 
	[jsonConnection release];

}

- (void)updateServerInventoryViewed{
	NSLog(@"Model: Inventory Viewed, update server");
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
						  [NSString stringWithFormat:@"%d",self.currentGame.gameId],
						  [NSString stringWithFormat:@"%d",playerId],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:self.serverURL 
																	andServiceName:@"players" 
																	 andMethodName:@"inventoryViewed" 
																	  andArguments:arguments];
	[jsonConnection performAsynchronousRequestWithParser:nil]; 
	[jsonConnection release];

}

- (void)startOverGame{
	NSLog(@"Model: Start Over");
    ARISAppDelegate *appDelegate = (ARISAppDelegate *)[[UIApplication sharedApplication] delegate];
	
    [appDelegate displayIntroNode];
    
    [self resetAllPlayerLists];

    [self resetAllGameLists];

    [appDelegate.tutorialViewController dismissAllTutorials];
    

	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
						  [NSString stringWithFormat:@"%d",self.currentGame.gameId],
						  [NSString stringWithFormat:@"%d",playerId],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]
                                      initWithServer:self.serverURL
                                      andServiceName:@"players"
                                      andMethodName:@"startOverGameForPlayer"
                                      andArguments:arguments];
	[jsonConnection performAsynchronousRequestWithParser:
        @selector(parseStartOverFromJSON:)]; 
	[jsonConnection release];
}


- (void)updateServerPickupItem: (int)itemId fromLocation: (int)locationId qty:(int)qty{
	NSLog(@"Model: Informing the Server the player picked up item");
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",self.currentGame.gameId],
						  [NSString stringWithFormat:@"%d",playerId],
						  [NSString stringWithFormat:@"%d",itemId],
						  [NSString stringWithFormat:@"%d",locationId],
						  [NSString stringWithFormat:@"%d",qty],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:self.serverURL 
																	andServiceName:@"players" 
																	 andMethodName:@"pickupItemFromLocation" 
																	  andArguments:arguments];
	[jsonConnection performAsynchronousRequestWithParser:@selector(fetchAllPlayerLists)]; //This is a cheat to make sure that the fetch Happens After 
	[self forceUpdateOnNextLocationListFetch];
	[jsonConnection release];
	
}

- (void)updateServerDropItemHere: (int)itemId qty:(int)qty{
	NSLog(@"Model: Informing the Server the player dropped an item");
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",self.currentGame.gameId],
						  [NSString stringWithFormat:@"%d",playerId],
						  [NSString stringWithFormat:@"%d",itemId],
						  [NSString stringWithFormat:@"%f",playerLocation.coordinate.latitude],
						  [NSString stringWithFormat:@"%f",playerLocation.coordinate.longitude],
						  [NSString stringWithFormat:@"%d",qty],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:self.serverURL 
																	andServiceName:@"players" 
																	 andMethodName:@"dropItem" 
																	  andArguments:arguments];
	[jsonConnection performAsynchronousRequestWithParser:@selector(fetchAllPlayerLists)]; //This is a cheat to make sure that the fetch Happens After 
	[self forceUpdateOnNextLocationListFetch];
	[jsonConnection release];

}

- (void)updateServerDestroyItem: (int)itemId qty:(int)qty {
	NSLog(@"Model: Informing the Server the player destroyed an item");
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",self.currentGame.gameId],
						  [NSString stringWithFormat:@"%d",playerId],
						  [NSString stringWithFormat:@"%d",itemId],
						  [NSString stringWithFormat:@"%d",qty],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:self.serverURL 
																	andServiceName:@"players" 
																	 andMethodName:@"destroyItem" 
																	  andArguments:arguments];
	[jsonConnection performAsynchronousRequestWithParser:@selector(fetchAllPlayerLists)]; //This is a cheat to make sure that the fetch Happens After 
	[jsonConnection release];

}

- (void)createItemAndGiveToPlayerFromFileData:(NSData *)fileData fileName:(NSString *)fileName 
										title:(NSString *)title description:(NSString*)description {

	// setting up the request object now
	NSURL *url = [self.serverURL URLByAppendingPathComponent:@"services/aris/uploadHandler.php"];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	request.timeOutSeconds = 60;
	
 	[request setPostValue:[NSString stringWithFormat:@"%d", self.currentGame.gameId] forKey:@"gameID"];	 
	[request setPostValue:fileName forKey:@"fileName"];
	[request setData:fileData forKey:@"file"];
	[request setDidFinishSelector:@selector(uploadItemRequestFinished:)];
	[request setDidFailSelector:@selector(uploadItemRequestFailed:)];
	[request setDelegate:self];
	
	//We need these after the upload is complete to create the item on the server
	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:title, @"title", description, @"description", nil];
	[request setUserInfo:userInfo];
	
	NSLog(@"Model: Uploading File. gameID:%d fileName:%@ title:%@ description:%@",self.currentGame.gameId,fileName,title,description );
	
	ARISAppDelegate* appDelegate = (ARISAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate showWaitingIndicator:@"Uploading" displayProgressBar:YES];
	[request setUploadProgressDelegate:appDelegate.waitingIndicator.progressView];
	[request startAsynchronous];
}

- (void)uploadItemRequestFinished:(ASIFormDataRequest *)request
{
	ARISAppDelegate* appDelegate = (ARISAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate removeWaitingIndicator];
	
	NSString *response = [request responseString];

	NSLog(@"Model: Upload Media Request Finished. Response: %@", response);
	
	NSString *title = [[request userInfo] objectForKey:@"title"];
	NSString *description = [[request userInfo] objectForKey:@"description"];
	
	if (description == NULL) description = @""; 
	
	NSString *newFileName = [request responseString];

	NSLog(@"AppModel: Creating Item for Title:%@ Desc:%@ File:%@",title,description,newFileName);
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects:
						  [NSString stringWithFormat:@"%d",self.currentGame.gameId],
						  [NSString stringWithFormat:@"%d",self.playerId],
						  title, //[title stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
						  description, //[description stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
						  newFileName,
						  @"1", //dropable
						  @"1", //destroyable
						  [NSString stringWithFormat:@"%f",playerLocation.coordinate.latitude],
						  [NSString stringWithFormat:@"%f",playerLocation.coordinate.longitude],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:self.serverURL 
																	andServiceName:@"items" 
																	 andMethodName:@"createItemAndGiveToPlayer" 
																	  andArguments:arguments];
	[jsonConnection performAsynchronousRequestWithParser:@selector(fetchAllPlayerLists)]; 
	[jsonConnection release];

}

- (void)uploadItemRequestFailed:(ASIHTTPRequest *)request
{
	ARISAppDelegate* appDelegate = (ARISAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate removeWaitingIndicator];
	NSError *error = [request error];
	NSLog(@"Model: uploadItemRequestFailed: %@",[error localizedDescription]);
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Upload Failed" message: @"An network error occured while uploading the file" delegate: self cancelButtonTitle: @"Ok" otherButtonTitles: nil];
	
	[alert show];
	[alert release];
}



- (void)updateServerWithPlayerLocation {
	NSLog(@"Model: updating player position on server and determining nearby Locations");
	
	if (!loggedIn) {
		NSLog(@"Model: Player Not logged in yet, skip the location update");	
		return;
	}
	
	if (self.currentlyUpdatingServerWithPlayerLocation) {
        NSLog(@"AppModel: Currently Updating server with player location, skipping this update");
        return;
    }
    
    self.currentlyUpdatingServerWithPlayerLocation = YES;
    
	//Update the server with the new Player Location
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",self.playerId],
						  [NSString stringWithFormat:@"%f",self.currentGame.gameId],
						  [NSString stringWithFormat:@"%f",playerLocation.coordinate.latitude],
						  [NSString stringWithFormat:@"%f",playerLocation.coordinate.longitude],
						  nil];
	JSONConnection *jsonConnection = [[JSONConnection alloc] initWithServer:self.serverURL 
																	 andServiceName:@"players" 
																	  andMethodName:@"updatePlayerLocation" 
																	   andArguments:arguments];
	[jsonConnection performAsynchronousRequestWithParser:@selector(parseUpdateServerWithPlayerLocationFromJSON:)]; 
	[jsonConnection release];
	
}


- (void) silenceNextServerUpdate {
	NSLog(@"AppModel: silenceNextServerUpdate");
	
	NSNotification *notification = [NSNotification notificationWithName:@"SilentNextUpdate" object:nil];
	[[NSNotificationCenter defaultCenter] postNotification:notification];
}


#pragma mark Retrieving Cashed Objects 

-(void)modifyQuantity: (int)quantityModifier forLocationId: (int)locationId {
	NSLog(@"AppModel: modifying quantity for a location in the local location list");
	
	for (Location* loc in locationList) {
		if (loc.locationId == locationId && loc.kind == NearbyObjectItem) {
			loc.qty += quantityModifier;
			NSLog(@"AppModel: Quantity for %@ set to %d",loc.name,loc.qty);	
		}
	}	
	
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"NewLocationListReady" object:nil]];
	
}

-(void)removeItemFromInventory:(Item*)item qtyToRemove:(int)qty {
	NSLog(@"AppModel: removing an item from the local inventory");
	
	item.qty -=qty; 
	if (item.qty < 1) [self.inventory removeObjectForKey:[NSString stringWithFormat:@"%d",item.itemId]];

	NSNotification *notification = [NSNotification notificationWithName:@"NewInventoryReady" object:nil];
	[[NSNotificationCenter defaultCenter] postNotification:notification];
	 
}

-(void)addItemToInventory: (Item*)item {
	NSLog(@"AppModel: adding an item from the local inventory");

	[self.inventory setObject:item forKey:[NSString stringWithFormat:@"%d",item.itemId]];
	NSNotification *notification = [NSNotification notificationWithName:@"NewInventoryReady" object:nil];
	[[NSNotificationCenter defaultCenter] postNotification:notification];
}

-(Media *)mediaForMediaId: (int)mId {
	Media *media = [self.gameMediaList objectForKey:[NSNumber numberWithInt:mId]];
	
	if (!media) {
		//Let's pause everything and do a lookup
		NSLog(@"AppModel: Media not found in cached media List, refresh");
		[self fetchGameMediaListAsynchronously:NO];
		
		media = [self.gameMediaList objectForKey:[NSNumber numberWithInt:mId]];
		if (media) NSLog(@"AppModel: Media found after refresh");
		else NSLog(@"AppModel: Media still NOT found after refresh");
	}
	return media;
}

-(Npc *)npcForNpcId: (int)mId {
	NSLog(@"AppModel: Npc %d requested from cached list",mId);

	Npc *npc = [self.gameNpcList objectForKey:[NSNumber numberWithInt:mId]];
	
	if (!npc) {
		//Let's pause everything and do a lookup
		NSLog(@"AppModel: Npc not found in cached item list, refresh");
		[self fetchGameNpcListAsynchronously:NO];
		
		npc = [self.gameNpcList objectForKey:[NSNumber numberWithInt:mId]];
		if (npc) NSLog(@"AppModel: Npc found after refresh");
		else NSLog(@"AppModel: Npc still NOT found after refresh");
	}
	return npc;
}

-(Node *)nodeForNodeId: (int)mId {
	Node *node = [self.gameNodeList objectForKey:[NSNumber numberWithInt:mId]];
	
	if (!node) {
		//Let's pause everything and do a lookup
		NSLog(@"AppModel: Node not found in cached item list, refresh");
		[self fetchGameNodeListAsynchronously:NO];
		
		node = [self.gameNodeList objectForKey:[NSNumber numberWithInt:mId]];
		if (node) NSLog(@"AppModel: Node found after refresh");
		else NSLog(@"AppModel: Node still NOT found after refresh");
	}
	return node;
}

-(Item *)itemForItemId: (int)mId {
	Item *item = [self.gameItemList objectForKey:[NSNumber numberWithInt:mId]];
	
	if (!item) {
		//Let's pause everything and do a lookup
		NSLog(@"AppModel: Item not found in cached item list, refresh");
		[self fetchGameItemListAsynchronously:NO];
		
		item = [self.gameItemList objectForKey:[NSNumber numberWithInt:mId]];
		if (item) NSLog(@"AppModel: Item found after refresh");
		else NSLog(@"AppModel: Item still NOT found after refresh");
	}
	return item;
}



#pragma mark Sync Fetch selectors
- (id) fetchFromService:(NSString *)aService usingMethod:(NSString *)aMethod 
			   withArgs:(NSArray *)arguments usingParser:(SEL)aSelector 
{
	NSLog(@"JSON://%@/%@/%@", aService, aMethod, arguments);
	
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:self.serverURL 
																	andServiceName:aService
																	 andMethodName:aMethod
																	  andArguments:arguments];
	JSONResult *jsonResult = [jsonConnection performSynchronousRequest]; 
	[jsonConnection release];
	
	
	if (!jsonResult) {
		NSLog(@"\tFailed.");
		return nil;
	}
	
	return [self performSelector:aSelector withObject:jsonResult.data];
}


-(Item *)fetchItem:(int)itemId{
	NSLog(@"Model: Fetch Requested for Item %d", itemId);
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",self.currentGame.gameId],
						  [NSString stringWithFormat:@"%d",itemId],
						  nil];

	return [self fetchFromService:@"items" usingMethod:@"getItem" withArgs:arguments 
					  usingParser:@selector(parseItemFromDictionary:)];
}

-(Node *)fetchNode:(int)nodeId{
	NSLog(@"Model: Fetch Requested for Node %d", nodeId);
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",self.currentGame.gameId],
						  [NSString stringWithFormat:@"%d",nodeId],
						  nil];
	
	return [self fetchFromService:@"nodes" usingMethod:@"getNode" withArgs:arguments
					  usingParser:@selector(parseNodeFromDictionary:)];
}

-(Npc *)fetchNpc:(int)npcId{
	NSLog(@"Model: Fetch Requested for Npc %d", npcId);
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",self.currentGame.gameId],
						  [NSString stringWithFormat:@"%d",npcId],
						  [NSString stringWithFormat:@"%d",self.playerId],
						  nil];
	return [self fetchFromService:@"npcs" usingMethod:@"getNpcWithConversationsForPlayer"
						 withArgs:arguments usingParser:@selector(parseNpcFromDictionary:)];
}



#pragma mark ASync Fetch selectors

- (void)fetchAllGameLists {
	[self fetchGameItemListAsynchronously:YES];
	[self fetchGameNpcListAsynchronously:YES];
	[self fetchGameNodeListAsynchronously:YES];
	[self fetchGameMediaListAsynchronously:YES];
}

- (void)resetAllGameLists {
	NSLog(@"AppModel: resetAllGameLists");
    
	//Clear them out
	self.gameItemList = [[NSMutableDictionary alloc] 
                         initWithCapacity:0];
	self.gameNodeList = [[NSMutableDictionary alloc] 
                         initWithCapacity:0];
    self.gameNpcList = [[NSMutableDictionary alloc] 
                        initWithCapacity:0];

}

- (void)fetchAllPlayerLists{
	[self fetchLocationList];
	[self fetchQuestList];
	[self fetchInventory];	
}

- (void)resetAllPlayerLists {
	NSLog(@"AppModel: resetAllPlayerLists");

	//Clear the Hashes
	questListHash = @"";
	inventoryHash = @"";
	locationListHash = @"";

	//Clear them out
	self.locationList = [[NSMutableArray alloc] initWithCapacity:0];
	self.nearbyLocationsList = [[NSMutableArray alloc] initWithCapacity:0];

	NSMutableArray *completedQuestObjects = [[NSMutableArray alloc] init];
	NSMutableArray *activeQuestObjects = [[NSMutableArray alloc] init];
	NSMutableDictionary *tmpQuestList = [[NSMutableDictionary alloc] init];
	[tmpQuestList setObject:activeQuestObjects forKey:@"active"];
	[tmpQuestList setObject:completedQuestObjects forKey:@"completed"];
	[activeQuestObjects release];
	[completedQuestObjects release];
	self.questList = tmpQuestList;
	[tmpQuestList release];

	
	self.inventory = [[NSMutableDictionary alloc] initWithCapacity:10];
	
	//Tell the VCs
	[self silenceNextServerUpdate];

	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"NewLocationListReady" object:nil]];
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"NewQuestListReady" object:nil]];
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"NewInventoryReady" object:nil]];
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"ReceivedNearbyLocationList" object:nil]];

}


-(void)fetchQRCode:(NSString*)code{
	NSLog(@"Model: Fetch Requested for QRCode Code: %@", code);
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",self.currentGame.gameId],
						  [NSString stringWithFormat:@"%@",code],
						  [NSString stringWithFormat:@"%d",self.playerId],
						  nil];
	/*
	return [self fetchFromService:@"qrcodes" usingMethod:@"getQRCodeObjectForPlayer"
						 withArgs:arguments usingParser:@selector(parseQRCodeObjectFromDictionary:)];
	*/
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:self.serverURL 
																	andServiceName:@"qrcodes"
																	 andMethodName:@"getQRCodeObjectForPlayer"
																	  andArguments:arguments];
	[jsonConnection performAsynchronousRequestWithParser:@selector(parseQRCodeObjectFromJSON:)]; 
	[jsonConnection release];
	
}	

-(void)fetchNpcConversations:(int)npcId afterViewingNode:(int)nodeId{
	NSLog(@"Model: Fetch Requested for Npc %d Conversations after Viewing node %d", npcId, nodeId);
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",self.currentGame.gameId],
						  [NSString stringWithFormat:@"%d",npcId],
						  [NSString stringWithFormat:@"%d",self.playerId],
						  [NSString stringWithFormat:@"%d",nodeId],
						  nil];
	
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:self.serverURL 
																	andServiceName:@"npcs"
																	 andMethodName:@"getNpcConversationsForPlayerAfterViewingNode"
																	  andArguments:arguments];
	[jsonConnection performAsynchronousRequestWithParser:@selector(parseConversationNodeOptionsFromJSON:)]; 
	[jsonConnection release];

}


- (void)fetchGameNpcListAsynchronously:(BOOL)YesForAsyncOrNoForSync {
	NSLog(@"AppModel: Fetching Npc List");
	
	NSArray *arguments = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d",self.currentGame.gameId], nil];
	
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:self.serverURL 
																	andServiceName:@"npcs"
																	 andMethodName:@"getNpcs"
																	  andArguments:arguments];
	if (YesForAsyncOrNoForSync){
		[jsonConnection performAsynchronousRequestWithParser:@selector(parseGameNpcListFromJSON:)]; 
		[jsonConnection release];
	}
	else [self parseGameNpcListFromJSON: [jsonConnection performSynchronousRequest]];

	
}


- (void)fetchGameMediaListAsynchronously:(BOOL)YesForAsyncOrNoForSync {
	NSLog(@"AppModel: Fetching Media List");
	
	NSArray *arguments = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d",self.currentGame.gameId], nil];
		
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:self.serverURL 
																	andServiceName:@"media"
																	 andMethodName:@"getMedia"
																	  andArguments:arguments];
	
	if (YesForAsyncOrNoForSync){
		[jsonConnection performAsynchronousRequestWithParser:@selector(parseGameMediaListFromJSON:)];
		[jsonConnection release];
	}
	else [self parseGameMediaListFromJSON: [jsonConnection performSynchronousRequest]];
}


- (void)fetchGameItemListAsynchronously:(BOOL)YesForAsyncOrNoForSync {
	NSLog(@"AppModel: Fetching Item List");
	
	NSArray *arguments = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d",self.currentGame.gameId], nil];
	
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:self.serverURL 
																	andServiceName:@"items"
																	 andMethodName:@"getItems"
																	  andArguments:arguments];
	if (YesForAsyncOrNoForSync) {
		[jsonConnection performAsynchronousRequestWithParser:@selector(parseGameItemListFromJSON:)]; 
		[jsonConnection release];
	}
	else [self parseGameItemListFromJSON: [jsonConnection performSynchronousRequest]];
	
}



- (void)fetchGameNodeListAsynchronously:(BOOL)YesForAsyncOrNoForSync  {
	NSLog(@"AppModel: Fetching Node List");
	
	NSArray *arguments = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d",self.currentGame.gameId], nil];
	
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:self.serverURL 
																	andServiceName:@"nodes"
																	 andMethodName:@"getNodes"
																	  andArguments:arguments];
	if (YesForAsyncOrNoForSync) {
		[jsonConnection performAsynchronousRequestWithParser:@selector(parseGameNodeListFromJSON:)]; 
		[jsonConnection release];
	}
    
	else {
        JSONResult *result = [jsonConnection performSynchronousRequest];
        [self parseGameNodeListFromJSON: result];
    }
    
	
}


- (void)fetchLocationList {
	NSLog(@"AppModel: Fetching Locations from Server");	
	
	if (!loggedIn) {
		NSLog(@"AppModel: Player Not logged in yet, skip the location fetch");	
		return;
	}
    
    if (self.currentlyFetchingLocationList) {
        NSLog(@"AppModel: Already fetching location list, skipping");
        return;
    }
    
    self.currentlyFetchingLocationList = YES;
			
	NSArray *arguments = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d", self.currentGame.gameId],
						  [NSString stringWithFormat:@"%d",self.playerId], 
						  nil];
	
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:self.serverURL 
																	andServiceName:@"locations"
																	 andMethodName:@"getLocationsForPlayer"
																	  andArguments:arguments];
	[jsonConnection performAsynchronousRequestWithParser:@selector(parseLocationListFromJSON:)]; 
	[jsonConnection release];
	
}

- (void)forceUpdateOnNextLocationListFetch {
	locationListHash = @"";
}

- (void)fetchInventory {
	NSLog(@"Model: fetchInventory");
    
    if (self.currentlyFetchingInventory) {
        NSLog(@"AppModel: Already fetching inventory, skipping");
        return;
    }
    
    self.currentlyFetchingInventory = YES;
	
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",self.currentGame.gameId],
						  [NSString stringWithFormat:@"%d",self.playerId],
						  nil];
	
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:self.serverURL 
																	andServiceName:@"items"
																	 andMethodName:@"getItemsForPlayer"
																	  andArguments:arguments];
	[jsonConnection performAsynchronousRequestWithParser:@selector(parseInventoryFromJSON:)]; 
	[jsonConnection release];
	
}


-(void)fetchQuestList {
	NSLog(@"Model: Fetch Requested for Quests");
    
    if (self.currentlyFetchingQuestList) {
        NSLog(@"AppModel: Already fetching quest list, skipping");
        return;
    }
    
    self.currentlyFetchingQuestList = YES;
	
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",self.currentGame.gameId],
						  [NSString stringWithFormat:@"%d",playerId],
						  nil];
	
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:self.serverURL 
																	andServiceName:@"quests"
																	 andMethodName:@"getQuestsForPlayer"
																	  andArguments:arguments];
	
	[jsonConnection performAsynchronousRequestWithParser:@selector(parseQuestListFromJSON:)]; 
	[jsonConnection release];
	
}

- (void)fetchGameList {
	NSLog(@"AppModel: Fetch Requested for Game List.");
		
	//Call server service
	NSArray *arguments = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%d",self.playerId],
						  [NSString stringWithFormat:@"%f",self.playerLocation.coordinate.latitude],
						  [NSString stringWithFormat:@"%f",self.playerLocation.coordinate.longitude],
						  nil];
	
	JSONConnection *jsonConnection = [[JSONConnection alloc]initWithServer:self.serverURL 
																	andServiceName:@"games"
																	 andMethodName:@"getGamesWithDetails"
																	  andArguments:arguments];
	
	[jsonConnection performAsynchronousRequestWithParser:@selector(parseGameListFromJSON:)]; 
	[jsonConnection release];
}



#pragma mark Parsers
- (NSInteger) validIntForKey:(NSString *const)aKey inDictionary:(NSDictionary *const)aDictionary {
	id theObject = [aDictionary valueForKey:aKey];
	return [theObject respondsToSelector:@selector(intValue)]
		? [theObject intValue] : kEmptyValue;
}

- (id) validObjectForKey:(NSString *const)aKey inDictionary:(NSDictionary *const)aDictionary {
	id theObject = [aDictionary valueForKey:aKey];
	return theObject == [NSNull null] ? nil : theObject;
}

-(Item *)parseItemFromDictionary: (NSDictionary *)itemDictionary{	
	Item *item = [[[Item alloc] init] autorelease];
	item.itemId = [[itemDictionary valueForKey:@"item_id"] intValue];
	item.name = [itemDictionary valueForKey:@"name"];
	item.description = [itemDictionary valueForKey:@"description"];
	item.mediaId = [[itemDictionary valueForKey:@"media_id"] intValue];
	item.iconMediaId = [[itemDictionary valueForKey:@"icon_media_id"] intValue];
	item.dropable = [[itemDictionary valueForKey:@"dropable"] boolValue];
	item.destroyable = [[itemDictionary valueForKey:@"destroyable"] boolValue];
	item.maxQty = [[itemDictionary valueForKey:@"max_qty_in_inventory"] intValue];
	
	NSLog(@"\tadded item %@", item.name);
	
	return item;	
}

-(Node *)parseNodeFromDictionary: (NSDictionary *)nodeDictionary{
	//Build the node
	NSLog(@"%@", nodeDictionary);
	Node *node = [[[Node alloc] init] autorelease];
	node.nodeId = [[nodeDictionary valueForKey:@"node_id"] intValue];
	node.name = [nodeDictionary valueForKey:@"title"];
	node.text = [nodeDictionary valueForKey:@"text"];
	NSLog(@"%@", [nodeDictionary valueForKey:@"media_id"]);
	node.mediaId = [self validIntForKey:@"media_id" inDictionary:nodeDictionary];
	node.iconMediaId = [self validIntForKey:@"icon_media_id" inDictionary:nodeDictionary];
	node.answerString = [self validObjectForKey:@"require_answer_string" inDictionary:nodeDictionary];
	node.nodeIfCorrect = [self validIntForKey:@"require_answer_correct_node_id" inDictionary:nodeDictionary];
	node.nodeIfIncorrect = [self validIntForKey:@"require_answer_incorrect_node_id" inDictionary:nodeDictionary];
	
	//Add options here
	int optionNodeId;
	NSString *text;
	NodeOption *option;
	
	if ([nodeDictionary valueForKey:@"opt1_node_id"] != [NSNull null] && [[nodeDictionary valueForKey:@"opt1_node_id"] intValue] > 0) {
		optionNodeId= [[nodeDictionary valueForKey:@"opt1_node_id"] intValue];
		text = [nodeDictionary valueForKey:@"opt1_text"]; 
		option = [[NodeOption alloc] initWithText:text andNodeId: optionNodeId];
		[node addOption:option];
		[option release];
	}
	if ([nodeDictionary valueForKey:@"opt2_node_id"] != [NSNull null] && [[nodeDictionary valueForKey:@"opt2_node_id"] intValue] > 0) {
		optionNodeId = [[nodeDictionary valueForKey:@"opt2_node_id"] intValue];
		text = [nodeDictionary valueForKey:@"opt2_text"]; 
		option = [[NodeOption alloc] initWithText:text andNodeId: optionNodeId];
		[node addOption:option];
		[option release];
	}
	if ([nodeDictionary valueForKey:@"opt3_node_id"] != [NSNull null] && [[nodeDictionary valueForKey:@"opt3_node_id"] intValue] > 0) {
		optionNodeId = [[nodeDictionary valueForKey:@"opt3_node_id"] intValue];
		text = [nodeDictionary valueForKey:@"opt3_text"]; 
		option = [[NodeOption alloc] initWithText:text andNodeId: optionNodeId];
		[node addOption:option];
		[option release];
	}
	
	
	return node;	
}

-(Npc *)parseNpcFromDictionary: (NSDictionary *)npcDictionary {
	Npc *npc = [[[Npc alloc] init] autorelease];
	npc.npcId = [[npcDictionary valueForKey:@"npc_id"] intValue];
	npc.name = [npcDictionary valueForKey:@"name"];
	npc.greeting = [npcDictionary valueForKey:@"text"];
	
	npc.closing = [npcDictionary valueForKey:@"closing"];
	if ((NSNull *)npc.closing == [NSNull null]) npc.closing = @"";

	npc.description = [npcDictionary valueForKey:@"description"];
	npc.mediaId = [[npcDictionary valueForKey:@"media_id"] intValue];
	npc.iconMediaId = [[npcDictionary valueForKey:@"icon_media_id"] intValue];

	return npc;	
}


-(void)parseConversationNodeOptionsFromJSON: (JSONResult *)jsonResult {
	NSArray *conversationOptionsArray = (NSArray *)jsonResult.data;
	
	NSMutableArray *conversationNodeOptions = [[NSMutableArray alloc] initWithCapacity:3];
	
	NSEnumerator *conversationOptionsEnumerator = [conversationOptionsArray objectEnumerator];
	NSDictionary *conversationDictionary;
	
	while (conversationDictionary = [conversationOptionsEnumerator nextObject]) {	
		//Make the Node Option and add it to the Npc
		int optionNodeId = [[conversationDictionary valueForKey:@"node_id"] intValue];
		NSString *text = [conversationDictionary valueForKey:@"text"]; 
		NodeOption *option = [[NodeOption alloc] initWithText:text andNodeId: optionNodeId];
		[conversationNodeOptions addObject:option];
		[option release];
	}
	
	//return conversationNodeOptions;
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"ConversationNodeOptionsReady" object:conversationNodeOptions]];
	
}


-(void)parseLoginResponseFromJSON: (JSONResult *)jsonResult{
	NSLog(@"AppModel: parseLoginResponseFromJSON");
	
	ARISAppDelegate *appDelegate = (ARISAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate removeNewWaitingIndicator];
		
	if ((NSNull *)jsonResult.data != [NSNull null] && jsonResult.data != nil) {
		self.loggedIn = YES;
		self.playerId = [((NSDecimalNumber*)jsonResult.data) intValue];
	}
	else {
		self.loggedIn = NO;	
	}

	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"NewLoginResponseReady" object:nil]];
}



-(void)parseSelfRegistrationResponseFromJSON: (JSONResult *)jsonResult{

	
	if (!jsonResult) {
		NSLog(@"AppModel registerNewUser: No result Data, return");
		[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"SelfRegistrationFailed" object:nil]];
	}

    int newId = [(NSDecimalNumber*)jsonResult.data intValue];
    
	if (newId > 0) {
		NSLog(@"AppModel: Result from new user request successfull");
		[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"SelfRegistrationSucceeded" object:nil]];
	}
	else { 
		NSLog(@"AppModel: Result from new user request unsuccessfull");
		[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"SelfRegistrationFailed" object:nil]];
	}
}



-(void)parseGameListFromJSON: (JSONResult *)jsonResult{
	
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"RecievedGameList" object:nil]];

	NSArray *gameListArray = (NSArray *)jsonResult.data;
	
	NSMutableArray *tempGameList = [[NSMutableArray alloc] init];
	
	NSEnumerator *gameListEnumerator = [gameListArray objectEnumerator];	
	NSDictionary *gameDictionary;
	while (gameDictionary = [gameListEnumerator nextObject]) {
		//create a new game
		Game *game = [[Game alloc] init];
	
		game.gameId = [[gameDictionary valueForKey:@"game_id"] intValue];
		NSLog(@"AppModel: Parsing Game: %d", game.gameId);		
		
		game.name = [gameDictionary valueForKey:@"name"];
		if ((NSNull *)game.name == [NSNull null]) game.name = @"";

		game.description = [gameDictionary valueForKey:@"description"];
		if ((NSNull *)game.description == [NSNull null]) game.description = @"";

		NSString *pc_media_id = [gameDictionary valueForKey:@"pc_media_id"];
		if ((NSNull *)pc_media_id != [NSNull null]) game.pcMediaId = [pc_media_id intValue];
		else game.pcMediaId = 0;
		
		NSString *distance = [gameDictionary valueForKey:@"distance"];
		if ((NSNull *)distance != [NSNull null]) game.distanceFromPlayer = [distance doubleValue];
		else game.distanceFromPlayer = 999999999;
		
		NSString *latitude = [gameDictionary valueForKey:@"latitude"];
		NSString *longitude = [gameDictionary valueForKey:@"longitude"];
		if ((NSNull *)latitude != [NSNull null] && (NSNull *)longitude != [NSNull null] )
			game.location = [[[CLLocation alloc] initWithLatitude:[latitude doubleValue]
												   longitude:[longitude doubleValue]] autorelease];
		else game.location = [[CLLocation alloc] init];
				
		game.authors = [gameDictionary valueForKey:@"editors"];
		if ((NSNull *)game.authors == [NSNull null]) game.authors = @"";

		NSString *numPlayers = [gameDictionary valueForKey:@"numPlayers"];
		if ((NSNull *)numPlayers != [NSNull null]) game.numPlayers = [numPlayers intValue];
		else game.numPlayers = 0;

		NSString *icon_media_id = [gameDictionary valueForKey:@"icon_media_id"];
		if ((NSNull *)icon_media_id != [NSNull null]) game.iconMediaId = [icon_media_id intValue];
		else game.iconMediaId = 0;
		
		NSString *completedQuests = [gameDictionary valueForKey:@"completedQuests"];	
		if ((NSNull *)completedQuests != [NSNull null]) game.completedQuests = [completedQuests intValue];
		else game.completedQuests = 0;
		
		NSString *totalQuests = [gameDictionary valueForKey:@"totalQuests"];
		if ((NSNull *)totalQuests != [NSNull null]) game.totalQuests = [totalQuests intValue];
		else game.totalQuests = 1;
		
		NSString *on_launch_node_id = [gameDictionary valueForKey:@"on_launch_node_id"];
		if ((NSNull *)on_launch_node_id != [NSNull null]) game.launchNodeId = [on_launch_node_id intValue];
		else game.launchNodeId = 0;
		
		NSString *game_complete_node_id = [gameDictionary valueForKey:@"game_complete_node_id"];
		if ((NSNull *)game_complete_node_id != [NSNull null]) game.completeNodeId = [game_complete_node_id intValue];
		else game.completeNodeId = 0;		
		
		NSLog(@"Model: Adding Game: %@", game.name);
		[tempGameList addObject:game]; 
		[game release];
	}

	self.gameList = tempGameList;
	[tempGameList release];
	
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"NewGameListReady" object:nil]];

}

-(void)parseLocationListFromJSON: (JSONResult *)jsonResult{

	NSLog(@"AppModel: Parsing Location List");
	
    self.currentlyFetchingLocationList = NO;
    
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"ReceivedLocationList" object:nil]];

	//Check for an error
	
	//Compare this hash to the last one. If the same, stop hee
	
	if ([jsonResult.hash isEqualToString:self.locationListHash]) {
		NSLog(@"AppModel: Hash is same as last location list update, continue");
		return;
	}
	 
	//Save this hash for later comparisions
	self.locationListHash = [jsonResult.hash copy];
	
	//Continue parsing
	NSArray *locationsArray = (NSArray *)jsonResult.data;
	
	
	//Build the location list
	NSMutableArray *tempLocationsList = [[NSMutableArray alloc] init];
	NSEnumerator *locationsEnumerator = [locationsArray objectEnumerator];	
	NSDictionary *locationDictionary;
	while (locationDictionary = [locationsEnumerator nextObject]) {
		//create a new location
		Location *location = [[Location alloc] init];
		location.locationId = [[locationDictionary valueForKey:@"location_id"] intValue];
		location.name = [locationDictionary valueForKey:@"name"];
		location.iconMediaId = [[locationDictionary valueForKey:@"icon_media_id"] intValue];
		CLLocation *tmpLocation = [[CLLocation alloc] initWithLatitude:[[locationDictionary valueForKey:@"latitude"] doubleValue]
															  longitude:[[locationDictionary valueForKey:@"longitude"] doubleValue]];
		location.location = tmpLocation;
		[tmpLocation release];
		location.error = [[locationDictionary valueForKey:@"error"] doubleValue];
		location.objectType = [locationDictionary valueForKey:@"type"];
		location.objectId = [[locationDictionary valueForKey:@"type_id"] intValue];
		location.hidden = [[locationDictionary valueForKey:@"hidden"] boolValue];
		location.forcedDisplay = [[locationDictionary valueForKey:@"force_view"] boolValue];
		location.allowsQuickTravel = [[locationDictionary valueForKey:@"allow_quick_travel"] boolValue];
		location.qty = [[locationDictionary valueForKey:@"item_qty"] intValue];
		
		NSLog(@"Model: Adding Location: %@ - Type:%@ Id:%d Hidden:%d ForceDisp:%d QuickTravel:%d Qty:%d", 
			  location.name, location.objectType, location.objectId, 
			  location.hidden, location.forcedDisplay, location.allowsQuickTravel, location.qty);
		[tempLocationsList addObject:location];
		[location release];
	}
	
	self.locationList = tempLocationsList;
	[tempLocationsList release];
	
	//Tell everyone
	NSLog(@"AppModel: Finished fetching locations from server, model updated");
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"NewLocationListReady" object:nil]];
	
}


-(void)parseGameMediaListFromJSON: (JSONResult *)jsonResult{

	NSArray *mediaListArray = (NSArray *)jsonResult.data;

	NSMutableDictionary *tempMediaList = [[NSMutableDictionary alloc] init];
	NSEnumerator *enumerator = [mediaListArray objectEnumerator];
	NSDictionary *dict;
	while (dict = [enumerator nextObject]) {
		NSInteger uid = [[dict valueForKey:@"media_id"] intValue];
		NSString *fileName = [dict valueForKey:@"file_name"];
		NSString *urlPath = [dict valueForKey:@"url_path"];

		NSString *type = [dict valueForKey:@"type"];
		
		if (uid < 1) {
			NSLog(@"AppModel fetchGameMediaList: Invalid media id: %d", uid);
			continue;
		}
		if ([fileName length] < 1) {
			NSLog(@"AppModel fetchGameMediaList: Empty fileName string for media #%d.", uid);
			continue;
		}
		if ([type length] < 1) {
			NSLog(@"AppModel fetchGameMediaList: Empty type for media #%d", uid);
			continue;
		}
		
		
		NSString *fullUrl = [NSString stringWithFormat:@"%@%@", urlPath, fileName];
		NSLog(@"AppModel fetchGameMediaList: Full URL: %@", fullUrl);
		
		Media *media = [[Media alloc] initWithId:uid andUrlString:fullUrl ofType:type];
		[tempMediaList setObject:media forKey:[NSNumber numberWithInt:uid]];
		[media release];
	}
	
	self.gameMediaList = tempMediaList;
	[tempMediaList release];
}


-(void)parseGameItemListFromJSON: (JSONResult *)jsonResult{
	NSArray *itemListArray = (NSArray *)jsonResult.data;

	NSMutableDictionary *tempItemList = [[NSMutableDictionary alloc] init];
	NSEnumerator *enumerator = [itemListArray objectEnumerator];
	NSDictionary *dict;
	while (dict = [enumerator nextObject]) {
		Item *tmpItem = [self parseItemFromDictionary:dict];
		
		[tempItemList setObject:tmpItem forKey:[NSNumber numberWithInt:tmpItem.itemId]];
		//[item release];
	}
	
	self.gameItemList = tempItemList;
	[tempItemList release];
}

-(void)parseGameNodeListFromJSON: (JSONResult *)jsonResult{
	NSArray *nodeListArray = (NSArray *)jsonResult.data;
	NSMutableDictionary *tempNodeList = [[NSMutableDictionary alloc] init];
	NSEnumerator *enumerator = [nodeListArray objectEnumerator];
	NSDictionary *dict;
	while (dict = [enumerator nextObject]) {
		Node *tmpNode = [self parseNodeFromDictionary:dict];
		
		[tempNodeList setObject:tmpNode forKey:[NSNumber numberWithInt:tmpNode.nodeId]];
		//[node release];
	}
	
	self.gameNodeList = tempNodeList;
	[tempNodeList release];
}


-(void)parseGameNpcListFromJSON: (JSONResult *)jsonResult{
	NSArray *npcListArray = (NSArray *)jsonResult.data;
	
	NSMutableDictionary *tempNpcList = [[NSMutableDictionary alloc] init];
	NSEnumerator *enumerator = [((NSArray *)npcListArray) objectEnumerator];
	NSDictionary *dict;
	while (dict = [enumerator nextObject]) {
		Npc *tmpNpc = [self parseNpcFromDictionary:dict];
		
		[tempNpcList setObject:tmpNpc forKey:[NSNumber numberWithInt:tmpNpc.npcId]];
	}
	
	self.gameNpcList = tempNpcList;
	[tempNpcList release];
}


-(void)parseInventoryFromJSON: (JSONResult *)jsonResult{
	NSLog(@"AppModel: Parsing Inventory");
	
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"ReceivedInventory" object:nil]];

    self.currentlyFetchingInventory = NO;

    
	//Check for an error
	
	//Compare this hash to the last one. If the same, stop hee	
	
	if ([jsonResult.hash isEqualToString:self.inventoryHash]) {
		NSLog(@"AppModel: Hash is same as last inventory listy update, continue");
		return;
	}
	
	
	//Save this hash for later comparisions
	self.inventoryHash = [jsonResult.hash copy];
	
	//Continue parsing
	NSArray *inventoryArray = (NSArray *)jsonResult.data;
	
	NSMutableDictionary *tempInventory = [[NSMutableDictionary alloc] initWithCapacity:10];
	NSEnumerator *inventoryEnumerator = [((NSArray *)inventoryArray) objectEnumerator];	
	NSDictionary *itemDictionary;
	while (itemDictionary = [inventoryEnumerator nextObject]) {
		Item *item = [[Item alloc] init];
		item.itemId = [[itemDictionary valueForKey:@"item_id"] intValue];
		item.name = [itemDictionary valueForKey:@"name"];
		item.description = [itemDictionary valueForKey:@"description"];
		item.mediaId = [[itemDictionary valueForKey:@"media_id"] intValue];
		item.iconMediaId = [[itemDictionary valueForKey:@"icon_media_id"] intValue];
		item.dropable = [[itemDictionary valueForKey:@"dropable"] boolValue];
		item.destroyable = [[itemDictionary valueForKey:@"destroyable"] boolValue];
		item.qty = [[itemDictionary valueForKey:@"qty"] intValue];
		NSLog(@"Model: Adding Item: %@", item.name);
		[tempInventory setObject:item forKey:[NSString stringWithFormat:@"%d",item.itemId]]; 
		[item release];
	}

	self.inventory = tempInventory;
	[tempInventory release];
	
	NSLog(@"AppModel: Finished fetching inventory from server, model updated");
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"NewInventoryReady" object:nil]];
	
	//Note: The inventory list VC listener will add the badge now that it knows something is different
	
}


-(void)parseQRCodeObjectFromJSON: (JSONResult *)jsonResult {

	NSObject<QRCodeProtocol> *qrCodeObject = nil;

	if ((NSNull*)jsonResult.data != [NSNull null]) {
		NSDictionary *qrCodeObjectDictionary = (NSDictionary *)jsonResult.data;

		/*
		NSString *latitude = [qrCodeObjectDictionary valueForKey:@"latitude"];
		NSString *longitude = [qrCodeObjectDictionary valueForKey:@"longitude"];
		NSLog(@"AppModel-parseQRCodeObjectFromDictionary: Lat:%@ Lng:%@",latitude,longitude);

		CLLocation *location = [[CLLocation alloc] initWithLatitude:[latitude doubleValue]
														  longitude:[longitude doubleValue]];
		
		self.playerLocation = [location copy];
		[location release];
		 */
		
		NSString *type = [qrCodeObjectDictionary valueForKey:@"type"];
		if ([type isEqualToString:@"Node"]) qrCodeObject = [self parseNodeFromDictionary:qrCodeObjectDictionary];
		if ([type isEqualToString:@"Item"]) qrCodeObject = [self parseItemFromDictionary:qrCodeObjectDictionary];
		if ([type isEqualToString:@"Npc"]) qrCodeObject = [self parseNpcFromDictionary:qrCodeObjectDictionary];
	}
	
	[[NSNotificationCenter defaultCenter] postNotification: [NSNotification notificationWithName:@"QRCodeObjectReady" object:qrCodeObject]];

	
}


-(void)parseStartOverFromJSON:(JSONResult *)jsonResult{
	NSLog(@"AppModel: Parsing start over result and firing off fetches");
	[self silenceNextServerUpdate];
	[self fetchAllPlayerLists];
}


-(void)parseUpdateServerWithPlayerLocationFromJSON:(JSONResult *)jsonResult{
    NSLog(@"AppModel: parseUpdateServerWithPlayerLocationFromJSON");
    self.currentlyUpdatingServerWithPlayerLocation = NO;
}

-(void)parseQuestListFromJSON: (JSONResult *)jsonResult{

	NSLog(@"AppModel: Parsing Quests");
    
    self.currentlyFetchingQuestList = NO;
	
	//Check for an error
	
	//Tell everyone we just recieved the questList
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"ReceivedQuestList" object:nil]];
	
	//Compare this hash to the last one. If the same, stop here
	if ([jsonResult.hash isEqualToString:self.questListHash]) {
		NSLog(@"AppModel: Hash is same as last quest list update, continue");
		return;
	}
	
	//Save this hash for later comparisions
	self.questListHash = [jsonResult.hash copy];
	
	//Continue parsing

	NSDictionary *questListDictionary = (NSDictionary *)jsonResult.data;	
	
	//parse out the active quests into quest objects
	NSMutableArray *activeQuestObjects = [[NSMutableArray alloc] init];
	NSArray *activeQuests = [questListDictionary objectForKey:@"active"];
	NSEnumerator *activeQuestsEnumerator = [activeQuests objectEnumerator];
	NSDictionary *activeQuest;
	while (activeQuest = [activeQuestsEnumerator nextObject]) {
		//We have a quest, parse it into a quest abject and add it to the activeQuestObjects array
		Quest *quest = [[Quest alloc] init];
		quest.questId = [[activeQuest objectForKey:@"quest_id"] intValue];
		quest.name = [activeQuest objectForKey:@"name"];
		quest.description = [activeQuest objectForKey:@"description"];
		quest.iconMediaId = [[activeQuest objectForKey:@"icon_media_id"] intValue];
		[activeQuestObjects addObject:quest];
		[quest release];
	}

	//parse out the completed quests into quest objects	
	NSMutableArray *completedQuestObjects = [[NSMutableArray alloc] init];
	NSArray *completedQuests = [questListDictionary objectForKey:@"completed"];
	NSEnumerator *completedQuestsEnumerator = [completedQuests objectEnumerator];
	NSDictionary *completedQuest;
	while (completedQuest = [completedQuestsEnumerator nextObject]) {
		//We have a quest, parse it into a quest abject and add it to the completedQuestObjects array
		Quest *quest = [[Quest alloc] init];
		quest.questId = [[completedQuest objectForKey:@"quest_id"] intValue];
		quest.name = [completedQuest objectForKey:@"name"];
		quest.description = [completedQuest objectForKey:@"text_when_complete"];
		quest.iconMediaId = [[completedQuest objectForKey:@"icon_media_id"] intValue];
		[completedQuestObjects addObject:quest];
		[quest release];
	}

	//Package the two object arrays in a Dictionary
	NSMutableDictionary *tmpQuestList = [[NSMutableDictionary alloc] init];
	[tmpQuestList setObject:activeQuestObjects forKey:@"active"];
	[tmpQuestList setObject:completedQuestObjects forKey:@"completed"];	
	self.questList = tmpQuestList;
	
	//Update Game Object
	self.currentGame.completedQuests = [completedQuestObjects count];
	
	NSString *totalQuests = [questListDictionary valueForKey:@"totalQuests"];
	if ((NSNull *)totalQuests != [NSNull null]) self.currentGame.totalQuests = [totalQuests intValue];
	else self.currentGame.totalQuests = 1;
	
	[activeQuestObjects release];
	[completedQuestObjects release];
	[tmpQuestList release];

	//Sound the alarm
	NSLog(@"AppModel: Finished fetching quests from server, model updated");
	[[NSNotificationCenter defaultCenter] postNotification: [NSNotification notificationWithName:@"NewQuestListReady" object:nil]];
	
}

@end
