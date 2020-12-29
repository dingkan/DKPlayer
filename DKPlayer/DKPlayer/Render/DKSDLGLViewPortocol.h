//
//  DKSDLGLViewPortocol.h
//  DKPlayer
//
//  Created by 丁侃 on 2020/12/29.
//  Copyright © 2020 丁侃. All rights reserved.
//

#ifndef DKSDLGLViewPortol_h
#define DKSDLGLViewPortol_h
#import <UIKit/UIkit.h>

typedef struct DKOverlay DKOverlay;
struct DKOverlay {
    int w;
    int h;
    UInt32 format;
    int plans;
    UInt16 *pitched;
    UInt8 **pixels;
    int sar_num;
    int sar_den;
    CVPixelBufferRef pixel_buffer;//像素图片
};

@protocol DKSDLGLViewPortocol <NSObject>

-(UIImage *)snapshot;

@property (nonatomic, readonly) CGFloat fps;
@property (nonatomic)           CGFloat scaleFactor;
@property (nonatomic)           BOOL    isThirdGLView;

-(void)display_pixels:(DKOverlay *)overlay;

@end

#endif /* DKSDLGLViewPortol_h */
