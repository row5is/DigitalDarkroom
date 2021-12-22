//
//  Layout.m
//  DigitalDarkroom
//
//  Created by William Cheswick on 3/2/21.
//  Copyright © 2021 Cheswick.com. All rights reserved.
//

#import "Layout.h"
#import "Defines.h"

BOOL
same_aspect(CGSize r1, CGSize r2) {
    float ar1 = r1.width/r1.height;
    float ar2 = r2.width/r2.height;
    float diffPct = DIFF_PCT(ar1,ar2);
    return diffPct < ASPECT_PCT_DIFF_OK;
};

NSString * __nullable displayThumbsPosition[] = {
    @"U",
    @"R",
    @"B",
};

NSString * __nullable displayOptionNames[] = {
    @"thum",
    @"ipho",
    @"ipad",
    @"tote",
    @"tot ",
};


#define EXECUTE_ROW_H       (mainVC.execFontSize + SEP)
#define EXECUTE_H_FOR(n)    ((n)*EXECUTE_ROW_H + 2*EXECUTE_BORDER_W + 2*SEP)
#define EXECUTE_MIN_H       MIN(PLUS_H, EXECUTE_H_FOR(1))
#define EXECUTE_FULL_H      [self executeHForRowCount:6]

#define SCALE_UNINITIALIZED (-1.0)

#define SCREEN  mainVC.containerView.frame

@interface Layout ()


@property (assign)  ThumbsPosition thumbsPosition;
@property (assign)  float thumbScore, displayScore, scaleScore;
@property (assign)  float thumbFrac;

@end

@implementation Layout

@synthesize transformSize;   // what we give the transform chain
@synthesize displayRect;     // where we put the transformed (and scaled) result
@synthesize fullThumbViewRect;
@synthesize thumbScrollRect;
@synthesize executeRect;     // where the active transform list is shown
@synthesize plusRect;        // in executeRect
@synthesize paramRect;       // where the parameter slider goes

@synthesize firstThumbRect;  // thumb size and position in fullThumbViewRect
@synthesize thumbImageRect;  // image sample size in each thumb button

@synthesize format, depthFormat;
@synthesize displayOption, thumbsPosition;

@synthesize imageSourceSize;
@synthesize executeIsTight;
@synthesize displayFrac, thumbFrac;
@synthesize scale, aspectRatio;
@synthesize executeOverlayOK;
@synthesize status, type;
@synthesize score, thumbScore, displayScore, scaleScore;

