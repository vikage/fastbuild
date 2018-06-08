//
//  AutoConfig.h
//  fbuild
//
//  Created by fuxsociety on 6/2/18.
//  Copyright © 2018 fsociety. All rights reserved.
//

#import <Foundation/Foundation.h>

void initConfigFile(NSString *configName);
void autoConfig(NSString *name, NSString *configName);
void getSwiftBuildConfigFromLogContent(NSString *logContent, NSString *configName);
void getObjcBuildConfigFromLogContent(NSString *logContent, NSString *configName);
void getLinkingConfigFromLogContent(NSString *logContent, NSString *configName);
void getXibConfigFromLogContent(NSString *logContent, NSString *configName);
void printListConfig(void);
