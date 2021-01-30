//
//  TransformInstance.m
//  DigitalDarkroom
//
//  Created by William Cheswick on 12/14/20.
//  Copyright © 2020 Cheswick.com. All rights reserved.
//

#import "TransformInstance.h"

@implementation TransformInstance

@synthesize value;
@synthesize remapBuf;
@synthesize elapsedProcessingTime;
@synthesize timesCalled;


- (id) initFromTransform:(Transform *)transform {
    self = [super init];
    if (self) {
        remapBuf = nil;
        value = transform.value;
        timesCalled = 0;
        elapsedProcessingTime = 0;
    }
    return self;
}

- (NSString *) valueInfo {
    return [NSString stringWithFormat:@"%4d", value];
}

- (NSString *) timeInfo {
    return [NSString stringWithFormat:@"%5.1f", 23.1];
}

@end
