//
//  InfiniteScrollView.m
//  Maximum9GAG
//
//  Created by Sorin Cioban on 25/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "InfiniteScrollView.h"
#import "HotViewController.h"
#import "IndividualViewer.h"
#import <MessageUI/MessageUI.h>
#import <Twitter/Twitter.h>
#import "AppDelegate.h"

@interface InfiniteScrollView () {
    UIView                  *imageContainerView;
    IndividualViewer        *secondaryViewer;
    UIImageView             *menuBar;
    UIView                  *secondaryViewHost;
    UIImage                 *gagToView;
    NSString                *imagePath;
    NSData                  *gag_data;
    BOOL                     imageFound;
}

@property (nonatomic) UIImage *gagToView;
@property (nonatomic) NSString *imagePath;
@property (nonatomic) NSData *gag_data;
@property (nonatomic) BOOL     imageFound;

@end

@implementation InfiniteScrollView

@synthesize gagToView, gagSet, url, urlLength, viewButtons, hideView, imageFound, imagePath, gag_data;

- (id)initWithFrame:(CGRect)frame andURL:(NSString *)mainURL
{
    self = [super initWithFrame:frame];
    if (self) {
        CGSize size = CGSizeMake(self.frame.size.width*3, self.frame.size.height*3);
        self.contentSize = size;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.opaque = NO;        
        self.backgroundColor = [UIColor clearColor];
        
        imageContainerView = [[UIView alloc] init];
        imageContainerView.frame = CGRectMake(0, 0, self.contentSize.width, self.contentSize.height);
        imageContainerView.opaque = NO;
        imageContainerView.backgroundColor = [UIColor clearColor];
        
        [self addSubview:imageContainerView];
        
        imageContainerView.userInteractionEnabled = YES;
        self.delegate = self;
        self.minimumZoomScale = 1.0;
        self.maximumZoomScale = 4.0;
        self.zoomScale = 1.5;
        
        self.url = mainURL;
        self.urlLength = (NSUInteger *)self.url.length;
        
        self.gagSet = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)showAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info!!" 
                                                    message:@"An error has occured, please make sure your internet connection is working, then try again."  
                                                   delegate:self 
                                          cancelButtonTitle:@"FUUUUUUU" 
                                          otherButtonTitles: nil];
    [alert show];
}

- (void)getNextImages:(NSString *)startID {
    __block NSString *imageID = nil;
    __block int count = 0;
    
    [gagViewController.downloadQueue addOperationWithBlock:^{
        
        while (count < 30) {
            if (count == 0) {
                imageID = startID;
            }
            
            else {
                imageID = [self getNextImageID:imageID];
            }
            //if ([gagViewController.images containsObject:imageID])
            
            if (![gagViewController.images containsObject:imageID] && ![imageID isEqualToString:@""]) {
                /*if ([gagViewController.images containsObject:imageID])
                    NSLog(@"CONTAINS %@", imageID);
                else {
                    NSLog(@"Does not contain %@", imageID);
                }*/
                //NSLog(@"%@", imageID);
                if (gagViewController.images.count > 50) {
                    id obj = [gagViewController.images objectAtIndex:0];
                    [gagViewController.images removeObject:obj];
                }
                
                NSLog(@"%d", gagViewController.images.count);
                [gagViewController.images addObject:imageID];
                
                [self addImageToView:imageID];
                
            }
            count++;
        }
    }];

}

- (void)addImageToView:(NSString *)imageID {
    NSString *imageLink = [NSString stringWithFormat:@"http://d24w6bsrhbeh9d.cloudfront.net/photo/%@_460s.jpg", imageID];
    NSURL *imageURL = [NSURL URLWithString:imageLink];
    
    int count = 0;
    for (NSString *str in gagViewController.images) {
        if ([str isEqualToString:imageID]) {
            if (++count > 1)
                [gagViewController.images removeObject:str];
        }
    }
    NSLog(@"%@, %d", imageID, count);
    if (count == 1) {
    
    if (!gagViewController.oq.isSuspended) {
        __weak ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:imageURL];
        
        //if (gagViewController.images.count > 30) [gagViewController.images removeObject:[gagViewController.images objectAtIndex:0]];
        [request setDelegate: self];
        [request setDidFinishSelector:@selector(putUpImage:)];
        [request setDidFailSelector:@selector(imageLoadFailed:)];
        [gagViewController.oq addOperation:request];
    }
    }
    
    else {
        NSLog(@"DUUUDE, count is greater than 1");
    }
}

