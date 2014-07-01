//
//  Trigger.m
//  ARIS
//
//  Created by David Gagnon on 4/1/09.
//  Copyright 2009 University of Wisconsin - Madison. All rights reserved.
//

#import "Trigger.h"
#import "AppModel.h"
#import "NSDictionary+ValidParsers.h"

@implementation Trigger

@synthesize trigger_id;
@synthesize instance_id;
@synthesize scene_id;
@synthesize type;
@synthesize title;
@synthesize icon_media_id;
@synthesize location;
@synthesize distance;
@synthesize infinite_distance;
@synthesize wiggle;
@synthesize show_title;
@synthesize code;
@synthesize mapCircle;

- (id) init
{
    if(self = [super init])
    {
        trigger_id = 0;
        instance_id = 0; 
        scene_id = 0;
        type = @"IMMEDIATE";
        title = @"";
        icon_media_id = 0; 
        location = [[CLLocation alloc] initWithLatitude:0.0 longitude:0.0];
        distance = 10;
        infinite_distance = NO; 
        wiggle = NO;
        show_title = NO;
        code = @"";
        mapCircle = [MKCircle circleWithCenterCoordinate:location.coordinate radius:(infinite_distance ? 0 : distance)];
    }
    return self;
}

- (id) initWithDictionary:(NSDictionary *)dict
{
    if(self = [super init])
    {
        trigger_id = [dict validIntForKey:@"trigger_id"];
        instance_id = [dict validIntForKey:@"instance_id"]; 
        scene_id = [dict validIntForKey:@"scene_id"];
        type = [dict validStringForKey:@"type"];
        title = [dict validStringForKey:@"title"];
        icon_media_id = [dict validIntForKey:@"icon_media_id"]; 
        location = [[CLLocation alloc] initWithLatitude:[dict validDoubleForKey:@"latitude"] longitude:[dict validDoubleForKey:@"longitude"]];
        distance = [dict validIntForKey:@"distance"];
        infinite_distance = distance < 0 || distance > 100000; 
        wiggle = [dict validBoolForKey:@"wiggle"];
        show_title = [dict validBoolForKey:@"show_title"];
        code = [dict validStringForKey:@"code"];
        mapCircle = [MKCircle circleWithCenterCoordinate:location.coordinate radius:(infinite_distance ? 0 : distance)]; 
    }
    return self;
}

- (void) mergeDataFromTrigger:(Trigger *)t
{
    trigger_id = t.trigger_id;
    instance_id = t.instance_id; 
    scene_id = t.scene_id;
    type = t.type;
    title = t.title;
    icon_media_id = t.icon_media_id; 
    location = t.location;
    distance = t.distance;
    infinite_distance = t.infinite_distance;
    wiggle = t.wiggle;
    show_title = t.show_title;
    code = t.code;
    mapCircle = t.mapCircle; 
}

//returns icon_media of instance if self's isn't set
- (int) icon_media_id
{
    if(icon_media_id) return icon_media_id;
    return [_MODEL_INSTANCES_ instanceForId:instance_id].icon_media_id;
}

//MKAnnotation stuff
- (CLLocationCoordinate2D) coordinate
{
    return location.coordinate;
}

- (void) setCoordinate:(CLLocationCoordinate2D)newCoordinate
{
    //no
}

//returns title of instance if self's isn't set
- (NSString *) title
{
    if(title && ![title isEqualToString:@""]) return title;
    return [_MODEL_INSTANCES_ instanceForId:instance_id].name; 
}

- (NSString *) subtitle
{
    return @"Subtitle!"; 
}

@end
