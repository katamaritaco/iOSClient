//
//  PopOverViewController.m
//  ARIS
//
//  Created by Jacob Hanshaw on 10/30/12.
//
//

#import "PopOverViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import "ARISMediaView.h"
#import "CircleView.h"
#import "Media.h"
#import "AppModel.h"
#import "MediaModel.h"

@interface PopOverViewController() <ARISMediaViewDelegate>
{
  CircleView *popOverView;
  ARISMediaView *iconMediaView;
  UILabel *header;
  UILabel *prompt;
  UIButton *continueButton;
}
@end

@implementation PopOverViewController

@synthesize delegate;

- (id) initWithDelegate:(id <PopOverViewDelegate>)d
{
    if(self = [super init])
    {
        delegate = d;
    }
    return self;
}

- (void) loadView
{
  [super loadView];

  [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(requestDismiss)]];

  self.view.backgroundColor = [[UIColor ARISColorTranslucentBlack] colorWithAlphaComponent:0.4];
  self.view.userInteractionEnabled = YES;

  popOverView = [[CircleView alloc] initWithFillColor:[[UIColor ARISColorTranslucentBlack] colorWithAlphaComponent:0.8] strokeColor:[UIColor ARISColorWhite] strokeWidth:4];
  [popOverView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(requestSubmit)]];
  popOverView.opaque = NO;

  header = [[UILabel alloc] init];
  header.font = [ARISTemplate ARISTitleFont];
  header.textColor = [UIColor ARISColorWhite];
  header.textAlignment = NSTextAlignmentCenter;
  header.backgroundColor = [UIColor clearColor];
  header.lineBreakMode = NSLineBreakByTruncatingTail;

  prompt = [[UILabel alloc] init];
  prompt.font = [ARISTemplate ARISSubtextFont];
  prompt.textColor = [UIColor ARISColorWhite];
  prompt.textAlignment = NSTextAlignmentCenter;
  prompt.backgroundColor = [UIColor clearColor];
  prompt.lineBreakMode = NSLineBreakByTruncatingTail;

  iconMediaView = [[ARISMediaView alloc] initWithDelegate:self];
  [iconMediaView setDisplayMode:ARISMediaDisplayModeAspectFit];

  continueButton = [[UIButton alloc] init];
  [continueButton setTitle:@"Continue" forState:UIControlStateNormal];
  [continueButton setBackgroundColor:[[UIColor ARISColorTranslucentBlack] colorWithAlphaComponent:0.8]];
  [continueButton.layer setBorderWidth:4.0f];
  [continueButton.layer setBorderColor:[UIColor ARISColorWhite].CGColor];
  continueButton.layer.cornerRadius = 10;
  continueButton.clipsToBounds = YES;
  continueButton.userInteractionEnabled = NO;

  [popOverView addSubview:header];
  [popOverView addSubview:prompt];
  [popOverView addSubview:iconMediaView];
  [self.view addSubview:continueButton];

  [self.view addSubview:popOverView];
}

- (void) viewWillLayoutSubviews
{
  [super viewWillLayoutSubviews];
  float radius = (self.view.bounds.size.width-60)/2;
  popOverView.frame = CGRectMake((self.view.bounds.size.width-(2*radius))/2,self.view.bounds.size.height/2-radius,radius*2,radius*2);
  [iconMediaView setFrame:CGRectMake(radius-64,radius-84,128,128)];
  header.frame = CGRectMake(25,radius+60,2*radius-50,24);
  prompt.frame = CGRectMake(50,radius+80,2*radius-100,24);
  continueButton.frame = CGRectMake(100,self.view.bounds.size.height/2+radius+30,self.view.bounds.size.width-200,40);
}

- (void) setHeader:(NSString *)h prompt:(NSString *)p icon_media_id:(long)m
{
    if(!self.view) self.view.hidden = NO; //Just accesses view to force its load

    header.text = h;
    prompt.text = p;

    if(m != 0) [iconMediaView setMedia:[_MODEL_MEDIA_ mediaForId:m]];
    else [iconMediaView setImage:[UIImage imageNamed:@"todo"]];
}

- (void) requestDismiss
{
    [delegate popOverRequestsDismiss];
}

- (void) requestSubmit
{
    [delegate popOverRequestsSubmit];
}

@end