- (id)initForSize:(CGSize) ss
      rightThumbs:(size_t) rightThumbs
     bottomThumbs:(size_t) bottomThumbs
    displayOption:(DisplayOptions) dopt
              format:(AVCaptureDeviceFormat * __nullable) fmt {
    self = [super init];
    if (self) {
        assert(rightThumbs == 0 || bottomThumbs == 0); // no fancy stuff
        
        imageSourceSize = ss;
        format = fmt;
        displayOption = dopt;
        depthFormat = nil;
        score = BAD_LAYOUT;
        status = nil;   // XXX may be a dreg
        
        aspectRatio = imageSourceSize.width / imageSourceSize.height;
        firstThumbRect = thumbImageRect = CGRectZero;
        thumbImageRect.size = CGSizeMake(THUMB_W, trunc(THUMB_W/aspectRatio));
        firstThumbRect.size = CGSizeMake(thumbImageRect.size.width,
                                         thumbImageRect.size.height + THUMB_LABEL_H);
        BOOL narrowScreen = mainVC.isiPhone;
        CGSize basicExecuteSize = CGSizeMake(narrowScreen ? mainVC.minExecWidth : mainVC.minExecWidth,
                                             narrowScreen ? EXECUTE_MIN_H : EXECUTE_FULL_H);
        paramRect.size = CGSizeMake(LATER, PARAM_VIEW_H);

        CGSize targetSize;
        displayRect.origin = CGPointZero;
        if (rightThumbs) {
            type = @"DP/ET";    // display and params on left, execute and thumbs on right
            thumbScrollRect.size.height = mainVC.containerView.frame.size.height - basicExecuteSize.height;
            thumbScrollRect.size.width = (firstThumbRect.size.width + SEP)*rightThumbs;
            targetSize = CGSizeMake(SCREEN.size.width - thumbScrollRect.size.width - SEP,
                                    SCREEN.size.height - SEP - PARAM_VIEW_H);
            if (targetSize.width < mainVC.minDisplayWidth) {
                NSLog(@"no room for %zu thumb columns on right", rightThumbs);
                return nil;
            }
            displayRect.size = [Layout fitSize:imageSourceSize toSize:targetSize];
            paramRect.origin.y = BELOW(displayRect) + SEP;

            // adjust thumbs view for actual available width:
            thumbScrollRect.size.width = thumbScrollRect.size.width - thumbScrollRect.origin.x;
            
            executeRect.origin = CGPointMake(RIGHT(displayRect) + SEP, 0);
            executeRect.size = CGSizeMake(thumbScrollRect.size.width, basicExecuteSize.height);
            thumbScrollRect.origin = CGPointMake(executeRect.origin.x, BELOW(executeRect) + SEP);
            thumbScrollRect.size.height = SCREEN.size.height - thumbScrollRect.origin.y;
        } else {
            type = @"DPET"; // all in a column
            thumbScrollRect.size.width = mainVC.containerView.frame.size.width;
            thumbScrollRect.size.height = (firstThumbRect.size.height + SEP)*bottomThumbs;
            targetSize = CGSizeMake(SCREEN.size.width,
                                    SCREEN.size.height - SEP - PARAM_VIEW_H - SEP - thumbScrollRect.size.height);
            if (targetSize.height < mainVC.minDisplayHeight) {
                NSLog(@"no room for %zu thumb rows on bottom", bottomThumbs);
                return nil;
            }
            displayRect.size = [Layout fitSize:imageSourceSize toSize:targetSize];
            paramRect.origin.y = BELOW(displayRect) + SEP;
            thumbScrollRect.origin.y = BELOW(paramRect) + SEP;
            thumbScrollRect.size.height = SCREEN.size.height - thumbScrollRect.origin.y;
        }
        
        plusRect = CGRectMake(0, 0, PLUS_H, PLUS_H);
        paramRect.size.width = displayRect.size.width;

        // plus sits at the beginning of the thumbs.  For now.
        firstThumbRect.origin = CGPointMake(RIGHT(plusRect) + SEP, 0);
        
        fullThumbViewRect.origin = CGPointZero;
        fullThumbViewRect.size = CGSizeMake(thumbScrollRect.size.width, LATER);
        
        scale = displayRect.size.width / imageSourceSize.width;
        transformSize = displayRect.size;


        [self scoreLayout];
    }
    return self;
}

- (void) scoreLayout {
#ifdef OLD
    size_t thumbsOnScreen;
    for (thumbsOnScreen=0; thumbsOnScreen < thumbPositionArray.count; thumbsOnScreen++) {
        CGRect thumbRect = thumbPositionArray[thumbsOnScreen].CGRectValue;
        if (thumbRect.origin.y <= BELOW(CONTAINER_FRAME))
            break;
    }
#endif
    
    if (displayRect.size.width < mainVC.minDisplayWidth) {
        score = 0;
//        NSLog(@"display too narrow");
        return;
    }
    if (displayRect.size.height < mainVC.minDisplayHeight) {
        score = 0;
//        NSLog(@"display too short");
        return;
    }

    CGFloat displayArea = displayRect.size.width * displayRect.size.height;
    CGFloat containerArea = SCREEN.size.width * SCREEN.size.height;
    displayFrac = displayArea / containerArea;
#ifdef OLD
    if (displayFrac < mainVC.minDisplayFrac) {
        score = 0;
        return;
    }
#endif
    if (scale == 1.0)
        scaleScore = 1.0;
    else if (scale > 1.0)
        scaleScore = 0.9;   // expanding the image
    else {
        // reducing size isn't a big deal, but we want some penalty for unnecessary reduction
        // 0.8 is the lowest value
        // XXX scaling shouldn't be a factor for fixed images
        scaleScore = 0.8 + 0.2*scale;
    }
    
    // we want the largest display that shows all the thumbs, or, if not
    // room for all the thumbs, the most thumbs with a small display.
    int onScreenThumbsPerRow = thumbScrollRect.size.width / (firstThumbRect.size.width + SEP);
    int onScreenThumbsPerCol = thumbScrollRect.size.height / (firstThumbRect.size.height + SEP);
    int thumbsOnScreen = onScreenThumbsPerRow * onScreenThumbsPerCol;
    float pctThumbsShown = (float)thumbsOnScreen / (float)mainVC.thumbViewsArray.count;
    if (displayOption != OnlyTransformDisplayed && pctThumbsShown < mainVC.minPctThumbsShown)
        thumbScore = 0;
    else {
        thumbScore = pctThumbsShown + displayFrac;
        long wastedThumbs = thumbsOnScreen - (int)mainVC.thumbViewsArray.count;
        
        if (wastedThumbs >= 0) {
            float wastedPenalty = pow(0.999, wastedThumbs);
            thumbScore *= wastedPenalty;  // slight penalty for wasted space
        }
    }

    displayScore = 1.0; // for now
    assert(thumbScore >= 0);
    assert(scaleScore >= 0);
    assert(displayScore >= 0);
    score = thumbScore * scaleScore * displayScore;
    NSLog(@"SSSS   %3.1f * %3.1f * %3.1f  = %3.1f",
          thumbScore, scaleScore, displayScore, score);
}

