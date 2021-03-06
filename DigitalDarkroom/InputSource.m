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
        imagePath = nil;
        thumbImage = nil;
    }
    return self;
}

+ (InputSource *) sourceForCamera:(Cameras) cam {
    InputSource *newSource = [[InputSource alloc] init];
    newSource.sourceType = cam;
    newSource.label = cameraNames[cam];
    return newSource;
}

static NSString * const cameraNames[] = {
    @"Front\ncamera",
    @"Rear\ncamera",
    @"Front 3D\ncamera",
    @"Rear 3D\ncamera",
    @"File"};

+ (NSString *)cameraNameFor:(Cameras)camera {
    assert(ISCAMERA(camera));
    return cameraNames[camera];
}

@end
