//
//  ViewController.m
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 8/22/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "ViewController.h"
#import "FHSTwitterEngine.h"

@implementation ViewController

@synthesize engine, tweetField, loggedInUserLabel;

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        NSString *username = [alertView textFieldAtIndex:0].text;
        NSString *password = [alertView textFieldAtIndex:1].text;
        
        dispatch_async(GCDBackgroundThread, ^{
            @autoreleasepool {
                [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
                int returnCode = [self.engine getXAuthAccessTokenForUsername:username password:password];
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                
                NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
                
                if (returnCode == 0) {
                    [dict setObject:@"Success" forKey:@"title"];
                    [dict setObject:@"You have successfully logged in via XAuth" forKey:@"message"];
                }
                
                if (returnCode > 0) {
                    dict = [[NSMutableDictionary alloc]initWithDictionary:[self.engine lookupErrorCode:returnCode]];
                }
                
                dispatch_sync(GCDMainThread, ^{
                    UIAlertView *av = [[UIAlertView alloc]initWithTitle:[dict objectForKey:@"title"] message:[dict objectForKey:@"message"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [av show];
                    
                    if (returnCode == 0) {
                        NSString *username = self.engine.loggedInUsername;
                        if (username.length > 0) {
                            loggedInUserLabel.text = [NSString stringWithFormat:@"Logged in as %@.",username];
                        } else {
                            loggedInUserLabel.text = @"You are not logged in.";
                        }
                    }
                });
            }
        });
    }
}

- (void)storeAccessToken:(NSString *)accessToken {
    [[NSUserDefaults standardUserDefaults]setObject:accessToken forKey:@"SavedAccessHTTPBody"];
}

- (NSString *)loadAccessToken {
    return [[NSUserDefaults standardUserDefaults]objectForKey:@"SavedAccessHTTPBody"];
}

- (IBAction)showLoginWindow:(id)sender {
    [self presentModalViewController:[self.engine OAuthLoginWindow] animated:YES];
}

- (IBAction)logout:(id)sender {
    [tweetField resignFirstResponder];
    [self.engine clearAccessToken];
    loggedInUserLabel.text = @"You are not logged in.";
}

- (IBAction)loginXAuth:(id)sender {
    UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"xAuth Login" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Login", nil];
    [av setAlertViewStyle:UIAlertViewStyleLoginAndPasswordInput];
    [[av textFieldAtIndex:0]setPlaceholder:@"Username"];
    [[av textFieldAtIndex:1]setPlaceholder:@"Password"];
    [av show];
}

- (IBAction)listFriends:(id)sender {

    [tweetField resignFirstResponder];
    dispatch_async(GCDBackgroundThread, ^{
        @autoreleasepool {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
            NSLog(@"%@",[self.engine getTimelineForUser:self.engine.loggedInUsername isID:NO count:5]);
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        }
    });
}

- (IBAction)postTweet:(id)sender {

    [tweetField resignFirstResponder];
    
    dispatch_async(GCDBackgroundThread, ^{
        @autoreleasepool {
            
            NSString *tweet = tweetField.text;
            
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
            
            int returnCode = [self.engine postTweet:tweet];
            
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            
            NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
            
            if (returnCode == 0) {
                [dict setObject:@"Tweet Posted" forKey:@"title"];
                [dict setObject:tweet forKey:@"message"];
            }
            
            if (returnCode > 0) {
                dict = [[NSMutableDictionary alloc]initWithDictionary:[self.engine lookupErrorCode:returnCode]];
            }
            
            dispatch_sync(GCDMainThread, ^{
                UIAlertView *av = [[UIAlertView alloc]initWithTitle:[dict objectForKey:@"title"] message:[dict objectForKey:@"message"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [av show];
            });
        }
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.engine = [[FHSTwitterEngine alloc]initWithConsumerKey:@"<consumer_key>" andSecret:@"<consumer_secret>"];
    [tweetField addTarget:self action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.engine loadAccessToken];
    NSString *username = self.engine.loggedInUsername;
    if (username.length > 0) {
        loggedInUserLabel.text = [NSString stringWithFormat:@"Logged in as %@",username];
    } else {
        loggedInUserLabel.text = @"You are not logged in.";
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

@end
