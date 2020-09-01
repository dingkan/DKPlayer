//
//  DKPromise+All.h
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/8/20.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//  处理多个promise，只要其中有一个失败就返回

#import "DKPromise.h"

NS_ASSUME_NONNULL_BEGIN

@interface DKPromise<Value> (All)

+(DKPromise *)all:(NSArray *)promises;

+(DKPromise *)onQueue:(dispatch_queue_t)queue
                  all:(NSArray *)promises;

@end

@interface DKPromise(DKAllAddiotions)

+(DKPromise *(^)(NSArray *))all;

+(DKPromise *(^)(dispatch_queue_t, NSArray *))allOn;

@end

NS_ASSUME_NONNULL_END
