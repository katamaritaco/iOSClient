//
//  ARISPusherHandler.h
//  ARIS
//
//  Created by Phil Dougherty on 5/3/13.
//
//

#import <Foundation/Foundation.h>

#define _PUSHER_ [ARISPusherHandler sharedPusherHandler]

@interface ARISPusherHandler : NSObject

+ (ARISPusherHandler *) sharedPusherHandler;

- (void) loginGame:(int)game_id;
- (void) loginPlayer:(int)user_id;
- (void) loginGroup:(NSString *)group;
- (void) loginWebPage:(int)web_page_id;

- (void) logoutGame;
- (void) logoutPlayer;
- (void) logoutGroup;
- (void) logoutWebPage;

@end
