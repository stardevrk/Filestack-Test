//
//  FilestackSetup.h
//  HelloWorld
//
//  Created by DevMaster on 12/6/19.
//  Copyright © 2019 Daniel R. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Set your app's URL scheme here.
static NSString *appURLScheme = @"tutorial";
// Set your Filestack's API key here.
static NSString *filestackAPIKey = @"AXkc2JgbsSQVuCZV9w4iBz";
// Set your Filestack's app secret here.
static NSString *filestackAppSecret = @"XQSOOK6NVFFYBAFORLKVXLJBSU";

@class FSFilestackClient;

@interface FilestackSetup : NSObject

@property(nonatomic, strong) FSFilestackClient *client;

+ (FilestackSetup *)sharedSingleton;

@end

NS_ASSUME_NONNULL_END
