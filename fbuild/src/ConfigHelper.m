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
        printf("Set current config '%s' done\n",configName.UTF8String);
    }
    else
    {
        printf("%sSet config '%s' fail%s\n",kRED,configName.UTF8String,kRS);
    }
}
