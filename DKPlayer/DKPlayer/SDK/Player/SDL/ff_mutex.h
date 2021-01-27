//
//  ff_mutex.h
//  DKPlayer
//
//  Created by 丁侃 on 2021/1/27.
//  Copyright © 2021 丁侃. All rights reserved.
//

#ifndef ff_mutex_h
#define ff_mutex_h

#include <stdio.h>
#include <pthread.h>

#define SDL_MUTEX_TIMEDOUT  1
/**
 同步机制
 互斥锁 条件变量
 */
typedef struct SDL_mutex{
    pthread_mutex_t         id;
} SDL_mutex ;

//锁操作相关
SDL_mutex *SDL_CreateMutex(void);
void SDL_DestoryMutex(SDL_mutex *mutex);
void SDL_DestoryMutexP(SDL_mutex **mutex);
int SDL_LockMutex(SDL_mutex *mutex);
int SDL_UnlockMutex(SDL_mutex *mutex);


//条件变量
typedef struct SDL_cond{
    pthread_cond_t          id;
} SDL_cond ;


SDL_cond *SDL_CreateCond(void);
void SDL_DestoryCond(SDL_cond *cond);
void SDL_DestoryCondP(SDL_cond **cond);
int SDL_CondSignle(SDL_cond *cond);
int SDL_CondBroadcast(SDL_cond *cond);
int SDL_CondWaitTimeout(SDL_cond *cond, SDL_mutex *mutex, uint32_t ms);
int SDL_CondWait(SDL_cond *cond, SDL_mutex *mutex);

#endif /* ff_mutex_h */
