//
//  AppDelegate.m
//  CJLabelTest
//
//  Created by C.K.Lian on 15/12/11.
//  Copyright © 2015年 C.K.Lian. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [self handleOpenURL:url];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [self handleOpenURL:url];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString*, id> *)options {
    return [self handleOpenURL:url];
}


- (BOOL)handleOpenURL:(NSURL *)url {
    NSString *urlStr = [url.absoluteString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//    NSRange wechatRang = [urlStr rangeOfString:WECHAT_APP_ID];
    
    NSMutableString *string = [[NSMutableString alloc] initWithString:urlStr];
    if ([urlStr hasPrefix:@"file://"]) {
        [string replaceOccurrencesOfString:@"file://" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, urlStr.length)];
    }
    
    if ([urlStr rangeOfString:@"file://"].location != NSNotFound) {
        if (([string rangeOfString:@".gif"].location != NSNotFound) || ([string rangeOfString:@".GIF"].location != NSNotFound)) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"gif" delegate:self cancelButtonTitle:@"朕知道了" otherButtonTitles:nil, nil];
            [alert show];
            return YES;
        }else if (([string rangeOfString:@".jpg"].location != NSNotFound) || ([string rangeOfString:@".jpeg"].location != NSNotFound)||([string rangeOfString:@".JPG"].location != NSNotFound) || ([string rangeOfString:@".JPEG"].location != NSNotFound)) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"jpeg" delegate:self cancelButtonTitle:@"朕知道了" otherButtonTitles:nil, nil];
            [alert show];
            return YES;
        }else if (([string rangeOfString:@".png"].location != NSNotFound) || ([string rangeOfString:@".PNG"].location != NSNotFound)) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"PNG" delegate:self cancelButtonTitle:@"朕知道了" otherButtonTitles:nil, nil];
            [alert show];
            return YES;
        }
        else if (([string rangeOfString:@".doc"].location != NSNotFound) || ([string rangeOfString:@".DOC"].location != NSNotFound)) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"DOC" delegate:self cancelButtonTitle:@"朕知道了" otherButtonTitles:nil, nil];
            [alert show];
            return YES;
        }
        else if (([string rangeOfString:@".docx"].location != NSNotFound) || ([string rangeOfString:@".DOCX"].location != NSNotFound)) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"DOCX" delegate:self cancelButtonTitle:@"朕知道了" otherButtonTitles:nil, nil];
            [alert show];
            return YES;
        }
    }
    
    return NO;
}


@end
