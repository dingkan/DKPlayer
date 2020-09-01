//
//  DKPromise+Catch.m
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/8/20.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//

#import "DKPromise+Catch.h"

@implementation DKPromise (Catch)

-(DKPromise *)catch:(DKPromiseCatchBlock)work{
    return [self onQueue:DKPromise.defaultPromiseQueue catch:work];
}

-(DKPromise *)onQueue:(dispatch_queue_t)queue catch:(DKPromiseCatchBlock)work{
    
    return [self chainOnQueue:queue onFulfill:nil onReject:^id _Nullable(NSError * _Nonnull error) {
        work(error);
        return error;
    }];
}
@end

@implementation DKPromise(DKCatchAdditions)

-(DKPromise *(^)(DKPromiseCatchBlock))catch{
    return ^(DKPromiseCatchBlock work){
        return [self catch:work];
    };
}

-(DKPromise *(^)(dispatch_queue_t, DKPromiseCatchBlock))catchOn{
    return ^(dispatch_queue_t queue, DKPromiseCatchBlock work){
        return [self onQueue:queue catch:work];
    };
}

@end
