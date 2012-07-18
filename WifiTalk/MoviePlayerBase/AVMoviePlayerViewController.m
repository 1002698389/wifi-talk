//
//  AVMoviePlayerViewController.m
//  AVMoviePlayer
//
//  Created by Joey Patino on 3/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AVMoviePlayerViewController.h"
#import "AVMoviePlayerView.h"

#define kAutoHideTimeout 10.0

@interface AVMoviePlayerViewController () <UIGestureRecognizerDelegate> {

    AVPlayer *moviePlayer;
    NSMutableArray *timeObservers;
    CGRect _frame;
    BOOL didAppear;
}

@property (nonatomic, strong) NSURL *assetURL;
@property (nonatomic, assign) BOOL isFullScreen;
@property (nonatomic, strong) NSTimer *autoHideTimer;
@property (nonatomic, strong) AVPlayer *moviePlayer;

@property (nonatomic, strong) NSMutableArray *timeObservers;

- (AVPlayerLayer *)playerLayer;
- (void)addGestureRecognizers;

@end


@implementation AVMoviePlayerViewController
@synthesize assetURL;
@synthesize isFullScreen;
@synthesize autoHideTimer;
@synthesize moviePlayer;
@synthesize shouldAutoPlay;
@synthesize timeObservers;
@synthesize didReachEndBlock;

#pragma mark -

- (id)initWithURL:(NSURL *)url {

    self = [super init];
    
    self.assetURL = url;
    self.timeObservers = [[NSMutableArray alloc] init];
    _frame = [[UIScreen mainScreen] bounds];
    self.wantsFullScreenLayout = YES;

    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {

    [self shutDown];
}

#pragma mark - View lifecycle

- (void)loadView {

    AVMoviePlayerView *view = [[AVMoviePlayerView alloc] initWithFrame:_frame];
    self.view = view;
}

- (void)viewDidLoad{
    [super viewDidLoad];

    self.moviePlayer = [[AVPlayer alloc] initWithURL:self.assetURL];
    self.moviePlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone; 
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:[self.moviePlayer currentItem]];
    
    [[self playerLayer] setPlayer:self.moviePlayer];
    [self addGestureRecognizers];
    
    [self.autoHideTimer invalidate];
    self.autoHideTimer = nil;

    self.autoHideTimer = [NSTimer scheduledTimerWithTimeInterval:kAutoHideTimeout target:self.view selector:@selector(autoHideTimerTick:) userInfo:nil repeats:YES];
}

- (void)viewDidUnload {
 NSLog(@"%s", __PRETTY_FUNCTION__);
    [super viewDidUnload];

    [self shutDown];
}

- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    [super viewWillAppear:animated];
    _frame = self.view.frame;
    didAppear = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    [super viewDidAppear:animated];
    
    if (self.shouldAutoPlay)
        [self.moviePlayer play];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

    if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) return YES;

    return NO;
}

#pragma mark -

- (AVPlayerLayer *)playerLayer {
    return (AVPlayerLayer *)self.view.layer;
}

- (void)shutDown {

    if (self.moviePlayer != nil) {

        // remove the time observers we may have added.
        for (id timeObserver in self.timeObservers){
            [self.moviePlayer removeTimeObserver:timeObserver];
        }

        [self.timeObservers removeAllObjects];

        // destroy the movie player instance.
        [self.moviePlayer pause];
        self.moviePlayer = nil;

    }
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    if (self.didReachEndBlock != NULL)
        self.didReachEndBlock();
}

- (void)setContentURL:(NSURL *)contentURL {

    self.assetURL = contentURL;

    [self.moviePlayer pause];
    [self.moviePlayer replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:self.assetURL]];
}

#pragma mark - Touch Interaction

