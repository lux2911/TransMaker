//
//  BRLineReader.h
//  CHCSVParser
//
//  Created by Tomislav Luketic on 7/6/16.
//
//

#import <Foundation/Foundation.h>

@interface BRLineReader : NSObject

@property (readonly, nonatomic) NSData *data;
@property (readonly, nonatomic) NSUInteger linesRead;
@property (strong, nonatomic) NSCharacterSet *lineTrimCharacters;
@property (readonly, nonatomic) NSStringEncoding stringEncoding;

- (instancetype)initWithFile:(NSString *)filePath encoding:(NSStringEncoding)encoding;
- (instancetype)initWithData:(NSData *)data encoding:(NSStringEncoding)encoding;
- (NSString *)readLine;
- (NSString *)readTrimmedLine;
- (void)setLineSearchPosition:(NSUInteger)position;

@end