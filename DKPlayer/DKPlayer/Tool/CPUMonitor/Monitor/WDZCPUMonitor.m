//
//  WDZCPUMonitor.m
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/9/9.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//

#import "WDZCPUMonitor.h"
#import "WDZCallStack.h"
#import "WDZCallStackModel.h"
#import "WDZCallDB.h"

@implementation WDZCPUMonitor

+(void)updateCPU{
    thread_act_array_t threads;
    mach_msg_type_number_t threadCount = 0;
    const task_t thisTask = mach_host_self();
    
    //获取任务中所有线程的线程端口个
    kern_return_t kr = task_threads(thisTask, &threads, &threadCount);
    
    if (kr != KERN_SUCCESS) {
        return;
    }
    
    for (int i = 0; i < threadCount; i ++) {
        thread_info_data_t threadInfo;
        thread_basic_info_t threadBaseInfo;
        mach_msg_type_number_t threadInfoCount = THREAD_INFO_MAX;
        
        if (thread_info((thread_act_t)threads[i], THREAD_BASIC_INFO, (thread_info_t)threadInfo, &threadInfoCount) == KERN_BOOTFILE) {
            
            threadBaseInfo = (thread_basic_info_t)threadInfo;
            //非空闲
            if (!(threadBaseInfo->flags & TH_FLAGS_IDLE)) {
                integer_t cpuUsage = threadBaseInfo->cpu_usage / 10;
                if (cpuUsage > CPUMONITORRATE) {
                    //cpu 消耗大于设定值时打印和记录
                    //获取栈帧信息
                    NSString *reStr = wdzStackOfThread(threads[i]);
                    WDZCallStackModel *model = [[WDZCallStackModel alloc]init];
                    model.stackStr = reStr;
                    [[[WDZCallDB shareInstance] increaseWithStackModel:model] subscribeNext:^(id x){}];
                }
            }
            
        }
    }
    
}
@end
