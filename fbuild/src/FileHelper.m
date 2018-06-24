//
//  FileHelper.m
//  fbuild
//
//  Created by fuxsociety on 6/2/18.
//  Copyright © 2018 fsociety. All rights reserved.
//

#include "FileHelper.h"
#include "Utils.h"
#include "Config.h"

NSArray *getAllFileSourceObjc()
{
    NSString *cmd = [NSString stringWithFormat:@"find %@ -name \"*.m\" | grep -v 'Test'| grep -v 'Pods'",currentDIR];
    NSString *response = GetSystemCall(cmd);
    
    return [response componentsSeparatedByString:@"\n"];
}

NSString *getAllFileSourceSwift()
{
    NSString *cmd = [NSString stringWithFormat:@"find %@ -name \"*.swift\" | grep -v 'Test'| grep -v 'Pods' | grep -v 'Carthage'",currentDIR];
    NSString *response = GetSystemCall(cmd);
    
    return response;
}

NSString *getListFileDir()
{
    NSString *listFileSwiftWritePath = [NSString stringWithFormat:@"%@/listFile.txt", getConfigPath()];
    
    return listFileSwiftWritePath;
}

NSArray *getListFileModified()
{
    NSString *commandGetListFileModify = [NSString stringWithFormat:@"cd %@;git status -s | grep '^.M' | cut -c4- | grep -E \".m$|.m\\\"$|.swift$|.swift\\\"$|.xib\" | grep -v '\\->'",currentDIR];
    NSString *resultListFileModify = GetSystemCall(commandGetListFileModify);
    resultListFileModify = [resultListFileModify stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    
    return [resultListFileModify componentsSeparatedByString:@"\n"];;
}

void writeListFileSwift()
{
    NSString *listFile = getAllFileSourceSwift();
    NSString *listFileSwiftWritePath = getListFileDir();
    listFile = [listFile lowercaseString];
    BOOL writeResult = [listFile writeToFile:listFileSwiftWritePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    if (writeResult)
    {
        print("%sWritten list file%s\n",KGRN,kRS);
    }
}

NSArray *getAllSourceFile()
{
    NSMutableArray *allSourceFile = [[NSMutableArray alloc] init];
    NSString *allSourceSwiftString = getAllFileSourceSwift();
    NSArray *allSourceSwift = [allSourceSwiftString componentsSeparatedByString:@"\n"];
    if (allSourceSwiftString.length == 0)
    {
        allSourceSwift = nil;
    }
    
    NSArray *allSourceObjc = getAllFileSourceObjc();
    
    [allSourceFile addObjectsFromArray:allSourceObjc];
    [allSourceFile addObjectsFromArray:allSourceSwift];
    
    return allSourceFile;
}
