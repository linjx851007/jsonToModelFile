//
//  AppDelegate.m
//  JsonToModelFile
//  Copyright © 2021年 apple. All rights reserved.

#import "AppDelegate.h"
#import "CreateFileModel.h"
#import "JSONKit.h"
#import "BaseItem.h"
@interface AppDelegate ()
@property (nonatomic, weak) IBOutlet NSWindow* window;
@property (nonatomic, weak) IBOutlet NSTextField* classText;
@property (nonatomic, weak) IBOutlet NSScrollView *textScrollView;
@property (nonatomic, weak) IBOutlet NSScrollView *containerBaseScrollView;
@property (nonatomic, weak) IBOutlet NSButton *checkButton;
@property (nonatomic, weak) IBOutlet NSButton *checkContainerButton;
@property (nonatomic, assign) BOOL isCheckOn;
@property (nonatomic, assign) BOOL isCheckContainerOn;
@property (nonatomic, strong) BaseItem *baseItem;
@end

@implementation AppDelegate
- (NSString*)loadTipString
{
    return @"上面复选框打勾时，此输入框生效\r\n基类拷贝时格式如下：\r\n\r\n@interface BaseModel : NSObject\r\n@property(strong,nonatomic) NSNumber *code;\r\n@property(strong,nonatomic) NSNumber *success;\r\n@property(copy,nonatomic) NSString *msg;\r\n@property(strong,nonatomic) NSNumber *total;\r\n@end\r\n\r\n生成的对象会继承BaseModel并过滤对应属性。\r\n因系统关键词问题，生成结果默认替换属性id->cid，new->cnew，其余自己视情况添加。";
}

