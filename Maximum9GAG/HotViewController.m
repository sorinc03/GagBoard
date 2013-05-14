//
//  HotViewController.m
//  Maximum9GAG
//
//  Created by Sorin Cioban on 27/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "HotViewController.h"
#import "InfiniteScrollView.h"

@interface HotViewController () {
    
}

@end

@implementation HotViewController

HotViewController *gagViewController;
InfiniteScrollView *scrollView;

@synthesize activityIndicator, bannerView, images, url, showFavs, refresh, backButton, downloadQueue, oq;

- (void)getGagsFromUrl:(NSString *)gagURL {
    NSURLRequest *getSourceCode;
    NSData *returnData;
    NSString *output;
    
    self.oq = [[NSOperationQueue alloc] init];
    [self.oq setName:@"imageQueue"];
    [self.oq setMaxConcurrentOperationCount:15];
    
    getSourceCode = [NSURLRequest requestWithURL:[NSURL URLWithString:gagURL]
                                     cachePolicy:NSURLRequestUseProtocolCachePolicy
                                 timeoutInterval:60.0];
    
    returnData = [NSURLConnection sendSynchronousRequest:getSourceCode 
                                       returningResponse:nil 
                                                   error:nil];
    
    output = [[NSString alloc] initWithData:returnData 
                                   encoding:NSUTF8StringEncoding];
    
    NSString *imageID = [self getFirstImage:output];
    [self.images addObject:imageID];
    [self addImageToView:imageID];
    
    [self loadImagesOneByOne:imageID];
}

- (void)loadImagesOneByOne:(NSString *)startID {
    __block NSString *imageID = nil;
    __block int count = 0;
    self.downloadQueue = [[NSOperationQueue alloc] init];
    [self.downloadQueue setName:@"Download Queue"];
    [self.downloadQueue setMaxConcurrentOperationCount:2];
    [self.downloadQueue addOperationWithBlock:^{
        
        while (count < 20 && !self.downloadQueue.isSuspended) {
            //NSLog(@"COUNT: %d", count);
            if (count == 0) {
                imageID = startID;
            }
            
            else {
                imageID = [self getNextImageID:imageID];
            }
            
            if (![self.images containsObject:imageID] && ![imageID isEqualToString:@""]) {
                [self.images addObject:imageID];
                
                [self addImageToView:imageID];
                
                
            }
            count++;
        }
    }];
    
    [UIView animateWithDuration:0.5
                     animations:^{
                         self.activityIndicator.alpha = 0.0;
                     }
                     completion:^(BOOL finished){
                         [self.activityIndicator removeFromSuperview];
                         self.refresh.alpha = 0.5;
                     }];
    [self.activityIndicator removeFromSuperview];
    [self.refresh setAlpha:0.5];
}

- (void)addImageToView:(NSString *)imageID {
    NSString *imageLink = [NSString stringWithFormat:@"http://d24w6bsrhbeh9d.cloudfront.net/photo/%@_460s.jpg", imageID];
    NSURL *imageURL = [NSURL URLWithString:imageLink];
    
    if (!self.oq.isSuspended) {
        __weak ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:imageURL];
        [request setDelegate: self];
        [request setDidFinishSelector:@selector(putUpImage:)];
        [request setDidFailSelector:@selector(imageLoadFailed:)];
        [self.oq addOperation:request];
        if (self.images.count == 19)
            [scrollView getNextImages:imageID];
    }
}

- (void)putUpImage:(ASIHTTPRequest *)request {
    NSData *responseData = [request responseData];
    
    if (responseData) {
        UIImage *gag = [UIImage imageWithData:responseData];
        CGFloat aspectRatio = gag.size.width/gag.size.height;
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (!isnan(aspectRatio)) {
                CGFloat x = 150 * (self.images.count%5);
                UIImageView *gagContainer = [[UIImageView alloc] initWithFrame:CGRectMake(x, [self findCorrectY:x], 150, 150/aspectRatio)];
                [gagContainer setBackgroundColor:[UIColor clearColor]];
                [gagContainer setImage:gag];
                
                [scrollView insertImage:gagContainer];
            }
        }];
    }
}

- (void)imageLoadFailed:(ASIHTTPRequest *)request {
    NSError *error = [request error];
    NSLog(@"%@", error);
}

- (CGFloat)findCorrectY:(CGFloat)x {
    CGFloat y = 300;
    
    UIView *view = [scrollView.subviews objectAtIndex:0];
    
    for (UIImageView *gagContainer in view.subviews) {
        CGRect frame = gagContainer.frame;
        
        if ((int)x == (int)frame.origin.x) {
            if (frame.origin.y+frame.size.height > y) {
                y = frame.origin.y + frame.size.height;
            }
        }
    }
    
    return y;
}

