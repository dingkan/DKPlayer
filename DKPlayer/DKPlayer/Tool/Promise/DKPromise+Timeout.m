//
//  DKPromise+Timeout.m
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/8/20.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//

#import "DKPromise+Timeout.h"

@implementation DKPromise (Timeout)

-(DKPromise *)timeout:(NSTimeInterval)time{
    return [self onQueue:DKPromise.defaultPromiseQueue timeout:time];
}

-(DKPromise *)onQueue:(dispatch_queue_t)queue
              timeout:(NSTimeInterval)time{
    
    DKPromise *promise = [DKPromise pendingPromise];
    
    [self ObserverOnQueue:queue fulfill:^(id  _Nonnull value) {
        
        [promise fulfilled:value];
        
    } reject:^(NSError * _Nonnull error) {
        [promise rejected:error];
    }];
    
    //如果超过一定时间还没有执行完成，则直接失败
    __weak typeof(self)weakPromise = promise;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakPromise rejected:[NSError errorWithDomain:@"超时" code:999098080 userInfo:nil]];
    });
    
    return promise;
}
@end
