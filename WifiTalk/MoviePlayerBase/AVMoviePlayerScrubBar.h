//
//  AVMoviePlayerScrubBar.h
//  MoviePlayerBase
//
//  Created by Joey Patino on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AVMoviePlayerControlsView.h"

@interface AVMoviePlayerScrubBar : AVMoviePlayerControlsView
@property (nonatomic, strong) IBOutlet UISlider* mScrubber;

- (void)commonInit;
- (BOOL)isScrubbing;
- (void)enableScrubber;
- (void)disableScrubber;


- (void)removePlayerTimeObserver;
@end
