//
//  CameraController.h
//  DigitalDarkroom
//
//  Created by ches on 9/15/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "MainVC.h"
#import "InputSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface CameraController : NSObject {
    AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
    __unsafe_unretained id<AVCaptureVideoDataOutputSampleBufferDelegate,
            AVCaptureDepthDataOutputDelegate>delegate;
}

@property (nonatomic, strong)   AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (assign)  __unsafe_unretained id<AVCaptureVideoDataOutputSampleBufferDelegate,
                    AVCaptureDepthDataOutputDelegate>delegate;


- (BOOL) isCameraAvailable:(Cameras) camera;
- (void) selectCamera:(Cameras) camera;
- (void) setupSessionForCurrentDeviceOrientation;
- (CGSize) setupCameraForSize:(CGSize) availableSize;

- (void) startCamera;
- (void) stopCamera;
- (BOOL) isCameraOn;

+ (AVCaptureVideoOrientation) videoOrientationForDeviceOrientation;
+ (NSString *) dumpDeviceOrientationName: (UIDeviceOrientation) o;

- (NSString *) dumpFormatType:(OSType) t;

@end

NS_ASSUME_NONNULL_END
