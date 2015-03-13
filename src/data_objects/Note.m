//
//  Note.m
//  ARIS
//
//  Created by Brian Thiel on 8/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Note.h"
#import "NSDictionary+ValidParsers.h"
#import "AppModel.h"

@implementation Note

@synthesize note_id;
@synthesize user_id;
@synthesize name;
@synthesize desc;
@synthesize media_id;
@synthesize tag_id;
@synthesize object_tag_id;
@synthesize created;

- (id) init
{
    if (self = [super init])
    {
      self.note_id = 0;
      self.user_id = 0;
      self.name = @"";
      self.desc = @"";
      self.media_id = 0;
      self.tag_id = 0;
      self.object_tag_id = 0;
      self.created = [[NSDate alloc] init];
    }
    return self;
}

- (id) initWithDictionary:(NSDictionary *)dict
{
    if(self = [super init])
    {
        self.note_id       = [dict validIntForKey:@"note_id"];
        self.user_id       = [dict validIntForKey:@"user_id"];
        self.name          = [dict validObjectForKey:@"name"];
        self.desc          = [dict validObjectForKey:@"description"];
        self.media_id      = [dict validIntForKey:@"media_id"];
        self.tag_id        = [dict validIntForKey:@"tag_id"];
        self.object_tag_id = [dict validIntForKey:@"object_tag_id"];
        self.created       = [dict validDateForKey:@"created"];

        [self createObjectTag];
    }
    return self;
}

- (void) mergeDataFromNote:(Note *)n //allows for notes to be updated easily- all things with this note pointer now have access to latest note data
{
  self.note_id  = n.note_id;
  self.user_id  = n.user_id;
  self.name     = n.name;
  self.desc     = n.desc;
  self.media_id = n.media_id;
  self.tag_id   = n.tag_id;
  self.object_tag_id = n.object_tag_id;
  self.created  = n.created;
}

- (long) icon_media_id
{
    if([_MODEL_TAGS_ tagsForObjectType:@"NOTE" id:note_id].count)
    {
      Tag *tag = [_MODEL_TAGS_ tagsForObjectType:@"NOTE" id:note_id][0];
      if(tag.media_id != 0)
      {
        return tag.media_id;
      }
    }

    return -6;
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"Note- Id:%ld\tName:%@\tOwner:%ld\t",self.note_id,self.name,self.user_id];
}


// If we receive or created a note after the game has loaded, link it to its tag
//
- (void) createObjectTag
{
  if(self.object_tag_id != 0)
  {
    ObjectTag *newObjectTag = [[ObjectTag alloc] init];
    newObjectTag.object_tag_id = self.object_tag_id;
    newObjectTag.object_type   = @"NOTE";
    newObjectTag.object_id     = self.note_id;
    newObjectTag.tag_id        = self.tag_id;

    [_MODEL_TAGS_ removeTagsFromObjectType:@"NOTE" id: note_id];
    _ARIS_NOTIF_SEND_(@"SERVICES_OBJECT_TAGS_RECEIVED", nil, @{@"object_tags":@[newObjectTag]});
  }
  else if(self.tag_id == 0 && self.object_tag_id == 0)
  {
    [_MODEL_TAGS_ removeTagsFromObjectType:@"NOTE" id: note_id];
    _ARIS_NOTIF_SEND_(@"SERVICES_OBJECT_TAGS_RECEIVED", nil, @{@"object_tags":@[]});
  }
}

@end
