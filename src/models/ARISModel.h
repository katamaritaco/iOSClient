//
//  ARISModel.h
//  ARIS
//
//  Created by Ben Longoria on 2/17/09.
//  Copyright 2009 University of Wisconsin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ARISModel : NSObject
{
  long n_game_data_received;
  long n_player_data_received;
}

- (void) requestGameData;
- (void) requestPlayerData;

- (void) clearGameData;
- (void) clearPlayerData;

- (long) nGameDataToReceive;
- (long) nPlayerDataToReceive;
- (long) nGameDataReceived;
- (long) nPlayerDataReceived;

- (BOOL) gameDataReceived;
- (BOOL) playerDataReceived;

- (NSString *) serializedName;
- (NSString *) serializeModel;
- (void) deserializeModel:(NSString *)data;

@end

