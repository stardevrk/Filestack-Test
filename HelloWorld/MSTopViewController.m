//
//  MSTopViewController.m
//  HelloWorld
//
//  Created by Daniel R on 10/2/13.
//  Copyright (c) 2013 Daniel R. All rights reserved.
//

#import "MSTopViewController.h"
#import "FilestackSetup.h"
@import FilestackSDK;
@import Filestack;

@interface MSTopViewController ()
    @property(nonatomic, strong) UIButton *presentPickerButton;
@end

@implementation MSTopViewController

- (instancetype)initWithMessage: (NSString *)message
{
    self = [super init];
    if (self) {
        self.message = message;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.frame = CGRectMake(10, 10, 50, 50);
    label.text = self.message;
    [self.view addSubview:label];
	// Do any additional setup after loading the view.
    
    self.presentPickerButton = [UIButton buttonWithType:UIButtonTypeSystem];
    
    [self.presentPickerButton setTitle:@"Present Picker"
                              forState:UIControlStateNormal];

    [self.presentPickerButton addTarget:self
                                 action:@selector(presentPicker:)
                       forControlEvents:UIControlEventTouchUpInside];

    self.presentPickerButton.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:self.presentPickerButton];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.presentPickerButton
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1
                                                           constant:0]];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.presentPickerButton
                                                          attribute:NSLayoutAttributeCenterY
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterY
                                                         multiplier:1
                                                           constant:0]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)presentPicker:(id)sender {
    FSFilestackClient *fsClient = [FilestackSetup sharedSingleton].client;
    NSMutableArray *sources = [NSMutableArray new];
//    fsClient.config.availableCloudSources = sources;

    if (!fsClient)
        return;

    // Store options for your uploaded files.
    // Here we are saying our storage location is S3 and access for uploaded files should be public.
    FSStorageOptions *storeOptions = [[FSStorageOptions alloc] initWithLocation:FSStorageLocationS3
                                                                         access:FSStorageAccessPublic];
    // Instantiate picker by passing the `StorageOptions` object we just set up.
    FSPickerNavigationController *picker = [fsClient pickerWithStoreOptions:storeOptions];
    
    // Set our view controller as the picker's delegate.
    picker.pickerDelegate = (id <FSPickerNavigationControllerDelegate>)self;
    
    // Finally, present the picker on the screen.
    [self presentViewController:picker
                       animated:YES
                     completion:nil];
}

 #pragma mark - FSPickerNavigationControllerDelegate Methods
// A file or set of files were picked from the camera, photo library, or Apple's Document Picker
- (void)pickerUploadedFilesWithPicker:(FSPickerNavigationController * _Nonnull)picker responses:(NSArray<FSNetworkJSONResponse *> * _Nonnull)responses {
    [picker dismissViewControllerAnimated:NO completion:^{
        NSMutableArray<NSString *> *handles = [NSMutableArray arrayWithCapacity:10];
        NSMutableArray<NSString *> *errorMessages = [NSMutableArray arrayWithCapacity:10];
        NSMutableArray<NSString *> *descriptions = [NSMutableArray arrayWithCapacity:10];

        for (FSNetworkJSONResponse *response in responses) {
            NSString *handle = response.json[@"handle"];
//            NSString *jsonString = [[NSString alloc] initWithData:response.description encoding:NSUTF8StringEncoding];
//            NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response.response;
//            NSInteger statusCode = [HTTPResponse statusCode];
            NSError *error = response.error;
            
            [descriptions addObject:response.description];

            if (handle != nil) {
                [handles addObject:handle];
            }

            if (error != nil) {
                [errorMessages addObject:error.localizedDescription];
            }
        }

        if (errorMessages.count == 0) {
            NSString *joinedHandles = [handles componentsJoinedByString:@", "];
//            [self presentAlert:@"Success"
//                       message:[NSString stringWithFormat:@"Finished storing files with handles: %@", joinedHandles]];
            NSString *resultDescription = [descriptions componentsJoinedByString:@", "];
            NSLog(@"Success: %@", resultDescription);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Upload Succss" message:@"Uploading is finished" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Cancel", nil];
            [alert show];
        } else {
            NSString *joinedErrors = [errorMessages componentsJoinedByString:@", "];
//            [self presentAlert:@"Error Uploading File"
//                       message:joinedErrors];
            NSLog(@"Success: %@", joinedErrors);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Upload Failed!" message:@"Uploading is failed" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Cancel", nil];
            [alert show];
        }
    }];
}
@end
