//
//  GameObjectProtocol.h
//  ARIS
//
//  Created by Phil Dougherty on 4/25/13.
//
//

#import <Foundation/Foundation.h>
#import "GameObjectViewController.h"

enum
{
	GameObjectNil       = 0,
	GameObjectNpc       = 1,
	GameObjectItem      = 2,
	GameObjectPlaque    = 3,
	GameObjectPlayer    = 4,
    GameObjectWebPage   = 5,
    GameObjectNote      = 6
};
typedef UInt32 GameObjectType;

@protocol GameObjectProtocol <NSObject>

- (id<GameObjectProtocol>) initWithDictionary:(NSDictionary *)dict;
- (GameObjectType) type;
- (NSString *) name;
- (int) icon_media_id;
- (GameObjectViewController *) viewControllerForDelegate:(id<GameObjectViewControllerDelegate>)d fromSource:(id)s;
- (id<GameObjectProtocol>) copy;
- (int) compareTo:(id<GameObjectProtocol>)ob;
- (NSString *) description;

@end