- (void)putUpImage:(ASIHTTPRequest *)request {
    NSData *responseData = [request responseData];
    
    if (responseData) {
        UIImage *gag = [UIImage imageWithData:responseData];
        
        if (![self.gagSet containsObject:gag])
            [self.gagSet addObject:gag];
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
        nextURL = [NSString stringWithFormat:@"http://m.9gag.com/read/go?id=%@&dir=next&list=%@", imageID, gagViewController.url];
        
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


- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    CGFloat zoomScale = scrollView.zoomScale;
    
    if (scrollView.tag == 2 && zoomScale < 0.7) {
        [self animateAndHide:scrollView];
    }
    
    UIView *subView = [scrollView.subviews objectAtIndex:0];
    
    CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width)? 
    (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
    
    CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height)?
    (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
    
    subView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX, 
                                 scrollView.contentSize.height * 0.5 + offsetY);
}

- (void)animateAndHide:(UIScrollView *)scrollView {
    [UIView animateWithDuration:0.5
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:(void (^)(void)) ^{
                         //scrollView.superview.transform = CGAffineTransformMakeScale(0.0f, 0.0f);
                         secondaryViewHost.alpha = 0.0;
                         
                         self.scrollEnabled = YES;
                         
                         [gagViewController.refresh setAlpha:0.5];
                         [gagViewController.backButton setAlpha:0.5];
                         [self setAlpha:1.0];
                     }
                     completion:^(BOOL finished) {
                         [scrollView.superview removeFromSuperview];
                     }];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return [scrollView.subviews objectAtIndex:0];
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView 
                       withView:(UIView *)view 
                        atScale:(float)scale {
    CGFloat scaleFactor = [[[self window] screen] scale] * scale;
    
    for (UIImageView *imageView in imageContainerView.subviews)
        [imageView setContentScaleFactor:scaleFactor];
}

- (void)recenterIfNecessary {
    CGPoint currentOffset = [self contentOffset];
    CGFloat contentWidth = [self contentSize].width;
    CGFloat contentHeight = [self contentSize].height;
    CGFloat centerOffsetX = (contentWidth - [self bounds].size.width) / 2.0;
    CGFloat distanceFromCenterX = fabs(currentOffset.x - centerOffsetX);
    
    CGFloat centerOffsetY = (contentHeight - self.bounds.size.height) / 2.0;
    CGFloat distanceFromCenterY = fabs(currentOffset.y - centerOffsetY);

    if (distanceFromCenterX > (contentWidth / 3.0) && distanceFromCenterY > (contentHeight / 3.0)) {
        self.contentOffset = CGPointMake(centerOffsetX, centerOffsetY);
        
        // move content by the same amount so it appears to stay still
        for (UIImageView *imageView in imageContainerView.subviews) {
            CGPoint center = [imageContainerView convertPoint:imageView.center toView:self];
            center.x += (centerOffsetX - currentOffset.x);
            center.y += (centerOffsetY - currentOffset.y);
            imageView.center = [self convertPoint:center toView:imageContainerView];
        }
    }
 
    
    if (distanceFromCenterX > (contentWidth / 3.0)) {
        self.contentOffset = CGPointMake(centerOffsetX, currentOffset.y);
        
        // move content by the same amount so it appears to stay still
        for (UIImageView *imageView in imageContainerView.subviews) {
            CGPoint center = [imageContainerView convertPoint:imageView.center toView:self];
            center.x += (centerOffsetX - currentOffset.x);
            imageView.center = [self convertPoint:center toView:imageContainerView];
        }
    }
    
    if (distanceFromCenterY > (contentHeight / 3.0)) {
        self.contentOffset = CGPointMake(currentOffset.x, centerOffsetY);
        
        // move content by the same amount so it appears to stay still
        for (UIImageView *imageView in imageContainerView.subviews) {
            CGPoint center = [imageContainerView convertPoint:imageView.center toView:self];
            center.y += (centerOffsetY - currentOffset.y);
            imageView.center = [self convertPoint:center toView:imageContainerView];
            
        }
    }
    
    if (gagViewController.showFavs != YES)
        [self clean];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self recenterIfNecessary];
    
    if(imageContainerView.subviews.count > 0 && gagViewController.showFavs != YES)
        [self tileImages];
    
}

