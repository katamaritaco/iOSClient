//
//  ARISMediaView.m
//  ARIS
//
//  Created by Phil Dougherty on 8/1/13.
//

#import "ARISMediaView.h"
#import "Media.h"
#import "AppServices.h"
#import "UIImage+animatedGIF.h"
#import "ARISMediaLoader.h"
#import <MediaPlayer/MediaPlayer.h>

@interface ARISMediaView() <ARISMediaLoaderDelegate>
{
    ARISMediaDisplayMode displayMode;
    Media *media;
    UIImage *image;
    
    UIImageView *imageView;
    MPMoviePlayerViewController *avVC;
    UIImageView *playIcon;
    UIActivityIndicatorView *spinner;
    
    ARISDelegateHandle *selfDelegateHandle;
    id<ARISMediaViewDelegate> __unsafe_unretained delegate;
}

@end

@implementation ARISMediaView

- (id) initWithDelegate:(id<ARISMediaViewDelegate>)d
{
    if(self = [super initWithFrame:CGRectMake(0,0,64,64)])
    {
        delegate = d;
    }
    return self;
}

- (id) initWithFrame:(CGRect)f
{
    if(self = [super initWithFrame:f])
    {
        self.frame = f; 
    } 
    return self;
}

- (id) initWithFrame:(CGRect)f delegate:(id<ARISMediaViewDelegate>)d
{
    if(self = [super initWithFrame:f])
    {
        delegate = d;
        self.frame = f; 
    } 
    return self; 
}

- (void) setDelegate:(id<ARISMediaViewDelegate>)d
{
    delegate = d;
}

- (void) setDisplayMode:(ARISMediaDisplayMode)dm
{
    displayMode = dm;
    [self conformFrameToMode];
}

- (void) setFrame:(CGRect)f
{
    super.frame = f; 
    [self conformFrameToMode];
}

- (void) setMedia:(Media *)m
{
    [self clear];
    if(!m.data)
    {
        [self addSpinner];
        selfDelegateHandle = [[ARISDelegateHandle alloc] initWithDelegate:self];
        [[AppServices sharedAppServices] loadMedia:m delegateHandle:selfDelegateHandle];
        return;//calls 'mediaLoaded' upon complete
    }
    media = m;
    [self displayMedia];
}

- (void) mediaLoaded:(Media *)m
{
    [self setMedia:m];
}

- (void) setImage:(UIImage *)i
{
    [self clear]; 
    image = i;
    [self displayImage];
}

- (void) clear
{
    if(selfDelegateHandle) [selfDelegateHandle invalidate];
    image = nil;
    media = nil; 
    [self removeSpinner];   
    [self removePlayIcon];
    if(avVC) { [avVC.view removeFromSuperview]; avVC = nil; }      
    if(imageView) { [imageView removeFromSuperview]; imageView = nil; }
}

- (void) displayMedia //simply routes to displayImage, displayVideo, or displayAudio
{
    NSString *type = media.type;
    if([type isEqualToString:@"IMAGE"])
    {
        NSString *dataType = [self contentTypeForImageData:media.data];
        if     ([dataType isEqualToString:@"image/gif"])
        {
            image = [UIImage animatedImageWithAnimatedGIFData:media.data];
            [self displayImage];
        }
        else if([dataType isEqualToString:@"image/jpeg"] ||
                [dataType isEqualToString:@"image/png"]) 
        {
            image = [UIImage imageWithData:media.data];
            [self displayImage];
        }
    }
    else if([type isEqualToString:@"VIDEO"])
        [self displayVideo:media];
    else if([type isEqualToString:@"AUDIO"])
        [self displayAudio:media];
}

- (void) displayImage
{
    [imageView removeFromSuperview];
    imageView = [[UIImageView alloc] init];
    [self addSubview:imageView];
    if(playIcon) [self addPlayIcon]; //to ensure it's on top of imageView
    [imageView setImage:image];
    [self conformFrameToMode];
}

- (void) displayVideo:(Media *)m
{
    [self addPlayIcon];
    
    avVC = [[MPMoviePlayerViewController alloc] initWithContentURL:media.localURL];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil]; 
    avVC.moviePlayer.shouldAutoplay = NO;
    [avVC.moviePlayer requestThumbnailImagesAtTimes:[NSArray arrayWithObject:[NSNumber numberWithFloat:1.0f]] timeOption:MPMovieTimeOptionNearestKeyFrame];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(displayVideoThumbLoaded:) name:MPMoviePlayerThumbnailImageRequestDidFinishNotification object:avVC.moviePlayer];
    avVC.moviePlayer.controlStyle = MPMovieControlStyleNone;
}

- (void) displayVideoThumbLoaded:(NSNotification*)notification
{
    image = [UIImage imageWithData:UIImageJPEGRepresentation([notification.userInfo objectForKey:MPMoviePlayerThumbnailImageKey], 1.0)];
    [self displayImage];
}

