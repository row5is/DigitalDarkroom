//
//  InputSource.m
//  DigitalDarkroom
//
//  Created by William Cheswick on 9/11/20.
//  Copyright © 2020 Cheswick.com. All rights reserved.
//

#import "InputSource.h"


@implementation InputSource

@synthesize sourceType;
@synthesize label;
@synthesize imagePath;
@synthesize thumbImage;
@synthesize imageSize;
@synthesize cameraNames;

- (id)init {
    self = [super init];
    if (self) {
        sourceType = NotACamera;
        imageSize = CGSizeZero;
    }
    return self;
}

+ (NSString *)cameraNameFor:(Cameras)camera {
    assert(ISCAMERA(camera));
    NSArray *cameraNames = @[@"Front camera",
                             @"Rear camera",
                             @"Front 3D camera",
                             @"Rear 3D camera"];
    return [cameraNames objectAtIndex:camera];
}

@end
