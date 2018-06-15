//
//  ConfigHelper.m
//  fbuild
//
//  Created by fuxsociety on 6/8/18.
//  Copyright © 2018 fsociety. All rights reserved.
//

#include "ConfigHelper.h"
#include "Config.h"
#import "FileHelper.h"
#import "Utils.h"
NSDictionary *getAppConfig(void)
{
    NSString *configPath = [NSString stringWithFormat:@"%@/fux.config",getConfigPath()];
    NSDictionary *configDict = [[NSDictionary alloc] initWithContentsOfFile:configPath];
    
    if (!configDict)
    {
        configDict = [[NSDictionary alloc] init];
    }
    
    return configDict;
}

BOOL writeConfig(NSDictionary *config)
{
    NSString *configPath = [NSString stringWithFormat:@"%@/fux.config",getConfigPath()];
    return [config writeToFile:configPath atomically:YES];
}

NSString *getCurrentConfig(void)
{
    NSDictionary *config = getAppConfig();
    NSString *currentConfig = [config objectForKey:kCurrentConfig];
    
    if (currentConfig == nil)
    {
        NSArray *listConfigName = [config objectForKey:kConfigs];
        currentConfig = listConfigName.firstObject;
    }
    
    return currentConfig;
}

void setCurrentConfig(NSString *configName)
{
    NSDictionary *config = getAppConfig();
    NSMutableDictionary *newConfig = [NSMutableDictionary dictionaryWithDictionary:config];
    [newConfig setObject:configName forKey:kCurrentConfig];
    
    BOOL writeConfigResult = writeConfig(newConfig);
    if (writeConfigResult)
    {
        print("Set current config '%s' done\n",configName.UTF8String);
    }
    else
    {
        print("%sSet config '%s' fail%s\n",kRED,configName.UTF8String,kRS);
    }
}

void removeConfig(NSString *configName)
{
    NSDictionary *config = getAppConfig();
    NSMutableDictionary *newConfig = [NSMutableDictionary dictionaryWithDictionary:config];
    
    NSString *currentConfig = [config objectForKey:kCurrentConfig];
    NSMutableArray *listConfig = [NSMutableArray arrayWithArray:[newConfig objectForKey:kConfigs]];
    
    if (![listConfig containsObject:configName])
    {
        print("%sConfig '%s' not found%s\n",kRED,configName.UTF8String,kRS);
        exit(0);
    }
    
    if ([currentConfig isEqualToString:configName])
    {
        [listConfig removeObject:currentConfig];
        NSString *newCurrentConfig = [listConfig firstObject];
        if (newCurrentConfig)
        {
            [newConfig setObject:newCurrentConfig forKey:kCurrentConfig];
            print("%sCurrent config is replace to '%s'%s\n",KMAG,newCurrentConfig.UTF8String,kRS);
        }
    }
    else
    {
        [listConfig removeObject:configName];
    }
    
    NSString *cmdRemoveConfigFolder = [NSString stringWithFormat:@"rm -r %@/%@",getConfigPath(),configName];
    NSString * removeConfigFolderResult = GetSystemCall(cmdRemoveConfigFolder);
    if (removeConfigFolderResult.length)
    {
        print("%sRemove dir of config '%s' failure, discard all change.%s\n",kRED,configName.UTF8String,kRS);
    }
    
    [newConfig setObject:listConfig forKey:kConfigs];
    BOOL writeConfigResult = writeConfig(newConfig);
    if (writeConfigResult)
    {
        print("%sRemove '%s' config done.%s\n",KGRN,configName.UTF8String,kRS);
    }
    else
    {
        print("%sWrite new config failed, discard all change.%s\n",kRED,kRS);
    }
}
