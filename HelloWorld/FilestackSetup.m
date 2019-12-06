//
//  FilestackSetup.m
//  HelloWorld
//
//  Created by DevMaster on 12/6/19.
//  Copyright © 2019 Daniel R. All rights reserved.
//

#import "FilestackSetup.h"
@import FilestackSDK;
@import Filestack;


@implementation FilestackSetup

-(instancetype)init {
    self = [super init];

    if (self) {
        FSPolicyCall policyCall =
            FSPolicyCallPick | FSPolicyCallRead | FSPolicyCallStat |
            FSPolicyCallWrite | FSPolicyCallWriteURL | FSPolicyCallStore |
            FSPolicyCallConvert | FSPolicyCallRemove | FSPolicyCallExif;

        FSPolicy *policy = [[FSPolicy alloc] initWithExpiry:NSDate.distantFuture
                                                       call:policyCall];

        FSSecurity *security = [[FSSecurity alloc] initWithPolicy:policy
                                                        appSecret:filestackAppSecret
                                                            error:nil];

        FSConfig *config = [FSConfig new];

//        config.appURLScheme = appURLScheme;
        config.imageURLExportPreset = FSImageURLExportPresetCurrent;
        config.maximumSelectionAllowed = 10;

        config.availableCloudSources = @[FSCloudSource.dropbox,
                                         FSCloudSource.googleDrive,
                                         FSCloudSource.googlePhotos,
                                         FSCloudSource.customSource];

        config.availableLocalSources = @[FSLocalSource.camera,
                                         FSLocalSource.photoLibrary,
                                         FSLocalSource.documents];

        self.client = [[FSFilestackClient alloc] initWithApiKey:filestackAPIKey
                                                        security:security
                                                          config:config
                                                           token:nil];
    }

    return self;
}

+ (FilestackSetup *)sharedSingleton
{
    static FilestackSetup *sharedSingleton;

    @synchronized(self)
    {
        if (!sharedSingleton)
            sharedSingleton = [FilestackSetup new];

        return sharedSingleton;
    }
}

@end
