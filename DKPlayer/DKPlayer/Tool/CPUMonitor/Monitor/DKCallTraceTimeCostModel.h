//
//  DKCallTraceTimeCostModel.h
//  DKPlayer
//
//  Created by 丁侃 on 2020/9/15.
//  Copyright © 2020 丁侃. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DKCallTraceTimeCostModel : NSObject
@property (nonatomic, strong) NSString *className;
@property (nonatomic, strong) NSString *methodName;
@property (nonatomic, assign) BOOL isClassMethod;
@property (nonatomic, assign) NSTimeInterval timeCost;
@property (nonatomic, assign) NSUInteger callDepth;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, assign) BOOL lastCall;
@property (nonatomic, assign) NSUInteger frequency;
@property (nonatomic, strong) NSArray <DKCallTraceTimeCostModel *>*subCosts;

-(NSString *)des;
@end

NS_ASSUME_NONNULL_END
