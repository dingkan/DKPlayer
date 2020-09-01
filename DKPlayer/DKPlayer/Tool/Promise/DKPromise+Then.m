//
//  DKPromise+Then.m
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/8/20.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//

#import "DKPromise+Then.h"

@implementation DKPromise (Then)

-(DKPromise *)then:(DKPromiseThenBlock)work{
    return [self onQueue:DKPromise.defaultPromiseQueue then:work];
}

-(DKPromise *)onQueue:(dispatch_queue_t)queue
                 then:(DKPromiseThenBlock)work{
    
    NSParameterAssert(queue);
    NSParameterAssert(work);
    
    return [self chainOnQueue:queue onFulfill:work onReject:nil];
}

@end


@implementation DKPromise(DKThemAdditions)

-(DKPromise *(^)(DKPromiseThenBlock))then{
    return ^(DKPromiseThenBlock work){
        return [self then:work];
    };
}

-(DKPromise *(^)(dispatch_queue_t, DKPromiseThenBlock))thenOn{
    return ^(dispatch_queue_t queue, DKPromiseThenBlock work){
        return [self onQueue:queue then:work];
    };
}


@end