- (void)addGestureRecognizers {
    
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGestureRecognized:)];
    [self.view addGestureRecognizer:pinch];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapGestureRecognized:)];
    doubleTap.numberOfTapsRequired = 2;
    doubleTap.delegate = self;
    [self.view addGestureRecognizer:doubleTap];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapGestureRecognized:)];
    singleTap.numberOfTapsRequired = 1;
    singleTap.delegate = self;
    [singleTap requireGestureRecognizerToFail:doubleTap];
    [self.view addGestureRecognizer:singleTap];
    
}

- (void)singleTapGestureRecognized:(UITapGestureRecognizer *)tapGesture {
    if (tapGesture.state == UIGestureRecognizerStateFailed) return;
    
    [self.autoHideTimer invalidate];
    self.autoHideTimer = nil;
    self.autoHideTimer = [NSTimer scheduledTimerWithTimeInterval:kAutoHideTimeout target:self.view selector:@selector(autoHideTimerTick:) userInfo:nil repeats:YES];

    [(AVMoviePlayerView *)[self view] singleTouch];
}

- (void)doubleTapGestureRecognized:(UITapGestureRecognizer *)tapGesture {
    if (tapGesture.state == UIGestureRecognizerStateFailed) return;
    [tapGesture cancelsTouchesInView];
    
    [(AVMoviePlayerView *)[self view] doubleTouch];
}

- (void)pinchGestureRecognized:(UIPinchGestureRecognizer *)pinchGesture {
	if (pinchGesture.state != 3) return;

    if (pinchGesture.scale > 1) {
        // go fullscreen.

        [self setFullScreen:YES animated:YES];
    }
    else if (pinchGesture.scale < 1){
        // return from fullscreen.
        
        [self setFullScreen:NO animated:YES];
    }
}

#pragma mark - Gesture Recognizer Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer 
       shouldReceiveTouch:(UITouch *)touch {

    for (AVMoviePlayerControlsView *controls in self.view.subviews){
        CGPoint p = [touch locationInView:self.view];
        if (CGRectContainsPoint(controls.frame, p))
            return NO;
    }
    
    return YES;
}

#pragma mark -

- (void)setFullScreen:(BOOL)fullScreen {

    [self setFullScreen:fullScreen animated:NO];

}

- (void)setFullScreen:(BOOL)fullScreen 
             animated:(BOOL)animated {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    if (!didAppear)
        [self viewWillAppear:YES];
    
    if (self.isFullScreen == fullScreen) return;
    
    CGRect newFrame = _frame;
    NSLog(@"newFrame %@", NSStringFromCGRect(newFrame));

    if (fullScreen){
        NSLog(@"isFullScreen");
        newFrame = [self.view.window convertRect:[[UIScreen mainScreen] applicationFrame] toView:self.view];
        newFrame.origin = CGPointMake(0, 0);
        
        newFrame = [self.view.superview convertRect:newFrame fromView:self.view.superview];
        newFrame = CGRectOffset(newFrame, -self.view.superview.frame.origin.x, -self.view.superview.frame.origin.y);
    }
    NSLog(@"newFrame %@", NSStringFromCGRect(newFrame));

    AVMoviePlayerView *view = (AVMoviePlayerView *)self.view;
    view.isFullScreen = fullScreen;
    
    NSTimeInterval animationDuration = animated ? 0.6 : 0.0;
    
    [UIView animateWithDuration:animationDuration delay:0.0
                        options:UIViewAnimationCurveEaseInOut 
                     animations:^{
                         
                         self.view.frame = newFrame;
                     } 
                     completion:^(BOOL finished){
                         self.isFullScreen = fullScreen;

                         if (self.isFullScreen)
                             self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                         else
                             self.view.autoresizingMask = UIViewAutoresizingNone;
                     }];
}

- (void)addMovieControls:(AVMoviePlayerControlsView *)controls {
    
    [controls setMoviePlayerController:self];
    [self.view addSubview:controls];
}

- (void)removeMovieControls:(AVMoviePlayerControlsView *)controls {

    for (UIView *subview in self.view.subviews){
        if ([subview isEqual:controls]){
            [subview removeFromSuperview];
            break;
        }
    }
}

@end