- (void)tileImages {
    CGRect visibleBounds = [self convertRect:[self bounds] toView:imageContainerView];
    CGFloat minimumVisibleX = CGRectGetMinX(visibleBounds);
    CGFloat maximumVisibleX = CGRectGetMaxX(visibleBounds);
    
    CGFloat minimumVisibleY = CGRectGetMinY(visibleBounds);
    CGFloat maximumVisibleY = CGRectGetMaxY(visibleBounds);
    
    CGFloat minX = [self findMinX];
    CGFloat maxX = [self findMaxX];
    
    if (self.gagSet.count < 15) {
        NSString *imgID = [gagViewController.images objectAtIndex:gagViewController.images.count-1];
        [self getNextImages:imgID];
    }
    
    for (int i = minimumVisibleX; i < maximumVisibleX; i = i+20) {
        CGPoint p = CGPointMake(i, maximumVisibleY);
        
        if (![self containsPoint:p]) {
            CGFloat x = [self findCol:p.x];
            CGFloat y;
            if (x != FLT_MAX) {
                y = [self findMinY:p.x] + [self findHeight:p.x];
                if (self.gagSet.count > 0 && x != FLT_MAX && y != FLT_MAX) {
                    UIImage *image = [self.gagSet objectAtIndex:0];
                    
                    CGFloat aspectRatio = image.size.width/image.size.height;
                    
                    UIImageView *view = [[UIImageView alloc] initWithFrame:CGRectMake(x, y, 150, 150/aspectRatio)];
                    view.image = image;
                    [self insertImage:view];
                    
                    [self.gagSet removeObject:image];
                }
            }
            
            if (x == FLT_MAX && self.gagSet.count > 0) {
                if (i > maxX) {
                    UIImage *image = [self.gagSet objectAtIndex:0];
                    
                    CGFloat aspectRatio = image.size.width/image.size.height;
                    
                    UIImageView *view = [[UIImageView alloc] initWithFrame:
                                         CGRectMake(maxX+150, minimumVisibleY, 150, 150/aspectRatio)];
                    view.image = image;
                    [self insertImage:view];
                    
                    [self.gagSet removeObject:image];
                }
            
             
                if (i < minX) {
                    UIImage *image = [self.gagSet objectAtIndex:0];
                    
                    CGFloat aspectRatio = image.size.width/image.size.height;
                    
                    UIImageView *view = [[UIImageView alloc] initWithFrame:
                                         CGRectMake(minX-150, minimumVisibleY, 150, 150/aspectRatio)];
                    view.image = image;
                    [self insertImage:view];
                    
                    [self.gagSet removeObject:image];
                }
            }
        }
        
        p = CGPointMake(i, minimumVisibleY);
        
        if (![self containsPoint:p]) {
            CGFloat x = [self findCol:p.x];
            CGFloat y = [self findMinY:p.x];
            
            if (self.gagSet.count > 0 && x != FLT_MAX && y != FLT_MAX) {  
                UIImage *image = [self.gagSet objectAtIndex:0];
                
                CGFloat aspectRatio = image.size.width/image.size.height;
                
                CGFloat height = 150/aspectRatio;
                
                UIImageView *view = [[UIImageView alloc] initWithFrame:
                                     CGRectMake(x, y-height, 150, height)];
                view.image = image;
                [self insertImage:view];
                
                [self.gagSet removeObject:image];
            }
        }

    }
}

- (CGFloat)findMinX {
    if (imageContainerView.subviews.count > 0) {
        UIImageView *view = [imageContainerView.subviews objectAtIndex:0];
        CGFloat x = view.frame.origin.x;
        
        for (UIImageView *imageView in imageContainerView.subviews) {
            if (imageView.frame.origin.x < x)
                x = imageView.frame.origin.x;
        }
        
        return x;
    }
    
    return FLT_MAX;
}