- (NSString *)getNextImageID:(NSString *)imageID {
    NSString *nextURL =  nil;
    NSString *ident = @"";
    if (imageID) {
        nextURL = [NSString stringWithFormat:@"http://m.9gag.com/read/go?id=%@&dir=next&list=%@", imageID, self.url];
        
        NSURLRequest *getSourceCode;
        NSData *returnData;
        NSString *output;
        
        getSourceCode = [NSURLRequest requestWithURL:[NSURL URLWithString:nextURL]
                                         cachePolicy:NSURLRequestUseProtocolCachePolicy
                                     timeoutInterval:60.0];
    
        returnData = [NSURLConnection sendSynchronousRequest:getSourceCode 
                                           returningResponse:nil 
                                                       error:nil];
    
        output = [[NSString alloc] initWithData:returnData 
                                       encoding:NSUTF8StringEncoding];
        
        NSRange initialRange = [output rangeOfString:@".cloudfront.net/photo/"];
        if ([self rangeValid:initialRange]) {
            output = [output substringFromIndex:initialRange.location+initialRange.length];
            
            NSRange tagRange = [output rangeOfString:@"_"];
            NSRange jpgRange = [output rangeOfString:@"jpg"];
            BOOL looking = [self rangeValid:tagRange] && [self rangeValid:jpgRange];
            
            if (looking) {
                if (tagRange.location > jpgRange.location)
                    output = [output substringToIndex:jpgRange.location];
                else
                    output = [output substringToIndex:tagRange.location];
            
                ident = output;
            }
            else {
                [self showAlert];
            }
        }
        
        else {
            //[self showAlert];
            return @"";
        }
    }
    return ident;
}

- (BOOL)rangeValid:(NSRange)range {
    return range.location != INT_MAX;
}

- (NSString *)getFirstImage:(NSString *)text {    
    return [self getCorrectStringFrom:text start:@"/gag/" end:@"\" onclick="];
}

- (NSString *)getJPEGForImage:(NSString *)photoURL {
    NSString *actualPhoto = [NSString stringWithFormat:@"http://m.9gag.com%@", photoURL];
    NSURLRequest *getSourceCode;
    NSData *returnData;
    NSString *output;
    
    getSourceCode = [NSURLRequest requestWithURL:[NSURL URLWithString:actualPhoto]
                                     cachePolicy:NSURLRequestUseProtocolCachePolicy
                                 timeoutInterval:60.0];
    
    returnData = [NSURLConnection sendSynchronousRequest:getSourceCode 
                                       returningResponse:nil 
                                                   error:nil];
    
    output = [[NSString alloc] initWithData:returnData 
                                   encoding:NSUTF8StringEncoding];
    
    NSString *start = @"<img src=\"";
    NSString *end   = @"\" alt=";
    
    return [self getCorrectStringFrom:output start:start end:end];
}

- (NSString *)getCorrectStringFrom:(NSString *)text
                             start:(NSString *)start
                               end:(NSString *)end {
    
    NSRange initialRange = [text rangeOfString:start];
    if ([self rangeValid:initialRange]) {
        text = [text substringFromIndex:initialRange.location + initialRange.length];
        
        NSRange finalRange = [text rangeOfString:end];
        if ([self rangeValid:finalRange])
            text = [text substringToIndex:finalRange.location];
        else {
            [self showAlert];
            return @"";
        }
    }
    
    else {
        [self showAlert];
        return @"";
    }

    return text;
}

- (void)showAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info!!" 
                                                    message:@"An error has occured, please make sure your internet connection is working, then try again."  
                                                   delegate:self 
                                          cancelButtonTitle:@"FUUUUUUU" 
                                          otherButtonTitles: nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)getRelevantTextfromBody:(NSString*)text 
                      fromStart:(NSString*)start 
                          toEnd:(NSString*)end 
{
    
    NSRange initialRange = [text rangeOfString:start];
    if (initialRange.location != INT_MAX) {
        NSRange finalRange = [text rangeOfString:end];
        
        NSString *newText = [text substringToIndex:finalRange.location+3];
        text = [text stringByReplacingOccurrencesOfString:newText withString:@""];
        newText = [newText substringFromIndex:initialRange.location];
        
        initialRange = [newText rangeOfString:@"http"];
        
        newText = [newText substringFromIndex:initialRange.location];
        
        [self.images addObject:newText];
        
        [self getRelevantTextfromBody:text fromStart:start toEnd:end];
    }    
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidAppear:(BOOL)animated {
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"dark_linen-640x960.png"]]];
    
    gagViewController = self;
    
    CGFloat height = [[UIScreen mainScreen] bounds].size.height;
    if (height > 480)
        [self moveButtonsToAdjustForScreen];
    
    [self setUpScroll];
    
    
    [self showAd];
    /*
    [self.view insertSubview:refresh aboveSubview:scrollView];
    [self.view insertSubview:backButton aboveSubview:scrollView];*/
    
    
    
    // Do any additional setup after loading the view from its nib.
}

