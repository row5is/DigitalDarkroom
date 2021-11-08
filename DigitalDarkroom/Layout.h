//
//  Layout.h
//  DigitalDarkroom
//
//  Created by William Cheswick on 3/2/21.
//  Copyright © 2021 Cheswick.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "MainVC.h"

NS_ASSUME_NONNULL_BEGIN

#define LAYOUT_IS_BAD(q)   (q < 0)

#define BAD_LAYOUT          (0.0)    // no quality. 1.0 is perfect

typedef enum {
    Bottom,
    Right,
    Both,
    None,
} ThumbsPosition;

@interface Layout : NSObject {
    AVCaptureDeviceFormat * __nullable format;
    AVCaptureDeviceFormat * __nullable depthFormat;
    DisplayOptions displayOption;

    float scale;            // how we scale the capture image.  1.0 (no scaling) is most efficient
    float aspectRatio;      // of the input source
    // quality of layout from 0.0 (reject) to 1.0 (perfect)
    float score;

    // layout stats and results:
    BOOL executeIsTight;    // if save verticle space
    float displayFrac;      // fraction of total display used by the transformed image
    
    CGSize imageSourceSize;
    CGSize transformSize;   // what we give the transform chain
    CGRect displayRect;     // what we give to the main display
    CGRect thumbArrayRect;  // space for the thumb array, to be placed according thumbsPlacement later
    CGRect firstThumbRect;  // thumb size for device, orientation, and aspect ratio
    CGRect thumbImageRect;  // image sample size in the thumb
    CGRect executeRect;     // where the active transform list is shown
    BOOL executeOverlayOK;  // if execute can creep up onto the transform display
    NSString *status;
    int maxThumbRows, maxThumbColumns;
}

@property (nonatomic, strong)   AVCaptureDeviceFormat * __nullable format;
@property (nonatomic, strong)   AVCaptureDeviceFormat * __nullable depthFormat;
@property (assign)              DisplayOptions displayOption;
@property (assign)              float score;
@property (assign)              float displayFrac;
@property (assign)              int maxThumbRows, maxThumbColumns;

@property (assign)              CGSize imageSourceSize;
@property (assign)              CGSize transformSize;   // what we give to the transform chain
@property (assign)              CGRect displayRect;     // where the transform chain puts the (possibly scaled) result
@property (assign)              CGRect thumbArrayRect;  // where the scrollable thumb array goes
@property (assign)              CGRect executeRect;     // total area available for the execute list
@property (assign)              BOOL executeOverlayOK, executeIsTight;  // text placement guidance

@property (assign)              CGRect firstThumbRect, thumbImageRect;

@property (assign)              float scale, aspectRatio;
@property (assign)              int quality;        // -1 = no, more positive is better

@property (nonatomic, strong)   NSString *status;

- (id)initWithOption:(DisplayOptions) disopt
          sourceSize:(CGSize) ss
              format:(AVCaptureDeviceFormat * __nullable) fmt;

- (BOOL) tryLayoutForThumbRowCount:(int) rowsWanted
                       columnCount:(int) columnsWanted;

- (NSComparisonResult) compare:(Layout *)layout;
+ (CGSize) fitSize:(CGSize)srcSize toSize:(CGSize)size;
- (NSString *) info;

extern  NSString * __nullable displayOptionNames[];

@end

NS_ASSUME_NONNULL_END