- (CGFloat)findMaxX {
    if (imageContainerView.subviews.count > 0) {
        UIImageView *view = [imageContainerView.subviews objectAtIndex:0];
        CGFloat x = view.frame.origin.x;
        
        for (UIImageView *imageView in imageContainerView.subviews) {
            if (imageView.frame.origin.x > x)
                x = imageView.frame.origin.x;
        }
    
        return x;
    }
    return FLT_MAX;
}

- (CGFloat)findMaxXLeftOf:(CGFloat)x {
    CGFloat maxX = FLT_MAX;
    for (UIImageView *view in imageContainerView.subviews) {
        if (view.frame.origin.x < x) {
            maxX = view.frame.origin.x;
            break;
        }
    }
    
    for (UIImageView *view in imageContainerView.subviews) {
        if (view.frame.origin.x < x && view.frame.origin.x > maxX) {
            maxX = view.frame.origin.x;
        }
    }
    
    return maxX;
}

- (CGFloat)findCol:(CGFloat)x {
    CGFloat col = FLT_MAX;
    
    for (UIImageView *view in imageContainerView.subviews) {
        CGRect frame = view.frame;
        if (x >= frame.origin.x && x <= frame.origin.x+150) {
            col = frame.origin.x;
            break;
        }
    }
    
    return col;
}

- (CGFloat)findMinY:(CGFloat)x {
    CGFloat y = FLT_MAX;
    CGFloat origin = [self findCol:x];
    
    for (UIImageView *view in imageContainerView.subviews) {
        CGRect frame = view.frame;
        if (fabs(origin-frame.origin.x) < FLT_EPSILON) {
            if (frame.origin.y < y)
                y = frame.origin.y;
        }
    }
    return y;
}

- (CGFloat)findMaxY:(CGFloat)x {
    CGFloat maxY = [self findMinY:x];
    CGFloat origin = [self findCol:x];
    CGRect frame;
    
    for (UIImageView *imageView in imageContainerView.subviews) {
        frame = imageView.frame;
        
        if (frame.origin.x == origin) {
            maxY += frame.size.height;
        }
    }
    
    //maxY -= frame.size.height;
    
    return maxY;
}

- (NSInteger)findHeight:(CGFloat)x {
    int height = 0;
    
    for (UIImageView *view in imageContainerView.subviews) {
        CGRect frame = view.frame;
        if (frame.origin.x == [self findCol:x]) {
            height += frame.size.height;
        }
    }
    
    return height;
}

