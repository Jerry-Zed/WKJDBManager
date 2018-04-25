//
//  WKJDBManager.m
//  Logistics
//
//  Created by 王恺靖 on 2017/12/7.
//  Copyright © 2017年 王恺靖. All rights reserved.
//

#import "WKJDBManager.h"
#import "FMDB.h"
#import "MJExtension/MJExtension.h"

@interface WKJDBManager ()

@property (nonatomic, strong) FMDatabaseQueue *queue;

@end

@implementation WKJDBManager

+ (instancetype)databaseWithPath:(NSString *)path
{
    return [[WKJDBManager alloc] initWithPath:path];
}

- (instancetype)initWithPath:(NSString *)path
{
    self = [super init];
    if (self) {
        
        self.queue = [FMDatabaseQueue databaseQueueWithPath:path];
    }
    return self;
}

#pragma mark Select

- (NSArray <id<WKJDBModel>> *)findModelsBySQL:(NSString *)sql modelClass:(Class)modelClass
{
    NSMutableArray *dataArray = [[NSMutableArray alloc] init];
    
    [self.queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *set = [db executeQuery:sql];
        
        while ([set next]) {
            
            id <WKJDBModel> model = [modelClass mj_objectWithKeyValues:set.resultDictionary];
            [dataArray addObject:model];
        }
    }];
    
    return [dataArray copy];
}

#pragma mark SaveOrUpdate

- (BOOL)saveOrUpdateModel:(id<WKJDBModel>)model
{
    if (nil == model) return NO;
    
    return [self saveOrUpdateModels:@[model]];
}

- (BOOL)saveOrUpdateModels:(NSArray <id<WKJDBModel>> *)models
{
    if (nil == models) return NO;
    
    __block BOOL result = YES;
    
    [self.queue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        
        result = [self executeUpdateModels:models db:db];
    }];
    
    return result;
}

- (BOOL)executeUpdateModels:(NSArray <id<WKJDBModel>> *)models db:(FMDatabase *)db
{
    for (NSObject <WKJDBModel> *model in models) {
        
        NSString *tableName = [self getTableNameForModel:model];
        if (!tableName || [tableName isEqualToString:@""]) continue;
        
//        NSArray *igKeys = @[@"debugDescription",@"description",@"hash",@"superclass"];
//        NSMutableDictionary *info = [model mj_keyValuesWithIgnoredKeys:igKeys];
        NSMutableDictionary *info = model.mj_keyValues;
        NSString *modelId = info[@"id"];
        
        NSString *paramStr = @"";
        NSString *colName = @"";
        NSString *valName = @"";
        
        for (NSString *key in info.allKeys) {
            
            if ([key isEqualToString:@"id"]) continue;
            
            NSString *valueStr = @"";
            
            if ([info[key] isKindOfClass:[NSString class]]) {
                valueStr = [NSString stringWithFormat:@"'%@'",info[key]];
            }
            else {
                valueStr = [NSString stringWithFormat:@"%@",info[key]];
            }
            
            colName = [colName stringByAppendingFormat:@"%@,",key];
            valName = [valName stringByAppendingFormat:@"%@,",valueStr];
            paramStr = [paramStr stringByAppendingFormat:@"%@=%@,",key,valueStr];
        }
        
        BOOL result = YES;
        
        if (modelId.integerValue == 0) {
            
            if (colName.length > 1 && valName.length > 1) {
                colName = [colName substringWithRange:NSMakeRange(0, colName.length-1)];
                valName = [valName substringWithRange:NSMakeRange(0, valName.length-1)];
            }
            
            NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)", tableName, colName, valName];
            
            result = [db executeUpdate:sql];
        }
        else {
            
            if (paramStr.length > 1) {
                paramStr = [paramStr substringWithRange:NSMakeRange(0, paramStr.length-1)];
            }
            
            NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE id = %@",tableName , paramStr, modelId];
            
            result = [db executeUpdate:sql];
        }
        
        if (!result) return NO;
    }
    
    return YES;
}

#pragma mark Delete

- (BOOL)deleteModel:(id<WKJDBModel>)model
{
    if (nil == model) return NO;
    
    return [self deleteModels:@[model]];
}

- (BOOL)deleteModels:(NSArray <id<WKJDBModel>> *)models
{
    if (nil == models) return NO;
    
    __block BOOL result = YES;
    
    [self.queue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        
        for (NSObject<WKJDBModel> *model in models) {
            
            NSString *tableName = [self getTableNameForModel:model];
            NSString *idStr = model.mj_keyValues[@"id"];
            
            NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE id = %@",tableName,idStr];
            
            result = [db executeUpdate:sql];
            
            if (!result) break;
        }
        
        *rollback = !result;
    }];
    
    return result;
}

#pragma mark ModelInfo

- (NSString *)getTableNameForModel:(NSObject<WKJDBModel> *)model
{
    if (![[model class] respondsToSelector:@selector(tableNameForModel)]) return @"";
    
    NSString *tableName = [[model class] tableNameForModel];
    
    return tableName;
}

@end
