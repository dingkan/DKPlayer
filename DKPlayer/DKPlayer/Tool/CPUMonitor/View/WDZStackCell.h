//
//  WDZStackCell.h
//  DKPlayer
//
//  Created by 丁侃 on 2020/9/11.
//  Copyright © 2020 丁侃. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WDZCallTraceTimeCostModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface WDZStackCell : UITableViewCell

- (void)updateWithModel:(WDZCallTraceTimeCostModel *)model;
@end

NS_ASSUME_NONNULL_END