// I realize that the following may give the wrong result if one dimension
// is greater than the other, but the other is shorter.  It isn't
// that important.

- (NSComparisonResult) compare:(Layout *)layout {
    if (displayRect.size.width > layout.displayRect.size.width ||
        displayRect.size.height > layout.displayRect.size.height)
        return NSOrderedAscending;
    if (displayRect.size.width == layout.displayRect.size.width &&
        displayRect.size.height == layout.displayRect.size.height)
        return NSOrderedSame;
    return NSOrderedDescending;
}

+ (CGSize) fitSize:(CGSize)srcSize toSize:(CGSize)size {
    assert(size.height > 0);
    assert(size.width > 0);
    float xScale = size.width/srcSize.width;
    float yScale = size.height/srcSize.height;
    CGFloat scale = MIN(xScale,yScale);
    CGSize scaledSize;
    scaledSize.width = round(scale*srcSize.width);
    scaledSize.height = round(scale*srcSize.height);
    return scaledSize;
}

- (CGFloat) executeHForRowCount:(size_t)rows {
    return ((rows)*EXECUTE_ROW_H + 2*EXECUTE_BORDER_W + 2*SEP);
}

- (NSString *) layoutSum {
    return [NSString stringWithFormat:@"%4.0fx%4.0f %4.0fx%4.0f %4.2f%%  e%3.0fx%3.0f p%3.0fx%2.0f  %4.2f%%  sc:%4.2f %@",
            transformSize.width, transformSize.height,
            displayRect.size.width, displayRect.size.height,
            scale,
            executeRect.size.width, executeRect.size.height,
            paramRect.size.width, paramRect.size.height,
            displayFrac,
            score, type
    ];
}

- (void) dump {
    NSLog(@"layout dump:  type %@  score %.1f  scale %.2f", type, score, scale);
    NSLog(@"screen format %@", format ? format : @"fixed image");
    if (format && depthFormat)
        NSLog(@"depth format %@", depthFormat);
    
    NSLog(@"source  %4.0fx%4.0f (%5.3f)",
          imageSourceSize.width, imageSourceSize.height,
          imageSourceSize.width / imageSourceSize.height);
    NSLog(@"trans   %4.0fx%4.0f (%5.3f)",
          imageSourceSize.width, imageSourceSize.height,
          imageSourceSize.width / imageSourceSize.height);
    NSLog(@"display %4.0fx%4.0f (%5.3f) at %.0f,%.0f",
          displayRect.size.width, displayRect.size.height,
          displayRect.size.width / displayRect.size.height,
          displayRect.origin.x, displayRect.origin.y);
    NSLog(@"param   %4.0fx%4.0f         at %.0f,%.0f",
          paramRect.size.width, paramRect.size.height,
          paramRect.origin.x, paramRect.origin.y);
    NSLog(@"exec    %4.0fx%4.0f         at %.0f,%.0f",
          executeRect.size.width, executeRect.size.height,
          executeRect.origin.x, executeRect.origin.y);
    NSLog(@"plus    %4.0fx%4.0f         at %.0f,%.0f",
          plusRect.size.width, plusRect.size.height,
          plusRect.origin.x, plusRect.origin.y);
    NSLog(@"first   %4.0fx%4.0f         at %.0f,%.0f",
          firstThumbRect.size.width, firstThumbRect.size.height,
          firstThumbRect.origin.x, firstThumbRect.origin.y);
}

@end
