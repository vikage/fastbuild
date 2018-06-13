//
//  AutoConfig.c
//  fbuild
//
//  Created by fuxsociety on 6/2/18.
//  Copyright © 2018 fsociety. All rights reserved.
//

#include "AutoConfig.h"
#import <Foundation/Foundation.h>
#include "Config.h"
#include "Utils.h"
#include "FileHelper.h"
#include "ConfigHelper.h"

void initConfigFile(NSString *configName)
{
    NSString *configDir = getConfigPath();
    NSString *objcBuildConfigFile = [NSString stringWithFormat:@"%@/%@/objc-build.sh",configDir, configName];
    NSString *swiftBuildConfigFile = [NSString stringWithFormat:@"%@/%@/swift-build.sh",configDir,configName];
    NSString *rebuildConfigFile = [NSString stringWithFormat:@"%@/%@/rebuild.sh",configDir,configName];
    NSString *resignConfigFile = [NSString stringWithFormat:@"%@/%@/resign.sh",configDir,configName];
    
    GetSystemCall([NSString stringWithFormat:@"mkdir -p %@",configDir]);
    GetSystemCall([NSString stringWithFormat:@"touch %1$@",objcBuildConfigFile]);
    GetSystemCall([NSString stringWithFormat:@"touch %1$@",swiftBuildConfigFile]);
    GetSystemCall([NSString stringWithFormat:@"touch %1$@",rebuildConfigFile]);
    GetSystemCall([NSString stringWithFormat:@"touch %1$@",resignConfigFile]);
}

void autoConfig(NSString *name, NSString *configName)
{
    initConfigFile(configName);
    printf("Auto config %s project\n",name.UTF8String);
    NSString *derivedDataPath = [NSString stringWithFormat:@"%@/Library/Developer/Xcode/DerivedData",GetHomeDir()];
    NSString *cmd = [NSString stringWithFormat:@"ls -t %@ | grep '%@' | head -1",derivedDataPath,name];
    
    NSString *output = GetSystemCall(cmd);
    
    if (output.length == 0)
    {
        printf("%sCan not found '%s' project derivedData, please correct project name%s\n",kRED,name.UTF8String,kRS);
        
        exit(0);
    }
    
    NSString *targetPath = [NSString stringWithFormat:@"%@/%@",derivedDataPath,output];
    NSString *logsPath = [NSString stringWithFormat:@"%@/Logs/Build",targetPath];
    
    NSString *cmdGetLastestLog = [NSString stringWithFormat:@"ls -t %@ | grep -v 'Cache' | grep 'xcactivitylog' | head -1",logsPath];
    
    NSString *lastestLogFileName = GetSystemCall(cmdGetLastestLog);
    
    if (lastestLogFileName.length == 0)
    {
        printf("%sCan not found build log for '%s' project, please rebuild once and try again%s\n",kRED,name.UTF8String,kRS);
        
        exit(0);
    }
    
    NSString *lastestLogPath = [NSString stringWithFormat:@"%@/%@",logsPath,lastestLogFileName];
    
    NSString *cmdGetLogContent = [NSString stringWithFormat:@"gunzip -c %@ -S .xcactivitylog",lastestLogPath];
    NSString *logContent = GetSystemCall(cmdGetLogContent);
    logContent = [logContent stringByReplacingOccurrencesOfString:@"36\"" withString:@"\n"];
    
    NSString *cmdCreateDir = [NSString stringWithFormat:@"mkdir -p %@/%@",getConfigPath(),configName];
    GetSystemCall(cmdCreateDir);
    
    getSwiftBuildConfigFromLogContent(logContent, configName);
    getObjcBuildConfigFromLogContent(logContent, configName);
    getLinkingConfigFromLogContent(logContent, configName);
    getXibConfigFromLogContent(logContent, configName);
    
    NSDictionary *currentConfig = getAppConfig();
    NSMutableDictionary *newConfig = [[NSMutableDictionary alloc] initWithDictionary:currentConfig];
    NSMutableArray *listConfig = [NSMutableArray arrayWithArray:[newConfig objectForKey:kConfigs]];
    
    if (![listConfig containsObject:configName])
    {
        [listConfig addObject:configName];
        
        if (listConfig.count == 1)
        {
            [newConfig setObject:configName forKey:kCurrentConfig];
        }
        
        [newConfig setObject:listConfig forKey:kConfigs];
    }
    
    BOOL writeConfigResult = writeConfig(newConfig);
    if (writeConfigResult)
    {
        printf("Config done\n");
    }
    else
    {
        printf("%sWrite config '%s' fail%s\n",kRED,configName.UTF8String,kRS);
    }
}

