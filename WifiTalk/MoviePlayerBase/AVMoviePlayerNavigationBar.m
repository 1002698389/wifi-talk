//
//  AVMoviePlayerNavigationBar.m
//  MoviePlayerBase
//
//  Created by Joey Patino on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AVMoviePlayerNavigationBar.h"
#import "AVMoviePlayerViewController.h"

@interface AVMoviePlayerNavigationBar (){
 
    IBOutlet UILabel *remainingTime;
    IBOutlet UILabel *currentPlaybackTime;
    IBOutlet UIButton *fsButton;
    id mTimeObserver;
    NSInteger margin;

}

- (NSString *)currentTimeStringWithTime:(double)time;
- (IBAction)fsPressed:(id)sender;

@end


@implementation AVMoviePlayerNavigationBar

@synthesize doneHandler = _doneHandler;
@synthesize fsHandler;

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItem *pItem = (AVPlayerItem *)object;
        AVPlayerItemStatus status = pItem.status;
        
        if (status == AVPlayerItemStatusReadyToPlay){

            @try {
                [self.moviePlayerController.moviePlayer.currentItem removeObserver:self forKeyPath:@"status"];
            }
            @catch (NSException *exception) {
//                return;
            }
            @finally {
                
            }

            if (mTimeObserver != nil) {
                [self.moviePlayerController.moviePlayer removeTimeObserver:mTimeObserver];
            }

            mTimeObserver = nil;
                            
            double tolerance = 1.0;
            mTimeObserver = [self.moviePlayerController.moviePlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(tolerance, NSEC_PER_SEC) 
                                                                                                  queue:NULL 
                                                                                             usingBlock: ^(CMTime time) {

                                                                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                                                                     
                                                                                                     double currentTime = CMTimeGetSeconds(time);
                                                                                                     double timeLeft;
                                                                                                     timeLeft = CMTimeGetSeconds(self.moviePlayerController.moviePlayer.currentItem.duration) - currentTime;

                                                                                                     currentPlaybackTime.text = [self currentTimeStringWithTime:currentTime];
                                                                                                     remainingTime.text = [self currentTimeStringWithTime:timeLeft];
                                                                                                 });
                                                                                                 
                                                                                             }];
           
        }
        else if (status == AVPlayerItemStatusFailed){

        }
    }
}

- (NSString *)currentTimeStringWithTime:(double)time {
 
    NSInteger seconds = (int)time % 60;
    NSInteger minutes = time / 60;
    NSInteger hour = time / 60 / 60;

    NSString *secondsBuffer = @"";
    NSString *minutesBuffer = @"";
    NSString *hourBuffer = @"";
    
    if (minutes >= 60) minutes = minutes % 60;
    if (minutes < 10) minutesBuffer = @"0";
    if (seconds < 10) secondsBuffer = @"0";
    if (hour > 0) hourBuffer = [NSString stringWithFormat:@"%i:", hour];

    return [NSString stringWithFormat:@"%@%@%i:%@%i", hourBuffer, minutesBuffer, minutes, secondsBuffer, seconds];
}

- (void)commonInit {
    
    [super commonInit];
    self.mScrubber.frame = CGRectInset(self.bounds, (self.bounds.size.width * .15), 0);
    margin = 4.0;
    
    if (self.moviePlayerController.moviePlayer.currentItem.status == AVPlayerItemStatusReadyToPlay ){
      
        if (mTimeObserver != nil) {
            [self.moviePlayerController.moviePlayer removeTimeObserver:mTimeObserver];
        }
        mTimeObserver = nil;
        
        double duration = CMTimeGetSeconds(self.moviePlayerController.moviePlayer.currentItem.duration);
        
        CGFloat width = CGRectGetWidth([self.mScrubber bounds]);
        double tolerance = 0.5f * duration / width;

            
        mTimeObserver = [self.moviePlayerController.moviePlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(tolerance, NSEC_PER_SEC) 
                                                                                              queue:NULL 
                                                                                         usingBlock: ^(CMTime time) {
                                                                                             
                                                                                             dispatch_async(dispatch_get_main_queue(), ^{

                                                                                                 double currentTime = CMTimeGetSeconds(time);
                                                                                                 double timeLeft;

                                                                                                 timeLeft = CMTimeGetSeconds(self.moviePlayerController.moviePlayer.currentItem.duration)-currentTime;
                                                                                             
                                                                                                 remainingTime.text = [self currentTimeStringWithTime:currentTime];
                                                                                                 currentPlaybackTime.text = [self currentTimeStringWithTime:timeLeft];
                                                                                             });
                                                                                         
                                                                                         }];
    }
    else {

        /* Observe the player item "status" key to determine when it is ready to play. */
        [self.moviePlayerController.moviePlayer.currentItem addObserver:self
                                                             forKeyPath:@"status"
                                                                options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                                                context:(void *)self];

    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(movieEnded:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.moviePlayerController.moviePlayer.currentItem];

}

-(void) movieEnded:(NSNotification*)notifiation {
    
    if ([notifiation object] == self.moviePlayerController.moviePlayer.currentItem) {
        
        [self donePressed:nil];
    }
}

- (IBAction)donePressed:(id)sender {
    
    [self.moviePlayerController shutDown];
    [self.moviePlayerController setFullScreen:NO animated:YES];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.moviePlayerController.moviePlayer removeTimeObserver:mTimeObserver];
    
    [fsButton setImage:[UIImage imageNamed:@"expand_fullscreen_ipad.png"] forState:UIControlStateNormal];
    
    if (self.doneHandler != nil)
        self.doneHandler();
}

- (IBAction)fsPressed:(id)sender { 
    
    if (self.fsHandler != nil)
        self.fsHandler();

    BOOL isFullScreen = !self.moviePlayerController.isFullScreen;

    if (isFullScreen){
        [fsButton setImage:[UIImage imageNamed:@"collapse_fullscreen_ipad.png"] forState:UIControlStateNormal];
    }
    else {
        [fsButton setImage:[UIImage imageNamed:@"expand_fullscreen_ipad.png"] forState:UIControlStateNormal];
    }
}

- (void)setIsFullScreen:(BOOL)isFullScreen {
    
    if (isFullScreen){
        margin = 0;
    }
    else {
        margin = 4;
    }
    
    if (isFullScreen){
        [fsButton setImage:[UIImage imageNamed:@"collapse_fullscreen_ipad.png"] forState:UIControlStateNormal];
    }
    else {
        [fsButton setImage:[UIImage imageNamed:@"expand_fullscreen_ipad.png"] forState:UIControlStateNormal];
    }
}


- (void)didRotate:(UIInterfaceOrientation)orientation withParentFrame:(CGRect)frame {
    self.frame = CGRectMake(margin, margin, self.moviePlayerController.view.frame.size.width-(2*margin), self.frame.size.height);
}


@end
