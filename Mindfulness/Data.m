//
//  Data.m
//  Mindfulness
//
//  Created by Shashank Bharadwaj on 4/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#define NSStringFromBOOL(aBOOL)    aBOOL? @"YES" : @"NO"
#import "Data.h"

@implementation Data


@synthesize appData;
@synthesize startTime;
@synthesize timer, initialTrialTime, trialCount, sessionCount, yesIncrement, noDecrement, sessionTime, minTrialTime, numberOfYesBeforeIncreasingMedTime, progress, numberOfSessionInASet, numberOfYes;
@synthesize subjectID,studyID;


- (NSDictionary*) getPlistData: (NSString*)plist {
    
    // get paths from root direcory
    NSArray *paths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
    // get documents path
    NSString *documentsPath = [paths objectAtIndex:0];
    // get the path to our Data/plist file
    NSString *plistPath = [documentsPath stringByAppendingPathComponent:[plist stringByAppendingString:@".plist"]];
    
    // check to see if Data.plist exists in documents
    if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath])
    {
        if ([plist isEqualToString:@"Data"]) {
            // if not in documents, get property list from main bundle
            plistPath = [[NSBundle mainBundle] pathForResource:plist ofType:@"plist"];
        } else {
            // if not in documents, create new NSMutableDictionary
            return nil;
        }
    }
    
    // read property list into memory as an NSData object
    NSData *dataPlist = [[NSFileManager defaultManager] contentsAtPath:plistPath];
    NSString *errorDesc = nil;
    NSPropertyListFormat format;
    // convert static property list into dictionary object
    return (NSDictionary *)[NSPropertyListSerialization propertyListFromData:dataPlist mutabilityOption:NSPropertyListMutableContainersAndLeaves format:&format errorDescription:&errorDesc];
}

-(NSArray*)getGraphDurationData{
    NSMutableArray *returnArray = [[NSMutableArray alloc] init];
    
    if ([[trials objectForKey:@"data"] count] > 1) {
        for (int i  = 1; i < [[trials objectForKey:@"data"] count]; i++) {
            [returnArray addObject:[[[trials objectForKey:@"data"] objectAtIndex:i] objectForKey:@"duration"]];
        }
    }
    
    return returnArray;
}

- (void) saveDataWithTrialTime: (double)time response:(BOOL)response andLength: (int) length
{
    // Write Data.plist
    // get paths from root direcory
    NSArray *paths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
    // get documents path
    NSString *documentsPath = [paths objectAtIndex:0];
    // get the path to our Data/plist file
    NSString *dataPath = [documentsPath stringByAppendingPathComponent:@"Data.plist"];
    
    appData = [NSDictionary dictionaryWithObjects: [NSArray arrayWithObjects: [NSNumber numberWithInt: timer], [NSNumber numberWithInt: trialCount], [NSNumber numberWithInt: yesIncrement], [NSNumber numberWithInt: noDecrement],[NSNumber numberWithInt: sessionTime], [NSNumber numberWithInt: minTrialTime], subjectID,studyID,[NSNumber numberWithInt:numberOfSessionInASet], nil] forKeys:[NSArray arrayWithObjects: @"timer", @"trials", @"yesIncrement", @"noDecrement", @"sessionTime", @"minTrialTime", @"subjectID",@"studyID",@"numberOfSessionInASet", nil] ];
    [appData writeToFile:dataPath atomically:YES];
    
    
    // Write X.plist where X is the user's name
    //NSMutableArray *trials;
    NSDictionary *temp = [self getPlistData:subjectID];
    if (temp==nil) {
        //trials = [NSMutableDictionary dictionaryWithObjectsAndKeys:subjectID,@"subjectID",studyID,@"studyID" nil];
        trials = [[NSMutableDictionary alloc] init];
        [trials setObject:subjectID forKey:@"subjectID"];
        [trials setObject:studyID forKey:@"studyID"];
        NSMutableArray *dataArray = [[NSMutableArray alloc] init];
        [trials setObject:dataArray forKey:@"data"];
        //[trials addObject:subjectID forKey:@"name"];//addObject:[NSDictionary dictionaryWithObject:subjectID forKey:@"name"]];
    } else {
        trials = [temp mutableCopy];
    }
    //Convert absolute time to NSDate
    NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:time];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];/*
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setLocale:usLocale];
     */
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HHmmssZZ"];
    NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setLocale:usLocale];
    
    NSDictionary *trial = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[dateFormatter stringFromDate:date],[NSNumber numberWithInt:sessionCount],[NSNumber numberWithInt:trialCount],[NSNumber numberWithInt:response], [NSNumber numberWithInt:length],nil] forKeys:[NSArray arrayWithObjects:@"date",@"sessionCount",@"trialCount",@"response",@"duration", nil]];
        
    //[trials addObject:trial];
    [[trials objectForKey:@"data"] addObject:trial];
    
    //Save on device
    NSString *trialsPath = [documentsPath stringByAppendingPathComponent:[subjectID stringByAppendingString:@".plist"]];
    [trials writeToFile:trialsPath atomically:YES];
    
    //Upload to Dropbox
    NSString *destDir = @"/";
    //[[self restClient] uploadFile:[subjectID stringByAppendingString:@".plist"] toPath:destDir fromPath:trialsPath];
    //[self restClient] load
    
    //Upload to Gazz Lab srevers
    if (cloud == Nil) {
        cloud = [[GAZZCloud alloc] init];
    }
    [cloud setStudyID:[trials objectForKey:@"studyID"] ];
    [cloud setSubjectID:[trials objectForKey:@"subjectID"]];
    [cloud postJSONOf:[trials objectForKey:@"data"] toAdress:@"https://pulvinar.cin.ucsf.edu"];
}

-(NSString*)startDate{
    return [[[trials objectForKey:@"data"] objectAtIndex:0] objectForKey:@"date"];
}
-(NSString*)endDate{
    return [ [[trials objectForKey:@"data"] objectAtIndex:[trials count]-1] objectForKey:@"date"];
}

- (id) init {
    self = [super init];
    if (self != nil) {
        appData = [self getPlistData:@"Data"];
        startTime = CFAbsoluteTimeGetCurrent();
        timer = [[appData objectForKey:@"timer"] intValue];
        if ([appData objectForKey:@"trials"] != nil) {
            trialCount = [[appData objectForKey:@"trials"] intValue];
        } else {
            trialCount = 0;
        }
        yesIncrement = [[appData objectForKey:@"yesIncrement"] intValue];
        noDecrement = [[appData objectForKey:@"noDecrement"] intValue];
        
        if (![[appData objectForKey:@"subjectID"] isKindOfClass:[NSNull class]]) {
            subjectID = [appData objectForKey:@"subjectID"];
        } else {
            subjectID = @"";
        }
        if (![[appData objectForKey:@"studyID"] isKindOfClass:[NSNull class]]) {
            studyID = [appData objectForKey:@"studyID"];
        } else {
            studyID = @"";
        }
        sessionTime = [[appData objectForKey:@"sessionTime"] intValue];
        minTrialTime = [[appData objectForKey:@"minTrialTime"] intValue];
        numberOfSessionInASet = [[appData objectForKey:@"numberOfSessionInASet"] intValue];
    }
    return self;
}

@end
