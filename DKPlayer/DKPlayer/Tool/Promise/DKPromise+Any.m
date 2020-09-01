//
//  DKPromise+Any.m
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/8/20.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//

#import "DKPromise+Any.h"
#import "DKPromise+Async.h"

static NSMutableArray *DKPromiseCombineValuesAndErrors(NSArray *promises){
    NSMutableArray *result = [NSMutableArray array];
    for (DKPromise *promise in promises) {
        if (promise.isFulfilled) {
            [result addObject:promise.value ?: [NSNull null]];
            continue;
        }
        
        if (promise.isRejected) {
            [result addObject:promise.error ?: [NSNull null]];
            continue;
        }
        
        assert(!promise.isPending);
    }
    return result;
}

@implementation DKPromise (Any)

-(DKPromise <NSArray *>*)any:(NSArray *)promises{
    return [self onQueue:DKPromise.defaultPromiseQueue any:promises];
}

-(DKPromise <NSArray *>*)onQueue:(dispatch_queue_t)queue
                             any:(NSArray *)promises{
    
    return [DKPromise onQueue:queue async:^(DKPromiseAsyncFulfillBlock  _Nonnull fulfill, DKPromiseAsyncRejectBlock  _Nonnull reject) {
        
        NSInteger count = promises.count;
        NSMutableArray *promiseArray = [promises mutableCopy];
        
        for (int i = 0; i < count; i ++) {
            id value = promises[i];
            if ([value isKindOfClass:[DKPromise class]]) {
                continue;
            }else if ([value isKindOfClass:[NSError class]]){
                reject(value);
                break;
            }else{
                [promiseArray replaceObjectAtIndex:i withObject:[[DKPromise alloc]initWithResolved:value]];
            }
        }
        
        for (DKPromise *promise in promiseArray) {
            
            [promise ObserverOnQueue:queue fulfill:^(id  _Nonnull value) {
                
                for (DKPromise *item in promiseArray) {
                    if (item.isPending) {
                        return;
                    }
                }
                
                fulfill(DKPromiseCombineValuesAndErrors(promises));
                
            } reject:^(NSError * _Nonnull error) {
                
                BOOL lastOneFulfill = NO;
                for (DKPromise *promise in promiseArray) {
                    if (promise.isPending) {
                        return;
                    }
                    
                    if (promise.isFulfilled) {
                        lastOneFulfill = YES;
                    }
                }
                
                if (lastOneFulfill) {
                    fulfill(DKPromiseCombineValuesAndErrors(promises));
                }else{
                    reject(error);
                }
                
            }];
            
        }
        
        
    }];
    
}
@end
