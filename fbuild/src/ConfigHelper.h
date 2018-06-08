//
//  ConfigHelper.h
//  fbuild
//
//  Created by fuxsociety on 6/8/18.
//  Copyright © 2018 fsociety. All rights reserved.
//

#import <Foundation/Foundation.h>

NSDictionary *getAppConfig(void);
BOOL writeConfig(NSDictionary *config);
NSString *getCurrentConfig(void);
void setCurrentConfig(NSString *configName);
