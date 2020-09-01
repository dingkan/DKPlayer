//
//  DKPromise+Delay.m
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/8/20.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//

#import "DKPromise+Delay.h"

@implementation DKPromise (Delay)

-(DKPromise *)delay:(NSTimeInterval)time{
    return [self onQueue:DKPromise.defaultPromiseQueue time:time];
}

-(DKPromise *)onQueue:(dispatch_queue_t)queue
                 time:(NSTimeInterval)time{
    
    DKPromise *promise = [DKPromise pendingPromise];
    
    [self ObserverOnQueue:queue fulfill:^(id  _Nonnull value) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [promise fulfilled:value];
        });
        
    } reject:^(NSError * _Nonnull error) {
        [promise rejected:error];
    }];
    
    return promise;
    
}
@end
