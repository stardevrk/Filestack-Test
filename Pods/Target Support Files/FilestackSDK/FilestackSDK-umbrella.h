#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "FilestackSDK.h"
#import "FSMetadataOptions.h"
#import "FSPolicyCall.h"
#import "FSTransformPosition.h"

FOUNDATION_EXPORT double FilestackSDKVersionNumber;
FOUNDATION_EXPORT const unsigned char FilestackSDKVersionString[];

