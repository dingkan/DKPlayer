//
//  DKPromise.m
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/8/20.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//

#import "DKPromise.h"

static dispatch_queue_t DKPromiseDefaultQueue;
typedef void(^DkPromiseObserverBlock)(DKPromiseState state, id value);

@interface DKPromise()
{
    DKPromiseState _state;
    
    id _value;
    
    NSError *_error;
    
    NSMutableArray <DkPromiseObserverBlock>*_observers;
    
    NSMutableSet *_pendingObejcts;
}

@end

@implementation DKPromise
#pragma public
-(void)fulfilled:(id)value{
    NSParameterAssert(value);
    
    if ([value isKindOfClass:[NSError class]]) {
        [self rejected:value];
    }else{
        @synchronized (self) {
            _state = DKPromiseStateFulfilled;
            _value = value;
            _pendingObejcts = nil;
            for (DkPromiseObserverBlock observer in _observers) {
                observer(_state, _value);
            }
            _observers = nil;
        }
    }
    
}

-(void)rejected:(NSError *)error{
    NSParameterAssert(error);
    
    if (![error isKindOfClass:[NSError class]]) {
        @throw error;
    }else{
        @synchronized (self) {
            _state = DKPromiseStateRejected;
            _error = error;
            _pendingObejcts = nil;
            for (DkPromiseObserverBlock observer in _observers) {
                observer(_state, error);
            }
            _observers = nil;
        }
    }
}

-(void)ObserverOnQueue:(dispatch_queue_t)queue
               fulfill:(DKPromiseFulfillBlock)onFulfill
              reject:(DKPromiseRejectedBlock)onReject{
    NSParameterAssert(queue);
    NSParameterAssert(onFulfill);
    NSParameterAssert(onReject);
    
    switch (_state) {
        case DKPromiseStatePending:
        {
            if (!_observers) {
                _observers = [NSMutableArray array];
            }
            
            DkPromiseObserverBlock observer = ^(DKPromiseState state, id __nullable value){
                switch (state) {
                    case DKPromiseStatePending:
                        break;
                    case DKPromiseStateFulfilled:
                    {
                        onFulfill(value);
                    }
                        break;
                    case DKPromiseStateRejected:
                    {
                        onReject(value);
                    }
                        break;
                    default:
                        break;
                }
            };
            
            [_observers addObject:observer];
        }
            break;
        case DKPromiseStateFulfilled:
        {
            dispatch_async(DKPromise.defaultPromiseQueue, ^{
                onFulfill(self->_value);
            });
        }
            break;
        case DKPromiseStateRejected:
        {
            dispatch_async(DKPromise.defaultPromiseQueue, ^{
                onReject(self->_error);
            });
        }
            break;
            
        default:
            break;
    }
    
}

-(DKPromise *)chainOnQueue:(dispatch_queue_t)queue
              onFulfill:(DKPromiseChainFulfillBlock)onFulfill
                  onReject:(DKPromiseChainRejectBlock)onReject{
    DKPromise *promise = [[DKPromise alloc]initWithPending];
    
    __auto_type resolved =  ^(id __nullable value) {
        if ([value isKindOfClass:[DKPromise class]]) {
            
            [(DKPromise *)value ObserverOnQueue:queue fulfill:^(id value) {
                [promise fulfilled:value];
            } reject:^(NSError *error) {
                [promise rejected:error];
            }];
            
        }else{
            [promise fulfilled:value];
        }
    };
    
    [self ObserverOnQueue:queue fulfill:^(id value) {
        value = onFulfill ? onFulfill(value) : value;
        resolved(value);
    } reject:^(NSError *error) {
        id value = onReject ? onReject(error) : error;
        resolved(value);
    }];
    
    return promise;
}

+(instancetype)pendingPromise{
    return [[DKPromise alloc]initWithPending];
}

+(instancetype)resolvedWith:(nullable id)resolution{
    return [[DKPromise alloc]initWithResolved:resolution];
}

-(BOOL)isPending{
    @synchronized (self) {
        return _state == DKPromiseStatePending;
    }
}

-(BOOL)isFulfilled{
    @synchronized (self) {
        return _state == DKPromiseStateFulfilled;
    }
}

-(BOOL)isRejected{
    @synchronized (self) {
        return _state == DKPromiseStateRejected;
    }
}

-(id)value{
    @synchronized (self) {
        return _value;
    }
}

-(NSError *)error{
    @synchronized (self) {
        return _error;
    }
}

#pragma private
+(dispatch_queue_t)defaultPromiseQueue{
    @synchronized (self) {
        return DKPromiseDefaultQueue;
    }
}

+(void)setDefaultPromiseQueue:(dispatch_queue_t)defaultPromiseQueue{
    @synchronized (self) {
        DKPromiseDefaultQueue = defaultPromiseQueue;
    }
}

+(void)initialize{
    @synchronized (self) {
        DKPromiseDefaultQueue = dispatch_get_main_queue();
    }
}

-(instancetype)initWithPending{
    if (self = [super init]) {
        dispatch_group_enter(DKPromise.defaultPromiseGroup);
    }
    return self;
}

-(instancetype)initWithResolved:(nullable id)resolution{
    if (self = [super init]) {
        if ([resolution isKindOfClass:[NSError class]]) {
            _state = DKPromiseStateRejected;
            _error = (NSError *)resolution;
        }else{
            _state = DKPromiseStateFulfilled;
            _value = resolution;
        }
    }
    return self;
}

-(void)dealloc{
    if (_state == DKPromiseStatePending) {
        dispatch_group_leave(DKPromise.defaultPromiseGroup);
    }
}

+(dispatch_group_t)defaultPromiseGroup{
    static dispatch_group_t group;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        group = dispatch_group_create();
    });
    return group;
}

@end
