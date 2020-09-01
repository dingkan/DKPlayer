//
//  DKPromise+All.m
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/8/20.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//

#import "DKPromise+All.h"
#import "DKPromise+Async.h"

@implementation DKPromise (All)

+(DKPromise *)all:(NSArray *)promises{
    return [self onQueue:DKPromise.defaultPromiseQueue all:promises];
}

+(DKPromise *)onQueue:(dispatch_queue_t)queue
                  all:(NSArray *)promises{
    
    return [self onQueue:queue async:^(DKPromiseAsyncFulfillBlock  _Nonnull fulfill, DKPromiseAsyncRejectBlock  _Nonnull reject) {
        
        //遍历
        NSMutableArray *promiseArray = [promises mutableCopy];
        NSInteger count = promises.count;
        for (int i = 0 ; i < count; i ++) {
            id value = promises[i];
            
            if ([value isKindOfClass:[self class]]) {
                continue;
            }else if ([value isKindOfClass:[NSError class]]){
                reject(value);
                break;
            }else{
                [promiseArray replaceObjectAtIndex:i withObject:[[DKPromise alloc] initWithResolved:value]];
            }
        }
        
        for (DKPromise *observe in promiseArray) {
            [observe ObserverOnQueue:queue fulfill:^(id  _Nonnull value) {
                
                for (DKPromise *item in promiseArray) {
                    if (!item.isFulfilled) {
                        return;
                    }
                }
                fulfill([promiseArray valueForKey:NSStringFromSelector(@selector(value))]);
                
            } reject:^(NSError * _Nonnull error) {
                reject(error);
            }];
        }
    }];
}
@end


@implementation DKPromise(DKAllAddiotions)

+(DKPromise *(^)(NSArray *))all{
    return ^(NSArray *promises){
        return [self all:promises];
    };
}

+(DKPromise *(^)(dispatch_queue_t, NSArray *))allOn{
    return ^(dispatch_queue_t queue, NSArray *promises){
        return [self onQueue:queue all:promises];
    };
}

@end
