//
//  IndividualViewer.m
//  GAG Board
//
//  Created by Sorin Cioban on 07/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "IndividualViewer.h"

@implementation IndividualViewer

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.contentSize = CGSizeMake(self.frame.size.width, self.frame.size.height);
        
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.opaque = NO;        
        self.userInteractionEnabled = YES;
        self.multipleTouchEnabled = YES;
        self.backgroundColor = [UIColor clearColor];
        
        self.zoomScale = 1.0;
        self.maximumZoomScale = 4.0;
    }
    
    return self;
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */

@end
