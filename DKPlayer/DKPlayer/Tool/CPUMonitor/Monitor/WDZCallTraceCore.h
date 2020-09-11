//
//  WDZCallTraceCore.h
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/9/10.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//


#include <stdio.h>
#include <objc/objc.h>
#include "fishhook.h"

typedef struct {
    __unsafe_unretained Class cls;
    SEL sel;
    uint64_t time;
    int depth;
} wdzCallRecord;

extern void wdzCallTraceStart(void);
extern void wdzCallTraceStop(void);

extern void wdzCallConfigMinTime(uint64_t us);//毫秒
extern void wdzCallConfigMaxDepth(int depth);//3

extern wdzCallRecord *wdzGetCallRecords(int *num);
extern void wdzClearCallRecords(void);
