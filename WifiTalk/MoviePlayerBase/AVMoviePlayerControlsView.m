//
//  AVMoviePlayerControlsView.m
//  AVMoviePlayer
//
//  Created by Joey Patino on 3/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AVMoviePlayerControlsView.h"
#import "AVMoviePlayerViewController.h"

@implementation AVMoviePlayerControlsView
@synthesize moviePlayerController;

- (BOOL)isInHiding {
    
    if (self.alpha == 0.0) return YES;
    
    return NO;
}

- (void)singleTouch {

    [UIView animateWithDuration:.4 delay:0.0 
                        options:UIViewAnimationCurveEaseInOut 
                     animations:^{
                         self.alpha = (self.alpha == 0.0) ? 1.0 : 0.0;
                     } 
                     completion:NULL];
}

- (void)doubleTouch {
    
}

- (void)setIsFullScreen:(BOOL)isFullScreen {
    
}

- (void)didRotate:(UIInterfaceOrientation)orientation 
  withParentFrame:(CGRect)frame {
    
    if (UIInterfaceOrientationIsPortrait(orientation)){
        //
    }
    else if (UIInterfaceOrientationIsLandscape(orientation)){
        //
    }
}

@end
