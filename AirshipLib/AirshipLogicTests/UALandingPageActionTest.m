
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "UALandingPageAction.h"
#import "UAURLProtocol.h"
#import "UAHTTPConnection.h"
#import "UALandingPageOverlayController.h"
#import "UAAction+Internal.h"
#import "UAirship.h"
#import "UAConfig.h"
@interface UALandingPageActionTest : XCTestCase

@property(nonatomic, strong) id mockURLProtocol;
@property(nonatomic, strong) id mockLandingPageOverlayController;
@property(nonatomic, strong) id mockHTTPConnection;
@property(nonatomic, strong) id mockAirship;
@property(nonatomic, strong) id mockConfig;
@property(nonatomic, strong) UALandingPageAction *action;

@end

@implementation UALandingPageActionTest

- (void)setUp {
    [super setUp];
    self.action = [[UALandingPageAction alloc] init];
    self.mockURLProtocol = [OCMockObject niceMockForClass:[UAURLProtocol class]];
    self.mockLandingPageOverlayController = [OCMockObject niceMockForClass:[UALandingPageOverlayController class]];
    self.mockHTTPConnection = [OCMockObject niceMockForClass:[UAHTTPConnection class]];

    self.mockConfig = [OCMockObject niceMockForClass:[UAConfig class]];
    self.mockAirship = [OCMockObject niceMockForClass:[UAirship class]];
    [[[self.mockAirship stub] andReturn:self.mockAirship] shared];
    [[[self.mockAirship stub] andReturn:self.mockConfig] config];

}

- (void)tearDown {
    [self.mockLandingPageOverlayController stopMocking];
    [self.mockURLProtocol stopMocking];
    [self.mockHTTPConnection stopMocking];
    [self.mockAirship stopMocking];
    [self.mockConfig stopMocking];
    [super tearDown];
}

/**
 * Test accepts arguments
 */
- (void)testAcceptsArguments {
    [self verifyAcceptsArgumentsWithValue:@"foo.urbanairship.com" shouldAccept:true];
    [self verifyAcceptsArgumentsWithValue:@"https://foo.urbanairship.com" shouldAccept:true];
    [self verifyAcceptsArgumentsWithValue:@"http://foo.urbanairship.com" shouldAccept:true];
    [self verifyAcceptsArgumentsWithValue:@"file://foo.urbanairship.com" shouldAccept:true];
    [self verifyAcceptsArgumentsWithValue:[NSURL URLWithString:@"https://foo.urbanairship.com"] shouldAccept:true];

    // Verify url encoded arrays
    [self verifyAcceptsArgumentsWithValue:@[@"third", @"uuid"] shouldAccept:true];
    [self verifyAcceptsArgumentsWithValue:@[@"uuid"] shouldAccept:true];

}

/**
 * Test accepts arguments rejects argument values that are unable to parsed
 * as a URL
 */
- (void)testAcceptsArgumentsNo {
    [self verifyAcceptsArgumentsWithValue:nil shouldAccept:false];
    [self verifyAcceptsArgumentsWithValue:[[NSObject alloc] init] shouldAccept:false];
    [self verifyAcceptsArgumentsWithValue:@[] shouldAccept:false];

    // Verify it doesnt accept arrays that do not contain 2 String elements
    [self verifyAcceptsArgumentsWithValue:@[@"one", @2] shouldAccept:false];
    [self verifyAcceptsArgumentsWithValue:@[@"one", @"two", @"three"] shouldAccept:false];
}

/**
 * Test perform in UASituationBackgroundPush
 */
