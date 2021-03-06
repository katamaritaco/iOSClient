//
//  ARISTemplate.m
//  ARIS
//
//  Created by Phil Dougherty on 1/8/14.
//
//

#import "ARISTemplate.h"

@implementation ARISTemplate

+ (UIColor *) ARISColorNavBarTint             { return [UIColor ARISColorTranslucentWhite]; }
+ (UIColor *) ARISColorNavBarText             { return [UIColor ARISColorBlack]; }
+ (UIColor *) ARISColorTabBarTint             { return [UIColor ARISColorWhite]; }
+ (UIColor *) ARISColorTabBarText             { return [UIColor ARISColorBlack]; }
+ (UIColor *) ARISColorToolBarTint            { return [UIColor ARISColorWhite]; }
+ (UIColor *) ARISColorBarButtonTint          { return [UIColor ARISColorLightBlue]; }
+ (UIColor *) ARISColorSegmentedControlTint   { return [UIColor ARISColorWhite]; }
+ (UIColor *) ARISColorSearchBarTint          { return [UIColor ARISColorWhite]; }
+ (UIColor *) ARISColorHighlightedText        { return [UIColor ARISColorLightBlue]; }

+ (UIColor *) ARISColorTextBackdrop           { return [UIColor ARISColorTranslucentWhite]; }
+ (UIColor *) ARISColorText                   { return [UIColor ARISColorBlack]; }
+ (UIColor *) ARISColorContentBackdrop        { return [UIColor ARISColorWhite]; }
+ (UIColor *) ARISColorViewBackdrop           { return [UIColor ARISColorWhite]; }
+ (UIColor *) ARISColorViewText               { return [UIColor ARISColorBlack]; }
+ (UIColor *) ARISColorSideNavigationBackdrop { return [UIColor ARISColorWhite];  }
+ (UIColor *) ARISColorSideNavigationText     { return [UIColor ARISColorBlack]; }

+ (UIFont *) ARISDefaultFont       { return [UIFont fontWithName:@"HelveticaNeue-Light" size:17]; }
+ (UIFont *) ARISNavTitleFont      { return [UIFont fontWithName:@"HelveticaNeue-Light" size:17]; }
+ (UIFont *) ARISNavButtonFont     { return [UIFont fontWithName:@"HelveticaNeue-Light" size:17]; }
+ (UIFont *) ARISTabTitleFont      { return [UIFont fontWithName:@"HelveticaNeue-Light" size:0]; }
+ (UIFont *) ARISCellTitleFont     { return [UIFont fontWithName:@"HelveticaNeue" size:17]; }
+ (UIFont *) ARISCellBoldTitleFont { return [UIFont fontWithName:@"HelveticaNeue-Bold" size:17]; }
+ (UIFont *) ARISCellSubtextFont   { return [UIFont fontWithName:@"HelveticaNeue-Light" size:13]; }
+ (UIFont *) ARISButtonFont        { return [UIFont fontWithName:@"HelveticaNeue-Light" size:17]; }
+ (UIFont *) ARISTitleFont         { return [UIFont fontWithName:@"HelveticaNeue-Light" size:17]; }
+ (UIFont *) ARISBodyFont          { return [UIFont fontWithName:@"HelveticaNeue-Light" size:17]; }
+ (UIFont *) ARISLabelFont         { return [UIFont fontWithName:@"HelveticaNeue-Light" size:17]; }
+ (UIFont *) ARISSubtextFont       { return [UIFont fontWithName:@"HelveticaNeue-Light" size:13]; }
+ (UIFont *) ARISInputFont         { return [UIFont fontWithName:@"HelveticaNeue-Light" size:17]; }
+ (UIFont *) ARISAnnotFont         { return [UIFont fontWithName:@"HelveticaNeue-Light" size:13]; }

+ (NSString *) ARISHtmlTemplate
{
    return
    @"<html>"
    @"<head>"
    @"  <style type='text/css'><!--"
    @"  html { margin:0; padding:0; }"
    @"  body {"
    @"      color:#000000;"
    @"      font-size:15px;"
    @"      font-family:HelveticaNeue-Light;"
    @"      margin:0;"
    @"      padding:10;"
    @"  }"
    @"  a { color: #000000; text-decoration: underline; }"
    @"  --></style>"
    @"</head>"
    @"<body>%@</body>"
    @"</html>";
}

@end
