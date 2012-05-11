#import "IntAirActTests.h"

#import <CocoaLumberjack/DDLog.h>
#import <CocoaLumberjack/DDTTYLogger.h>
#import <IntAirAct/IntAirAct.h>
#import <RestKit/RestKit.h>
#import <RestKit+Blocks/RestKit+Blocks.h>

#import "IANumber.h"

// Log levels : off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@interface IntAirActTests()

@property (nonatomic, strong) IAIntAirAct * intAirAct;

@end

@implementation IntAirActTests

@synthesize intAirAct;

-(void)logging
{
    static dispatch_once_t once;
    dispatch_once(&once, ^ {
        [DDLog addLogger:[DDTTYLogger sharedInstance]];
    });
}

-(void)setUp
{
    [super setUp];
    
    // Set-up code here.
    [self logging];

    // Given
    self.intAirAct = [IAIntAirAct new];
}

-(void)tearDown
{
    // Tear-down code here.
    if(self.intAirAct.isRunning) {
        [self.intAirAct stop];
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:5]];
    }
    self.intAirAct = nil;
    
    [super tearDown];
}

-(void)testOwnDeviceShouldBeNil
{
    // Then
    STAssertNil(self.intAirAct.ownDevice, @"Own Device should be nil");
}

-(void)testRouterShouldNotBeNil
{
    // Then
    STAssertNotNil(self.intAirAct.router, @"Router should not be nil");
}

-(void)testObjectMappingProviderShouldNotBeNil
{   
    // Then
    STAssertNotNil(self.intAirAct.objectMappingProvider, @"ObjectMappingProvider should not be nil");
}

-(void)testDefaultPortShouldBeZero
{   
    // Then
    STAssertEquals((UInt16) 0, self.intAirAct.port, @"Default port should be zero but was %i", self.intAirAct.port);
}

-(void)testDefaultClientShouldBeYES
{   
    // Then
    STAssertTrue(self.intAirAct.client, @"Client should be YES");
}

-(void)testDefaultServerShouldBeYES
{
    // Then
    STAssertTrue(self.intAirAct.server, @"Server should be YES");
}

-(void)testDefaultMimeTypeShouldBeJSON
{
    // Then
    STAssertEqualObjects(@"application/json", self.intAirAct.defaultMimeType, @"defaultMimeType should be JSON");
}

-(void)testDefaultCapabilitiesShouldBeEmpty
{
    // Then
    STAssertNotNil(self.intAirAct.capabilities, @"Capabilities should not be nil");
    STAssertTrue([self.intAirAct.capabilities count] == 0, @"Capabilities should be empty");
}

-(void)testDefaultDevicesShouldBeEmpty
{
    // Then
    STAssertNotNil(self.intAirAct.devices, @"Devices should not be nil");
    STAssertTrue([self.intAirAct.devices count] == 0, @"Devices should be empty");
}

-(void)testHTTPServerShouldNotBeNil
{
    // Then
    STAssertNotNil(self.intAirAct.httpServer, @"httpServer should not be nil");
}

-(void)testIsRunningShouldBeNO
{
    // Then
    STAssertFalse(self.intAirAct.isRunning, @"isRunning should be NO");
}

-(void)testTXTRecordDictionaryShouldNotBeNil
{
    // Then
    STAssertNotNil(self.intAirAct.txtRecordDictionary, @"txtRecordDictionary should not be nil");
}

-(void)testIntAirActShouldStart
{
    // Then
    NSError * error = nil;
    if (![self.intAirAct start:&error]) {
        STFail(@"HTTP server failed to start: %@", error);
    }
    
    [self.intAirAct stop];
}

-(void)testIntAirActShouldNotStart
{
    // And
    self.intAirAct.port = 80;

    // Then
    NSError * error = nil;
    if ([self.intAirAct start:&error]) {
        STFail(@"Server should fail to start");
    }
}

-(void)testIntAirActShouldFindOwnDeviceInFiveSeconds
{
    // Then
    NSError * error = nil;
    if (![self.intAirAct start:&error]) {
        STFail(@"HTTP server failed to start: %@", error);
        return;
    }
    NSDate * start = [NSDate new];
    while(self.intAirAct.ownDevice == nil) {
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        if([start timeIntervalSinceNow] < -5) {
            STFail(@"IntAirAct should find own Device in five seconds");
            return;
        }
    }
    
    [self.intAirAct stop];
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:5]];
}

-(void)testOwnDeviceCapabilitesShouldBeEqualToResolved
{
    // And
    IACapability * cap = [IACapability new];
    cap.capability = @"capability string";
    [self.intAirAct.capabilities addObject:cap];
    
    // Then
    NSError * error = nil;
    if (![self.intAirAct start:&error]) {
        STFail(@"HTTP server failed to start: %@", error);
    } else {
        NSDate * start = [NSDate new];
        while(self.intAirAct.ownDevice == nil) {
            [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
            if([start timeIntervalSinceNow] < -5) {
                STFail(@"IntAirAct should find own Device in five seconds");
                return;
            }
        }
    }
    
    STAssertEqualObjects(self.intAirAct.capabilities, self.intAirAct.ownDevice.capabilities, @"ownDevice.capabilities and capabilities should be equal");
    
    [self.intAirAct stop];
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:5]];
}

