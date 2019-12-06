//
//  MSTopViewController.h
//  HelloWorld
//
//  Created by Daniel R on 10/2/13.
//  Copyright (c) 2013 Daniel R. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MSTopViewController : UIViewController
- (instancetype)initWithMessage: (NSString *)message;

@property (strong, nonatomic) NSString* message;

@end
