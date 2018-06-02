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
    NSString *cmd = [NSString stringWithFormat:@"find %@ -name \"*.m\" | grep -v 'Test'",currentDIR];
    NSString *response = GetSystemCall(cmd);
    
    return [response componentsSeparatedByString:@"\n"];
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

NSArray *getListFileModified()
{
    NSString *commandGetListFileModify = [NSString stringWithFormat:@"cd %@;git status -s | grep '^.M' | cut -c4- | grep -E \".m$|.swift$\"",currentDIR];
    NSString *resultListFileModify = GetSystemCall(commandGetListFileModify);
    
    return [resultListFileModify componentsSeparatedByString:@"\n"];;
}

void writeListFileSwift()
{
    NSString *listFile = getAllFileSourceSwift();
    NSString *listFileSwiftWritePath = getListFileDir();
    BOOL writeResult = [listFile writeToFile:listFileSwiftWritePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    if (writeResult)
    {
        printf("%sWritten list file%s\n",KGRN,kRS);
    }
}

NSArray *getAllSourceFile()
{
    NSMutableArray *allSourceFile = [[NSMutableArray alloc] init];
    NSString *allSourceSwiftString = getAllFileSourceSwift();
    NSArray *allSourceSwift = [allSourceSwiftString componentsSeparatedByString:@"\n"];
    NSArray *allSourceObjc = getAllFileSourceObjc();
    
    [allSourceFile addObjectsFromArray:allSourceObjc];
    [allSourceFile addObjectsFromArray:allSourceSwift];
    
    return allSourceFile;
}
