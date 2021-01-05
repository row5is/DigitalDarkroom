//
//  TaskCtrl.h
//  DigitalDarkroom
//
//  Created by William Cheswick on 12/10/20.
//  Copyright © 2020 Cheswick.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Transforms.h"
#import <UIKit/UIKit.h>
#import "MainVC.h"
#import "TaskGroup.h"
#import "Task.h"

NS_ASSUME_NONNULL_BEGIN

// tasks are grouped by targetsize.  All active tasks in a particular group
// are processed in parallel.

typedef enum {
    ScreenTasks,
    ThumbTasks,
    ExternalTasks,
} TaskGroup_t;
#define N_TASK_GROUPS   (ExternalTasks + 1)

@class Task;
@class TaskGroup;

@interface TaskCtrl : NSObject {
    MainVC *mainVC;
    Transforms *transforms;
    NSMutableArray *taskGroups;
    volatile BOOL layoutNeeded;
}

@property (nonatomic, strong)   MainVC *mainVC;
@property (nonatomic, strong)   NSMutableArray *taskGroups;
@property (nonatomic, strong)   Transforms *transforms;
@property (assign, atomic)      BOOL layoutNeeded;

- (TaskGroup *) newTaskGroupNamed:(NSString *)name;

- (void) needLayoutTo:(CGSize) newSize;
- (void) layoutCompleted;

- (void) selectDepthTransform:(int)index;
- (void) executeTasksWithImage:(UIImage *) image;
- (void) depthToPixels: (DepthImage *)depthImage pixels:(Pixel *)depthPixelVisImage;

- (void) layoutIfReady;

@end

NS_ASSUME_NONNULL_END