- (void)testPerformInForeground {
    // Verify https is added to schemeless urls
    [self verifyPerformInForegroundWithValue:@"foo.urbanairship.com" expectedUrl:@"https://foo.urbanairship.com"];

    // Verify common scheme types
    [self verifyPerformInForegroundWithValue:@"http://foo.urbanairship.com" expectedUrl:@"http://foo.urbanairship.com"];
    [self verifyPerformInForegroundWithValue:@"https://foo.urbanairship.com" expectedUrl:@"https://foo.urbanairship.com"];
    [self verifyPerformInForegroundWithValue:@"file://foo.urbanairship.com" expectedUrl:@"file://foo.urbanairship.com"];


    // Verify arrays with shortened url data - https://<third-level doman>.urbanairship.com/binary/public/<app key>/<UUID>
    [[[self.mockConfig stub] andReturn:@"app-key"] appKey];
    [self verifyPerformInForegroundWithValue:@[@"third", @"uuid"] expectedUrl:@"https://third.urbanairship.com/binary/public/app-key/uuid"];
    [self verifyPerformInForegroundWithValue:@[@"uuid"] expectedUrl:@"https://dl-origin.urbanairship.com/binary/public/app-key/uuid"];
}

/**
 * Test perform in foreground situations
 */
- (void)testPerformInBackground {
    // Verify https is added to schemeless urls
    [self verifyPerformInBackgroundWithValue:@"foo.urbanairship.com" expectedUrl:@"https://foo.urbanairship.com" successful:YES];

    // Verify common scheme types
    [self verifyPerformInBackgroundWithValue:@"http://foo.urbanairship.com" expectedUrl:@"http://foo.urbanairship.com" successful:YES];
    [self verifyPerformInBackgroundWithValue:@"https://foo.urbanairship.com" expectedUrl:@"https://foo.urbanairship.com" successful:YES];
    [self verifyPerformInBackgroundWithValue:@"file://foo.urbanairship.com" expectedUrl:@"file://foo.urbanairship.com" successful:YES];

    // Verify arrays with shortened url data - https://<third-level doman>.urbanairship.com/binary/public/<app key>/<UUID>
    [[[self.mockConfig stub] andReturn:@"app-key"] appKey];
    [self verifyPerformInBackgroundWithValue:@[@"third", @"uuid"] expectedUrl:@"https://third.urbanairship.com/binary/public/app-key/uuid" successful:YES];
    [self verifyPerformInBackgroundWithValue:@[@"uuid"] expectedUrl:@"https://dl-origin.urbanairship.com/binary/public/app-key/uuid" successful:YES];
}

/**
 * Test perform in background situation when caching fails
 */
- (void)testPerformInBackgroundFail {
    // Verify https is added to schemeless urls
    [self verifyPerformInBackgroundWithValue:@"foo.urbanairship.com" expectedUrl:@"https://foo.urbanairship.com" successful:NO];

    // Verify common scheme types
    [self verifyPerformInBackgroundWithValue:@"http://foo.urbanairship.com" expectedUrl:@"http://foo.urbanairship.com" successful:NO];
    [self verifyPerformInBackgroundWithValue:@"https://foo.urbanairship.com" expectedUrl:@"https://foo.urbanairship.com" successful:NO];
    [self verifyPerformInBackgroundWithValue:@"file://foo.urbanairship.com" expectedUrl:@"file://foo.urbanairship.com" successful:NO];

    // Verify arrays with shortened url data - https://<third-level doman>.urbanairship.com/binary/public/<app key>/<UUID>
    [[[self.mockConfig stub] andReturn:@"app-key"] appKey];
    [self verifyPerformInBackgroundWithValue:@[@"third", @"uuid"] expectedUrl:@"https://third.urbanairship.com/binary/public/app-key/uuid" successful:NO];
    [self verifyPerformInBackgroundWithValue:@[@"uuid"] expectedUrl:@"https://dl-origin.urbanairship.com/binary/public/app-key/uuid" successful:NO];
}


/**
 * Helper method to verify perfrom in foreground situations
 */
- (void)verifyPerformInForegroundWithValue:(id)value expectedUrl:(NSString *)expectedUrl {
    NSArray *foregroundSitutions = @[[NSNumber numberWithInteger:UASituationWebViewInvocation],
                                     [NSNumber numberWithInteger:UASituationForegroundPush],
                                     [NSNumber numberWithInteger:UASituationLaunchedFromPush],
                                     [NSNumber numberWithInteger:UASituationManualInvocation]];

    for (NSNumber *situationNumber in foregroundSitutions) {
        [[self.mockLandingPageOverlayController expect] closeAll:NO];

        [[self.mockLandingPageOverlayController expect] showURL:[OCMArg checkWithBlock:^(id obj){
            return (BOOL)([obj isKindOfClass:[NSURL class]] && [((NSURL *)obj).absoluteString isEqualToString:expectedUrl]);
        }]];

        UAActionArguments *args = [UAActionArguments argumentsWithValue:value withSituation:[situationNumber integerValue]];
        [self verifyPerformWithArgs:args withExpectedUrl:expectedUrl withExpectedFetchResult:UAActionFetchResultNewData];
    }
}

