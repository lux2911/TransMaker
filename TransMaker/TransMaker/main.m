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
    NSString* _wrongCharacters;
}


-(void)makeTrans:(NSString*)fileName
{
    BRLineReader* reader=[[BRLineReader alloc] initWithFile:fileName encoding:NSUTF8StringEncoding];
    
    NSString* field=nil;
    
    while ((field=[reader readLine]))
    {
        if ([field length]==0)
            continue;
        
        
       
        
        if (!_languages)
            [self initializeLanguages:field];
        else
            [self addField:field];
        
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
        
        [str writeToFile:[NSString stringWithFormat:@"%@.strings",aKey]  atomically:NO encoding:NSUTF8StringEncoding error:&err];
        
        
    }

}


- (void) initializeLanguages:(NSString*)aField
{
    
    _languages=[NSMutableDictionary dictionary];
    _columnMap=[NSMutableDictionary dictionary];
    
    _wrongCharacters=[[NSString alloc] initWithFormat:@"%c%c",0xC2,0xA0];
    
    NSString* file= [[NSBundle mainBundle] pathForResource:@"Languages" ofType:@"plist"];
    
      
    NSDictionary* dict=[NSDictionary dictionaryWithContentsOfFile:file];
    
    NSArray* langs=[aField componentsSeparatedByString:@","];
    
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
    
  
    
    while ([scanner isAtEnd] == NO)
    {
        [scanner scanUpToString:@",\"" intoString:NULL];
        [scanner scanString:@",\"" intoString:NULL];
        [scanner scanUpToString:@"\"," intoString:&tmp];
        if ([scanner isAtEnd] == NO)
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
    
    if (![_keysOrder containsObject:vals[0]])
        [_keysOrder addObject:vals[0]];
    
    for (int i=0; i<[vals count]; i++) {
        
        NSNumber* colIdx = [NSNumber numberWithInteger:i];
        NSString* aKey=_columnMap[colIdx];
        
        
        
        if (aKey)
        {
            NSMutableDictionary* langDict= _languages[aKey];
            
            NSString* val=vals[colIdx.integerValue];
            
            if ([val containsString:@"$$##"])
            {
                val=[val stringByReplacingOccurrencesOfString:@"\"$$##" withString:@""];
                val=[val stringByReplacingOccurrencesOfString:@"$$##\"" withString:@""];
                int idx=[val intValue];
                val=[val stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%d",idx] withString:target[idx]];
                
                
            }
            
             val=[val stringByReplacingOccurrencesOfString:@"\\\"\"" withString:@"\\\""];
             val=[val stringByReplacingOccurrencesOfString:_wrongCharacters withString:@" "];
            
            
            
            langDict[vals[0]]=val;
            
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