- (void) displayAudio:(Media *)m
{
    [self addPlayIcon];
    
    avVC = [[MPMoviePlayerViewController alloc] initWithContentURL:media.localURL];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];  
    avVC.moviePlayer.shouldAutoplay = NO;
    avVC.moviePlayer.controlStyle = MPMovieControlStyleNone;  
    image = [UIImage imageNamed:@"sound_with_bg.png"];
    [self displayImage];
}

- (void) conformFrameToMode
{
    CGRect oldFrame = self.frame;
    
    switch(displayMode)
    {
        case ARISMediaDisplayModeDefault:
        case ARISMediaDisplayModeAspectFill:
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            break;
        case ARISMediaDisplayModeStretchFill:
            imageView.contentMode = UIViewContentModeScaleToFill;
            break;
        case ARISMediaDisplayModeAspectFit:
        case ARISMediaDisplayModeTopAlignAspectFitWidth:
        case ARISMediaDisplayModeTopAlignAspectFitWidthAutoResizeHeight:
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            break;
    }
    
    float mult = oldFrame.size.width/image.size.width; 
    switch(displayMode)
    {
        case ARISMediaDisplayModeTopAlignAspectFitWidth:
            imageView.frame = CGRectMake(0,0,oldFrame.size.width,image.size.height*mult);
            break;
        case ARISMediaDisplayModeTopAlignAspectFitWidthAutoResizeHeight:
            imageView.frame = CGRectMake(0,0,oldFrame.size.width,image.size.height*mult);
            //instead of getting in infinite loop with "setFrame", just handle silent cleanup here 
            super.frame = CGRectMake(oldFrame.origin.x,oldFrame.origin.y,oldFrame.size.width,imageView.frame.size.height);
        default:
            imageView.frame = self.bounds;
            break;
    }
    
    if(avVC) avVC.view.frame = imageView.frame;   
    [self centerSpinner];
    [self centerPlayIcon]; 
    
    if(oldFrame.origin.x == self.frame.origin.x &&
       oldFrame.origin.y == self.frame.origin.y && 
       oldFrame.size.width == self.frame.size.width &&  
       oldFrame.size.height ==  self.frame.size.height)
        return; //no change to frame- don't notify delegate
       
    if(delegate && [(NSObject *)delegate respondsToSelector:@selector(ARISMediaViewFrameUpdated:)])
        [delegate ARISMediaViewFrameUpdated:self]; 
}

- (void) playbackFinished:(NSNotification *)n
{
    [self stop]; 
    if([[n.userInfo objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue] == MPMovieFinishReasonUserExited)
        if(delegate && [(NSObject *)delegate respondsToSelector:@selector(ARISMediaViewFinishedPlayback:)])
            [delegate ARISMediaViewFinishedPlayback:self];
}

- (void) addSpinner
{
    if(spinner) [self removeSpinner];
    spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self centerSpinner];
    [self addSubview:spinner];
    [spinner startAnimating];
}

- (void) centerSpinner
{
    spinner.center = self.center; 
}

- (void) removeSpinner
{
	[spinner stopAnimating];
    [spinner removeFromSuperview];
    spinner = nil;
}

- (void) addPlayIcon
{
    if(playIcon) [self removePlayIcon];
    playIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"play.png"]];
    [playIcon addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playIconTouched)]];
    playIcon.userInteractionEnabled = YES;
    [self centerPlayIcon];
    playIcon.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:playIcon];
}

- (void) centerPlayIcon
{
    double h = self.frame.size.height;
    double w = self.frame.size.width; 
    if(h > 60) h = 60;
    if(w > 60) w = 60; 
    playIcon.frame = CGRectMake((self.frame.size.width-w)/2,(self.frame.size.height-h)/2,w,h); 
}

- (void) removePlayIcon
{
    [playIcon removeFromSuperview];
    playIcon = nil;
}

- (void) playIconTouched
{
    if(delegate && [(NSObject *)delegate respondsToSelector:@selector(ARISMediaViewShouldPlayButtonTouched:)])
    {
        if([delegate ARISMediaViewShouldPlayButtonTouched:self])
            [self play];
    }
    else
        [self play];
}

- (void) play
{
    if(!media || [media.type isEqualToString:@"IMAGE"] || !avVC) return;
    [self removePlayIcon];
    avVC.view.frame = self.bounds; 
    [self addSubview:avVC.view];  
    [avVC.moviePlayer play]; 
}

- (void) stop
{
    if(!media || [media.type isEqualToString:@"IMAGE"] || !avVC) return;
    [self addPlayIcon];
    [avVC.moviePlayer stop];
    [avVC.view removeFromSuperview];
}

- (NSString *) contentTypeForImageData:(NSData *)d
{
    uint8_t c;
    [d getBytes:&c length:1];
   
    switch(c)
    {
        case 0xFF:
            return @"image/jpeg";
        case 0x89:
            return @"image/png";
        case 0x47:
            return @"image/gif";
        case 0x49:
        case 0x4D:
            return @"image/tiff";
    }
    return nil;
}

- (Media *) media { return media; }
- (UIImage *) image { return image; }

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];  
    if(selfDelegateHandle) [selfDelegateHandle invalidate];
    if(avVC) [avVC.moviePlayer cancelAllThumbnailImageRequests]; 
}

@end
