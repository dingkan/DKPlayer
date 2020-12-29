//
//  DKSDLGLView.m
//  DKPlayer
//
//  Created by 丁侃 on 2020/12/29.
//  Copyright © 2020 丁侃. All rights reserved.
//

#import "DKSDLGLView.h"
#import "dkSDK_gles2.h"

typedef enum : NSUInteger {
    DKSDLGLViewApplicationUnknowState       = 0,
    DKSDLGLViewApplicationForegroundState   = 1,
    DKSDLGLViewApplicationBackgroundState   = 2,
} DKSDLGLViewApplicationState;

@interface DKSDLGLView()
//递归锁
@property (atomic, strong) NSRecursiveLock *glActiveLock;
@property (atomic)         BOOL             alActivePaused;
@end

@implementation DKSDLGLView{
    EAGLContext     *_context;
    GLuint          _frameBuffer;
    GLuint          _renderBuffer;
    
    GLint           _backingWidht;
    GLint           _backingHeight;
    
    BOOL            _didSetupGL;
    
    NSMutableArray  *_registerNotifications;
    
    DKSDLGLViewApplicationState _applicationState;
}

@synthesize scaleFactor         = _scaleFactor;

+(Class)layerClass{
    return [CAEAGLLayer class];
}


-(BOOL)setupELGLContext:(EAGLContext *)context{
    glGenFramebuffers(1, &_frameBuffer);
    glGenRenderbuffers(1, &_renderBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingHeight);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"failed to make complete framebuffer object %x\n",status);
        return NO;
    }
    
    GLenum glError = glGetError();
    if (GL_NO_ERROR != glError) {
        NSLog(@"failed to setup GL %x\n",glError);
        return NO;
    }
    return  YES;
}

-(CAEAGLLayer *)eaglLayer{
    return (CAEAGLLayer *)self.layer;
}

//初始化上下文
-(BOOL)setupGL{
    if (_didSetupGL) return YES;
    
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking,
                                    kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    _scaleFactor = [[UIScreen mainScreen] scale];
    if (_scaleFactor < 0.1f) {
        _scaleFactor = 1.0f;
    }
    
    [eaglLayer setContentsScale:_scaleFactor];
    
    _context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (_context == nil) {
        NSLog(@"failed to setup EAGLContext\n");
        return NO;
    }
    
    EAGLContext *prevContext = [EAGLContext currentContext];
    [EAGLContext setCurrentContext:_context];
    
    _didSetupGL = NO;
    
    if ([self setupELGLContext:_context]) {
        NSLog(@"Ok setup GL\n");
        _didSetupGL = YES;
    }
    
    [EAGLContext setCurrentContext:prevContext];
    return _didSetupGL;
}

-(BOOL)setupGLOnce{
    if (_didSetupGL) return YES;
    
    if (![self tryLockGLActive]) return NO;
    
    BOOL didSetupGL = [self setupGL];
    
    [self unlockGLActive];
    return didSetupGL;
}

#pragma  AppDelegate
-(void)lockGLActive{
    [self.glActiveLock lock];
}

-(void)unlockGLActive{
    [self.glActiveLock unlock];
}

-(BOOL)tryLockGLActive{
    if (![self.glActiveLock tryLock]) {
        return NO;
    }
    
    if (self.alActivePaused) {
        [self.glActiveLock unlock];
        return NO;
    }
    return YES;
}

//切换上下文
-(void)toggleGLPaused:(BOOL)paused{
    [self lockGLActive];
    
    if (!self.alActivePaused && paused) {
        if (_context != nil) {
            EAGLContext *preContext = [EAGLContext currentContext];
            [EAGLContext setCurrentContext:_context];
            glFinish();
            [EAGLContext setCurrentContext:preContext];
        }
    }
    self.alActivePaused = paused;
    [self unlockGLActive];
}

-(void)registerApplicationObservers{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(applicationWillEnterForeground)
                                                name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [_registerNotifications addObject:UIApplicationWillEnterForegroundNotification];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(applicationDidBecomeActive)
                                                name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [_registerNotifications addObject:UIApplicationDidBecomeActiveNotification];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(applicationWillResignActive)
                                                name:UIApplicationWillResignActiveNotification
                                               object:nil];
    [_registerNotifications addObject:UIApplicationWillResignActiveNotification];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(applicationDidEnterBackground)
                                                name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [_registerNotifications addObject:UIApplicationDidEnterBackgroundNotification];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillTerminate)
                                                name:UIApplicationWillTerminateNotification
                                               object:nil];
    [_registerNotifications addObject:UIApplicationWillTerminateNotification];
}


-(void)unregisterApplicationObservers{
    for (NSString *noticationName in _registerNotifications) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:noticationName
                                                      object:nil];
    }
}

-(void)applicationWillEnterForeground{
    [self setupGLOnce];
    _applicationState = DKSDLGLViewApplicationForegroundState;
    [self toggleGLPaused:NO];
}

-(void)applicationDidBecomeActive{
    [self setupGLOnce];
    [self toggleGLPaused:NO];
}

-(void)applicationWillResignActive{
    [self toggleGLPaused:YES];
    glFinish();
}

-(void)applicationDidEnterBackground{
    _applicationState = DKSDLGLViewApplicationBackgroundState;
    [self toggleGLPaused:YES];
    glFinish();
}

-(void)applicationWillTerminate{
    [self toggleGLPaused:YES];
}

#pragma mark snapshot



@end
