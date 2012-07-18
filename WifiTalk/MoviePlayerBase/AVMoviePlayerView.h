//
//  AVMoviePlayerView.h
//  AVMoviePlayer
//
//  Created by Joey Patino on 3/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

@interface AVMoviePlayerView : UIView {
    BOOL isFullScreen;
}

@property (nonatomic, assign) BOOL isFullScreen;

- (void)singleTouch;
- (void)doubleTouch;
- (BOOL)isFullScreen;

- (void)setIsFullScreen:(BOOL)newValue;

@end
