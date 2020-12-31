//
//  TaskGroup.m
//  DigitalDarkroom
//
//  Created by William Cheswick on 12/22/20.
//  Copyright © 2020 Cheswick.com. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "TaskCtrl.h"
#import "TaskGroup.h"
#import "Task.h"

@interface TaskGroup ()

@property (nonatomic, strong)   PixBuf *srcPix;   // common source pixels for all tasks in this group
// remapping for every transform of current size, plus parameter
@property (nonatomic, strong)   NSMutableDictionary *remapCache;

@end

@implementation TaskGroup

@synthesize taskCtrl;
@synthesize srcPix;
@synthesize tasksStatus;

@synthesize tasks;
@synthesize remapCache;
@synthesize bytesPerRow, pixelsInImage, pixelsPerRow;
@synthesize bitsPerComponent;
@synthesize bytesInImage;
@synthesize transformSize;
@synthesize imageOrientation;

- (id)initWithController:(TaskCtrl *) caller {
    self = [super init];
    if (self) {
        self.taskCtrl = caller;
        tasks = [[NSMutableArray alloc] init];
        remapCache = [[NSMutableDictionary alloc] init];
        srcPix = nil;
        bytesPerRow = 0;    // no current configuration
        transformSize = CGSizeZero; // unconfigured group
        tasksStatus = Stopped;
    }
    return self;
}

- (void) removeAllTransforms {
    for (Task *task in tasks)
        [task removeAllTransforms];
}

- (void) removeLastTransform {
    for (Task *task in tasks)
        [task removeLastTransform];
}
- (void) configureForSize:(CGSize) s {
    assert(tasksStatus == Stopped);
    if (s.width == transformSize.width &&
        s.height == transformSize.height &&
        srcPix)
        return; // no change, nothing to do
    transformSize = s;
    srcPix = [[PixBuf alloc] initWithWidth:s.width height:s.height];
    
    // clear and recompute any remaps, since the size has changed.
    [remapCache removeAllObjects];
    
    for (Task *task in tasks) {
        [task configureForSize:(CGSize) s];
    }
    tasksStatus = Ready;
}

// This is called back from task for transforms that remap pixels.  The remapping is based
// on the pixel array size, and maybe parameter settings.  We only compute the transform/parameter
// remap once, because it is good for every identical transform/param in all the tasks in this group.

- (RemapBuf *) remapForTransform:(Transform *) transform params:(Params *)params {
    NSString *name = [NSString stringWithFormat:@"%@:%d", transform.name, params.value];
    RemapBuf *remapBuf = [remapCache objectForKey:name];
    if (remapBuf)
        return remapBuf;
    transform.remapImageF(remapBuf, params);
    [remapCache setObject:remapBuf forKey:name];
    return remapBuf;
}

- (Task *) createTaskForTargetImageView:(UIImageView *) tiv {
    Task *newTask = [[Task alloc] initInGroup:self];
    newTask.taskIndex = tasks.count;
    newTask.targetImageView = tiv;
    [tasks addObject:newTask];
    return newTask;   // XXX not sure we are going to use this
}

- (void) layoutCompleted {
    tasksStatus = Ready;
    for (Task *task in tasks) {
        assert(task.taskStatus == Stopped);
        task.taskStatus = Ready;
    }
}

- (void) executeTasksWithImage:(UIImage *) srcImage {
    // we prepare a read-only PixBuf for this image.
    // Task must not change it: it is shared among the tasks.
    // At the end of the loop, we don't need it any more
    // We assume (and verify) that the incoming buffer has
    // certain properties that not all iOS pixel buffer formats have.
    // srcBuf's pixels are copied out of the kernel buffer, so we
    // don't have to hold the memory lock.

    // The incoming image size might be larger than the transform size.  Reduce it.
    // The aspect ratio should not change.
    
    if (taskCtrl.layoutNeeded && tasksStatus != Stopped) {
        for (Task *task in tasks) {
            if (task.taskStatus != Stopped) {   // still waiting for this one
                return;
            }
        }
        // The are all stopped.  Inform the authorities
        tasksStatus = Stopped;
//        STUB
        return;
    } else {
        for (Task *task in tasks) {
            if (task.taskStatus == Stopped) {   // still waiting for this one
                task.taskStatus = Ready;
            }
        }
    }
    tasksStatus = Running;
    
    CGFloat scale = transformSize.width / srcImage.size.width;
    UIImage *scaledImage = [UIImage imageWithCGImage:srcImage.CGImage
                                               scale:(srcImage.scale * scale)
                                         orientation:(srcImage.imageOrientation)];
    CGImageRef imageRef = [scaledImage CGImage];
    
#ifdef notdef
    CFDataRef rawData = CGDataProviderCopyData(CGImageGetDataProvider(imageRef));
    CFIndex length = CFDataGetLength(rawData);
    UInt8 * buf = (UInt8 *) CFDataGetBytePtr(rawData);
    NSLog(@" AA %ld", (long)length);
    NSLog(@" BB %lu", srcPix.h * srcPix.w * sizeof(Pixel));
    assert(length >= srcPix.h * srcPix.w * sizeof(Pixel));
    size_t len = srcPix.h * srcPix.w * sizeof(Pixel);
    memcpy(srcPix.pb, buf, len);
    CFRelease(rawData);
#endif
    
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
//    NSUInteger bytesPerPixel = CGImageGetBitsPerPixel(imageRef);
    NSUInteger bytesPerRow = CGImageGetBytesPerRow(imageRef);
    NSUInteger bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(srcPix.pb, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 BITMAP_OPTS);
    CGColorSpaceRelease(colorSpace);

    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);

    @synchronized (srcPix) {
        for (Task *task in tasks) {
            if (task.taskStatus == Running)
                continue;
            [task executeTransformsWithPixBuf:srcPix];
        }
    }
}

- (void) configureForImage:(UIImage *) image {
}

@end
