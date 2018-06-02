//
//  AutoConfig.h
//  fbuild
//
//  Created by fuxsociety on 6/2/18.
//  Copyright © 2018 fsociety. All rights reserved.
//

#import <Foundation/Foundation.h>

void initConfigFile(void);
void autoConfig(NSString *name);
void getSwiftBuildConfigFromLogContent(NSString *logContent);
void getObjcBuildConfigFromLogContent(NSString *logContent);
void getLinkingConfigFromLogContent(NSString *logContent);
