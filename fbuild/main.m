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
#include "Config.h"

NSString *currentDIR;

void compileFile(NSString *filePath,NSString *fileName);
void reBuildBinary(void);

void PrintCopyRight()
{
    printf("\
d88888b d8    8b '88      88' .d8888.  .d88b.   .o88b. d888888b d88888b d888888b db    db\n\
88'     8P    Y8   '88  88'   88'  YP .8P  Y8. d8P  Y8   `88'   88         88    `8b  d8'\n\
88ooo   88    88     '88'     `8bo.   88    88 8P         88    88ooooo    88     `8bd8'\n\
88      88    88     '88'       `Y8b. 88    88 8b         88    88         88       88\n\
88      '8b  d8'   'db  8D'   db   8D `8b  d8' Y8b  d8   .88.   88.        88       88\n\
YP       'Y88P'  '88      88' '8888Y'  `Y88P'   `Y88P' Y888888P Y88888P    YP       YP\n\n");
    
    printf("                  }-------{+} fastbuild xcode project {+}-------{}\n");
    printf("                   }-------{+} Coded by fuxsociety {+}-------{}\n\n");
}

NSString *GetHomeDir()
{
    char *home = getenv("HOME");
    return [[NSString alloc] initWithUTF8String:home];
}

NSString * GetSystemCall(NSString *cmd)
{
    NSString *tempFilePath = [NSString stringWithFormat:@"%@/Documents/fastbuild/Temp.out",GetHomeDir()];
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

NSString *getAllFileSourceSwift()
{
    NSString *cmd = [NSString stringWithFormat:@"find %@ -name \"*.swift\" | grep -v 'Test'",currentDIR];
    NSString *response = GetSystemCall(cmd);
    
    return response;
}

NSString *getListFileDir()
{
    NSString *listFileSwiftWritePath = [NSString stringWithFormat:@"%@/Documents/fastbuild/listFile.txt", GetHomeDir()];
    
    return listFileSwiftWritePath;
}

int main(int argc, const char * argv[])
{
    currentDIR = GetSystemCall(@"pwd");
//#ifdef DEBUG
//    currentDIR = @"/Users/fsociety/Desktop/TestSwift";
//#endif
    PrintCopyRight();
    NSString *listFile = getAllFileSourceSwift();
    NSString *listFileSwiftWritePath = getListFileDir();
    BOOL writeResult = [listFile writeToFile:listFileSwiftWritePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    if (writeResult)
    {
        printf("Writen list file at path: %s\n",listFileSwiftWritePath.UTF8String);
    }
    
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
    NSString *commandGetListFileModify = [NSString stringWithFormat:@"cd %@;git status -s | grep '^.M' | cut -c4- | grep -E \".m$|.swift$\"",currentDIR];
    NSString *resultListFileModify = GetSystemCall(commandGetListFileModify);
    NSArray *listFileNameModified = [resultListFileModify componentsSeparatedByString:@"\n"];
    
    for (NSString *fileModified in listFileNameModified)
    {
        if (fileModified.length == 0)
        {
            continue;
        }
        
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
    compileCommand = [compileCommand stringByReplacingOccurrencesOfString:kFileName withString:fileName];
    compileCommand = [compileCommand stringByReplacingOccurrencesOfString:kFilePath withString:filePath];
    compileCommand = [compileCommand stringByReplacingOccurrencesOfString:kFileListDir withString:getListFileDir()];
    GetSystemCall(compileCommand);
    GetSystemCall([NSString stringWithFormat:@"git add %@",filePath]);
}

void reBuildBinary()
{
    printf("Rebuilding...\n");
    NSString *scriptFilePath = [NSString stringWithFormat:@"%@/Documents/fastbuild/rebuild.sh",GetHomeDir()];
    NSString *rebuildCommand = [[NSString alloc] initWithContentsOfFile:scriptFilePath encoding:NSUTF8StringEncoding error:nil];
    
    GetSystemCall(rebuildCommand);
}
