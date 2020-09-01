//
//  DKPromise+Async.m
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/8/20.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//

#import "DKPromise+Async.h"

@implementation DKPromise (Async)

+(DKPromise *)async:(DKPromiseAsyncBlock)work{
    return [self onQueue:DKPromise.defaultPromiseQueue async:work];
}

+(DKPromise *)onQueue:(dispatch_queue_t)queue
                async:(DKPromiseAsyncBlock)work{
    
    NSParameterAssert(queue);
    NSParameterAssert(work);
    
    DKPromise *promise = [DKPromise pendingPromise];
    
    dispatch_group_async(DKPromise.defaultPromiseGroup, queue, ^{
       
        work(^(id __nullable value){
            
            if ([value isKindOfClass:[DKPromise class]]) {
                
                [(DKPromise *)value ObserverOnQueue:queue fulfill:^(id  _Nonnull value) {
                    
                    [promise fulfilled:value];
                    
                } reject:^(NSError * _Nonnull error) {
                    [promise rejected:error];
                }];
                    
            }else{
                [promise fulfilled:value];
            }
            
        },^(NSError *error){
            [promise rejected:error];
        });
        
    });
    
    return promise;
}
@end


@implementation DKPromise(DKAsyncAdditions)

+(DKPromise *(^)(DKPromiseAsyncBlock))async{
    return ^(DKPromiseAsyncBlock work){
        return [self async:work];
    };
}

+(DKPromise *(^)(dispatch_queue_t, DKPromiseAsyncBlock))work{
    return ^(dispatch_queue_t queue, DKPromiseAsyncBlock work){
        return [self onQueue:queue async:work];
    };
}

@end
