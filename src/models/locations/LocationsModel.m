//
//  LocationsModel.m
//  ARIS
//
//  Created by Phil Dougherty on 2/20/13.
//
//

#import "LocationsModel.h"


@implementation LocationsModel

@synthesize currentLocations;

- (id) init
{
    self = [super init];
    if(self)
    {
        [self clearData];
  _ARIS_NOTIF_LISTEN_(@"LatestPlayerLocationsReceived",self,@selector(latestPlayerLocationsReceived:),nil);
    }
    return self;
}

- (void) dealloc
{
    _ARIS_NOTIF_IGNORE_ALL_(self);                  
}

- (void) clearData
{
    [self updateLocations:[[NSArray alloc] init]];
}

- (void) removeLocation:(Location *)location
{
    NSMutableArray *currentLocationsMutable = [self.currentLocations mutableCopy];
    for(int i = 0; i < currentLocationsMutable.count; ++i)
    {
        Location *existingLocation = [currentLocationsMutable objectAtIndex:i];
        if([existingLocation isEqual:location])
        {
            [currentLocationsMutable removeObject:existingLocation];
            --i;
        }
    }
    
    [self updateLocations:currentLocationsMutable];
}

- (void) latestPlayerLocationsReceived:(NSNotification *)notification
{
    [self updateLocations:[notification.userInfo objectForKey:@"locations"]];
}

- (void) updateLocations:(NSArray *)locations
{
    NSMutableArray *newlyAvailableLocations   = [[NSMutableArray alloc] initWithCapacity:5];
    NSMutableArray *newlyUnavailableLocations = [[NSMutableArray alloc] initWithCapacity:5];
    
    //Gained Locations
    for(Location *newLocation in locations)
    {
        BOOL match = NO;
        for (Location *existingLocation in self.currentLocations)
        {
            if ([newLocation compareTo:existingLocation])
                match = YES;
        }
        
        if(!match) //New Location
            [newlyAvailableLocations addObject:newLocation];
    }
    
    //Lost Locations
    for (Location *existingLocation in self.currentLocations)
    {
        BOOL match = NO;
        for (Location *newLocation in locations)
        {
            if ([newLocation compareTo:existingLocation])
                match = YES;
        }
        
        if(!match) //Lost location
            [newlyUnavailableLocations addObject:existingLocation];
    }
    
    self.currentLocations = locations;
    
    if(newlyAvailableLocations.count > 0)
    {
        NSDictionary *lDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                               newlyAvailableLocations,@"newlyAvailableLocations",
                               locations,@"allLocations",
                               nil];
        _ARIS_NOTIF_SEND_(@"NewlyAvailableLocationsAvailable",self,lDict);
    }
    if(newlyUnavailableLocations.count > 0)
    {
        NSDictionary *lDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                               newlyUnavailableLocations,@"newlyUnavailableLocations",
                               locations,@"allLocations",
                               nil];
        _ARIS_NOTIF_SEND_(@"NewlyUnavailableLocationsAvailable",self,lDict);
    }
    NSDictionary *lDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                           locations,@"allLocations",
                           nil];
    _ARIS_NOTIF_SEND_(@"LocationsAvailable",self,lDict);
}

- (int) modifyQuantity:(int)quantityModifier forLocationId:(int)locationId
{
    NSMutableArray *newLocations = [[NSMutableArray alloc] initWithCapacity:self.currentLocations.count];
    for(int i = 0; i < self.currentLocations.count; i++)
        [newLocations addObject:[((Location *)[self.currentLocations objectAtIndex:i]) copy]];
    
    Location *tmpLocation;
	for (int i = 0; i < newLocations.count; i++)
    {
        tmpLocation = (Location *)[newLocations objectAtIndex:i];
        //if(tmpLocation.gameObject.type != GameObjectItem) continue;
        if(tmpLocation.locationId == locationId)
			tmpLocation.qty += quantityModifier;
        if(tmpLocation.qty <= 0 && !tmpLocation.infiniteQty) 
        {
            [newLocations removeObjectAtIndex:i];
            i--;
        }
	}
    
    [self updateLocations:newLocations];
    return tmpLocation.qty;
}

- (Location *) locationForId:(int)locationId
{
    for(int i = 0; i < currentLocations.count; i++)
        if(((Location *)[currentLocations objectAtIndex:i]).locationId == locationId) return [currentLocations objectAtIndex:i];
    return nil;
}

@end
