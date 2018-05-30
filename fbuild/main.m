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

#define KNRM  "\x1B[0m"
#define KRED  "\x1B[31m"
#define KGRN  "\x1B[32m"
#define KYEL  "\x1B[33m"
#define KBLU  "\x1B[34m"
#define KMAG  "\x1B[35m"
#define KCYN  "\x1B[36m"
#define KWHT  "\x1B[37m"
#define kRS   "\x1B[0m"

NSString *currentDIR;

NSString *getConfigPath(void);
BOOL compileFile(NSString *filePath,NSString *fileName);
void reBuildBinary(void);
void autoConfig(NSString *name);
void getSwiftBuildConfigFromLogContent(NSString *logContent);
void getObjcBuildConfigFromLogContent(NSString *logContent);
void getLinkingConfigFromLogContent(NSString *logContent);


void PrintCopyRight()
{
    printf("%s\
d88888b d8    8b '88      88' .d8888.  .d88b.   .o88b. d888888b d88888b d888888b db    db\n\
88'     8P    Y8   '88  88'   88'  YP .8P  Y8. d8P  Y8   `88'   88         88    `8b  d8'\n\
88ooo   88    88     '88'     `8bo.   88    88 8P         88    88ooooo    88     `8bd8'\n\
88      88    88     '88'       `Y8b. 88    88 8b         88    88         88       88\n\
88      '8b  d8'   'db  8D'   db   8D `8b  d8' Y8b  d8   .88.   88.        88       88\n\
YP       'Y88P'  '88      88' '8888Y'  `Y88P'   `Y88P' Y888888P Y88888P    YP       YP\n\n%s",KRED,kRS);
    
    printf("                  }-------{+} fastbuild xcode project {+}-------{}\n");
    printf("                   }-------{+} Coded by fuxsociety {+}-------{}\n\n");
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

NSString * GetSystemCall(NSString *cmd)
{
    NSString *tempFilePath = [NSString stringWithFormat:@"%@/Temp.out",getConfigPath()];
    NSString *reCmd = [NSString stringWithFormat:@"%@ &> %@",cmd,tempFilePath];
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
    NSString *configDir = getConfigPath();
    NSString *objcBuildConfigFile = [NSString stringWithFormat:@"%@/objc-build.sh",configDir];
    NSString *swiftBuildConfigFile = [NSString stringWithFormat:@"%@/swift-build.sh",configDir];
    NSString *rebuildConfigFile = [NSString stringWithFormat:@"%@/rebuild.sh",configDir];
    NSString *resignConfigFile = [NSString stringWithFormat:@"%@/resign.sh",configDir];
    
    GetSystemCall([NSString stringWithFormat:@"mkdir -p %@",configDir]);
    GetSystemCall([NSString stringWithFormat:@"rm -f %1$@;touch %1$@",objcBuildConfigFile]);
    GetSystemCall([NSString stringWithFormat:@"rm -f %1$@;touch %1$@",swiftBuildConfigFile]);
    GetSystemCall([NSString stringWithFormat:@"rm -f %1$@;touch %1$@",rebuildConfigFile]);
    GetSystemCall([NSString stringWithFormat:@"rm -f %1$@;touch %1$@",resignConfigFile]);
}

NSString *getAllFileSourceSwift()
{
    NSString *cmd = [NSString stringWithFormat:@"find %@ -name \"*.swift\" | grep -v 'Test'",currentDIR];
    NSString *response = GetSystemCall(cmd);
    
    return response;
}

NSString *getListFileDir()
{
    NSString *listFileSwiftWritePath = [NSString stringWithFormat:@"%@/listFile.txt", getConfigPath()];
    
    return listFileSwiftWritePath;
}

int main(int argc, const char * argv[])
{
    NSString *cmdInitFolder = [NSString stringWithFormat:@"mkdir -p %@/",getConfigPath()];
    system(cmdInitFolder.UTF8String);
    
    currentDIR = GetSystemCall(@"pwd");
    
//#ifdef DEBUG
//    currentDIR = @"/Volumes/Workspace/ominext/assignmnent/ios";
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
    
//    autoConfig(@"Drjoy");
    
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
    
    BOOL errorWhenCompile = NO;
    for (NSString *fileModified in listFileNameModified)
    {
        if (fileModified.length == 0)
        {
            continue;
        }
        
        NSString *fullPath = [NSString stringWithFormat:@"%@/%@",currentDIR,fileModified];
        
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
    
    reBuildBinary();
    printf("Done\n");
    
    return 0;
}

BOOL compileFile(NSString *filePath,NSString *fileName)
{
    printf("Compiling [%s%s%s]\n",KMAG,fileName.UTF8String,kRS);
    NSString *scriptFileName = @"objc-build.sh";
    if ([filePath hasSuffix:@"swift"])
    {
        scriptFileName = @"swift-build.sh";
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
        printf("Compiled [%s%s%s]\n",KGRN,fileName.UTF8String,kRS);
        GetSystemCall([NSString stringWithFormat:@"git add %@",filePath]);
        return YES;
    }
    
    printf("Error occurred while compile file: [%s%s%s] at path: [%s%s%s], Error: %s\n\n",KRED,fileName.UTF8String,kRS, KRED, filePath.UTF8String,kRS, compileResult.UTF8String);
    return NO;
}

void reBuildBinary()
{
    printf("Rebuilding...\n");
    NSString *rebuildScriptFilePath = [NSString stringWithFormat:@"%@/rebuild.sh",getConfigPath()];
    NSString *rebuildCommand = [[NSString alloc] initWithContentsOfFile:rebuildScriptFilePath encoding:NSUTF8StringEncoding error:nil];
    
    GetSystemCall(rebuildCommand);
    
    printf("Resigning...\n");
    NSString *resignScriptFilePath = [NSString stringWithFormat:@"%@/resign.sh",getConfigPath()];
    NSString *resignCommand = [[NSString alloc] initWithContentsOfFile:resignScriptFilePath encoding:NSUTF8StringEncoding error:nil];
    
    GetSystemCall(resignCommand);
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
        printf("%sCan not found '%s' project derivedData, please correct project name%s\n",KRED,name.UTF8String,kRS);
        
        exit(0);
    }
    
    NSString *targetPath = [NSString stringWithFormat:@"%@/%@",derivedDataPath,output];
    NSString *logsPath = [NSString stringWithFormat:@"%@/Logs/Build",targetPath];
    
    NSString *cmdGetLastestLog = [NSString stringWithFormat:@"ls -t %@ | grep -v 'Cache' | head -1",logsPath];
    
    NSString *lastestLogFileName = GetSystemCall(cmdGetLastestLog);
    
    if (lastestLogFileName.length == 0)
    {
        printf("%sCan not found build log for '%s' project, please rebuild once and try again%s\n",KRED,name.UTF8String,kRS);
        
        exit(0);
    }
    
    NSString *lastestLogPath = [NSString stringWithFormat:@"%@/%@",logsPath,lastestLogFileName];
    
    NSString *cmdGetLogContent = [NSString stringWithFormat:@"gunzip -c %@ -S .xcactivitylog",lastestLogPath];
    NSString *logContent = GetSystemCall(cmdGetLogContent);
    logContent = [logContent stringByReplacingOccurrencesOfString:@"36\"" withString:@"\n"];
    
    getSwiftBuildConfigFromLogContent(logContent);
    getObjcBuildConfigFromLogContent(logContent);
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
        
        if (![checkingResultString containsString:@"-primary-file"])
        {
            continue;
        }
        
        targetCmd = checkingResultString;
    }
    
    if (targetCmd)
    {
        if (![targetCmd containsString:@"-filelist"])
        {
            printf("fastbuild only used to project with over 128 source file swift\n");
            exit(0);
        }
        
        NSRegularExpression *regexGetFileName = [NSRegularExpression regularExpressionWithPattern:@"-primary-file [a-z0-9\\/\\-_]+\\/([a-z0-9\\-_\\.]+\\.swift)" options:(NSRegularExpressionCaseInsensitive|NSRegularExpressionAnchorsMatchLines) error:nil];
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
            
            NSRegularExpression *regexReplaceListFile = [NSRegularExpression regularExpressionWithPattern:@"-filelist [a-z0-9\\/\\-_]+" options:(NSRegularExpressionCaseInsensitive|NSRegularExpressionAnchorsMatchLines) error:nil];
            [regexReplaceListFile replaceMatchesInString:finalTargetCmd options:NSMatchingReportCompletion range:NSMakeRange(0, finalTargetCmd.length) withTemplate:@"-filelist ${FILE_LIST}"];
            
            NSString *scriptFilePath = [NSString stringWithFormat:@"%@/swift-build.sh",getConfigPath()];
            BOOL writeResult = [finalTargetCmd writeToFile:scriptFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
            
            if (writeResult)
            {
                printf("%sWritten swift build config%s\n",KGRN,kRS);
            }
        }
        else
        {
            printf("%sCan not found swift config. If you using swift project, edit any swift file then build (⌘ + B) and try again. If not ignore this message%s\n",KRED,kRS);
        }
    }
    else
    {
        printf("%sCan not found swift config. If you using swift project, edit any swift file then build (⌘ + B) and try again. If not ignore this message%s\n",KRED,kRS);
    }
}

