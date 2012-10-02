//
//  GlobalPlayerViewController.m
//  ARIS
//
//  Created by Phil Dougherty on 9/21/12.
//
//

#import "GlobalPlayerViewController.h"

@implementation GlobalPlayerViewController

@synthesize playerPic;
@synthesize playerNameField;
@synthesize playerPicOpt1;
@synthesize playerPicOpt2;
@synthesize playerPicOpt3;
@synthesize playerPicCam;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    playerPicOpt1.delegate = self;
    playerPicOpt2.delegate = self;
    playerPicOpt3.delegate = self;
    playerPicCam.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    if([AppModel sharedAppModel].userName)
        playerNameField.text = [AppModel sharedAppModel].userName;
    [playerPicOpt1 loadImageFromMedia:[[AppModel sharedAppModel] mediaForMediaId:39715]];
    [playerPicOpt2 loadImageFromMedia:[[AppModel sharedAppModel] mediaForMediaId:39716]];
    [playerPicOpt3 loadImageFromMedia:[[AppModel sharedAppModel] mediaForMediaId:39717]];
    [playerPicCam loadImageFromMedia:[[AppModel sharedAppModel] mediaForMediaId:36]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)playerNameFieldTouched:(id)sender
{
    return;
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

-(id)playerPicOptTouched:(id)sender
{
    return nil;
}

-(IBAction)goButtonTouched:(id)sender
{
    self.parentViewController.view.hidden = true;
    return;
}

-(void)asyncMediaImageTouched:(id)sender
{
    if(sender == self.playerPicCam)
    {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
        {
            UIImagePickerController *picker = [[UIImagePickerController alloc]init];
            picker.delegate = self;
            picker.sourceType = UIImagePickerControllerSourceTypeCamera;
            picker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:picker.sourceType];
            picker.allowsEditing = YES;
            picker.showsCameraControls = YES;
            [self presentModalViewController:picker animated:NO];
        }
    }
    else
        [self.playerPic loadImageFromMedia:[(AsyncMediaImageView *)sender media]];
    return;
}
-(void) imageFinishedLoading{
    return;
}

- (void)imagePickerController:(UIImagePickerController *)aPicker didFinishPickingMediaWithInfo:(NSDictionary  *)info
{
    [aPicker dismissModalViewControllerAnimated:NO];

    UIImage *image;
    NSString *mediaFilePath;
    NSURL *imageURL;
    NSData *mediaData;
    
    image = [info objectForKey:UIImagePickerControllerEditedImage];
    image = [image scaleToSize:CGSizeMake(1024,1024)];
    mediaFilePath =[NSTemporaryDirectory() stringByAppendingString: [NSString stringWithFormat:@"%@image.jpg",[NSDate date]]];
    imageURL = [[NSURL alloc] initFileURLWithPath:mediaFilePath];
    mediaData = UIImageJPEGRepresentation(image, 0.4);
    if (mediaData != nil) [mediaData writeToURL:imageURL atomically:YES];
                
    // If image not selected from camera roll, save image with metadata to camera roll
    if ([info objectForKey:UIImagePickerControllerReferenceURL] == NULL) {
        ALAssetsLibrary *al = [[ALAssetsLibrary alloc] init];
        [al writeImageDataToSavedPhotosAlbum:mediaData metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {                        
            // once image is saved, get asset from assetURL
            [al assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                if (asset) {
                    // save image to temporary directory to be able to upload it
                    ALAssetRepresentation *rep = [asset defaultRepresentation];
                    CGImageRef iref = [rep fullResolutionImage];
                    UIImage *image = [UIImage imageWithCGImage:iref];
                    NSData *imageData = UIImageJPEGRepresentation(image, 0.4);
                    NSString *newFilePath =[NSTemporaryDirectory() stringByAppendingString: [NSString stringWithFormat:@"%@image.jpg",[NSDate date]]];
                    NSURL *imageURL = [[NSURL alloc] initFileURLWithPath: newFilePath];
                    playerPic.image = image;
                    
                    [imageData writeToURL:imageURL atomically:YES];
                    
                    [[[AppModel sharedAppModel] uploadManager] uploadPlayerPicContentwithType:kNoteContentTypePhoto withFileURL:imageURL];
                }
            } failureBlock:^(NSError *error) {
            }];
        }];
    }
    else {
        // image from camera roll
         [[[AppModel sharedAppModel] uploadManager] uploadPlayerPicContentwithType:kNoteContentTypePhoto withFileURL:imageURL];
    }
}


@end