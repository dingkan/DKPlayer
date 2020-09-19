//
//  DKCallTraceCore.h
//  DKPlayer
//
//  Created by 丁侃 on 2020/9/16.
//  Copyright © 2020 丁侃. All rights reserved.
//

#ifndef DKCallTraceCore_h
#define DKCallTraceCore_h

#include <stdio.h>
#include <objc/objc.h>


typedef struct {
    __unsafe_unretained Class cls;
    SEL sel;
    uint64_t time;
    int depth;
} DKCallRecord;





#endif
