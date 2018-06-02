//
//  CompilerHelper.c
//  fbuild
//
//  Created by fuxsociety on 6/2/18.
//  Copyright © 2018 fsociety. All rights reserved.
//

#include "CompilerHelper.h"
#include "Utils.h"
#include "AutoConfig.h"
#include "FileHelper.h"
BOOL compileFile(NSString *filePath,NSString *fileName)
{
    BOOL isXib = NO;
    NSString *scriptFileName = @"objc-build.sh";
    if ([filePath hasSuffix:@".swift"] ||
        [filePath hasSuffix:@".m"])
    {
        printf("Compiling [%s%s%s]\n",KMAG,fileName.UTF8String,kRS);
        if ([filePath hasSuffix:@"swift"])
        {
            scriptFileName = @"swift-build.sh";
        }
    }
    else
    {
        printf("Compiling XIB [%s%s%s]\n",KMAG,fileName.UTF8String,kRS);
        scriptFileName = @"xib-compile.sh";
        isXib = YES;
    }
    
    NSString *scriptFilePath = [NSString stringWithFormat:@"%@/%@",getConfigPath(),scriptFileName];
    NSString *compileCommand = [[NSString alloc] initWithContentsOfFile:scriptFilePath encoding:NSUTF8StringEncoding error:nil];
    compileCommand = [compileCommand stringByReplacingOccurrencesOfString:kFileName withString:fileName];
    compileCommand = [compileCommand stringByReplacingOccurrencesOfString:kFilePath withString:filePath];
    compileCommand = [compileCommand stringByReplacingOccurrencesOfString:kFileListDir withString:getListFileDir()];
    NSString *compileResult = GetSystemCall(compileCommand);
    
    if (compileResult.length == 0 ||
        ![compileResult containsString:@"error"])
    {
        if (isXib)
        {
            printf("Compiled XIB [%s%s%s]\n",KGRN,fileName.UTF8String,kRS);
        }
        else
        {
            printf("Compiled [%s%s%s]\n",KGRN,fileName.UTF8String,kRS);
        }
        
        GetSystemCall([NSString stringWithFormat:@"git add %@",filePath]);
        return YES;
    }
    
    printf("Error occurred while compile file: [%s%s%s] at path: [%s%s%s], Error: %s\n\n",kRED,fileName.UTF8String,kRS, kRED, filePath.UTF8String,kRS, compileResult.UTF8String);
    return NO;
}

BOOL reBuildBinary()
{
    printf("Rebuilding...\n");
    NSString *rebuildScriptFilePath = [NSString stringWithFormat:@"%@/rebuild.sh",getConfigPath()];
    NSString *rebuildCommand = [[NSString alloc] initWithContentsOfFile:rebuildScriptFilePath encoding:NSUTF8StringEncoding error:nil];
    
    NSString *resultRebuild = GetSystemCall(rebuildCommand);
    
    if (resultRebuild.length != 0)
    {
        printf("Rebuild failed with error: \n%s%s%s\n",kRED,resultRebuild.UTF8String,kRS);
        return NO;
    }
    
    printf("Resigning...\n");
    NSString *resignScriptFilePath = [NSString stringWithFormat:@"%@/resign.sh",getConfigPath()];
    NSString *resignCommand = [[NSString alloc] initWithContentsOfFile:resignScriptFilePath encoding:NSUTF8StringEncoding error:nil];
    
    NSString *resultResign = GetSystemCall(resignCommand);
    if (resultResign.length != 0 && ![resultResign containsString:@"replacing existing signature"])
    {
        printf("Resign failed with error: \n%s%s%s\n",kRED,resultResign.UTF8String,kRS);
        return NO;
    }
    
    return YES;
}

void compileAllModifiedFile()
{
    NSArray *listFileNameModified = getListFileModified();
    
    BOOL errorWhenCompile = NO;
    for (NSString *fileModified in listFileNameModified)
    {
        if (fileModified.length == 0)
        {
            continue;
        }
        
        NSString *fullPath = [NSString stringWithFormat:@"%@/%@",currentDIR,fileModified];
        fullPath = [fullPath stringByReplacingOccurrencesOfString:@" " withString:@"\\ "];
        
        NSString *fileName = GetFileNameFromFilePath(fileModified);
        
        BOOL compileResult = compileFile(fullPath, fileName);
        
        if (compileResult == NO)
        {
            errorWhenCompile = YES;
            break;
        }
    }
    
    if (errorWhenCompile)
    {
        printf("%sCompile queue pause cause error occurred, Please fix code and retry!%s\n",KWHT,kRS);
        exit(0);
    }
    
    BOOL result = reBuildBinary();
    if (result)
    {
        printf("Done\n");
    }
}


BOOL compileAllSource()
{
    NSArray *allSource = getAllSourceFile();
    for (NSString *filePath in allSource)
    {
        NSString *path = [filePath stringByReplacingOccurrencesOfString:@" " withString:@"\\ "];
        NSString *fileName = GetFileNameFromFilePath(path);
        
        BOOL compileResult = compileFile(path, fileName);
        if (compileResult == NO)
        {
            return NO;
        }
    }
    
    return YES;
}

void compileAllSourceAndRebuild(void)
{
    BOOL compileAllSourceResult = compileAllSource();
    if (compileAllSourceResult == NO)
    {
        exit(0);
    }
    
    BOOL resultBuildAndResign = reBuildBinary();
    if (resultBuildAndResign == YES)
    {
        printf("Done\n");
    }
}
