//
//  Utils.h
//  fbuild
//
//  Created by fuxsociety on 6/2/18.
//  Copyright © 2018 fsociety. All rights reserved.
//

extern NSString *currentDIR;

NSString * GetSystemCall(NSString *cmd);
NSString *GetHomeDir(void);
NSString *getConfigPath(void);
NSString *GetFileNameFromFilePath(NSString *filePath);