- (void)handleTap:(UITapGestureRecognizer *)tapper {
    self.scrollEnabled = NO;
    
    CGFloat actualHeight = [[UIScreen mainScreen] bounds].size.height-50;
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    NSString *value = [prefs stringForKey:@"com.appetizerinc.removeads"];
    
    if ([value isEqualToString:@"Yes"])
        actualHeight = [[UIScreen mainScreen] bounds].size.height;
    
    [gagViewController.refresh setAlpha:0.0];
    [gagViewController.backButton setAlpha:0.0];
    
    self.gagToView = ((UIImageView *)tapper.view).image;
    secondaryViewHost = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, actualHeight)];
    secondaryViewer = [[IndividualViewer alloc] initWithFrame:CGRectMake(0, 0, 320, actualHeight)];
    secondaryViewer.tag = 2;
    
    menuBar = [[UIImageView alloc] initWithFrame:CGRectMake(0, actualHeight-50, 320, 50)];
    menuBar.image = [UIImage imageNamed:@"menu bar"];
    [menuBar setAlpha:0.0];
    menuBar.tag = 1;
    
    CGFloat aspectRatio = self.gagToView.size.width/self.gagToView.size.height;
    
    CGFloat height = 320 / aspectRatio;
    
    CGFloat y = 0;
    
    if (height < actualHeight) {
        y = (actualHeight-height)/2;
        height = actualHeight;
    }
    
    UIImageView *view = [[UIImageView alloc] initWithFrame:CGRectMake(0, y, 320, 320 / aspectRatio)];
    [view setContentMode:UIViewContentModeScaleAspectFit];
    view.image = self.gagToView;
    
    [secondaryViewer setContentSize:CGSizeMake(320, height)];
    [secondaryViewer addSubview:view];
    
    secondaryViewer.delegate = self;
    
    [secondaryViewHost addSubview:secondaryViewer];
    
    [secondaryViewHost setBackgroundColor:[UIColor clearColor]];
    [secondaryViewer setBackgroundColor:[UIColor clearColor]];
    
    secondaryViewHost.alpha = 0.0;
    [self.superview insertSubview:secondaryViewHost aboveSubview:self];
    [secondaryViewHost insertSubview:menuBar aboveSubview:secondaryViewer];
    [self setAlpha:0.5];
    
    [UIView animateWithDuration:0.4
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:(void (^)(void)) ^{
                         secondaryViewHost.alpha = 1.0;
                     }
                     completion:^(BOOL finished) {
                         
                     }];

    
    [self addButtonsToBar];
    
    [self addTapTo:secondaryViewHost];
    [self addTapToHide:secondaryViewHost];
    
    BOOL showInfo = [[NSUserDefaults standardUserDefaults] boolForKey:@"InfoGiven"];;
    
    if (!showInfo) {
        UIAlertView *instructionBox = [[UIAlertView alloc] initWithTitle:@"Info!"
                                                                 message:@"A single tap shows extra buttons.\nDouble tapping or zooming out to makes the image go away. This will only be displayed once."
                                                                delegate:self
                                                       cancelButtonTitle:@"Got it!"
                                                       otherButtonTitles:nil];
        [instructionBox show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alertView.title isEqualToString:@"Info!"] && buttonIndex == 0) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"InfoGiven"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)addTapToHide:(UIView *)view {
    self.hideView = [[UITapGestureRecognizer alloc] initWithTarget:self 
                                                       action:@selector(hideView:)];
    self.hideView.delegate = self;
    [self.hideView setNumberOfTapsRequired:2];
    [self.hideView setNumberOfTouchesRequired:1];
    
    [view addGestureRecognizer:self.hideView];
}

- (void)hideView:(UITapGestureRecognizer *)doubleTap {
    UIView *view = doubleTap.view;
    
    UIScrollView *scrollView = [view.subviews objectAtIndex:0];
    
    [self animateAndHide:scrollView];
}

- (void)addTapTo:(UIView *)view {
    self.viewButtons = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                          action:@selector(viewButtons:)];
    self.viewButtons.delegate = self;
    [self.viewButtons setNumberOfTapsRequired:1];
    [self.viewButtons setNumberOfTouchesRequired:1];
    
    [view addGestureRecognizer:self.viewButtons];
    
   // [self.viewButtons requireGestureRecognizerToFail:self.hideView];
}

- (void)viewButtons:(UITapGestureRecognizer *)tap {
    for (UIView *view in secondaryViewHost.subviews) {
        if (view.tag == 1) {
                [UIView animateWithDuration:0.4
                                      delay:0.0
                                    options:UIViewAnimationOptionBeginFromCurrentState
                                 animations:(void (^)(void)) ^{
                                     view.alpha = view.alpha > 0.5 ? 0.0 : 0.8;
                                 }
                                 completion:^(BOOL finished) {
                                     
                                 }];

        }
    }
}

