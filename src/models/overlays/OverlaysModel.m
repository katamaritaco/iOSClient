//
//  OverlaysModel.m
//  ARIS
//
//  Created by Justin Moeller on 3/7/14.
//
//

#import "OverlaysModel.h"


@implementation OverlaysModel
@synthesize overlayIds;

- (id) init
{
    self = [super init];
    if (self) {
        [self clearData];
  _ARIS_NOTIF_LISTEN_(@"OverlaysReceived",self,@selector(overlaysReceived:),nil);
  _ARIS_NOTIF_LISTEN_(@"OverlayIdsReceived",self,@selector(overlayIdsReceived:),nil);
    }
    return self;
}

- (void) dealloc
{
    _ARIS_NOTIF_IGNORE_ALL_(self);                          
}

- (void) overlaysReceived:(NSNotification *)notification
{
    NSDictionary *newOverlays = [notification.userInfo objectForKey:@"overlays"];
    allOverlays = newOverlays;
}

- (void) clearData
{
    allOverlays = [[NSDictionary alloc] init];
    overlayIds = [[NSArray alloc] init];
}

- (void) overlayIdsReceived:(NSNotification *)notification
{
    NSArray *ids = [notification.userInfo objectForKey:@"overlayIds"];
    overlayIds = ids;
    _ARIS_NOTIF_SEND_(@"NewOverlaysAvailable",self,nil);
}

- (CustomMapOverlay *) overlayForOverlayId:(int)overlayId
{
    return [allOverlays objectForKey:[NSNumber numberWithInt:overlayId]];
}



@end