- (void)moveButtonsToAdjustForScreen {
    CGFloat height = [[UIScreen mainScreen] bounds].size.height;
    CGRect frame = self.refresh.frame;
    frame.origin.y = height-45;
    
    self.refresh.frame = frame;
    
    frame = self.backButton.frame;
    frame.origin.y = height-45;
    
    self.backButton.frame = frame;
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error {
    NSLog(@"%@", error);
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {
    NSLog(@"%@", error);
}

- (void)showAd {
    CGFloat height = [[UIScreen mainScreen] bounds].size.height;
    CGRect refreshFrame = CGRectMake(267, height-95, 41, 40);
    CGRect backButtonFrame = CGRectMake(218, height-95, 41, 40);
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    NSString *value = [prefs stringForKey:@"com.appetizerinc.noads"];
    
    self.bannerView.delegate = self;
    
    if (![value isEqualToString:@"Yes"]) {
        self.bannerView.hidden = FALSE;
        
        self.bannerView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner];
        self.bannerView.frame = CGRectMake(0, height-50, 320, 50);
        
        self.bannerView.adUnitID = @"dd8665e84f1642ac";
        
        self.bannerView.rootViewController = self;
        
        [self.bannerView removeFromSuperview];
        [self.view insertSubview:self.bannerView atIndex:1];
        
        // Initiate a generic request to load it with an ad.
        [self.bannerView loadRequest:[GADRequest request]];
    }
    
    else {
        [self.bannerView removeFromSuperview];
        
        refreshFrame.origin.y += 50;
        backButtonFrame.origin.y += 50;
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        self.refresh.frame = refreshFrame;
        self.activityIndicator.frame = self.refresh.frame;
        self.backButton.frame = backButtonFrame;
    }];
}

- (void)setUpScroll {
    CGFloat height = [[UIScreen mainScreen] bounds].size.height;
    self.images = [[NSMutableArray alloc] init];
    
    [scrollView removeFromSuperview];
    scrollView = [[InfiniteScrollView alloc] initWithFrame:CGRectMake(0, 0, 320, height) andURL:self.url];
    scrollView.clipsToBounds = YES;
    
    [self.view insertSubview:scrollView atIndex:0];
    
    if (self.showFavs == NO)
        [self showWaiting];
    
    [scrollView setContentOffset:CGPointMake(200, height-80)];
    
    if (self.showFavs == NO) {
        NSString *actualURL = [NSString stringWithFormat:@"http://m.9gag.com/%@", self.url];
        
        [self performSelectorInBackground:@selector(getGagsFromUrl:) withObject:actualURL];
    }
    
    if (self.showFavs == YES) {
        [self loadFavorites];
    }
}

- (void)loadFavorites {    
    CGFloat x = 0;
    CGFloat y = 0;    
    
    int count = 0;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(
                                                         NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:documentsDirectory];
    
    for (NSString *path in directoryEnumerator) {
        if ([[path pathExtension] isEqualToString:@"jpeg"]) {
            x = 150 * (count % 3);
            y = [self findCorrectY:x];
            //NSLog(@"(x,y)=(%.0f, %.0f)", x, y);
            
            NSString *actualPath = [documentsDirectory stringByAppendingPathComponent:path];
            //NSLog(@"%@", actualPath);
            UIImage *gag = [UIImage imageWithContentsOfFile:actualPath];
            
            CGFloat aspectRatio = gag.size.width/gag.size.height;
            CGFloat height = 150/aspectRatio;
            
            if(!isnan(height)) {
                UIImageView *gagView = [[UIImageView alloc] initWithFrame:CGRectMake(x, y, 150, height)];
                gagView.alpha = 0.0;
                [gagView setImage:gag];
                [gagView setBackgroundColor:[UIColor clearColor]];
                
                [scrollView insertImage:gagView];
                
                [UIView animateWithDuration:0.3
                                 animations:^{
                                     gagView.alpha = 1.0;
                                 }];
                
                count++;
            }
        }
    }
}

- (void)showWaiting {
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
    
    [self.activityIndicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.activityIndicator setColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"animation.png"]]];
    [self.activityIndicator setCenter:self.refresh.center];
    [self.activityIndicator startAnimating];
    [self.refresh setAlpha:0.0];
    [self.view addSubview:self.activityIndicator];
}

- (IBAction)goBack:(id)sender {
    [self cancelDownloads];
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)refresh:(id)sender {
    [self cancelDownloads];
    [self setUpScroll];
}

- (void)cancelDownloads {
    [self.downloadQueue cancelAllOperations];
    [self.downloadQueue setSuspended:YES];
    [self.oq setSuspended:YES];
    [self.oq cancelAllOperations];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