- (NSString*)loadMidString:(NSString*)fullString beginString:(NSString*)beginString endString:(NSString*)endString
{
    NSRange startRange = [fullString rangeOfString:beginString];
    NSRange endRange = [fullString rangeOfString:endString];
    if (startRange.length && endRange.length)
    {
        NSRange range = NSMakeRange(startRange.location + startRange.length, endRange.location - startRange.location - startRange.length);
        NSString *result = [fullString substringWithRange:range];
        return [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    return nil;
}

- (NSString*)loadSufString:(NSString*)fullString formString:(NSString*)formString
{
    NSRange startRange = [fullString rangeOfString:formString];
    if (startRange.length)
    {
        NSString *result = [fullString substringFromIndex:startRange.location + startRange.length];
        return [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    return nil;
}

- (void)analysisContainerString
{
    if (self.checkContainerButton.state == NSControlStateValueOn)
    {
        NSTextView* jsonTextView=(NSTextView*)self.containerBaseScrollView.contentView.documentView;
        NSString* inputString=jsonTextView.textStorage.string;
        
        NSString *baseClassName = [self loadMidString:inputString beginString:@"@interface" endString:@":"];
        if (baseClassName)
        {
            BaseItem *item = [[BaseItem alloc] init];
            item.baseClassName = baseClassName;
            
            NSArray *proList = [inputString componentsSeparatedByString:@";"];
            NSMutableArray *resultList = [[NSMutableArray alloc] init];
            for (NSInteger index = 0; index < proList.count; index++)
            {
                NSString *single = [proList objectAtIndex:index];
                NSString *property = [self loadSufString:single formString:@"*"];
                if (property)
                {
                    [resultList addObject:property];
                }
            }
            item.basePropertyName = resultList;
            self.baseItem = item;
        }
    }
    else
    {
        self.baseItem = nil;
    }
}

- (BOOL)propertyStringIsInBaseClass:(NSString*)propertyString
{
    if (self.baseItem && self.baseItem.basePropertyName.count > 0 && self.checkContainerButton.state == NSControlStateValueOn)
    {
        for (NSString *subString in self.baseItem.basePropertyName)
        {
            if ([subString isEqualToString:propertyString])
            {
                return YES;
            }
        }
    }
    return NO;
}

- (void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
    self.isCheckOn = YES;
    self.checkButton.state = NSControlStateValueOn;
    
    self.isCheckContainerOn = NO;
    self.checkContainerButton.state = NSControlStateValueOff;
    
    NSTextView* containerTextView=(NSTextView*)self.containerBaseScrollView.contentView.documentView;
    NSAttributedString* attr = [[NSAttributedString alloc] initWithString:[self loadTipString]];
    [[containerTextView textStorage] appendAttributedString:attr];
    
}

- (IBAction)displayImportString:(id)sender
{
    NSButton *checkButton = (NSButton*)sender;
    if (checkButton.state == NSControlStateValueOn) {
        self.isCheckOn = YES;
    }
    else{
        self.isCheckOn = NO;
    }
}

- (IBAction)displayContainerBaseString:(id)sender
{
    NSButton *checkButton = (NSButton*)sender;
    if (checkButton.state == NSControlStateValueOn) {
        self.isCheckContainerOn = YES;
    }
    else{
        self.isCheckContainerOn = NO;
    }
}

- (IBAction)createClassFile:(id)sender
{
    NSTextView* jsonTextView=(NSTextView*)self.textScrollView.contentView.documentView;
    NSString* jsonStr=jsonTextView.textStorage.string;
    NSDictionary* dic = [self GetDictionaryWithJson:jsonStr];
    if (dic == nil) {
        jsonTextView.string = @"JSON格式错误";
        return;
    }
    
    [self analysisContainerString];
    NSString* className = self.classText.stringValue;
    if (className==nil||className.length<1) {
        jsonTextView.string = @"请在上方输入框输入要保存的类名【ClassName】";
        return;
    }
    className=[self stringToClassName:className];
    NSArray* keyArray = [dic allKeys];

    NSMutableArray* createFileModelArray = [[NSMutableArray alloc] init];
    [self ergodicMethod:keyArray dataSourceDic:dic className:className createFileModelArray:createFileModelArray];

    [self createJsonModelFily:createFileModelArray classFileName:className];
}

- (void)ergodicMethod:(NSArray*)keyArray dataSourceDic:(NSDictionary*)dic className:(NSString*)className createFileModelArray:(NSMutableArray*)createFileModelArray
{
    ClassModel* createFileModel = [[ClassModel alloc] init];
    createFileModel.myClassName = className;
    createFileModel.fieldsArray = [[NSMutableArray alloc] init];
    [createFileModelArray addObject:createFileModel];

    for (int i = 0; i < keyArray.count; i++) {
        id key = [keyArray objectAtIndex:i];
        id value = [dic objectForKey:key];
         
#ifdef WORD_ID
        if (key && [key isKindOfClass:[NSString class]])
        {
            NSString *keyString = (NSString*)key;
            if ([keyString isEqualToString:@"id"])
            {
                key = @"cid";
            }
            else if([keyString isEqualToString:@"new"])
            {
                key = @"cnew";
            }
        }
#endif

        PropertyModel* fieldsModel = [[PropertyModel alloc] init];
        fieldsModel.keyObject = key;
        fieldsModel.valueObject = value;
        key=[self stringToClassName:key];

        if ([value isKindOfClass:[NSDictionary class]]) {
            NSDictionary* dicChild = (NSDictionary*)value;
            NSArray* dicChildKeyArray = [dicChild allKeys];
            NSString* tempClassName=[NSString stringWithFormat:@"%@%@",className,key];

            fieldsModel.convertString=tempClassName;
            [self ergodicMethod:dicChildKeyArray dataSourceDic:dicChild className:tempClassName createFileModelArray:createFileModelArray];
        }
        else if ([value isKindOfClass:[NSArray class]]) {
            NSArray* tempArray = (NSArray*)value;

            if (tempArray.count > 0) {
                id arrayValue = tempArray[0];
                if ([arrayValue isKindOfClass:[NSDictionary class]]) {
                    
                    NSDictionary* dicChild = (NSDictionary*)arrayValue;
                    NSArray* dicChildKeyArray = [dicChild allKeys];
                    NSString* tempClassName = [NSString stringWithFormat:@"%@%@",className,key];

                    fieldsModel.convertString = tempClassName;
                    
                    [self ergodicMethod:dicChildKeyArray dataSourceDic:dicChild className:tempClassName createFileModelArray:createFileModelArray];
                }
            }else{
                fieldsModel.convertString=[NSString stringWithFormat:@"%@%@",className,key];
                
                ClassModel* emptyArrayCreateFileModel = [[ClassModel alloc] init];
                emptyArrayCreateFileModel.myClassName = fieldsModel.convertString;
                emptyArrayCreateFileModel.fieldsArray = [[NSMutableArray alloc] init];
                [createFileModelArray addObject:emptyArrayCreateFileModel];
            }
        }

        [createFileModel.fieldsArray addObject:fieldsModel];
    }
}

-(void)createJsonModelFily:(NSMutableArray*)createFileModelArray classFileName:(NSString*)className{
    
    BOOL hasBaseClassString = NO;
    if (self.baseItem && self.checkContainerButton.state == NSControlStateValueOn)
    {
        hasBaseClassString = YES;
    }
    
    NSString* pointHFileStr = [NSString stringWithFormat:@"%@#pragma mark -- \r\n#pragma mark -- %@\r\n",(self.isCheckOn)?@"":@"#import <Foundation/Foundation.h>\r\n",className];
    NSString *mfileHeadimport = [NSString stringWithFormat:@"#import \"%@.h\"\r\n",className];
    NSString* pointMFileStr = [NSString stringWithFormat:@"%@#pragma mark -- \r\n#pragma mark -- %@\r\n",(self.isCheckOn)?@"":mfileHeadimport,className];
    for (NSInteger i=createFileModelArray.count-1;i>=0;i--) {
        ClassModel* createFileModel =[createFileModelArray objectAtIndex:i];
        pointHFileStr = [pointHFileStr stringByAppendingString:[NSString stringWithFormat:@"@interface %@ : %@\r\n", createFileModel.myClassName,hasBaseClassString ? self.baseItem.baseClassName :@"NSObject"]];
        pointMFileStr = [pointMFileStr stringByAppendingString:[NSString stringWithFormat:@"@implementation %@\r\n", createFileModel.myClassName]];
        
        NSString* mapperPropertyString=nil; //modelCustomPropertyMapper
        NSString* containerPropertyString=nil; //modelContainerPropertyGenericClass
        
        for (PropertyModel* fieldsModel in createFileModel.fieldsArray) {
            NSString* fileStr;
            if ([fieldsModel.valueObject isKindOfClass:[NSString class]]) {
                
                if (![self propertyStringIsInBaseClass:fieldsModel.keyObject])
                {
                    fileStr = [NSString stringWithFormat:@"@property (copy,nonatomic)   NSString *%@;\r\n", fieldsModel.keyObject];
                }
                #ifdef WORD_ID
                if ([fieldsModel.keyObject isKindOfClass:[NSString class]])
                {
                    NSString *keyString = (NSString*)fieldsModel.keyObject;
                    if ([keyString isEqualToString:@"cid"])
                    {
                        mapperPropertyString=[NSString stringWithFormat:@"+ (NSDictionary *)modelCustomPropertyMapper{  \r\n       return @{ @\"cid\":@\"id\""];
                    }
                    else if ([keyString isEqualToString:@"cnew"])
                    {
                        mapperPropertyString=[NSString stringWithFormat:@"+ (NSDictionary *)modelCustomPropertyMapper{  \r\n       return @{ @\"cnew\":@\"new\""];
                    }
                }
                #endif
            }
            else if ([fieldsModel.valueObject isKindOfClass:[NSNumber class]]) {
                if (![self propertyStringIsInBaseClass:fieldsModel.keyObject])
                {
                    fileStr = [NSString stringWithFormat:@"@property (strong,nonatomic) NSNumber *%@;\r\n", fieldsModel.keyObject];
                }
                #ifdef WORD_ID
                if ([fieldsModel.keyObject isKindOfClass:[NSString class]])
                {
                    NSString *keyString = (NSString*)fieldsModel.keyObject;
                    if ([keyString isEqualToString:@"cid"])
                    {
                        mapperPropertyString=[NSString stringWithFormat:@"+ (NSDictionary *)modelCustomPropertyMapper{  \r\n       return @{ @\"cid\":@\"id\""];
                    }
                    else if ([keyString isEqualToString:@"cnew"])
                    {
                        mapperPropertyString=[NSString stringWithFormat:@"+ (NSDictionary *)modelCustomPropertyMapper{  \r\n       return @{ @\"cnew\":@\"new\""];
                    }
                }
                #endif
            }
            else if ([fieldsModel.valueObject isKindOfClass:[NSArray class]]) {
                if (![self propertyStringIsInBaseClass:fieldsModel.keyObject])
                {
                    fileStr = [NSString stringWithFormat:@"@property (strong,nonatomic) NSArray *%@;\r\n", fieldsModel.keyObject];
                }
                
                NSLog(@"fieldsModel.convertString:%@",fieldsModel.convertString);
                if (containerPropertyString) {
                    containerPropertyString=[NSString stringWithFormat:@"%@,@\"%@\" : [%@ class]",containerPropertyString,fieldsModel.keyObject,fieldsModel.convertString!=nil?fieldsModel.convertString:@"NSString"];
                }else{
                    containerPropertyString=[NSString stringWithFormat:@"+ (nullable NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass{  \r\n       return @{ @\"%@\" : [%@ class] ", fieldsModel.keyObject,fieldsModel.convertString!=nil?fieldsModel.convertString:@"NSString"];
                }
            }
            else {
                if (fieldsModel.convertString) {
                    if (![self propertyStringIsInBaseClass:fieldsModel.keyObject])
                    {
                        fileStr = [NSString stringWithFormat:@"@property (strong,nonatomic) %@ *%@;\r\n",fieldsModel.convertString, fieldsModel.keyObject];
                    }
                    if (containerPropertyString) {
                        containerPropertyString=[NSString stringWithFormat:@"%@,@\"%@\" : [%@ class]",containerPropertyString,fieldsModel.keyObject,fieldsModel.convertString!=nil?fieldsModel.convertString:@"NSString"];
                    }else{
                        containerPropertyString=[NSString stringWithFormat:@"+ (nullable NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass{  \r\n       return @{ @\"%@\" : [%@ class] ", fieldsModel.keyObject,fieldsModel.convertString!=nil?fieldsModel.convertString:@"NSString"];
                    }
                    
                }else{
                    if (![self propertyStringIsInBaseClass:fieldsModel.keyObject])
                    {
                        fileStr = [NSString stringWithFormat:@"@property (strong,nonatomic) NSString *%@;\r\n", fieldsModel.keyObject];
                    }
                }
            }
            if(fileStr)
            {
                pointHFileStr = [pointHFileStr stringByAppendingString:fileStr];
            }
        }
        if (mapperPropertyString) {
            mapperPropertyString=[mapperPropertyString stringByAppendingString:@"}; \r\n}\r\n"];
            pointMFileStr = [pointMFileStr stringByAppendingString:mapperPropertyString];
        }
        
        if (containerPropertyString) {
            containerPropertyString=[containerPropertyString stringByAppendingString:@"}; \r\n}\r\n"];
            pointMFileStr = [pointMFileStr stringByAppendingString:containerPropertyString];
        }
        
        NSLog(@"model.myClassName:%@", createFileModel.myClassName);
        pointHFileStr = [pointHFileStr stringByAppendingString:@"@end\r\n\r\n"];
        pointMFileStr = [pointMFileStr stringByAppendingString:@"@end\r\n\r\n"];
    }
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseDirectories = YES;
    panel.canChooseFiles = NO;
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if(result == 0) return ;
        NSString* path = [panel.URL path];
        [pointHFileStr writeToFile:[NSString stringWithFormat:@"%@/%@.h",path,className] atomically:NO encoding:NSUTF8StringEncoding error:nil];
        [pointMFileStr writeToFile:[NSString stringWithFormat:@"%@/%@.m",path,className] atomically:NO encoding:NSUTF8StringEncoding error:nil];
    }];
}

-(NSString*)stringToClassName:(NSString*)string{//字符串转换为类名，规则为第一个字母大写
    NSString* oneString=[[string substringWithRange:NSMakeRange(0, 1)] uppercaseString];
    NSString* fromOneString=[string substringFromIndex:1];
    string=[oneString stringByAppendingString:fromOneString];
    return string;
}

- (NSDictionary*)GetDictionaryWithJson:(NSString*)jsonStr
{
    return [jsonStr objectFromJSONStringWithParseOptions:JKParseOptionLooseUnicode];
}

- (void)applicationWillTerminate:(NSNotification*)aNotification
{
    // Insert code here to tear down your application
}

@end