void getObjcBuildConfigFromLogContent(NSString *logContent)
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
            
            if ([matchString containsString:@"-fmodule-name="])
            {
                continue;
            }
            
            if ([matchString containsString:@"-filelist"])
            {
                continue;
            }
            
            if ([matchString containsString:@".c"])
            {
                continue;
            }
            
            linkingCommand = matchString;
        }
        
        if (linkingCommand)
        {
            NSRegularExpression *regexGetFileName = [NSRegularExpression regularExpressionWithPattern:@"-c [a-z0-9\\/\\-]+\\/([a-z0-9\\-_\\.]+\\.m)" options:(NSRegularExpressionCaseInsensitive|NSRegularExpressionAnchorsMatchLines) error:nil];
            NSArray *matchings = [regexGetFileName matchesInString:linkingCommand options:NSMatchingReportCompletion range:NSMakeRange(0, linkingCommand.length)];
            
            NSTextCheckingResult *firstMatch = [matchings firstObject];
            if (firstMatch && firstMatch.numberOfRanges > 1)
            {
                NSRange fileNameRange = [firstMatch rangeAtIndex:1];
                NSString *fileNameAndEx = [linkingCommand substringWithRange:fileNameRange];
                NSString *fileName = [fileNameAndEx stringByReplacingOccurrencesOfString:@".m" withString:@""];
                
                NSMutableString *finalTargetCmd = [[NSMutableString alloc] initWithString:linkingCommand];
                [finalTargetCmd replaceCharactersInRange:firstMatch.range withString:@"-c ${FILEPATH}"];
                [finalTargetCmd replaceOccurrencesOfString:[fileName stringByAppendingString:@"."] withString:@"${FILENAME}." options:0 range:NSMakeRange(0, finalTargetCmd.length)];
                
                NSString *scriptFilePath = [NSString stringWithFormat:@"%@/objc-build.sh",getConfigPath()];
                BOOL writeResult = [finalTargetCmd writeToFile:scriptFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
                
                if (writeResult)
                {
                    printf("%sWritten objc build config%s\n",KGRN,kRS);
                }
            }
        }
    }
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
            NSString *codeSignCommand;
            NSRegularExpression *codeSignRegex = [NSRegularExpression regularExpressionWithPattern:@"\\/usr\\/bin\\/codesign --force --sign [^\\n]+" options:(NSRegularExpressionCaseInsensitive|NSRegularExpressionAnchorsMatchLines) error:nil];
            NSArray *matchCodeSignResults = [codeSignRegex matchesInString:logContent options:NSMatchingReportCompletion range:NSMakeRange(0, logContent.length)];
            NSTextCheckingResult *codeSignLastMatch = [matchCodeSignResults lastObject];
            
            if (codeSignLastMatch)
            {
                codeSignCommand = [logContent substringWithRange:codeSignLastMatch.range];
                codeSignCommand = [codeSignCommand stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                
                NSString *resignScriptFilePath = [NSString stringWithFormat:@"%@/resign.sh",getConfigPath()];
                BOOL writeResult = [codeSignCommand writeToFile:resignScriptFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
                
                if (writeResult)
                {
                    printf("%sWritten resign build config%s\n",KGRN,kRS);
                }
            }
            
            NSString *scriptFilePath = [NSString stringWithFormat:@"%@/rebuild.sh",getConfigPath()];
            BOOL writeResult = [linkingCommand writeToFile:scriptFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
            
            if (writeResult)
            {
                printf("%sWritten relink build config%s\n",KGRN,kRS);
            }
        }
    }
}
