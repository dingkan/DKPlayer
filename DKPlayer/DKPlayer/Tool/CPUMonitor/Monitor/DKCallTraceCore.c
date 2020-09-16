//
//  DKCallTraceCore.m
//  DKPlayer
//
//  Created by 丁侃 on 2020/9/16.
//  Copyright © 2020 丁侃. All rights reserved.
//

#include "DKCallTraceCore.h"

#include "fishhook.h"

#ifdef __aarch64__


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stddef.h>
#include <stdint.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <objc/message.h>
#include <objc/runtime.h>
#include <dispatch/dispatch.h>
#include <pthread.h>

static pthread_key_t _thread_key;
static bool _call_record_enable = true;
static uint64_t _min_time_cost = 1000;//us
static int _max_call_depth = 3;

static DKCallRecord *_dkCallRecords;
static int _dkRecordNum;
static int _dkRecordAlloc;


typedef struct {
    id self;
    Class cls;
    SEL cmd;
    uint64_t time;
    uint64_t lr;
} thread_call_record;


typedef struct {
    thread_call_record *stack;
    int allocated_length;
    int index;//记录当前调用方法树的深度
    bool is_main_thread;
} thread_call_stack;


static inline thread_call_stack *get_thread_call_stack(){
    thread_call_stack *cs = (thread_call_stack *)pthread_getspecific(_thread_key);
    if (cs == NULL) {
        cs = (thread_call_stack *)malloc(sizeof(thread_call_stack));
        cs->stack = (thread_call_record *)calloc(128, sizeof(thread_call_record));
        cs->allocated_length = 64;
        cs->index = -1;
        cs->is_main_thread = pthread_main_np();
        //绑定
        pthread_setspecific(_thread_key, cs);
    }
    return cs;
}

static inline void push_call_record(id _self, Class _cls, SEL _cmd, uintptr_t lr){
    thread_call_stack *cs = get_thread_call_stack();
    if (cs) {
        int nextIndex = (++ cs->index);
        //扩容
        if (nextIndex >= cs->allocated_length) {
            cs->allocated_length += 64;
            cs->stack = (thread_call_record *)realloc(cs->stack, cs->allocated_length * sizeof(thread_call_record));
        }
        thread_call_record *newRecord = &cs->stack[nextIndex];
        newRecord->self = _self;
        newRecord->cls = _cls;
        newRecord->cmd = _cmd;
        newRecord->lr = lr;
        
        if (cs->is_main_thread && _call_record_enable) {
            struct timeval now;
            gettimeofday(&now, NULL);
            newRecord->time = (now.tv_sec % 100) * 1000000 + now.tv_usec;
        }
    }
}

static inline uintptr_t pop_call_record(){
    thread_call_stack *cs = get_thread_call_stack();
    int curIndex = cs->index;
    int nextIndex = cs->index --;
    //获取前一个方法
    thread_call_record *pRecord = &cs->stack[nextIndex];
    
    if (cs->is_main_thread && _call_record_enable) {
        struct timeval now;
        gettimeofday(&now, NULL);
        uint64_t time = (now.tv_sec % 100) * 1000000 + now.tv_usec;
        if (time < pRecord->time) {
            time += 100 * 1000000;
        }
        
        uint64_t cost = time - pRecord->time;
        if (cost > _min_time_cost && cs->index < _max_call_depth) {
            
            //初始化格式化耗时数据
            if (!_dkCallRecords) {
                _dkRecordAlloc = 1024;
                _dkCallRecords = malloc(sizeof(DKCallRecord) * _dkRecordAlloc);
            }
            
            _dkRecordNum ++;
            if (_dkRecordNum > _dkRecordAlloc) {
                _dkRecordAlloc += 1024;
                _dkCallRecords = realloc(_dkCallRecords, sizeof(DKCallRecord) * _dkRecordAlloc);
            }
            
            //记录数据到格式化耗时数据
            DKCallRecord *log = &_dkCallRecords[_dkRecordNum - 1];
            log->cls = pRecord->cls;
            log->depth = curIndex;
            log->sel = pRecord->cmd;
            log->time = cost;
        }
    }
    return pRecord->lr;
}

void before_objc_msgSend(id self, SEL _cmd, uintptr_t lr){
    push_call_record(self, object_getClass(self), _cmd, lr);
}

uintptr_t after_objc_msgSend(){
    return pop_call_record();
}

#define call(b, value)\
__asm volatile ("stp x8, x9, [sp, #-16]!\n");\
__asm volatile ("mov x12, %0\n" :: "r"(value));\
__asm volatile ("ldp x8, x9, [sp], #16\n");\
__asm volatile (#b " x12\n");

#else

#endif
