//
//  AppDelegate.h
//  Maximum9GAG
//
//  Created by Sorin Cioban on 27/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FBConnect.h"

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    Facebook *facebook;
}

@property (strong) Facebook *facebook;

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) ViewController *viewController;

@end
