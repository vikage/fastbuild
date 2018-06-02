//
//  Utils.m
//  fbuild
//
//  Created by fuxsociety on 6/2/18.
//  Copyright © 2018 fsociety. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Utils.h"

NSString *currentDIR;

NSString * GetSystemCall(NSString *cmd)
{
    cmd = [cmd stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    NSString *tempFilePath = [NSString stringWithFormat:@"%@/Temp.out",getConfigPath()];
    NSString *reCmd = [NSString stringWithFormat:@"%@ &> %@",cmd,tempFilePath];
    system(reCmd.UTF8String);
    
    NSString *output = [[NSString alloc] initWithContentsOfFile:tempFilePath encoding:NSUTF8StringEncoding error:nil];
    return [output stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}


NSString *GetHomeDir()
{
    char *home = getenv("HOME");
    return [[NSString alloc] initWithUTF8String:home];
}

NSString *getConfigPath()
{
    return [NSString stringWithFormat:@"%@/Library/Developer/fastbuild",GetHomeDir()];
}

NSString *GetFileNameFromFilePath(NSString *filePath)
{
    NSArray *components = [filePath componentsSeparatedByString:@"/"];
    NSString *filePathAndEx = [components lastObject];
    NSArray *fileComponents = [filePathAndEx componentsSeparatedByString:@"."];
    return [fileComponents firstObject];
}
