//
//  Task.h
//  DigitalDarkroom
//
//  Created by William Cheswick on 12/16/20.
//  Copyright © 2020 Cheswick.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TaskGroup.h"

#import "Transforms.h"
#import "Transform.h"

NS_ASSUME_NONNULL_BEGIN

#define UNASSIGNED_TASK (-1)

@interface Task : NSObject {
    TaskStatus_t taskStatus;
    NSMutableArray *transformList;
    UIImageView *targetImageView;
    long taskIndex;  // or UNASSIGNED_TASK
}

@property (assign)              BOOL active, busy;
@property (assign, atomic)      TaskStatus_t taskStatus;
@property (nonatomic, strong)   UIImageView *targetImageView;
@property (strong, nonatomic)   NSMutableArray *transformList;
@property (assign)              long taskIndex;
@property (strong, nonatomic)   TaskGroup *taskGroup;

- (id)initInGroup:(TaskGroup *) tg;

- (void) appendTransform:(Transform *) transform;
- (void) removeLastTransform;
- (void) removeAllTransforms;
- (void) configureForSize:(CGSize) s;
- (void) executeTransformsWithPixBuf:(const PixBuf *) srcBuf;

@end

NS_ASSUME_NONNULL_END
