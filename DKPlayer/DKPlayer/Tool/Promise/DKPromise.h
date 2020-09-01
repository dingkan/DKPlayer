//
//  DKPromise.h
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/8/20.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DKPromiseHeader.h"

NS_ASSUME_NONNULL_BEGIN

@interface DKPromise<__covariant Value> : NSObject

typedef void(^DKPromiseFulfillBlock)(id value);
typedef void(^DKPromiseRejectedBlock)(NSError *error);
typedef id __nullable(^ __nullable DKPromiseChainFulfillBlock)(Value value);
typedef id __nullable(^ __nullable DKPromiseChainRejectBlock)(NSError *error);

@property (class) dispatch_queue_t defaultPromiseQueue;

+(dispatch_group_t)defaultPromiseGroup;

-(void)ObserverOnQueue:(dispatch_queue_t)queue
               fulfill:(DKPromiseFulfillBlock)onFulfill
                reject:(DKPromiseRejectedBlock)onReject;


-(DKPromise *)chainOnQueue:(dispatch_queue_t)queue
              onFulfill:(DKPromiseChainFulfillBlock)onFulfill
                  onReject:(DKPromiseChainRejectBlock)onReject;

-(void)fulfilled:(id)value;

-(void)rejected:(NSError *)error;

-(BOOL)isPending;

-(BOOL)isFulfilled;

-(BOOL)isRejected;

-(id)value;

-(NSError *)error;

+(instancetype)pendingPromise;
+(instancetype)resolvedWith:(nullable id)resolution;

-(instancetype)initWithPending;
-(instancetype)initWithResolved:(nullable id)resolution;
@end

NS_ASSUME_NONNULL_END
