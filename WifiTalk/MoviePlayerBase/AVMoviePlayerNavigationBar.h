//
//  AVMoviePlayerNavigationBar.h
//  MoviePlayerBase
//
//  Created by Joey Patino on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AVMoviePlayerScrubBar.h"

typedef void(^MovieDoneHandler)();
typedef void(^FullscreenHandler)();

@interface AVMoviePlayerNavigationBar : AVMoviePlayerScrubBar

@property (copy, nonatomic) MovieDoneHandler doneHandler;
@property (copy, nonatomic) FullscreenHandler fsHandler;
@end
