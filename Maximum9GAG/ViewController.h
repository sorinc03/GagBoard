//
//  ViewController.h
//  Maximum9GAG
//
//  Created by Sorin Cioban on 27/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <iAd/iAd.h>
#import "GADBannerView.h"
#import <StoreKit/StoreKit.h>

@interface ViewController : UIViewController <MFMailComposeViewControllerDelegate, GADBannerViewDelegate, UIGestureRecognizerDelegate, SKProductsRequestDelegate, SKPaymentTransactionObserver, UIAlertViewDelegate, ADBannerViewDelegate> {
    GADBannerView *bannerView;
}
@property (strong) GADBannerView *bannerView;
@property (strong, nonatomic) IBOutlet UIImageView *backgroundView;
@property (nonatomic, strong) IBOutlet UIImageView *splashImage;

@end