void getSwiftBuildConfigFromLogContent(NSString *logContent, NSString *configName)
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
            printf("%sfux only used to project with over 128 source file swift%s\n",kRED,kRS);
            exit(0);
        }
        
        NSRegularExpression *regexGetFileName = [NSRegularExpression regularExpressionWithPattern:@"-primary-file [a-z0-9\\/\\-_]+\\/([a-z0-9\\-_\\.+]+\\.swift)" options:(NSRegularExpressionCaseInsensitive|NSRegularExpressionAnchorsMatchLines) error:nil];
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
            
            NSString *scriptFilePath = [NSString stringWithFormat:@"%@/%@/swift-build.sh",getConfigPath(),configName];
            BOOL writeResult = [finalTargetCmd writeToFile:scriptFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
            
            if (writeResult)
            {
                printf("%sWritten swift build config%s\n",KGRN,kRS);
            }
        }
        else
        {
            printf("%sCan not found swift config. If you using swift project, edit any swift file then build (⌘ + B) and try again. If not ignore this message%s\n",kRED,kRS);
        }
    }
    else
    {
        printf("%sCan not found swift config. If you using swift project, edit any swift file then build (⌘ + B) and try again. If not ignore this message%s\n",kRED,kRS);
    }
}

void getObjcBuildConfigFromLogContent(NSString *logContent, NSString *configName)
{
    NSRegularExpression *regexGetLinking = [NSRegularExpression regularExpressionWithPattern:@"^.*\\/clang [^\\n]+" options:(NSRegularExpressionCaseInsensitive|NSRegularExpressionAnchorsMatchLines) error:nil];
    NSArray *resultMatching = [regexGetLinking matchesInString:logContent options:NSMatchingReportCompletion range:NSMakeRange(0, logContent.length)];
    
    if (resultMatching.count != 0)
    {
        NSString *compileCommand;
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
            
            compileCommand = matchString;
        }
        
        if (compileCommand)
        {
            NSRegularExpression *regexGetFileName = [NSRegularExpression regularExpressionWithPattern:@"-c [a-z0-9\\/\\-]+\\/([a-z0-9\\-_\\.+]+\\.m)" options:(NSRegularExpressionCaseInsensitive|NSRegularExpressionAnchorsMatchLines) error:nil];
            NSArray *matchings = [regexGetFileName matchesInString:compileCommand options:NSMatchingReportCompletion range:NSMakeRange(0, compileCommand.length)];
            
            NSTextCheckingResult *firstMatch = [matchings firstObject];
            if (firstMatch && firstMatch.numberOfRanges > 1)
            {
                NSRange fileNameRange = [firstMatch rangeAtIndex:1];
                NSString *fileNameAndEx = [compileCommand substringWithRange:fileNameRange];
                NSString *fileName = [fileNameAndEx stringByReplacingOccurrencesOfString:@".m" withString:@""];
                
                NSMutableString *finalTargetCmd = [[NSMutableString alloc] initWithString:compileCommand];
                [finalTargetCmd replaceCharactersInRange:firstMatch.range withString:@"-c ${FILEPATH}"];
                [finalTargetCmd replaceOccurrencesOfString:[fileName stringByAppendingString:@"."] withString:@"${FILENAME}." options:0 range:NSMakeRange(0, finalTargetCmd.length)];
                
                NSString *scriptFilePath = [NSString stringWithFormat:@"%@/%@/objc-build.sh",getConfigPath(),configName];
                BOOL writeResult = [finalTargetCmd writeToFile:scriptFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
                
                if (writeResult)
                {
                    printf("%sWritten objc build config%s\n",KGRN,kRS);
                }
            }
        }
    }
}

