//
//  IconQuestsViewController.m
//  ARIS
//
//  Created by Jacob Hanshaw on 9/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "IconQuestsViewController.h"

static NSString * const OPTION_CELL = @"quest";
static int const ACTIVE_SECTION = 0;
static int const COMPLETED_SECTION = 1;
int itemsPerColumnWithoutScrolling;
int initialHeight;

NSString *const kIconQuestsHtmlTemplate = 
@"<html>"
@"<head>"
@"	<title>Aris</title>"
@"	<style type='text/css'><!--"
@"	body {"
@"		background-color: #E9E9E9;"
@"		color: #000000;"
@"		font-family: Helvetia, Sans-Serif;"
@"		margin: 0;"
@"	}"
@"	h1 {"
@"		color: #000000;"
@"		font-size: 18px;"
@"		font-style: bold;"
@"		font-family: Helvetia, Sans-Serif;"
@"		margin: 0 0 10 0;"
@"	}"
@"	--></style>"
@"</head>"
@"<body></div><div style=\"position:relative; top:0px; background-color:#DDDDDD; border-style:ridge; border-width:3px; border-radius:11px; border-color:#888888;padding:15px;\"><h1>%@</h1>%@</div></body>"
@"</html>";

@implementation IconQuestsViewController

@synthesize quests, isLink, activeSort;

//Override init for passing title and icon to tab bar
- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle
{
    self = [super initWithNibName:nibName bundle:nibBundle];
    if (self) {
        self.title = @"Icon Quests";// NSLocalizedString(@"QuestViewTitleKey",@"");
        self.tabBarItem.image = [UIImage imageNamed:@"117-todo"];
        activeSort = 1;
		self.isLink = NO;
		//register for notifications
		NSNotificationCenter *dispatcher = [NSNotificationCenter defaultCenter];
        [dispatcher addObserver:self selector:@selector(removeLoadingIndicator) name:@"ConnectionLost" object:nil];
		[dispatcher addObserver:self selector:@selector(removeLoadingIndicator) name:@"ReceivedQuestList" object:nil];
		[dispatcher addObserver:self selector:@selector(refreshViewFromModel) name:@"NewQuestListReady" object:nil];
		[dispatcher addObserver:self selector:@selector(silenceNextUpdate) name:@"SilentNextUpdate" object:nil];
    }
	
    return self;
}

- (void)silenceNextUpdate {
	silenceNextServerUpdateCount++;
	NSLog(@"IconQuestsViewController: silenceNextUpdate. Count is %d",silenceNextServerUpdateCount );
    
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];

	NSLog(@"IconQuestsViewController: Quests View Loaded");
	
}

-(void)loadView{
    [super loadView];
    
    CGRect fullScreenRect=CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    UIScrollView *scrollView=[[UIScrollView alloc] initWithFrame:fullScreenRect];
    scrollView.contentSize=CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
    initialHeight = self.view.frame.size.height;
    itemsPerColumnWithoutScrolling = self.view.frame.size.height/ICONHEIGHT + .5;
    itemsPerColumnWithoutScrolling--;
    
    self.view=scrollView;
}

- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"IconQuestsViewController: viewDidAppear");
    
    if (![AppModel sharedAppModel].loggedIn || [AppModel sharedAppModel].currentGame.gameId==0) {
        NSLog(@"QuestsVC: Player is not logged in, don't refresh");
        return;
    }
    
	[[AppServices sharedAppServices] updateServerQuestsViewed];
	
	[self refresh];
	
	self.tabBarItem.badgeValue = nil;
	newItemsSinceLastView = 0;
	silenceNextServerUpdateCount = 0;
    
}

-(void)dismissTutorial{
	[[RootViewController sharedRootViewController].tutorialViewController dismissTutorialPopupWithType:tutorialPopupKindQuestsTab];
}

- (void)refresh {
	NSLog(@"IconQuestsViewController: refresh requested");
	if ([AppModel sharedAppModel].loggedIn) [[AppServices sharedAppServices] fetchQuestList];
	[self showLoadingIndicator];
}


