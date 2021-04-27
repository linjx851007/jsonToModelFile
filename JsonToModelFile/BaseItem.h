//
//  BaseItem.h
//  JsonToModelFile
//
//  Created by Linjx on 2021/4/27.
//  Copyright © 2021 apple. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BaseItem : NSObject
@property(nonatomic, strong) NSString* baseClassName;
@property(nonatomic, strong) NSArray* basePropertyName;
@end

NS_ASSUME_NONNULL_END
