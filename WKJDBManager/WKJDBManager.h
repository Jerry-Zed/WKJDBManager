//
//  WKJDBManager.h
//  Logistics
//
//  Created by 王恺靖 on 2017/12/7.
//  Copyright © 2017年 王恺靖. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol WKJDBModel <NSObject>

@required

+ (NSString *)tableNameForModel;

@end

@interface WKJDBManager : NSObject

+ (instancetype)databaseWithPath:(NSString *)path;

- (instancetype)initWithPath:(NSString *)path;

- (NSArray <id<WKJDBModel>> *)findModelsBySQL:(NSString *)sql modelClass:(Class)modelClass;

- (BOOL)saveOrUpdateModel:(id<WKJDBModel>)model;

- (BOOL)saveOrUpdateModels:(NSArray <id<WKJDBModel>> *)models;

- (BOOL)deleteModel:(id<WKJDBModel>)model;

- (BOOL)deleteModels:(NSArray <id<WKJDBModel>> *)models;

@end
