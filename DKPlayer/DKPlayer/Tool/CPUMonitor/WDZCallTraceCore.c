//
//  WDZCallTraceCore.m
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/9/10.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//

#include "WDZCallTraceCore.h"
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
static uint64_t _min_time_cost = 1000;
static int _max_call_depth = 3;
static wdzCallRecord *_wdzCallRecords;

static int _wdzRecordNum;
static int _wdzRecordAlloc;

typedef struct {
    id self;
    Class cls;
    SEL cmd;
    uint64_t time;
    uintptr_t lr; //Link register
} thread_call_record;

typedef struct {
    thread_call_record *stack;
    int allocated_length;
    int index;//方法调用树的深度
    bool is_main_thread;
} thread_call_stack;

//inline是c99的特性。在c99中，inline是向编译器建议，将被inline修饰的函数以内联的方式嵌入到调用这个函数的地方。而编译器会判断这样做是否合适，以此最终决定是否这么做。
static inline thread_call_stack * get_thread_call_stack(){
    //读取线程私有数据
    thread_call_stack *stack = (thread_call_stack *)pthread_getspecific(_thread_key);
    if (stack == NULL) {
        stack = (thread_call_stack *)malloc(sizeof(thread_call_stack));
        stack->stack = (thread_call_record *)calloc(128, sizeof(thread_call_record));
        stack->allocated_length = 64;
        stack->index = -1;
        stack->is_main_thread = pthread_main_np();
        
        //将数据与线程进行绑定
        pthread_setspecific(_thread_key, stack);
    }
    return stack;
}

static void release_thread_call_stack(void *ptr){
    thread_call_stack *stack = (thread_call_stack *)ptr;
    if (stack == NULL) {
        return;
    }
    if (stack->stack) free(stack->stack);
    free(stack);
}

//记录方法调用时间，在开始时深度+1
static inline void push_call_record(id _self, Class _cls, SEL _cmd, uintptr_t _lr){
    thread_call_stack *stack = get_thread_call_stack();
    if (stack) {
        int nextIndex = (++stack->index);
        if (nextIndex > stack->allocated_length) {
            stack->allocated_length += 64;
            stack->stack = (thread_call_record *)realloc(stack->stack, stack->allocated_length * sizeof(thread_call_record));
        }
        
        thread_call_record *newRecord = &stack->stack[nextIndex];
        newRecord->self = _self;
        newRecord->cls = _cls;
        newRecord->cmd = _cmd;
        newRecord->lr = _lr;
        if (stack->is_main_thread && _call_record_enable) {
            struct timeval now;
            gettimeofday(&now, NULL);
            //tv_sec 秒
            //tv_usec 微妙
            newRecord->time = (now.tv_sec % 100) * 1000000 + now.tv_usec;
        }
    }
}

//记录方法结束调用时间
static inline uintptr_t pop_call_record(){
    thread_call_stack *stack = get_thread_call_stack();
    int currentIndex = stack->index;
    int nextIndex = stack->index --;
    thread_call_record *record = &stack->stack[nextIndex];
    
    if (stack->is_main_thread && _call_record_enable) {
        struct timeval now;
        gettimeofday(&now, NULL);
        uint64_t time = (now.tv_sec % 100) * 1000000 + now.tv_usec;
        
        if (time < record->time) {
            time += 100 * 1000000;
        }
        
        uint64_t cost = time - record->time;
        if (cost > _min_time_cost && stack->index < _max_call_depth) {
            if (!_wdzCallRecords) {
                _wdzRecordAlloc = 1024;
                _wdzCallRecords = malloc(sizeof(wdzCallRecord) * _wdzRecordAlloc);
            }
            
            _wdzRecordNum ++;
            if (_wdzRecordNum > _wdzRecordAlloc) {
                _wdzRecordAlloc += 1024;
                _wdzCallRecords = realloc(_wdzCallRecords, sizeof(wdzCallRecord) * _wdzRecordAlloc);
            }
            
            wdzCallRecord *log = &_wdzCallRecords[_wdzRecordNum- 1];
            log->cls = record->cls;
            log->sel = record->cmd;
            log->depth = currentIndex;
            log->time = cost;
        }
    }
    return record->lr;
}

void before_objc_msgSend(id _self, SEL _cmd, uintptr_t _lr){
    push_call_record(_self, object_getClass(_self), _cmd, _lr);
}

uintptr_t after_objc_msgSend(){
    return pop_call_record();
}



