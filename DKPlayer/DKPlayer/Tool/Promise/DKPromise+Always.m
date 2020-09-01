//
//  DKPromise+Always.m
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/8/20.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//

#import "DKPromise+Always.h"

@implementation DKPromise (Always)

-(DKPromise *)always:(DKPromiseAlwaysBlock)work{
    return [self onQueue:DKPromise.defaultPromiseQueue always:work];
}

-(DKPromise *)onQueue:(dispatch_queue_t)queue
               always:(DKPromiseAlwaysBlock)work{
    
    NSParameterAssert(queue);
    NSParameterAssert(work);

    return [self chainOnQueue:queue onFulfill:^id _Nullable(id  _Nonnull value) {
        
        work();
        
        return value;
        
    } onReject:^id _Nullable(NSError * _Nonnull error) {
        work();
        
        return error;
    }];
}
@end

@implementation DKPromise(DKAlwaysAdditions)

-(DKPromise *(^)(DKPromiseAlwaysBlock))always{
    return ^(DKPromiseAlwaysBlock work){
        return [self always:work];
    };
}

-(DKPromise *(^)(dispatch_queue_t, DKPromiseAlwaysBlock))alwaysOn{
    return ^(dispatch_queue_t queue, DKPromiseAlwaysBlock work){
        return [self onQueue:queue always:work];
    };
}

@end
