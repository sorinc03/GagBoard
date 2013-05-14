//
//  HotViewController.h
//  Maximum9GAG
//
//  Created by Sorin Cioban on 27/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <iAd/iAd.h>
#import "InfiniteScrollView.h"
#import "GADBannerView.h"
#import "ASIHTTPRequest.h"

@interface HotViewController : UIViewController <GADBannerViewDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate, UIAlertViewDelegate, ADBannerViewDelegate, MFMailComposeViewControllerDelegate, ASIHTTPRequestDelegate> {
    NSString *url;
    NSMutableArray *images;
    UIActivityIndicatorView *activityIndicator;
    UIButton *refresh;
    UIButton *backButton;
    GADBannerView *bannerView;
    NSOperationQueue *downloadQueue;
    NSOperationQueue *oq;
}
@property (nonatomic) BOOL showFavs;
@property (strong) GADBannerView *bannerView;
@property (nonatomic, strong) IBOutlet UIButton *refresh;
@property (nonatomic, strong) IBOutlet UIButton *backButton;
@property (nonatomic, strong) NSMutableArray *images;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) NSOperationQueue *downloadQueue;
@property (nonatomic, strong) NSOperationQueue *oq;
- (void)setUpScroll;


@end

extern HotViewController *gagViewController;
extern InfiniteScrollView *scrollView;
