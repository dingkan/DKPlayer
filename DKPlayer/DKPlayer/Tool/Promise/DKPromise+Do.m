//
//  DKPromise+Do.m
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/8/20.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//

#import "DKPromise+Do.h"

@implementation DKPromise (Do)

-(DKPromise *)do:(DKPromiseDoBlock)work{
    return [self onQueue:DKPromise.defaultPromiseQueue do:work];
}

-(DKPromise *)onQueue:(dispatch_queue_t)queue do:(DKPromiseDoBlock)work{
    DKPromise *promise = [DKPromise pendingPromise];
    
    dispatch_group_async(DKPromise.defaultPromiseGroup, queue, ^{
       
        id value = work();
        
        if([value isKindOfClass:[DKPromise class]]){
            
            [(DKPromise *)value ObserverOnQueue:queue fulfill:^(id  _Nonnull value) {
               
                [promise fulfilled:value];
                
            } reject:^(NSError * _Nonnull error) {
                [promise rejected:error];
            }];
            
        }else{
            [promise fulfilled:value];
        }
        
    });
    
    return promise;
}
@end


@implementation DKPromise(DKDoAdditions)

-(DKPromise *(^)(DKPromiseDoBlock))do{
    return ^(DKPromiseDoBlock work){
        return [self do:work];
    };
}

-(DKPromise *(^)(dispatch_queue_t, DKPromiseDoBlock))doOn{
    return ^(dispatch_queue_t queue, DKPromiseDoBlock work){
        return [self onQueue:queue do:work];
    };
}

@end
