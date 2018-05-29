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
void autoConfig(NSString *name);
void getSwiftBuildConfigFromLogContent(NSString *logContent);
void getObjcBuildConfigFromLogContent(NSString *logContent);
void getLinkingConfigFromLogContent(NSString *logContent);


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
//    currentDIR = @"/Users/fsociety/Desktop/AXXX";
//#endif
    
    PrintCopyRight();
    printf("[ENV] %s\n",currentDIR.UTF8String);
    if (argc >= 2)
    {
        NSString *param2 = [NSString stringWithUTF8String:argv[1]];
        if ([param2 isEqualToString:@"init"])
        {
            initConfigFile();
            
            return 0;
        }
        
        if ([param2 isEqualToString:@"config"] && argc >= 3)
        {
            NSString *projectName = [NSString stringWithUTF8String:argv[2]];
            
            autoConfig(projectName);
            
            return 0;
        }
    }
    
    // Write listFile
    NSString *listFile = getAllFileSourceSwift();
    NSString *listFileSwiftWritePath = getListFileDir();
    BOOL writeResult = [listFile writeToFile:listFileSwiftWritePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    if (writeResult)
    {
        printf("Written list file at path: %s\n",listFileSwiftWritePath.UTF8String);
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


void autoConfig(NSString *name)
{
    initConfigFile();
    printf("Auto config %s project\n",name.UTF8String);
    NSString *derivedDataPath = [NSString stringWithFormat:@"%@/Library/Developer/Xcode/DerivedData",GetHomeDir()];
    NSString *cmd = [NSString stringWithFormat:@"ls -t %@ | grep '%@' | head -1",derivedDataPath,name];
    
    NSString *output = GetSystemCall(cmd);
    
    if (output.length == 0)
    {
        printf("Can not found '%s' project derivedData, please correct project name\n",name.UTF8String);
        
        exit(0);
    }
    
    NSString *targetPath = [NSString stringWithFormat:@"%@/%@",derivedDataPath,output];
    NSString *logsPath = [NSString stringWithFormat:@"%@/Logs/Build",targetPath];
    
    NSString *cmdGetLastestLog = [NSString stringWithFormat:@"ls -t %@ | grep -v 'Cache' | head -1",logsPath];
    
    NSString *lastestLogFileName = GetSystemCall(cmdGetLastestLog);
    
    if (lastestLogFileName.length == 0)
    {
        printf("Can not found build log for '%s' project, please rebuild once and try again\n",name.UTF8String);
        
        exit(0);
    }
    
    NSString *lastestLogPath = [NSString stringWithFormat:@"%@/%@",logsPath,lastestLogFileName];
    
    NSString *cmdGetLogContent = [NSString stringWithFormat:@"gunzip -c %@ -S .xcactivitylog",lastestLogPath];
    NSString *logContent = GetSystemCall(cmdGetLogContent);
    logContent = [logContent stringByReplacingOccurrencesOfString:@"36\"" withString:@"\n"];
    
    getSwiftBuildConfigFromLogContent(logContent);
    getLinkingConfigFromLogContent(logContent);
    
    printf("Config done\n");
}

void getSwiftBuildConfigFromLogContent(NSString *logContent)
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^.*swift -frontend[^\\n]+" options:(NSRegularExpressionCaseInsensitive|NSRegularExpressionAnchorsMatchLines) error:nil];
    NSArray *matchResults = [regex matchesInString:logContent options:NSMatchingReportCompletion range:NSMakeRange(0, logContent.length)];
    
    NSString *targetCmd;
    for (NSTextCheckingResult *checkingResult in matchResults)
    {
        NSString *checkingResultString = [logContent substringWithRange:checkingResult.range];
        checkingResultString = [checkingResultString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if ([checkingResultString hasSuffix:@"PrecompiledHeaders"])
        {
            continue;
        }
        
        targetCmd = checkingResultString;
        break;
    }
    
    if (targetCmd)
    {
        NSRegularExpression *regexGetFileName = [NSRegularExpression regularExpressionWithPattern:@"-primary-file [a-z0-9\\/]+\\/([a-z0-9]+\\.swift)" options:(NSRegularExpressionCaseInsensitive|NSRegularExpressionAnchorsMatchLines) error:nil];
        NSArray *matchings = [regexGetFileName matchesInString:targetCmd options:NSMatchingReportCompletion range:NSMakeRange(0, targetCmd.length)];
        
        NSTextCheckingResult *firstMatch = [matchings firstObject];
        if (firstMatch && firstMatch.numberOfRanges > 1)
        {
            NSRange fileNameRange = [firstMatch rangeAtIndex:1];
            NSString *fileNameAndEx = [targetCmd substringWithRange:fileNameRange];
            NSString *fileName = [fileNameAndEx stringByReplacingOccurrencesOfString:@".swift" withString:@""];
            
            NSMutableString *finalTargetCmd = [[NSMutableString alloc] initWithString:targetCmd];
            [finalTargetCmd replaceCharactersInRange:firstMatch.range withString:@"-primary-file ${FILEPATH}"];
            [finalTargetCmd replaceOccurrencesOfString:[fileName stringByAppendingString:@"."] withString:@"${FILENAME}." options:0 range:NSMakeRange(0, finalTargetCmd.length)];
            
            NSRegularExpression *regexReplaceListFile = [NSRegularExpression regularExpressionWithPattern:@"-filelist [a-z0-9\\/-_-]+" options:(NSRegularExpressionCaseInsensitive|NSRegularExpressionAnchorsMatchLines) error:nil];
            [regexReplaceListFile replaceMatchesInString:finalTargetCmd options:NSMatchingReportCompletion range:NSMakeRange(0, finalTargetCmd.length) withTemplate:@"-filelist ${FILE_LIST}"];
            
            NSString *scriptFilePath = [NSString stringWithFormat:@"%@/Documents/fastbuild/swift-build.sh",GetHomeDir()];
            BOOL writeResult = [finalTargetCmd writeToFile:scriptFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
            
            if (writeResult)
            {
                printf("Written swift build config at path: %s\n", scriptFilePath.UTF8String);
            }
        }
    }
}

void getObjcBuildConfigFromLogContent(NSString *logContent)
{
    
}

void getLinkingConfigFromLogContent(NSString *logContent)
{
    NSRegularExpression *regexGetLinking = [NSRegularExpression regularExpressionWithPattern:@"^.*\\/clang [^\\n]+" options:(NSRegularExpressionCaseInsensitive|NSRegularExpressionAnchorsMatchLines) error:nil];
    NSArray *resultMatching = [regexGetLinking matchesInString:logContent options:NSMatchingReportCompletion range:NSMakeRange(0, logContent.length)];
    
    if (resultMatching.count != 0)
    {
        NSString *linkingCommand;
        for (NSTextCheckingResult *checkingResult in resultMatching)
        {
            NSString *matchString = [logContent substringWithRange:checkingResult.range];
            matchString = [matchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            if ([matchString containsString:@"-filelist"])
            {
                linkingCommand = matchString;
            }
        }
        
        if (linkingCommand)
        {
            NSString *scriptFilePath = [NSString stringWithFormat:@"%@/Documents/fastbuild/rebuild.sh",GetHomeDir()];
            BOOL writeResult = [linkingCommand writeToFile:scriptFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
            
            if (writeResult)
            {
                printf("Written relinking config at path: %s\n", scriptFilePath.UTF8String);
            }
        }
    }
}
