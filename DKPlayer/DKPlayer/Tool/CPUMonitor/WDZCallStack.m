//
//  WDZCallStack.m
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/9/9.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//

#import "WDZCallStack.h"
#import "WDZCallLib.h"

//栈帧
//uintptr_t 类型用来存放指针地址
typedef struct WDZStackFrame{
    const struct WDZStackFrame *const previous;
    const uintptr_t return_address;
}WDZStackFrame;

//thread info
typedef struct WDZThreadInfoFrame{
    double cpuUsage;
    integer_t userTime;
}WDZThreadInfoFrame;

static mach_port_t _wdzMainThreadId;

@implementation WDZCallStack

+(void)load{
    //获得线程内核端口的发送权限
    _wdzMainThreadId = mach_thread_self();
}

+(NSString *)callStackWithType:(kWDZStackType)type{
    
    if (type == kWDZStackTypeAll) {
        
        thread_act_array_t list;
        mach_msg_type_number_t listCnt = 0;
        const task_t task = mach_thread_self();//init
        //获取这个task 所有线程
        kern_return_t kt = task_threads(task, &list, &listCnt);
        if (kt != KERN_SUCCESS) {
            return @"fail get all threads";
        }
        
        
    }else if (type == kWDZStackTypeMain){
        
    }else if (type == kWDZStackTypeCurrent){
        
    }
}

@end
