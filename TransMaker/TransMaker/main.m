//
//  main.m
//  TransMaker
//
//  Created by Tomislav Luketic on 7/6/16.
//  Copyright © 2016 Tomislav Luketic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BRLineReader.h"


@interface TransMaker : NSObject



@end

@implementation TransMaker
{
    NSMutableDictionary * _languages;
    NSMutableDictionary* _columnMap;
    NSMutableArray* _keysOrder;
    NSUInteger _numberOfElements;
}


-(void)makeTrans:(NSString*)fileName
{
    BRLineReader* reader=[[BRLineReader alloc] initWithFile:fileName encoding:NSUTF8StringEncoding];
    
    NSString* field=nil;
    NSString* tmpField = @"";
    
    while ((field=[reader readLine]))
    {
        if ([field length]==0)
            continue;
        
        
       
        
        if (!_languages)
            [self initializeLanguages:field];
        else
        {
            NSArray* arr = [field componentsSeparatedByString:@","];
            
            if ([arr count] < _numberOfElements)
            {
                tmpField = [tmpField stringByAppendingString:field];
                tmpField = [tmpField stringByReplacingOccurrencesOfString:@"\"""" withString:@""];
                tmpField = [tmpField stringByReplacingOccurrencesOfString:@"""" withString:@""];
                tmpField = [tmpField stringByReplacingOccurrencesOfString:@"\r" withString:@""];
                tmpField = [tmpField stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                
                arr = [tmpField componentsSeparatedByString:@","];
                
                if ([arr count] < _numberOfElements)
                  continue;
                else
                    field = @"";
            }
            
            if ([tmpField length]>0)
            {
                field = [tmpField stringByAppendingString:field];
                tmpField = @"";
            }
            
            [self addField:field];
        }
        
    }
    
    
    
    for (NSString* aKey in _languages.allKeys) {
        
        NSDictionary* dict = _languages[aKey];
        
        NSMutableArray* arr=[NSMutableArray array];
        
        for (NSString* aKey2 in _keysOrder)
        {
            if ([dict[aKey2] length]==0)
                continue;
            
            [arr addObject:[NSString stringWithFormat:@"\"%@\"=\"%@\";",aKey2,dict[aKey2]]];
            
        }
        
        NSString* str=[arr componentsJoinedByString:@"\n"];
        NSError* err=nil;
        
        if ([str length]>0)
          [str writeToFile:[NSString stringWithFormat:@"%@.strings",aKey]  atomically:NO encoding:NSUTF8StringEncoding error:&err];
        
        
    }

}


- (void) initializeLanguages:(NSString*)aField
{
    
    _languages=[NSMutableDictionary dictionary];
    _columnMap=[NSMutableDictionary dictionary];
    
   
    
    NSString* file= [[NSBundle mainBundle] pathForResource:@"Languages" ofType:@"plist"];
    
      
    NSDictionary* dict=[NSDictionary dictionaryWithContentsOfFile:file];
    
    NSArray* langs=[aField componentsSeparatedByString:@","];
    
    _numberOfElements = [langs count];
    
    NSNumber* colIdx = [NSNumber numberWithInteger:0];
    
    for (NSString* lang in langs) {
        
        NSString* shortLang = dict[lang];
        
        
        
        if (shortLang)
        {
            _columnMap[colIdx]=shortLang;
            _languages[shortLang]=[NSMutableDictionary dictionary];
            
            
        }
        
        NSInteger i =colIdx.integerValue;
        i++;
        colIdx=[NSNumber numberWithInteger:i];
        
    }
    
    
}

-(void)addField:(NSString*)aField
{
    if ([aField length]==0)
    {
        return;
    }
    
    
    NSMutableArray *target = [NSMutableArray array];
    NSScanner *scanner = [NSScanner scannerWithString:aField];
    NSString *tmp;
    
    if ([aField rangeOfString:@"confirm_endday"].length>0)
         {
             ;
         }

    
    
   
    while ([scanner isAtEnd] == NO)
    {
        [scanner scanUpToString:@",\"" intoString:NULL];
        [scanner scanString:@",\"" intoString:NULL];
        [scanner scanUpToString:@"\"," intoString:&tmp];
        //if ([scanner isAtEnd] == NO)
           if ([tmp length]>0)
            [target addObject:tmp];
        [scanner scanString:@"\"" intoString:NULL];
    }
    
    for (int i=0; i<[target count]; i++) {
        
        NSString* str=target[i];
        aField=[aField stringByReplacingOccurrencesOfString:str withString:[NSString stringWithFormat:@"$$##%d$$##",i]];
    }
    
    
    NSArray* vals=[aField componentsSeparatedByString:@","];
    
    
    if (1>=[vals count])
        return;
    
    
    
    if (!_keysOrder)
        _keysOrder=[NSMutableArray array];
    
    
     NSString* keyValue=[vals[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (![_keysOrder containsObject:keyValue])
    {
        
        [_keysOrder addObject:keyValue ];
    }
    
    
    
    for (int i=0; i<[vals count]; i++) {
        
        NSNumber* colIdx = [NSNumber numberWithInteger:i];
        NSString* aKey=_columnMap[colIdx];
        
      
        
        if (aKey)
        {
            aKey=[aKey stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            
            NSMutableDictionary* langDict= _languages[aKey];
            
            NSString* val=vals[colIdx.integerValue];
            
            if ([val containsString:@"$$##"])
            {
                val=[val stringByReplacingOccurrencesOfString:@"\"$$##" withString:@""];
                val=[val stringByReplacingOccurrencesOfString:@"$$##\"" withString:@""];
                val=[val stringByReplacingOccurrencesOfString:@"$$##" withString:@""];
                int idx=[val intValue];
                val=[val stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%d",idx] withString:target[idx]];
                
                
            }
            
            val=[val stringByReplacingOccurrencesOfString:@"\\\"\"" withString:@"\\\""];
            val=[val stringByReplacingOccurrencesOfString:@" " withString:@" "];
            val=[val stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            val=[val stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                       
            langDict[keyValue]=val;
            
        }
        
        
    }
    
}



@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
       
        NSArray *arguments = [[NSProcessInfo processInfo] arguments];

        
        if ([arguments count]==2)
        {
            TransMaker* maker=[[TransMaker alloc] init];
            [maker makeTrans:arguments[1]];
        }
    
    }
    return 0;
}
