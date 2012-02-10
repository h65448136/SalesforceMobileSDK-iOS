/*
 Copyright (c) 2011, salesforce.com, inc. All rights reserved.
 Author: Todd Stellanova
 
 Redistribution and use of this software in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of
 conditions and the following disclaimer in the documentation and/or other materials provided
 with the distribution.
 * Neither the name of salesforce.com, inc. nor the names of its contributors may be used to
 endorse or promote products derived from this software without specific prior written
 permission of salesforce.com, inc.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "SFSoupCursor.h"

#import "SFSmartStore.h"
#import "SFSoupQuerySpec.h"

@interface SFSoupCursor ()

@property (nonatomic, readwrite, strong) NSString *cursorId;
@property (nonatomic, readwrite, strong) NSString *soupName;

@property (nonatomic, readwrite, strong) SFSoupQuerySpec *querySpec;
@property (nonatomic, readwrite, strong) NSArray *currentPageOrderedEntries;
@property (nonatomic, readwrite, strong) NSNumber *pageSize;
@property (nonatomic, readwrite, strong) NSNumber *totalPages;


@end

@implementation SFSoupCursor

@synthesize soupName = _soupName;
@synthesize cursorId = _cursorId;
@synthesize querySpec = _querySpec;

@synthesize currentPageOrderedEntries = _currentPageOrderedEntries;
@synthesize currentPageIndex = _currentPageIndex;
@synthesize pageSize = _pageSize;
@synthesize totalPages = _totalPages;




- (id)initWithSoupName:(NSString*)soupName 
                 store:(SFSmartStore*)store 
             querySpec:(SFSoupQuerySpec*)querySpec  
          totalEntries:(NSUInteger)totalEntries
{
    self = [super init];
    
    if (nil != self) {
        _store = [store retain];
        [self setCursorId:[NSString stringWithFormat:@"0x%x",[self hash]]];
        
        self.soupName = soupName;
        self.querySpec = querySpec;
        
        NSInteger myPageSize = 10;
        myPageSize =  [querySpec pageSize];

        self.pageSize = [NSNumber numberWithInteger:myPageSize]; 
        
        NSUInteger totalPages = (totalEntries / querySpec.pageSize) + 1;     
        if (0 == totalEntries) 
            totalPages = 0;
        
        self.totalPages = [NSNumber numberWithInt:totalPages]; 
                
        [self setCurrentPageIndex:[NSNumber numberWithInteger:0]];
    }
    return self;
}

                            
- (void)dealloc {
    [self close];
    [super dealloc];
}


- (void)close {
    NSLog(@"closing cursor id: %@",self.cursorId);

    [_store release]; _store = nil;
    self.soupName = nil;
    self.cursorId = nil;
    self.querySpec = nil;
    
    self.currentPageOrderedEntries = nil;
    self.currentPageIndex = nil;
    self.pageSize = nil;
    self.totalPages = nil;
}

#pragma mark - Properties

- (void)setCurrentPageIndex:(NSNumber *)pageIdx {
    //TODO check bounds?
    if (![pageIdx isEqual:_currentPageIndex]) {
        _currentPageIndex = [pageIdx retain];
        
        if (nil != _currentPageIndex) {
            NSUInteger pageIdx = [_currentPageIndex integerValue];
            NSArray *newEntries = [_store querySoup:self.soupName withQuerySpec:self.querySpec pageIndex:pageIdx];
            self.currentPageOrderedEntries = newEntries;
        } 
    }
}

#pragma mark - Converting to JSON

- (NSDictionary*)asDictionary
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    [result setObject:self.soupName forKey:@"soupName"];
    [result setObject:self.cursorId forKey:@"cursorId"];
    if (nil != self.querySpec) {
        [result setObject:[self.querySpec asDictionary] forKey:@"querySpec"];
    }
    //note that we only encode the current page worth of entries
    [result setObject:self.currentPageOrderedEntries forKey:@"currentPageOrderedEntries"];
    [result setObject:self.currentPageIndex forKey:@"currentPageIndex"];
    [result setObject:self.pageSize forKey:@"pageSize"];
    [result setObject:self.totalPages forKey:@"totalPages"];
    
    return result;
}


- (NSString*)description {
    return [NSString stringWithFormat:@"<SFSoupCursor: 0x%x> {\n cursorId: %@ \n soup: %@ \n totalPages:%@ \n currentPage:%@ \n currentPageOrderedEntries: [%d] \n}",
                        self,self.cursorId, self.soupName,self.totalPages,self.currentPageIndex,[self.currentPageOrderedEntries count]];
}

@end
