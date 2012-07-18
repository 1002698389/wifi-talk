//
//  AVMoviePlayerViewController.h
//  AVMoviePlayer
//
//  Created by Joey Patino on 3/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AVMoviePlayer.h"

@interface AVMoviePlayerViewController : UIViewController

@property (nonatomic, readonly, strong) AVPlayer *moviePlayer;  // The current AVMoviePlayer instance. 
@property (nonatomic, readonly, strong) NSURL *assetURL;        // The currently playing asset's URL
@property (nonatomic, readonly) BOOL isFullScreen;              // Use to determine the current view state. defaults to NO
@property (nonatomic, assign) BOOL shouldAutoPlay;              // Configures whether the player begins to play automatically. defaults to NO
@property (nonatomic, copy) dispatch_block_t didReachEndBlock;

/*  Returns a new instance of AVMoviePlayerViewController object. 
    URL must be a valid URL to a local or remote asset. After
    creating the AVMoviePlayerViewController, you must add the view 
    into a view hierarchy */
- (id)initWithURL:(NSURL *)url;

/*  User this method to add custom subviews to the movie player. 
    All controls added must be a subclass of AVMoviePlayerControlsView
    In addition, your custom subclass should implement the 
    didRotate:withParentFrame: method in order to recieve rotation calls
    See AVMoviePlayerControlsView.h for more information on creating
    custom controls. */
- (void)addMovieControls:(AVMoviePlayerControlsView *)controls;

/*  Use these method to enter or exit fullscreen, optionally animated. 
    You may also check the isFullScreen property to determine the players
    current configuration. */
- (void)setFullScreen:(BOOL)fullScreen animated:(BOOL)animated;

/*  Forces the view into or out of fullscreen with no animations */
- (void)setFullScreen:(BOOL)fullScreen;

- (void)setContentURL:(NSURL *)contentURL;

- (void)shutDown;

@end
