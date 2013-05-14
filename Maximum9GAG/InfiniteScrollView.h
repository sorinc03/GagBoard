//
//  InfiniteScrollView.h
//  Maximum9GAG
//
//  Created by Sorin Cioban on 25/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "FBConnect.h"

@interface InfiniteScrollView : UIScrollView <UIScrollViewDelegate, UIGestureRecognizerDelegate, UIAlertViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, FBSessionDelegate, FBRequestDelegate, FBDialogDelegate> {
    NSString                *url;
    NSUInteger              *urlLength;
    NSMutableArray          *gagSet;
    UITapGestureRecognizer  *viewButtons;
    UITapGestureRecognizer  *hideView;
}

@property (nonatomic, strong) UITapGestureRecognizer *viewButtons;
@property (nonatomic, strong) UITapGestureRecognizer *hideView;
@property (nonatomic, strong) NSString *url;
@property (nonatomic) NSUInteger *urlLength;
@property (nonatomic, strong) NSMutableArray *gagSet;
- (id)initWithFrame:(CGRect)frame andURL:(NSString *)mainURL;
- (void)insertImage:(UIImageView *)imageView;
- (void)getNextImages:(NSString *)imageID;

@end
