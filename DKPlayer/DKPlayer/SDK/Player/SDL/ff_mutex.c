//
//  ff_mutex.c
//  DKPlayer
//
//  Created by 丁侃 on 2021/1/27.
//  Copyright © 2021 丁侃. All rights reserved.
//

#include "ff_mutex.h"
#include "ff_misc.h"
#include <errno.h>
#include <assert.h>
#include <sys/time.h>

SDL_mutex *SDL_CreateMutex(void)
{
    SDL_mutex *mutex;
    mutex = (SDL_mutex *)mallocz(sizeof(SDL_mutex));
    
    if (!mutex) {
        return NULL;
    }
    
    if (pthread_mutex_init(&mutex->id, NULL) != 0) {
        free(mutex);
        return NULL;
    }
    
    return mutex;
}

void SDL_DestoryMutex(SDL_mutex *mutex)
{
    if (mutex) {
        pthread_mutex_destroy(&mutex->id);
        free(mutex);
    }
}

void SDL_DestoryMutexP(SDL_mutex **mutex)
{
    if (mutex) {
        SDL_DestoryMutex(*mutex);
        *mutex = NULL;
    }
}

int SDL_LockMutex(SDL_mutex *mutex)
{
    assert(mutex);
    
    if (!mutex) {
        return -1;
    }
    
    return pthread_mutex_lock(&mutex->id);
}

int SDL_UnlockMutex(SDL_mutex *mutex)
{
    assert(mutex);
    
    if (!mutex) {
        return  -1;
    }
    
    return pthread_mutex_unlock(&mutex->id);
}


SDL_cond *SDL_CreateCond(void)
{
    SDL_cond *cond;
    cond = (SDL_cond *)mallocz(sizeof(SDL_cond));
    
    if (!cond) {
        return NULL;
    }
    
    if (pthread_cond_init(&cond->id, NULL) != 0) {
        free(cond);
        return NULL;
    }
    return cond;
}


void SDL_DestoryCond(SDL_cond *cond)
{
    if (cond) {
        pthread_cond_destroy(&cond->id);
        free(cond);
    }
}


void SDL_DestoryCondP(SDL_cond **cond){
    if (cond) {
        SDL_DestoryCond(*cond);
        *cond = NULL;
    }
}

int SDL_CondSignle(SDL_cond *cond){
    assert(cond);
    
    if (!cond) {
        return -1;
    }
    
    return pthread_cond_signal(&cond->id);
}


int SDL_CondBroadcast(SDL_cond *cond)
{
    assert(cond);
    if (!cond) {
        return -1;
    }
    return pthread_cond_broadcast(&cond->id);
}

int SDL_CondWaitTimeout(SDL_cond *cond, SDL_mutex *mutex, uint32_t ms)
{
    int retval;
    struct timeval delta;
    struct timespec  abstime;
    
    assert(cond);
    assert(mutex);
    
    if (!cond || !mutex) {
        return -1;
    }
    
    //获取当前时间
    gettimeofday(&delta, NULL);
    
    //更新延迟时间
    abstime.tv_sec = delta.tv_sec + (ms / 1000);
    abstime.tv_nsec = (delta.tv_usec + (ms % 1000) * 1000) * 1000;
    
    if (abstime.tv_nsec > 1000000000) {
        abstime.tv_sec += 1;
        abstime.tv_nsec -= 1000000000;
    }
    
    while (1) {
        retval = pthread_cond_timedwait(&cond->id, &mutex->id, &abstime);
        if (retval == 0) {
            return 0;
        }else if (retval == EINTR){
            continue;
        }else if (retval == ETIMEDOUT){
            return SDL_MUTEX_TIMEDOUT;
        }else{
            break;
        }
    }
    return  -1;
}

int SDL_CondWait(SDL_cond *cond, SDL_mutex *mutex)
{
    assert(cond);
    assert(mutex);
    if (!cond || !mutex) {
        return -1;
    }
    return pthread_cond_wait(&cond->id, &mutex->id);
}
