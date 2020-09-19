//
//  WDZLagMonitor.m
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/9/10.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//

#import "WDZLagMonitor.h"
#import "WDZCallStack.h"
#import "WDZCallDB.h"
#import "WDZCPUMonitor.h"

@interface WDZLagMonitor()
{
    int timeoutCount;
    CFRunLoopObserverRef runLoopobserver;
    
    @public
    dispatch_semaphore_t dispatchSemaphore;
    CFRunLoopActivity runLoopActivity;
}

@property (nonatomic, strong) NSTimer *cpuMonitorTime;

@end

@implementation WDZLagMonitor

+(instancetype)shareInstance{
    static WDZLagMonitor *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc]init];
    });
    return manager;
}

-(void)beginMonitor{
    self.isMonitoring = YES;
    
    self.cpuMonitorTime = [NSTimer scheduledTimerWithTimeInterval:3
                                                             target:self
                                                           selector:@selector(updateCPUInfo)
                                                           userInfo:nil
                                                            repeats:YES];
    
    //卡顿
    if (runLoopobserver) {
        return;
    }
    
    dispatchSemaphore = dispatch_semaphore_create(0);
    //创建观察者
    CFRunLoopObserverContext context = {0,(__bridge void *)self, NULL, NULL};
    runLoopobserver = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, &runLoopObserverCallBack, &context);
    CFRunLoopAddObserver(CFRunLoopGetMain(), runLoopobserver, kCFRunLoopCommonModes);
    
    //子线程监控
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
       
        while (YES) {
            long semaphoreWait = dispatch_semaphore_wait(self->dispatchSemaphore, dispatch_time(DISPATCH_TIME_NOW, STUCKMONITORRATE * NSEC_PER_MSEC));
            
            if (semaphoreWait != 0) {
                
                if (!self->runLoopobserver) {
                    self->timeoutCount = 0;
                    self->dispatchSemaphore = 0;
                    self->runLoopActivity = 0;
                    return;
                }
                
                //检测卡顿
                if (self->runLoopActivity == kCFRunLoopBeforeSources || self->runLoopActivity == kCFRunLoopAfterWaiting) {
                    if (++self->timeoutCount < 3) {
                        continue;
                    }
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                       
                        NSString *reStr = [WDZCallStack callStackWithType:(kWDZStackTypeAll)];
                        WDZCallStackModel *model = [[WDZCallStackModel alloc]init];
                        model.stackStr = reStr;
                        model.isStuck = YES;
                        
                        [[[WDZCallDB shareInstance] increaseWithStackModel:model] subscribeNext:^(id x){}];
                    });
                }
                
            }
            
            self->timeoutCount = 0;
        }
        
    });
}

-(void)endMonitor{
    
    self.isMonitoring = NO;
    [self.cpuMonitorTime invalidate];
    
    if (!runLoopobserver) {
        return;
    }
    
    CFRunLoopRemoveObserver(CFRunLoopGetMain(), runLoopobserver, kCFRunLoopCommonModes);
    CFRelease(runLoopobserver);
    runLoopobserver = NULL;
}

-(void)updateCPUInfo{
    [WDZCPUMonitor updateCPU];
}

static void runLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info){
    WDZLagMonitor *lagMonitor = (__bridge WDZLagMonitor *)info;
    lagMonitor->runLoopActivity = activity;
    
    dispatch_semaphore_t semaphore = lagMonitor->dispatchSemaphore;
    dispatch_semaphore_signal(semaphore);
}

@end
