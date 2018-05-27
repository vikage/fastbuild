//
//  main.m
//  FastBuildSimple
//
//  Created by fsociety on 5/27/18.
//  Copyright © 2018 fsociety. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <unistd.h>
#include <sys/types.h>
#include <pwd.h>

NSString *currentDIR;

void compileFile(NSString *filePath,NSString *fileName);
void reBuildBinary(void);

NSString *GetHomeDir()
{
    char *home = getenv("HOME");
    return [[NSString alloc] initWithUTF8String:home];
}

NSString * GetSystemCall(NSString *cmd)
{
    NSString *tempFilePath = [NSString stringWithFormat:@"%@/Documents/Temp.out",GetHomeDir()];
    NSString *reCmd = [NSString stringWithFormat:@"%@ > %@",cmd,tempFilePath];
    system(reCmd.UTF8String);
    
    NSString *output = [[NSString alloc] initWithContentsOfFile:tempFilePath encoding:NSUTF8StringEncoding error:nil];
    return [output stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

NSString *GetFileNameFromFilePath(NSString *filePath)
{
    NSArray *components = [filePath componentsSeparatedByString:@"/"];
    NSString *filePathAndEx = [components lastObject];
    NSArray *fileComponents = [filePathAndEx componentsSeparatedByString:@"."];
    return [fileComponents firstObject];
}

void initConfigFile()
{
    NSString *configDir = [NSString stringWithFormat:@"%@/Documents/fastbuild/",GetHomeDir()];
    NSString *objcBuildConfigFile = [NSString stringWithFormat:@"%@/Documents/fastbuild/objc-build.sh",GetHomeDir()];
    NSString *swiftBuildConfigFile = [NSString stringWithFormat:@"%@/Documents/fastbuild/swift-build.sh",GetHomeDir()];
    NSString *rebuildConfigFile = [NSString stringWithFormat:@"%@/Documents/fastbuild/rebuild.sh",GetHomeDir()];
    
    GetSystemCall([NSString stringWithFormat:@"mkdir -p %@",configDir]);
    GetSystemCall([NSString stringWithFormat:@"touch %@",objcBuildConfigFile]);
    GetSystemCall([NSString stringWithFormat:@"touch %@",swiftBuildConfigFile]);
    GetSystemCall([NSString stringWithFormat:@"touch %@",rebuildConfigFile]);
}

int main(int argc, const char * argv[])
{
    currentDIR = GetSystemCall(@"pwd");
#ifdef DEBUG
    currentDIR = @"/Users/fsociety/Desktop/TestSwift/";
#endif
    
    printf("[ENV] %s\n",currentDIR.UTF8String);
    
    if (argc >= 2)
    {
        NSString *param2 = [NSString stringWithUTF8String:argv[1]];
        if ([param2 isEqualToString:@"init"])
        {
            initConfigFile();
            
            return 0;
        }
    }
    
    // Get List file modify
    NSString *commandGetListFileModify = [NSString stringWithFormat:@"cd %@;git status -s | cut -c4- | grep -E \".m$|.swift$\"",currentDIR];
    NSString *resultListFileModify = GetSystemCall(commandGetListFileModify);
    NSArray *listFileNameModified = [resultListFileModify componentsSeparatedByString:@"\n"];
    
    for (NSString *fileModified in listFileNameModified)
    {
        NSString *fullPath = [NSString stringWithFormat:@"%@/%@",currentDIR,fileModified];
        
        NSString *fileName = GetFileNameFromFilePath(fileModified);
        
        compileFile(fullPath, fileName);
    }
    
    reBuildBinary();
    printf("Done\n");
    
    return 0;
}

void compileFile(NSString *filePath,NSString *fileName)
{
    printf("Compiling %s\n",fileName.UTF8String);
    NSString *scriptFileName = @"objc-build.sh";
    if ([filePath hasSuffix:@"swift"])
    {
        scriptFileName = @"swift-build.sh";
    }
    
    NSString *scriptFilePath = [NSString stringWithFormat:@"%@/Documents/fastbuild/%@",GetHomeDir(),scriptFileName];
    NSString *compileCommand = [[NSString alloc] initWithContentsOfFile:scriptFilePath encoding:NSUTF8StringEncoding error:nil];
    compileCommand = [compileCommand stringByReplacingOccurrencesOfString:@"${FILENAME}" withString:fileName];
    compileCommand = [compileCommand stringByReplacingOccurrencesOfString:@"${FILEPATH}" withString:filePath];
    GetSystemCall(compileCommand);
}

void reBuildBinary()
{
    printf("Rebuilding...\n");
    NSString *scriptFilePath = [NSString stringWithFormat:@"%@/Documents/fastbuild/rebuild.sh",GetHomeDir()];
    NSString *rebuildCommand = [[NSString alloc] initWithContentsOfFile:scriptFilePath encoding:NSUTF8StringEncoding error:nil];
    
    GetSystemCall(rebuildCommand);
}