-(void)showLoadingIndicator{
	UIActivityIndicatorView *activityIndicator = 
    [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	UIBarButtonItem * barButton = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
	[[self navigationItem] setRightBarButtonItem:barButton];
	[activityIndicator startAnimating];
}

-(void)removeLoadingIndicator{
	[[self navigationItem] setRightBarButtonItem:nil];
	NSLog(@"IconQuestsViewController: removeLoadingIndicator");
}

-(void)refreshViewFromModel {
	NSLog(@"IconQuestsViewController: Refreshing view from model");
	
    ARISAppDelegate* appDelegate = (ARISAppDelegate *)[[UIApplication sharedApplication] delegate];
//	progressLabel.text = [NSString stringWithFormat:@"%d %@ %d %@", [AppModel sharedAppModel].currentGame.completedQuests, NSLocalizedString(@"OfKey", @"Number of Number"), [AppModel sharedAppModel].currentGame.totalQuests, NSLocalizedString(@"QuestsCompleteKey", @"")];
//	progressView.progress = (float)[AppModel sharedAppModel].currentGame.completedQuests / (float)[AppModel sharedAppModel].currentGame.totalQuests;
    
	NSLog(@"IconQuestsViewController: refreshViewFromModel: silenceNextServerUpdateCount = %d", silenceNextServerUpdateCount);
	
	//Update the badge
	if (silenceNextServerUpdateCount < 1) {
		//Check if anything is new since last time
		int newItems = 0;
		NSArray *newActiveQuestsArray = [[AppModel sharedAppModel].questList objectForKey:@"active"];
		for (Quest *quest in newActiveQuestsArray) {		
			BOOL match = NO;
			for (Quest *existingQuest in [self.quests objectAtIndex:ACTIVE_SECTION]) {
				if (existingQuest.questId == quest.questId) match = YES;	
			}
			if (match == NO) {
				newItems ++;;
                quest.sortNum = activeSort;
                activeSort++;
                
                [[RootViewController sharedRootViewController] enqueueNotificationWithFullString:[NSString stringWithFormat:@"%@ %@", quest.name, NSLocalizedString(@"QuestsViewNewQuestsKey", @"")]
                                                                                 andBoldedString:quest.name];

			}
		}
        
        NSArray *newCompletedQuestsArray = [[AppModel sharedAppModel].questList objectForKey:@"completed"];
        
        for (Quest *quest in newCompletedQuestsArray) {		
			BOOL match = NO;
			for (Quest *existingQuest in [self.quests objectAtIndex:COMPLETED_SECTION]) {
				if (existingQuest.questId == quest.questId) match = YES;	
			}
			if (match == NO) {
                [appDelegate playAudioAlert:@"inventoryChange" shouldVibrate:YES];
                
                
                [[RootViewController sharedRootViewController] enqueueNotificationWithFullString:[NSString stringWithFormat:@"%@ %@", quest.name, NSLocalizedString(@"QuestsViewQuestCompletedKey", @"")]
                                                                                 andBoldedString:quest.name];

			}
		}
        
		if (newItems > 0) {
			newItemsSinceLastView += newItems;
			self.tabBarItem.badgeValue = [NSString stringWithFormat:@"%d",newItemsSinceLastView];
			
			if (![AppModel sharedAppModel].hasSeenQuestsTabTutorial){
                //Put up the tutorial tab
				[[RootViewController sharedRootViewController].tutorialViewController showTutorialPopupPointingToTabForViewController:self.navigationController 
                                                                                                                                 type:tutorialPopupKindQuestsTab 
                                                                                                                                title:NSLocalizedString(@"QuestViewNewQuestKey", @"")
                                                                                                                              message:NSLocalizedString(@"QuestViewNewQuestMessageKey", @"")];
				[AppModel sharedAppModel].hasSeenQuestsTabTutorial = YES;
                [self performSelector:@selector(dismissTutorial) withObject:nil afterDelay:5.0];
			}
		}
		else if (newItemsSinceLastView < 1) self.tabBarItem.badgeValue = nil;
	}
	else {
		newItemsSinceLastView = 0;
		self.tabBarItem.badgeValue = nil;
	}
	
	//rebuild the list
	NSArray *activeQuestsArray = [[AppModel sharedAppModel].questList objectForKey:@"active"];
	NSArray *completedQuestsArray = [[AppModel sharedAppModel].questList objectForKey:@"completed"];
	
	self.quests = [NSArray arrayWithObjects:activeQuestsArray, completedQuestsArray, nil];
    
	[self createIcons];
	
	if (silenceNextServerUpdateCount>0) silenceNextServerUpdateCount--;
    
}

-(void)createIcons{
	NSLog(@"IconQuestsVC: Constructing Icons");
    
    for (UIView *view in [self.view subviews]) {
        [view removeFromSuperview];
    }
	
	NSArray *activeQuests = [self.quests objectAtIndex:ACTIVE_SECTION];
	NSArray *completedQuests = [self.quests objectAtIndex:COMPLETED_SECTION];
    
    NSLog(@"Self frame: %f, %f", self.view.frame.size.width, self.view.frame.size.height);
    
    for(int i = 0; i < [activeQuests count]; i++){
        Quest *currentQuest = [activeQuests objectAtIndex:i];
        int xMargin = truncf((self.view.frame.size.width - ICONSPERROW * ICONWIDTH)/(ICONSPERROW +1));
        int yMargin = truncf((initialHeight - itemsPerColumnWithoutScrolling * ICONHEIGHT)/(itemsPerColumnWithoutScrolling + 1));
        int row = (i/ICONSPERROW);
        int xOrigin = (i % ICONSPERROW) * (xMargin + ICONWIDTH) + xMargin;
        int yOrigin = row * (yMargin + ICONHEIGHT) + yMargin;
        
        UIImage *iconImage;
        if(currentQuest.iconMediaId != 0){
          Media *iconMedia = [[AppModel sharedAppModel] mediaForMediaId: currentQuest.iconMediaId];
          iconImage = [UIImage imageWithData:iconMedia.image];
        }
        else iconImage = [UIImage imageNamed:@"item.png"];
        IconQuestsButton *iconButton = [[IconQuestsButton alloc] initWithFrame:CGRectMake(xOrigin, yOrigin, ICONWIDTH, ICONHEIGHT) andImage:iconImage andTitle:currentQuest.name];
        iconButton.tag = i;
        [iconButton addTarget:self action:@selector(questSelected:) forControlEvents:UIControlEventTouchUpInside];
        iconButton.imageView.layer.cornerRadius = 9.0;
        [self.view addSubview:iconButton];
        [iconButton setNeedsDisplay];
    }
    
    int currentButtonIndex = [activeQuests count];
    
    for(int i = 0; i < [completedQuests count]; i++){
        Quest *currentQuest = [completedQuests objectAtIndex:i];
        int xMargin = truncf((self.view.frame.size.width - ICONSPERROW * ICONWIDTH)/(ICONSPERROW +1));
        int yMargin = truncf((initialHeight - itemsPerColumnWithoutScrolling * ICONHEIGHT)/(itemsPerColumnWithoutScrolling + 1));
        int row = (currentButtonIndex/ICONSPERROW);
        int xOrigin = (currentButtonIndex % ICONSPERROW) * (xMargin + ICONWIDTH) + xMargin;
        int yOrigin = row * (yMargin + ICONHEIGHT) + yMargin;
        
        UIImage *iconImage;
        if(currentQuest.iconMediaId != 0){
            Media *iconMedia = [[AppModel sharedAppModel] mediaForMediaId: currentQuest.iconMediaId];
            iconImage = [UIImage imageWithData:iconMedia.image];
        }
        else iconImage = [UIImage imageNamed:@"item.png"];
        IconQuestsButton *iconButton = [[IconQuestsButton alloc] initWithFrame:CGRectMake(xOrigin, yOrigin, 76, 91) andImage:iconImage andTitle:currentQuest.name];
        iconButton.tag = currentButtonIndex;
        [iconButton addTarget:self action:@selector(questSelected:) forControlEvents:UIControlEventTouchUpInside];
        iconButton.imageView.layer.cornerRadius = 9.0;
        [self.view addSubview:iconButton];
        [iconButton setNeedsDisplay];
        currentButtonIndex++;
    }
	
	NSLog(@"QuestsVC: Icons created");
}

- (void) questSelected: (id)sender {
    UIButton *button = (UIButton*)sender;
    
    NSArray *activeQuests = [self.quests objectAtIndex:ACTIVE_SECTION];
	NSArray *completedQuests = [self.quests objectAtIndex:COMPLETED_SECTION];
    
    Quest *questSelected;
    if(button.tag >= [activeQuests count]){
       button.tag -= [activeQuests count];
       questSelected = [completedQuests objectAtIndex:button.tag];
    }
    else questSelected = [activeQuests objectAtIndex:button.tag];
    QuestDetailsViewController *questDetailsViewController =[[QuestDetailsViewController alloc] initWithQuest: questSelected];
 //   UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:questDetailsViewController];
 //   [self presentViewController:navigationController animated:YES completion:nil];
    [self presentViewController:questDetailsViewController animated:YES completion:nil];
}

- (BOOL)webView:(UIWebView *)webView  
shouldStartLoadWithRequest:(NSURLRequest *)request  
 navigationType:(UIWebViewNavigationType)navigationType; {  
	
    /* NSURL *requestURL = [ [ request URL ] retain ];
     if ( ( [ [ requestURL scheme ] isEqualToString: @"http" ]  
     || [ [ requestURL scheme ] isEqualToString: @"https" ] )  
     && ( navigationType == UIWebViewNavigationTypeLinkClicked ) ) {  
     return ![ [ UIApplication sharedApplication ] openURL: [ requestURL autorelease ] ];  
     }  */
    if(self.isLink && ![[[request URL]absoluteString] isEqualToString:@"about:blank"]) {
        webpageViewController *webPageViewController = [[webpageViewController alloc] initWithNibName:@"webpageViewController" bundle: [NSBundle mainBundle]];
        WebPage *temp = [[WebPage alloc]init];
        temp.url = [[request URL]absoluteString];
        webPageViewController.webPage = temp;
        webPageViewController.delegate = self;
        [self.navigationController pushViewController:webPageViewController animated:NO];
        
        return NO;
    }
    else{
        self.isLink = YES;
        return YES;}
    
	// Check to see what protocol/scheme the requested URL is.  
	
	// Auto release  
	//[ requestURL release ];  
	// If request url is something other than http or https it will open  
	// in UIWebView. You could also check for the other following  
	// protocols: tel, mailto and sms  
	//return YES;  
} 



- (void)webViewDidFinishLoad:(UIWebView *)webView {
	
	NSLog(@"IconQuestsViewController: VebView loaded");
    
    //[self performSelector:@selector(updateCellSizes) withObject:nil afterDelay:0.1];
}

/*-(void)updateCellSize:(UITableViewCell*)cell {
	NSLog(@"QuestViewController: Updating Cell Sizes");
    
	UIWebView *descriptionView = (UIWebView *)[cell viewWithTag:1];
	float newHeight = [[descriptionView stringByEvaluatingJavaScriptFromString:@"document.body.offsetHeight;"] floatValue];
	
	NSLog(@"QuestViewController: Description View Calculated Height is: %f",newHeight);
    
	
	CGRect descriptionFrame = [descriptionView frame];	
	descriptionFrame.size = CGSizeMake(descriptionFrame.size.width,newHeight);
	[descriptionView setFrame:descriptionFrame];
	[[[descriptionView subviews] lastObject] setScrollEnabled:NO];
	NSLog(@"QuestViewController: description UIWebView frame set to {%f, %f, %f, %f}", 
		  descriptionFrame.origin.x, 
		  descriptionFrame.origin.y, 
		  descriptionFrame.size.width,
		  descriptionFrame.size.height);
	
	CGRect cellFrame = [cell frame];
	cellFrame.size = CGSizeMake(cell.frame.size.width,newHeight + 25);
	[cell setFrame:cellFrame];
    
	NSLog(@"QuestViewController: cell frame set to {%f, %f, %f, %f}", 
		  cell.frame.origin.x, 
		  cell.frame.origin.y, 
		  cell.frame.size.width,
		  cell.frame.size.height);
} */


//	NSString *htmlDescription = [NSString stringWithFormat:kQuestsHtmlTemplate, quest.name, quest.description];


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

@end