- (void)addButtonsToBar {
    menuBar.userInteractionEnabled = YES;
    
    UIButton *fav = [[UIButton alloc] initWithFrame:CGRectMake(115, 5, 40, 40)];
    NSString *favImage = @"addFav";
    
    UIButton *share = [[UIButton alloc] initWithFrame:CGRectMake(165, 5, 55, 40)];
    [share setBackgroundImage:[UIImage imageNamed:@"share_button"] forState:UIControlStateNormal];
    
    NSString *documentsDirectory = [self getDocDir];
    
    NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:documentsDirectory];
    
    self.imageFound = NO;
    
    self.gag_data = UIImageJPEGRepresentation(self.gagToView, 1.0);
    for (NSString *path in directoryEnumerator) {
        self.imageFound = [self isImageDataStored:self.gag_data atPath:path];
        
        if (self.imageFound)
            break;
    }
    
    if (self.imageFound)
        favImage = @"removeFav";
        
    [fav setBackgroundImage:[UIImage imageNamed:favImage] forState:UIControlStateNormal];
    [fav addTarget:self
            action:@selector(favorite:)
  forControlEvents:UIControlEventTouchUpInside];
    
    [share addTarget:self action:@selector(shareImage:) forControlEvents:UIControlEventTouchUpInside];
    
    [menuBar addSubview:fav];
    [menuBar addSubview:share];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isDescendantOfView:menuBar])
        return NO;
    return YES;
}

- (NSString *)getNewFile {
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    
    NSDate *now = [[NSDate alloc] init];
    
    NSString *theDate = [dateFormat stringFromDate:now];
    NSString *theTime = [timeFormat stringFromDate:now];
    
    NSString *fileName = [NSString stringWithFormat:@"image%@%@.jpeg", theDate, theTime];

    return fileName;
}

- (IBAction)favorite:(UIButton *)sender {
    
    NSString *documentsDirectory = [self getDocDir];
    
    NSString *fileName = [self getNewFile];
    
    NSString *file = [documentsDirectory stringByAppendingPathComponent:fileName];
    
    if (!self.imageFound) {
        self.imageFound = YES;
        self.imagePath = file;
        NSLog(@"File: %@", file);
        [[NSFileManager defaultManager] createFileAtPath:file
                                                contents:self.gag_data
                                              attributes:nil];
        [sender setBackgroundImage:[UIImage imageNamed:@"removeFav"] forState:UIControlStateNormal];
        
    }
    
    else {
        self.imageFound = NO;
        [[NSFileManager defaultManager] removeItemAtPath:self.imagePath error:nil];
        [sender setBackgroundImage:[UIImage imageNamed:@"addFav"] forState:UIControlStateNormal];
    }
    
    if (gagViewController.showFavs) {
        [UIView animateWithDuration:0.4
                         animations:^{
                             secondaryViewHost.alpha = 0.0;
                             [gagViewController.refresh setAlpha:0.5];
                             [gagViewController.backButton setAlpha:0.5];
                         }
                         completion:^(BOOL finished) {
                             [secondaryViewHost removeFromSuperview];
                             [gagViewController setUpScroll];
                         }];
    }
    
}

- (BOOL)isImageDataStored:(NSData *)gag_data atPath:(NSString *)path {
    BOOL ret = NO;
    
    self.imagePath = @"";
    
    NSString *documentsDirectory = [self getDocDir];
    
    if ([[path pathExtension] isEqualToString:@"jpeg"]) {
        NSString *actualPath = [documentsDirectory stringByAppendingPathComponent:path];
        NSData *image_data;
        if (!gagViewController.showFavs)
            image_data = [NSData dataWithContentsOfFile:actualPath];
        else {
            UIImage *img = [UIImage imageWithContentsOfFile:actualPath];
            image_data = UIImageJPEGRepresentation(img, 1.0);
        }
        
        if ([image_data isEqualToData:self.gag_data]) {
            ret = YES;
            self.imagePath = actualPath;
            
        }        
    }

    return ret;
}

- (NSString *)getDocDir {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(
                                                         NSDocumentDirectory, NSUserDomainMask, YES); 
    NSString *documentsDirectory = [paths objectAtIndex:0];

    return documentsDirectory;
}

- (IBAction)shareImage:(UIButton *)sender {
    NSString *os_version = [[UIDevice currentDevice] systemVersion];
    os_version = [os_version substringToIndex:1];
    if ([os_version intValue] > 5) {
        
        [self showForLatest];
    }
    
    else {
        [self showForOlder:sender];
    }
    
}

