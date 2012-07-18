//
//  AVMoviePlayerScrubBar.m
//  MoviePlayerBase
//
//  Created by Joey Patino on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AVMoviePlayerScrubBar.h"
#import "AVMoviePlayerViewController.h"

@interface AVMoviePlayerScrubBar () {
    id mTimeObserver;
    IBOutlet UISlider* mScrubber;
    float mRestoreAfterScrubbingRate;   
}



- (void)initScrubberTimer;
- (void)syncScrubber;

- (BOOL)isScrubbing;
- (void)enableScrubber;
- (void)disableScrubber;


- (IBAction)beginScrubbing:(id)sender;
- (IBAction)scrub:(id)sender;
- (IBAction)endScrubbing:(id)sender;

- (CMTime)playerItemDuration;

- (void)commonInit;

@end


static void *AVObservationContext = &AVObservationContext;
NSString * const kStatusKey         = @"status";

@implementation AVMoviePlayerScrubBar
@synthesize mScrubber;
@synthesize moviePlayerController = _moviePlayerController;


- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    [self commonInit];    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    [self commonInit];
    return self;
}

- (void)commonInit {

    self.backgroundColor = [UIColor blackColor];

    self.mScrubber = [[UISlider alloc] initWithFrame:self.bounds] ;
    self.mScrubber.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self addSubview:self.mScrubber];
    
    [self.mScrubber addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
    [self.mScrubber addTarget:self action:@selector(beginScrubbing:) forControlEvents:UIControlEventTouchDown];
    [self.mScrubber addTarget:self action:@selector(endScrubbing:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)dealloc {

    [self removePlayerTimeObserver];
}

#pragma mark -

- (void)setMoviePlayerController:(AVMoviePlayerViewController *)mPlayer {

    _moviePlayerController = mPlayer;
    
    [self initScrubberTimer];

    /* Observe the player item "status" key to determine when it is ready to play. */
    [_moviePlayerController.moviePlayer.currentItem addObserver:self
                                                     forKeyPath:kStatusKey 
                                                        options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                                        context:(__bridge void *)self];
}

/* Requests invocation of a given block during media playback to update the movie scrubber control. */
- (void)initScrubberTimer {

    double interval = .1f;  

    CMTime playerDuration = [self playerItemDuration];
    
//    do not need this check. causes scrubber not to start on playback begin.
//    if (CMTIME_IS_INVALID(playerDuration)) {
//        return;
//    } 

    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        CGFloat width = CGRectGetWidth([mScrubber bounds]);
        interval = 0.5f * duration / width;
    }

    if (mTimeObserver)
        [self removePlayerTimeObserver];
    
    /* Update the scrubber during normal playback. */
    mTimeObserver = [self.moviePlayerController.moviePlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC) 
                                                                                          queue:NULL /* If you pass NULL, the main queue is used. */
                                                                                     usingBlock:^(CMTime time)  {
                                                                   
                                                                                         [self syncScrubber];

                                                                                     }];
    
}

/* Set the scrubber based on the player current time. */
- (void)syncScrubber {

    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        mScrubber.minimumValue = 0.0;
        return;
    } 
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        float minValue = [mScrubber minimumValue];
        float maxValue = [mScrubber maximumValue];
        double time = CMTimeGetSeconds([self.moviePlayerController.moviePlayer currentTime]);
        
        [mScrubber setValue:(maxValue - minValue) * time / duration + minValue];
    }
}

/* The user is dragging the movie controller thumb to scrub through the movie. */
- (IBAction)beginScrubbing:(id)sender {
    
    mRestoreAfterScrubbingRate = [self.moviePlayerController.moviePlayer rate];
    [self.moviePlayerController.moviePlayer setRate:0.f];
    
    /* Remove previous timer. */
    [self removePlayerTimeObserver];
}

/* Set the player current time to match the scrubber position. */
- (IBAction)scrub:(id)sender {

    if ([sender isKindOfClass:[UISlider class]]) {
        
        UISlider* slider = sender;
        
        CMTime playerDuration = [self playerItemDuration];
        if (CMTIME_IS_INVALID(playerDuration)) {
            return;
        } 
        
        double duration = CMTimeGetSeconds(playerDuration);
        if (isfinite(duration))
        {
            float minValue = [slider minimumValue];
            float maxValue = [slider maximumValue];
            float value = [slider value];
            
            double time = duration * (value - minValue) / (maxValue - minValue);
            
            [self.moviePlayerController.moviePlayer seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
        }
    }
}

/* The user has released the movie thumb control to stop scrubbing through the movie. */
- (IBAction)endScrubbing:(id)sender {

    if (!mTimeObserver) {
        
        CMTime playerDuration = [self playerItemDuration];
        if (CMTIME_IS_INVALID(playerDuration)) {
            return;
        } 
        
        double duration = CMTimeGetSeconds(playerDuration);
        if (isfinite(duration)) {
            CGFloat width = CGRectGetWidth([mScrubber bounds]);
            double tolerance = 0.5f * duration / width;
            
            mTimeObserver = [self.moviePlayerController.moviePlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(tolerance, NSEC_PER_SEC) 
                                                                            queue:NULL 
                                                                       usingBlock: ^(CMTime time) {
                                                                           
                                                                           [self syncScrubber];
                                                                           
                                                                       }];
        }
    }
    
    if (mRestoreAfterScrubbingRate) {
        [self.moviePlayerController.moviePlayer setRate:mRestoreAfterScrubbingRate];
        mRestoreAfterScrubbingRate = 0.f;
    }
}

#pragma mark -

- (BOOL)isScrubbing {
    return mRestoreAfterScrubbingRate != 0.f;
}

- (void)enableScrubber {
    self.mScrubber.enabled = YES;
}

- (void)disableScrubber {
    self.mScrubber.enabled = NO;    
}

#pragma mark -

- (CMTime)playerItemDuration {
	
    AVPlayerItem *playerItem = [self.moviePlayerController.moviePlayer currentItem];
	if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
		return([playerItem duration]);
	}
	
	return(kCMTimeInvalid);
}

/* Cancels the previously registered time observer. */
- (void)removePlayerTimeObserver {

	if (mTimeObserver) {
		[self.moviePlayerController.moviePlayer removeTimeObserver:mTimeObserver];
		mTimeObserver = nil;
	}
}

- (void)observeValueForKeyPath:(NSString*) path 
                      ofObject:(id)object 
                        change:(NSDictionary*)change 
                       context:(void*)context {

    if (context == (__bridge void *)self) {

        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
    
        switch (status) {
            case AVPlayerStatusReadyToPlay:

                [self.moviePlayerController.moviePlayer.currentItem removeObserver:self forKeyPath:kStatusKey];
                [self initScrubberTimer];
                break;
            case AVPlayerStatusFailed:

                break;
        }
	}
}


// AVMoviePlayer controls methods
- (void)didRotate:(UIInterfaceOrientation)orientation 
  withParentFrame:(CGRect)frame {

     if (UIInterfaceOrientationIsPortrait(orientation)){
         self.frame = CGRectMake(0, 0, frame.size.width, 44);
     }
     else if (UIInterfaceOrientationIsLandscape(orientation)){
         self.frame = CGRectMake(0, 0, frame.size.width, 44);
     }
}

@end
