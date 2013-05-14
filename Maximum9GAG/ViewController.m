//
//  ViewController.m
//  Maximum9GAG
//
//  Created by Sorin Cioban on 27/01/2012.
//  Copyright (c) 2012 Appetizer, Inc. All rights reserved.
//

#import "ViewController.h"
#import "HotViewController.h"

@implementation ViewController

@synthesize bannerView;

- (IBAction)getPosts:(UIButton *)sender {
    HotViewController *postViewer = [[HotViewController alloc] initWithNibName:@"HotViewController" bundle:nil];
    
    [postViewer setShowFavs:NO];
    NSString *url = @"";
    
    switch (sender.tag) {
        case 3:
            url = @"hot/";
            break;
        case 6:
            url = @"trending/";
            break;
        case 9:
            url = @"vote/";
            break;
        case 15:
            [postViewer setShowFavs:YES];
            break;
    }
    
    [postViewer setUrl:url];
    [self.navigationController pushViewController:postViewer animated:YES];
    
    [self putLeatherBack];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (IBAction)sendReport:(id)sender {
    MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
    
    mailComposer.mailComposeDelegate = self;
    
    [mailComposer setSubject:@"GAG Board feature request/bug report"];
    
    [mailComposer setToRecipients:[NSArray arrayWithObject:@"appetizer.inc@gmail.com"]];
    
    [mailComposer setMessageBody:@"Here's what I'd like added/fixed in the app:" isHTML:NO];
    
    if (mailComposer) {
        [self presentModalViewController:mailComposer animated:YES];
        [self putLeatherBack];
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 

{	
    UIAlertView *alert ;	// Notifies users about errors associated with the interface
	switch (result)
	{
		case MFMailComposeResultCancelled : 
            alert = [[UIAlertView alloc]initWithTitle:@"Result" message:@"Mail sending has been cancelled." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil]; 
			[alert show];
			break;
            
		case MFMailComposeResultSaved:
            alert = [[UIAlertView alloc]initWithTitle:@"Result" message:@"Report has been saved." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil]; 
			[alert show];
			break;
            
		case MFMailComposeResultSent:
            alert = [[UIAlertView alloc]initWithTitle:@"Result" message:@"Report has been sent. Thanks!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil]; 
			[alert show];
			break;
            
		case MFMailComposeResultFailed:
            alert = [[UIAlertView alloc]initWithTitle:@"Result" message:@"Sending Session Report failed." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil]; 
			[alert show];
			break;
            
		default:
            alert = [[UIAlertView alloc]initWithTitle:@"Result" message:@"Mail could not be sent." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil]; 
			[alert show];
            
			break;
	}
    
	[self dismissModalViewControllerAnimated:YES];
}

- (void)moveButtonsToAdjustForScreen {
    for (UIButton *b in self.view.subviews) {
        if (b.tag == 3 || b.tag == 6 || b.tag == 9 || b.tag == 12) {
            CGRect frame = b.frame;
            frame.origin.y += 40;
            
            b.frame = frame;
        }
    }
    
    CGRect frame = self.backgroundView.frame;
    frame.size.height = [[UIScreen mainScreen] bounds].size.height;
    self.backgroundView.frame = frame;
}

- (void)showSplashFade {
    CGFloat height = [[UIScreen mainScreen] bounds].size.height;
    
    if (height > 480) {
        UIImage *image = [UIImage imageNamed:@"Default-568h"];
        CGRect frame = self.splashImage.frame;
        frame.size.height = height;
        self.splashImage.frame = frame;
        self.splashImage.image = image;
    }
    
    [UIView animateWithDuration:1.3
                     animations:^{
                         self.splashImage.alpha = 0.0;
                     }
                     completion:^(BOOL finished) {
                         [self.splashImage removeFromSuperview];
                     }
     ];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    NSString *value = [prefs stringForKey:@"com.appetizerinc.noads"];
    
    CGFloat height = [[UIScreen mainScreen] bounds].size.height;
    
    [self showSplashFade];
    
    /*
    [UIView animateWithDuration:1.0 animations:^{self.splashImage.alpha = 0.0;}];*/
    
    if (height > 480)
        [self moveButtonsToAdjustForScreen];
    
    if ([value isEqualToString:@"Yes"]) {
        [self.bannerView removeFromSuperview];
    }
    
    else {
        [self showAd];
        
        UIView *removeAd = [[UIView alloc] initWithFrame:CGRectMake(210, -80, 80, 117)];
        removeAd.tag = 101;
        
        UIImageView *leather = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 80, 117)];
        [leather setUserInteractionEnabled:YES];
        [leather setImage:[UIImage imageNamed:@"leather"]];
        
        UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] 
                                           initWithTarget:self 
                                           action:@selector(handleSwipe:)];
        swipe.delegate = self;
        swipe.direction = UISwipeGestureRecognizerDirectionDown;
        [removeAd addGestureRecognizer:swipe];
        [removeAd addSubview:leather];
        
        UIButton *adRemoval = [UIButton buttonWithType:UIButtonTypeCustom];
        adRemoval.frame = CGRectMake(10, 10, 60, 68);
        [adRemoval setBackgroundImage:[UIImage imageNamed:@"tap here"] forState:UIControlStateNormal];
        [adRemoval addTarget:self action:@selector(removeAds:) forControlEvents:UIControlEventTouchUpInside];
        [removeAd insertSubview:adRemoval aboveSubview:leather];
        
        //removeAd.transform = CGAffineTransformRotate(removeAd.transform, 0.01745*2);
        
        [self.view addSubview:removeAd];
    }
    
    NSInteger start = [[NSUserDefaults standardUserDefaults] integerForKey:@"startTimes"];
    
    if (start == 1) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Notice!"
                                                        message:@"This app uses a lot of data. Please make sure your data plan allows for numerous image downloads or stay on Wifi. Also, being on a Wifi network ensures image downloads are faster."
                                                       delegate:self
                                              cancelButtonTitle:@"Understood"
                                              otherButtonTitles:nil];
        [alert show];
    }

	// Do any additional setup after loading the view, typically from a nib.
}

