//
//  WDZCallDB.h
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/9/9.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <FMDB.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/RACEXTScope.h>

#import "WDZCallStackModel.h"
#import "WDZCallTraceTimeCostModel.h"

#define PATH_OF_APP_HOME    NSHomeDirectory()
#define PATH_OF_TEMP        NSTemporaryDirectory()
#define PATH_OF_DOCUMENT    [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]

#define CPUMONITORRATE 80
#define STUCKMONITORRATE 88

NS_ASSUME_NONNULL_BEGIN

@interface WDZCallDB : NSObject

+(instancetype)shareInstance;

#pragma stack
-(RACSignal *)increaseWithStackModel:(WDZCallStackModel *)model;
-(RACSignal *)selectStackWithPage:(NSUInteger)page;
-(void)clearStackData;

#pragma clsStack
-(void)addClsCallStackModel:(WDZCallTraceTimeCostModel *)model;
-(RACSignal *)selectClsCallStackWithPage:(NSUInteger)page;
-(void)clearClsCallStackData;


/**
 1.对objc_msgSend监听，在调用前后分别插入兼容代码
    1.前push_call_record方法记录方法调用时间
        - pthread_getspecific/pthread_setspecific 方法与线程的绑定 获取/绑定 该线程对应方法的私有数据 获取thread_call_stack自定义结构体（标识了调用方法的信息、方法名、方法类型、树深）线程中的函数调用栈
        - 获取该线程的栈数据，并且扩展stack类型存储空间。记录当前方法的信息添加到stack中
    2.后pop_call_record记录方法结束调用时间。返回下一个函数调用地址
        - 获取当前线程的函数调用栈信息
        - 获取当前的调用方法，判断该方法是否是在主线程并且开启记录。记录在格式化耗时记录数据上

 2.对于监听的方法
 */

@end

NS_ASSUME_NONNULL_END
