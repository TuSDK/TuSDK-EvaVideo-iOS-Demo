//
//  TTDocument.m
//  TuSDKEvaDemo
//
//  Created by 言有理 on 2022/3/14.
//  Copyright © 2022 TuSdk. All rights reserved.
//

#import "TTDocument.h"

@implementation TTDocument

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError * _Nullable __autoreleasing *)outError {
    
    self.data = contents;
    
    return YES;
}

@end
