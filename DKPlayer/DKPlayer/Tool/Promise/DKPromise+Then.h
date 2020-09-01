//
//  DKPromise+Then.h
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/8/20.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//

#import "DKPromise.h"

NS_ASSUME_NONNULL_BEGIN

@interface DKPromise<Value> (Then)

typedef id __nullable (^DKPromiseThenBlock)(Value value);

-(DKPromise *)then:(DKPromiseThenBlock)work;

-(DKPromise *)onQueue:(dispatch_queue_t)queue
                 then:(DKPromiseThenBlock)work;

@end

@interface DKPromise(DKThemAdditions)

-(DKPromise *(^)(DKPromiseThenBlock))then;
-(DKPromise *(^)(dispatch_queue_t, DKPromiseThenBlock))thenOn;
@end

NS_ASSUME_NONNULL_END
