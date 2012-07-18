//
//  AVMoviePlayerControlsView.h
//  AVMoviePlayer
//
//  Created by Joey Patino on 3/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AVMoviePlayer.h"


/*
 
 Tips for creating custom AVMoviePlayer controls.
 
 --All custom controls must be a subclass of AVMoviePlayerViewController.
 You should (almost) always override the didRotate:withParentFrame: method 
 and perform your layout logic there. Your custom controls should have 
 their auto resizing property set to UIViewAutoResizingNone in order to 
 allow you the control to lay them out.
 
 --Override the singleTouch method in order to change the default behaviour
 when the user touches the screen.
 
 --Custom movie controls may be created through code or they may be loaded 
 from a xib.
 
 --Use the property 'moviePlayerViewController' of AVMoviePlayerControlsView in order
 to control movie playback or access infomation about the current movie player.
 
*/


@class AVMoviePlayerViewController;
@interface AVMoviePlayerControlsView : UIView

/*
 this property contains reference to the movie player controller 
 that the controls were added to. */
@property (nonatomic, assign) AVMoviePlayerViewController *moviePlayerController;

/*  Use this method to adjust the layout of your controls based on the current 
    orientation and the frame of the movie player view that is passed in. */
- (void)didRotate:(UIInterfaceOrientation)orientation 
  withParentFrame:(CGRect)frame;

/*  Override this method if you wish to change the default behaviour for 
    single tap events. Call super singleTouch if you only want to supplement 
    the default behaviour. */
- (void)singleTouch;


// use this to do something different when you are in fullscreen vs. embedded view
- (void)setIsFullScreen:(BOOL)isFullScreen;

@end


@interface AVMoviePlayerControlsView (PRIVATE)

- (BOOL)isInHiding;
- (void)doubleTouch;

@end