- (void)showForLatest {
    UIActivityViewController *shareController = [
                                                 [UIActivityViewController alloc] initWithActivityItems:@[self.gag_data]                                                                                  applicationActivities:@[]];
    
    //[shareController setHidesBottomBarWhenPushed:YES];
    
    [shareController setCompletionHandler:^(NSString *activityType, BOOL completed){
        NSLog(@"%@", activityType);
        if (completed) {
            NSLog(@"DONE");
        }
        
        else {
            NSLog(@"NOT DONE");
            [secondaryViewHost removeFromSuperview];
        }
    }];
    
    [gagViewController presentViewController:shareController animated:YES completion:nil];
}

- (void)showForOlder:(UIButton *)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Share/Save"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Mail", @"Twitter", @"Facebook", @"Save to Camera Roll", nil];
    
    [actionSheet showInView:self];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            [self showMail];
            break;
        case 1:
            [self showTweet];
            break;
        case 2:
            [self shareToFB];
            break;
        case 3:
            [self saveToAlbum];
            break;
        default:
            break;
    }
}

- (void)saveToAlbum {
    UIImageWriteToSavedPhotosAlbum(self.gagToView, nil, nil, nil);
}

- (void)shareToFB {
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [[delegate facebook] setSessionDelegate:self];
    [self login];
}

- (void)login {
    NSArray *permissions = [NSArray arrayWithObjects:@"publish_stream", @"offline_access", nil];
    
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (![[delegate facebook] isSessionValid]) {
        [[delegate facebook] authorize:permissions];
    } else {
        [self postImageToAlbum];
    }
}

- (void)postImageToAlbum {
    NSString *caption = @"Here's a great image I found on 9gag.com through GAG Board on iOS!!";
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   self.gagToView, @"photo",
                                   caption, @"caption",
                                   nil];
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [[delegate facebook] requestWithGraphPath:@"me/photos"
                                    andParams:params
                                andHttpMethod:@"POST"
                                  andDelegate:self];        
}

- (void)fbDidLogin {
    [self postImageToAlbum];
    
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [self storeAuthData:[[delegate facebook] accessToken] expiresAt:[[delegate facebook] expirationDate]];
}

- (void)fbSessionInvalidated {
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:@"Auth Exception"
                              message:@"Your session has expired."
                              delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil,
                              nil];
    [alertView show];
    [self fbDidLogout];
}

- (void)fbDidLogout {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"FBAccessTokenKey"];
    [defaults removeObjectForKey:@"FBExpirationDateKey"];
    [defaults synchronize];
}

-(void)fbDidExtendToken:(NSString *)accessToken expiresAt:(NSDate *)expiresAt {
    NSLog(@"token extended");
    [self storeAuthData:accessToken expiresAt:expiresAt];
}

- (void)storeAuthData:(NSString *)accessToken expiresAt:(NSDate *)expiresAt {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:accessToken forKey:@"FBAccessTokenKey"];
    [defaults setObject:expiresAt forKey:@"FBExpirationDateKey"];
    [defaults synchronize];
}

/**
 * Called when the user canceled the authorization dialog.
 */
-(void)fbDidNotLogin:(BOOL)cancelled {
    
}