/**
 * Helper method to verify perform in background situations
 */
- (void)verifyPerformInBackgroundWithValue:(id)value expectedUrl:(NSString *)expectedUrl successful:(BOOL)successful  {
    UAActionArguments *args = [UAActionArguments argumentsWithValue:value withSituation:UASituationBackgroundPush];

    __block UAHTTPConnectionSuccessBlock success;
    __block UAHTTPConnectionFailureBlock failure;
    __block UAHTTPRequest *request;

    [[[self.mockHTTPConnection expect] andReturn:self.mockHTTPConnection]
     connectionWithRequest:[OCMArg checkWithBlock:^(id obj){
        request = obj;
        return YES;
    }] successBlock:[OCMArg checkWithBlock:^(id obj){
        success = obj;
        return YES;
    }] failureBlock:[OCMArg checkWithBlock:^(id obj){
        failure = obj;
        return YES;
    }]];

    [(UAHTTPConnection *)[[self.mockHTTPConnection expect] andDo:^(NSInvocation *inv){
        if (successful) {
            NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:request.url
                                                                      statusCode:200
                                                                     HTTPVersion:nil
                                                                    headerFields:nil];
            [request setValue:response forKey:@"response"];
            success(request);
        } else {
            failure(request);
        }
    }] start];

    UAActionFetchResult expectedResult = successful? UAActionFetchResultNewData : UAActionFetchResultFailed;

    [self verifyPerformWithArgs:args withExpectedUrl:expectedUrl withExpectedFetchResult:expectedResult];
}

/**
 * Helper method to verify perfrom
 */
- (void)verifyPerformWithArgs:(UAActionArguments *)args withExpectedUrl:(NSString *)expectedUrl withExpectedFetchResult:(UAActionFetchResult)fetchResult {

    __block BOOL finished = NO;

    [[self.mockURLProtocol expect] addCachableURL:[OCMArg checkWithBlock:^(id obj){
        return (BOOL)([obj isKindOfClass:[NSURL class]] && [((NSURL *)obj).absoluteString isEqualToString:expectedUrl]);
    }]];

    [self.action performWithArguments:args withCompletionHandler:^(UAActionResult *result){
        finished = YES;
        XCTAssertEqual(result.fetchResult, fetchResult,
                       @"fetch result %ud should match expect result %ud", result.fetchResult, fetchResult);
    }];

    [self.mockURLProtocol verify];
    [self.mockLandingPageOverlayController verify];
    [self.mockHTTPConnection verify];

    XCTAssertTrue(finished, @"action should have completed");
}

/**
 * Helper method to verify accepts arguments
 */
- (void)verifyAcceptsArgumentsWithValue:(id)value shouldAccept:(BOOL)shouldAccept {
    NSArray *situations = @[[NSNumber numberWithInteger:UASituationWebViewInvocation],
                                     [NSNumber numberWithInteger:UASituationForegroundPush],
                                     [NSNumber numberWithInteger:UASituationBackgroundPush],
                                     [NSNumber numberWithInteger:UASituationLaunchedFromPush],
                                     [NSNumber numberWithInteger:UASituationManualInvocation]];

    for (NSNumber *situationNumber in situations) {
        UAActionArguments *args = [UAActionArguments argumentsWithValue:value
                                                          withSituation:[situationNumber integerValue]];

        BOOL accepts = [self.action acceptsArguments:args];
        if (shouldAccept) {
            XCTAssertTrue(accepts, @"landing page action should accept value %@ in situation %@", value, situationNumber);
        } else {
            XCTAssertFalse(accepts, @"landing page action should not accept value %@ in situation %@", value, situationNumber);
        }
    }
}

@end