- (void)showAd {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    NSString *value = [prefs stringForKey:@"com.appetizerinc.noads"];
    
    if ([value isEqualToString:@"Yes"]) {
        [self.bannerView removeFromSuperview];
        
        for (UIButton *button in self.view.subviews) {
            CGRect frame = button.frame;
            if (button.tag%3 == 0) {
                frame.origin.y += 14;
                button.frame = frame;
            }
        }
    }
    
    else {
        self.bannerView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner];
        CGFloat height = [[UIScreen mainScreen] bounds].size.height;
        self.bannerView.frame = CGRectMake(0, height-50, 320, 50);
        
        self.bannerView.adUnitID = @"dd8665e84f1642ac";
        self.bannerView.tag = 100;
        
        self.bannerView.rootViewController = self;
        [self.view addSubview:self.bannerView];
        
        // Initiate a generic request to load it with an ad.
        [self.bannerView loadRequest:[GADRequest request]];
    }

}


- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error {
    
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {
    
}


- (IBAction)handleSwipe:(UISwipeGestureRecognizer *)sender {
    if (sender.direction == UISwipeGestureRecognizerDirectionDown) {
        [UIView animateWithDuration:0.5
                              delay:0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:(void (^)(void)) ^{
                             sender.view.transform=CGAffineTransformMakeTranslation(0, 73);
                             
                             for (UIView *view in self.view.subviews) {
                                 if (view.tag != 101 && view.tag != 100) {
                                     view.alpha = 0.5;
                                     [self blurButtons:YES];
                                 }
                             }
                         }
                         completion:^(BOOL finished){
                             sender.view.transform=CGAffineTransformMakeTranslation(0, 73);
                         }];
        
        UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc] 
                                             initWithTarget:self 
                                             action:@selector(passRemoveAds:)];
        swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
        swipeUp.delegate = self;
        [sender.view addGestureRecognizer:swipeUp];
    }
}