- (void)showMail {    
    MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
    
    mailComposer.mailComposeDelegate = self;
    
    [mailComposer addAttachmentData:self.gag_data mimeType:@"image/jpeg" fileName:@"GAG Board Image"];
    
    [mailComposer setSubject:@"Image from GAG Board"];
    
    [mailComposer setMessageBody:@"Here's a cool image I found on 9GAG through GAG Board on iOS" isHTML:NO];
    
    if (mailComposer) {
        [gagViewController.navigationController presentModalViewController:mailComposer animated:YES];
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error

{
    UIAlertView *alert ;	// Notifies users about errors associated with the interface
	switch (result)
	{
		case MFMailComposeResultCancelled :
            alert = [[UIAlertView alloc]initWithTitle:@"Result" message:@"Mail has been cancelled." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
			[alert show];
			break;
            
		case MFMailComposeResultSaved:
            alert = [[UIAlertView alloc]initWithTitle:@"Result" message:@"Email has been saved." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
			break;
            
		case MFMailComposeResultSent:
            alert = [[UIAlertView alloc]initWithTitle:@"Result" message:@"Email has been sent. Thanks!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
			break;
            
		case MFMailComposeResultFailed:
            alert = [[UIAlertView alloc]initWithTitle:@"Result" message:@"Sending failed." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
			break;
            
		default:
            alert = [[UIAlertView alloc]initWithTitle:@"Result" message:@"Email could not be sent." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
            
			break;
	}
    
	[gagViewController.navigationController dismissModalViewControllerAnimated:YES];
}


- (void)showTweet {
    TWTweetComposeViewController *tweet = [[TWTweetComposeViewController alloc] init];
    [tweet setInitialText:@"Here's a cool image I found on 9GAG through GAG Board"];
    [tweet addImage:self.gagToView];
    
    [tweet setCompletionHandler:^(TWTweetComposeViewControllerResult result) {
        //NSString *output;
        
        switch (result) {
            case TWTweetComposeViewControllerResultCancelled:
                // The cancel button was tapped.
                NSLog(@"Tweet cancelled.");
                break;
            case TWTweetComposeViewControllerResultDone:
                // The tweet was sent.
                NSLog(@"Tweet done.");
                break;
            default:
                break;
        }        
        // Dismiss the tweet composition view controller.
        [gagViewController.navigationController dismissModalViewControllerAnimated:YES];
    }];
    
    // Present the tweet composition view controller modally.
    [gagViewController.navigationController presentModalViewController:tweet animated:YES];
}

- (void)insertImage:(UIImageView *)imageView {
    [imageView setUserInteractionEnabled:YES];
    [imageView setMultipleTouchEnabled:YES];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(handleTap:)];
    [tap setDelegate:self];
    [tap setNumberOfTapsRequired:1];
    [tap setNumberOfTouchesRequired:1];
    
    [imageView addGestureRecognizer:tap];
    
    if (gagViewController.showFavs == YES) {
        [imageContainerView addSubview:imageView];
    }
    
    else {
        if (imageContainerView.subviews.count < 30) {
            [imageContainerView addSubview:imageView];
        }
        
        else {
            [self clean];
            [imageContainerView addSubview:imageView];
        }
    }
}

- (void)clean {
    CGRect visibleBounds = [self convertRect:[self bounds] toView:imageContainerView];
    CGFloat minX = CGRectGetMinX(visibleBounds);
    CGFloat maxX = CGRectGetMaxX(visibleBounds);
    CGFloat minY = CGRectGetMinY(visibleBounds);
    CGFloat maxY = CGRectGetMaxY(visibleBounds);
    
    int height = 480, width = 320;
    
    NSString *model = [UIDevice currentDevice].model;
    if ([model isEqualToString:@"iPod"]) {
        height = 320;
        width = 240;
    }
    
    else if ([model isEqualToString:@"iPad"]) {
        height = 1024;
        width = 768;
    }
    
    for (UIImageView *view in imageContainerView.subviews) {
        CGRect frame = view.frame;
        
        if (frame.origin.x < minX-width) {
            [view removeFromSuperview];
        }
        
        else if (frame.origin.x > maxX+width) {
            [view removeFromSuperview];
        }
        
        else if (frame.origin.y < minY-height && frame.origin.y + frame.size.height < minY-height) {
            [view removeFromSuperview];
        }
        
        else if (frame.origin.y > maxY+height) {
            [view removeFromSuperview];
        }
    }

}

- (BOOL)containsPoint:(CGPoint)point {
    if (imageContainerView.subviews.count > 0) {
        for (UIView *view in imageContainerView.subviews) {
            if (CGRectContainsPoint(view.frame, point))
                return YES;
        }
    }
    
    return NO;
}

- (NSInteger)countImagesAbove:(CGFloat)y on:(CGFloat)x {
    NSInteger count = 0;
    
    for (UIImageView *view in imageContainerView.subviews) {
        if (view.frame.origin.x == x && view.frame.origin.y < y) {
            count++;
        }
    }
    
    return count;    
}

- (NSInteger)countImagesUnder:(CGFloat)y on:(CGFloat)x {
    NSInteger count = 0;
    
    for (UIImageView *view in imageContainerView.subviews) {
        if (view.frame.origin.x == x && view.frame.origin.y > y) {
            count++;
        }
    }
    
    return count;
}

@end
