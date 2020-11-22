//
//  DWCameraManagerMacro.h
//  DWCameraManager
//
//  Created by Wicky on 2020/6/22.
//  Copyright © 2020 Wicky. All rights reserved.
//

#ifndef DWCameraManagerMacro_h
#define DWCameraManagerMacro_h

#define DWCameraManagerLogWarning(...) \
do {\
    NSLog(@"DWCameraManager Warning : %@",[NSString stringWithFormat:__VA_ARGS__]);\
} while (0)

#define DWCameraManagerLogError(...) \
do {\
    NSLog(@"DWCameraManager Error : %@",[NSString stringWithFormat:__VA_ARGS__]);\
} while (0)

#endif /* DWCameraManagerMacro_h */