- (void)putLeatherBack {
    for (UIView *view in self.view.subviews) {
        if (view.tag == 101) {
            [UIView animateWithDuration:0.3
                                  delay:0
                                options:UIViewAnimationOptionBeginFromCurrentState
                             animations:(void (^)(void)) ^{
                                 view.transform=CGAffineTransformMakeTranslation(0, 0);
                                 
                                 for (UIView *view in self.view.subviews) {
                                     if (view.tag != 101 && view.tag != 100) {
                                         view.alpha = 1.0;
                                         
                                         [self blurButtons:NO];
                                     }
                                 }
                                 
                             }
                             completion:^(BOOL finished){
                                 view.transform=CGAffineTransformMakeTranslation(0, 0);
                             }];
        }
    }
}

- (void)passRemoveAds:(UISwipeGestureRecognizer *)sender {
    if (sender.direction == UISwipeGestureRecognizerDirectionUp) {
        [self putLeatherBack];
        [sender.view removeGestureRecognizer:sender];
    }

}

- (void)blurButtons:(BOOL)value {
    UIImage *image;
    for (UIButton *b in self.view.subviews) {
        int tag = b.tag;
        //NSLog(@"%@", [b backgroundImageForState:UIControlStateNormal].description);
        //NSRange range =
        switch (tag) {
            case 3:
                if (!value)
                    image = [UIImage imageNamed:@"hot button"];
                else
                    image = [UIImage imageNamed:@"hot button blur"];
                [b setBackgroundImage:image forState:UIControlStateNormal];
                break;
                
            case 6:
                if (!value)
                    image = [UIImage imageNamed:@"trending button"];
                else
                    image = [UIImage imageNamed:@"trending button blur"];
                [b setBackgroundImage:image forState:UIControlStateNormal];
                break;
                
            case 9:
                if (!value)
                    image = [UIImage imageNamed:@"vote button"];
                else
                    image = [UIImage imageNamed:@"vote button blur"];
                [b setBackgroundImage:image forState:UIControlStateNormal];
                break;
                
            case 12:
                if (!value)
                    image = [UIImage imageNamed:@"mail us"];
                else
                    image = [UIImage imageNamed:@"mail us blur"];
                [b setBackgroundImage:image forState:UIControlStateNormal];
                break;
            case 15:
                if (!value)
                    image = [UIImage imageNamed:@"newFav"];
                else
                    image = [UIImage imageNamed:@"newFav blur"];
                [b setBackgroundImage:image forState:UIControlStateNormal];
        }
    }
}

- (IBAction)removeAds:(UIButton *)sender {
    [self showStore];
}

- (void)showStore {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    NSString *value = [prefs stringForKey:@"com.appetizerinc.noads"];
    
    if (![value isEqualToString:@"Yes"]) {
        SKPayment *payment = [SKPayment paymentWithProductIdentifier:@"com.appetizerinc.noads"];
        
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
}

- (void)saveData:(NSString *)b {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    [prefs setValue:b forKey:@"com.appetizerinc.noads"];
    
    [prefs synchronize];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    SKProduct *validProduct = nil;
    int count = [response.products count];
    
    if (count > 0) {
        validProduct = [response.products objectAtIndex:0];
    }
    
    else if (count == 0) {
        NSLog(@"No products available");
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing:
                
                break;
                
            case SKPaymentTransactionStatePurchased: {
                [self saveData:@"Yes"];
                
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            }
                
            case SKPaymentTransactionStateRestored: {
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            }
                
            case SKPaymentTransactionStateFailed: {
                if (transaction.error.code != SKErrorPaymentCancelled) {
                    NSLog(@"An error encountered");
                }
                break;
            }
                
        }
    }
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation == UIInterfaceOrientationPortrait);
    } else {
        return YES;
    }
}

@end
