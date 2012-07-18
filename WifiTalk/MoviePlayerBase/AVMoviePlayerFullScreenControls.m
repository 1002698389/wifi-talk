//
//  AVMoviePlayerFullScreenControls.m
//  MoviePlayerBase
//
//  Created by Joey Patino on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AVMoviePlayerFullScreenControls.h"
#import "AVMoviePlayerViewController.h"

#define kSeekTime 10.0

@interface AVMoviePlayerFullScreenControls (){
 
    IBOutlet UIButton *playPauseButton;
}
@end


@implementation AVMoviePlayerFullScreenControls

- (void)setMoviePlayerController:(AVMoviePlayerViewController *)moviePlayerController {

    [super setMoviePlayerController:moviePlayerController];
    
    if (moviePlayerController.shouldAutoPlay)
        [playPauseButton setBackgroundImage:[UIImage imageNamed:@"pause_btn.png"] forState:UIControlStateNormal];
}

- (IBAction)rewindPressed:(id)sender {
    
    CMTime currentTime = self.moviePlayerController.moviePlayer.currentTime;
                          
    double time = CMTimeGetSeconds(currentTime);
    time -= kSeekTime;

    [self.moviePlayerController.moviePlayer seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
}

- (IBAction)playPausePressed:(id)sender {
    
    if (self.moviePlayerController.moviePlayer.rate == 1.0){
        self.moviePlayerController.moviePlayer.rate = 0.0;
        [playPauseButton setBackgroundImage:[UIImage imageNamed:@"play_btn.png"] forState:UIControlStateNormal];
    }
    else {
        self.moviePlayerController.moviePlayer.rate = 1.0;
        [playPauseButton setBackgroundImage:[UIImage imageNamed:@"pause_btn.png"] forState:UIControlStateNormal];
    }
}

- (IBAction)fastForwardPressed:(id)sender {

    CMTime currentTime = self.moviePlayerController.moviePlayer.currentTime;
    
    double time = CMTimeGetSeconds(currentTime);

    time += kSeekTime;
    
    [self.moviePlayerController.moviePlayer seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];

}

@end
