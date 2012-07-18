//
//  AVMoviePlayerView.m
//  AVMoviePlayer
//
//  Created by Joey Patino on 3/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AVMoviePlayerView.h"
#import "AVMoviePlayerControlsView.h"

@interface AVMoviePlayerView () {
    CALayer *border;
}
- (void)commonInit;
@end

@implementation AVMoviePlayerView
@synthesize isFullScreen;

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    [self commonInit];
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    [self commonInit];
    return self;
}

- (void)commonInit {

    [(AVPlayerLayer *)self.layer setVideoGravity:AVLayerVideoGravityResizeAspect];
    [(AVPlayerLayer *)self.layer setMasksToBounds:YES];
    self.backgroundColor = [UIColor blackColor];
    self.autoresizingMask = UIViewAutoresizingNone;

    border = [CALayer layer];
    border.borderColor = [UIColor whiteColor].CGColor;
    border.borderWidth = 4;
    border.frame = self.bounds;
    
    [self.layer addSublayer:border];
}

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (void)autoHideTimerTick:(NSTimer *)theTimer {

    for (AVMoviePlayerControlsView *subview in self.subviews){
        if ([subview isKindOfClass:[AVMoviePlayerControlsView class]]){
            if (![subview isInHiding])
                [subview singleTouch];
        }
    }
}

- (void)layoutSubviews {

    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    for (AVMoviePlayerControlsView *subview in self.subviews){
        if ([subview isKindOfClass:[AVMoviePlayerControlsView class]]){
            [subview didRotate:orientation withParentFrame:self.bounds];
        }
    }

    if (UIInterfaceOrientationIsPortrait(orientation)){
        
        if (self.isFullScreen) {
            self.frame = CGRectMake(-92, -64, 768, 1004);
        }

        [CATransaction begin];
        [CATransaction setValue:[NSNumber numberWithFloat:0.6f]
                         forKey:kCATransactionAnimationDuration];
        
        [CATransaction setValue:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]
                         forKey:kCATransactionAnimationTimingFunction];
        
        border.frame = self.bounds;
        
        [CATransaction commit];

    }
    else if (UIInterfaceOrientationIsLandscape(orientation)){

        if (self.isFullScreen) {
            self.frame = CGRectMake(0, -44, 1024, 748);
        }

        [CATransaction begin];
        [CATransaction setValue:[NSNumber numberWithFloat:0.6f]
                         forKey:kCATransactionAnimationDuration];
        
        [CATransaction setValue:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]
                         forKey:kCATransactionAnimationTimingFunction];
        
        border.frame = self.bounds;
        
        [CATransaction commit];
    }


}

- (void)singleTouch {
    
     for (AVMoviePlayerControlsView *subview in self.subviews){
         if ([subview isKindOfClass:[AVMoviePlayerControlsView class]]){
             [subview singleTouch];
         }
     }
}

- (void)doubleTouch {

    AVPlayerLayer *playerLayer = (AVPlayerLayer *)[self layer];
    NSString *gravity = [playerLayer videoGravity];

    if ([gravity isEqualToString:AVLayerVideoGravityResizeAspect])
        [playerLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    else
        [playerLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    
    playerLayer.bounds = playerLayer.bounds;
}

- (BOOL)isFullScreen {
    return isFullScreen;
}

- (void)setIsFullScreen:(BOOL)newValue {
    isFullScreen = newValue;

    for (AVMoviePlayerControlsView *subview in self.subviews){
        if ([subview isKindOfClass:[AVMoviePlayerControlsView class]]){
            [subview setIsFullScreen:isFullScreen];
        }
    }
    
    if (isFullScreen)
        border.borderColor = [UIColor clearColor].CGColor;
    else
        border.borderColor = [UIColor whiteColor].CGColor;
}

@end