-(void)testDefaultObjectMappings
{
    // Then
    STAssertNotNil([self.intAirAct.objectMappingProvider serializationMappingForClass:[IADevice class]], @"A serialization mapping should exist");
    STAssertNotNil([self.intAirAct.objectMappingProvider mappingForKeyPath:@"devices"], @"A deserialization mapping should exist");
    
    STAssertNotNil([self.intAirAct.objectMappingProvider serializationMappingForClass:[IAAction class]], @"A serialization mapping should exist");
    STAssertNotNil([self.intAirAct.objectMappingProvider mappingForKeyPath:@"actions"], @"A deserialization mapping should exist");
    
    STAssertNotNil([self.intAirAct.objectMappingProvider serializationMappingForClass:[IACapability class]], @"A serialization mapping should exist");
    STAssertNotNil([self.intAirAct.objectMappingProvider mappingForKeyPath:@"capabilities"], @"A deserialization mapping should exist");
}

-(void)testAddMappingForClass
{
    // And
    [self.intAirAct addMappingForClass:[IANumber class] withKeypath:@"numbers" withAttributes:@"number", nil];
 
    // Then
    STAssertNotNil([self.intAirAct.objectMappingProvider serializationMappingForClass:[IANumber class]], @"A serialization mapping should exist");
    STAssertNotNil([self.intAirAct.objectMappingProvider mappingForKeyPath:@"numbers"], @"A deserialization mapping should exist");
}

-(void)testObjectManagerForOwnDeviceShouldHaveLocalInterface
{
    // And
    NSError * error = nil;
    if (![self.intAirAct start:&error]) {
        STFail(@"HTTP server failed to start: %@", error);
    } else {
        NSDate * start = [NSDate new];
        while(self.intAirAct.ownDevice == nil) {
            [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
            if([start timeIntervalSinceNow] < -5) {
                STFail(@"IntAirAct should find own Device in five seconds");
                return;
            }
        }
    }
    
    // Then
    RKObjectManager * man = [self.intAirAct objectManagerForDevice:self.intAirAct.ownDevice];
    STAssertNotNil(man, @"Should return an RKObjectManager");
    STAssertTrue([[man.baseURL absoluteString] hasPrefix:@"http://127.0.0.1"], @"Should be a local interface");
    
    [self.intAirAct stop];
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:5]];
}

-(void)testIntAirActShouldFindOtherDeviceInFiveSeconds
{
    // And
    NSError * error = nil;
    IAIntAirAct * iAA = [IAIntAirAct new];
    if (![iAA start:&error]) {
        STFail(@"IntAirAct failed to start: %@", error);
    } else if (![self.intAirAct start:&error]) {
    // And
        STFail(@"IntAirAct failed to start: %@", error);
    } else {
        NSDate * start = [NSDate new];
        while(self.intAirAct.ownDevice == nil && iAA.ownDevice == nil) {
            [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
            if([start timeIntervalSinceNow] < -5) {
                STFail(@"IntAirAct should find own Device in five seconds");
                return;
            }
        }
        
        // Then
        start = [NSDate new];
        while([self.intAirAct.devices containsObject:iAA.ownDevice] && [iAA.devices containsObject:self.intAirAct.ownDevice]) {
            [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
            if([start timeIntervalSinceNow] < -5) {
                STFail(@"IntAirAct should find other Device in five seconds");
                return;
            }
        }
        
        // Then
        STAssertNotNil([self.intAirAct objectManagerForDevice:iAA.ownDevice], @"Should return an RKObjectManager");        
    }

    [iAA stop];
    [self.intAirAct stop];
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:5]];
}

-(void)testResourcePathFor
{
    // And
    NSError * error = nil;
    if (![self.intAirAct start:&error]) {
        STFail(@"HTTP server failed to start: %@", error);
    } else {
        NSDate * start = [NSDate new];
        while(self.intAirAct.ownDevice == nil) {
            [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
            if([start timeIntervalSinceNow] < -5) {
                STFail(@"IntAirAct should find own Device in five seconds");
                return;
            }
        }
    }
    
    // Then
    RKObjectManager * manager = [self.intAirAct objectManagerForDevice:self.intAirAct.ownDevice];
    STAssertNotNil(manager, @"Should return an RKObjectManager");
    
    IAAction * action = [IAAction new];
    action.action = @"actionName";
    
    NSString * expected = @"/action/actionName";
    
    STAssertEqualObjects(expected, [self.intAirAct resourcePathFor:action forObjectManager:manager], @"Resource path for action should be %@ but was %@", expected, [self.intAirAct resourcePathFor:action forObjectManager:manager]);
    
    [self.intAirAct stop];
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:5]];
}

-(void)testTimeout
{
    
    RKClient * client = [RKClient clientWithBaseURL:[NSURL URLWithString:@"http://127.0.0.1"]];
    client.timeoutInterval = 5;
    
    __block BOOL finished = NO;
    
    [client get:@"/" withCompletionHandler:^(RKResponse *response, NSError *error) {
        finished = YES;
    }];
    
    NSDate * start = [NSDate new];
    while(!finished) {
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        if([start timeIntervalSinceNow] < -5) {
            STFail(@"IntAirAct should call add in five seconds");
            return;
        }
    }
}

@end