void getLinkingConfigFromLogContent(NSString *logContent, NSString *configName)
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
                
                NSString *resignScriptFilePath = [NSString stringWithFormat:@"%@/%@/resign.sh",getConfigPath(), configName];
                BOOL writeResult = [codeSignCommand writeToFile:resignScriptFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
                
                if (writeResult)
                {
                    printf("%sWritten resign build config%s\n",KGRN,kRS);
                }
            }
            
            NSString *scriptFilePath = [NSString stringWithFormat:@"%@/%@/rebuild.sh",getConfigPath(),configName];
            BOOL writeResult = [linkingCommand writeToFile:scriptFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
            
            if (writeResult)
            {
                printf("%sWritten relink build config%s\n",KGRN,kRS);
            }
        }
    }
}

void getXibConfigFromLogContent(NSString *logContent, NSString *configName)
{
    NSRegularExpression *regexGetXibCompile = [NSRegularExpression regularExpressionWithPattern:@"^.*\\/ibtool [^\\n]+" options:(NSRegularExpressionCaseInsensitive|NSRegularExpressionAnchorsMatchLines) error:nil];
    NSArray *resultMatching = [regexGetXibCompile matchesInString:logContent options:NSMatchingReportCompletion range:NSMakeRange(0, logContent.length)];
    
    NSString *compileXibCommand;
    
    for(NSTextCheckingResult *checkingResult in resultMatching)
    {
        NSString *cmd = [logContent substringWithRange:checkingResult.range];
        cmd = [cmd stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if ([cmd containsString:@"storyboard"])
        {
            continue;
        }
        
        compileXibCommand = cmd;
    }
    
    if (compileXibCommand)
    {
        NSRegularExpression *regexGetFileNameAndEx = [NSRegularExpression regularExpressionWithPattern:@"\\.nib (.*\\/([a-z0-9\\-_\\.+]+)\\.xib)" options:(NSRegularExpressionCaseInsensitive|NSRegularExpressionAnchorsMatchLines) error:nil];
        
        NSArray *matchRegexGetFileNameAndEx = [regexGetFileNameAndEx matchesInString:compileXibCommand options:NSMatchingReportCompletion range:NSMakeRange(0, compileXibCommand.length)];
        NSTextCheckingResult *fileNameMatchResult = [matchRegexGetFileNameAndEx firstObject];
        
        if (fileNameMatchResult && fileNameMatchResult.numberOfRanges > 2)
        {
            NSRange fileNameAndExRange = [fileNameMatchResult rangeAtIndex:2];
            NSString *fileName = [compileXibCommand substringWithRange:fileNameAndExRange];
            
            NSMutableString *finalCompileXibCommand = [[NSMutableString alloc] initWithString:compileXibCommand];
            [finalCompileXibCommand replaceCharactersInRange:[fileNameMatchResult rangeAtIndex:1] withString:@"${FILEPATH}"];
            [finalCompileXibCommand replaceOccurrencesOfString:fileName withString:@"${FILENAME}" options:0 range:NSMakeRange(0, finalCompileXibCommand.length)];
            
            NSString *scriptFilePath = [NSString stringWithFormat:@"%@/%@/xib-compile.sh",getConfigPath(),configName];
            BOOL writeResult = [finalCompileXibCommand writeToFile:scriptFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
            
            if (writeResult)
            {
                printf("%sWritten xib-compile config%s\n",KGRN,kRS);
            }
        }
    }
}


void printListConfig()
{
    NSDictionary *config = getAppConfig();
    NSString *currentConfig = [config objectForKey:kCurrentConfig];
    NSArray *listConfig = [config objectForKey:kConfigs];
    
    printf("List config: \n");
    
    for (NSString *configName in listConfig)
    {
        if ([configName isEqualToString:currentConfig])
        {
            printf("%s* %s%s\n",KGRN,configName.UTF8String,kRS);
        }
        else
        {
            printf("  %s\n",configName.UTF8String);
        }
    }
}
