#import "IARoutingHTTPServerAdapter.h"

#import <RoutingHTTPServer/RoutingHTTPServer.h>

#import "IAIntAirAct.h"
#import "IARoute.h"
#import "IARequest.h"
#import "IARequest+RouteRequest.h"
#import "RouteResponse+IAResponse.h"
#import "IAResponse.h"

@interface IARoutingHTTPServerAdapter ()

@property (strong, nonatomic) RoutingHTTPServer* routingHTTPServer;

@end

@implementation IARoutingHTTPServerAdapter

@synthesize port = _port;

- (id)init
{
    return [self initWithRoutingHTTPServer:[RoutingHTTPServer new]];
}

-(id)initWithRoutingHTTPServer:(RoutingHTTPServer *)routingHTTPServer
{
    self = [super init];
    if (self) {
        _port = 0;
        
        _routingHTTPServer = routingHTTPServer;
    }
    return self;
}

-(BOOL)route:(IARoute *)route withHandler:(IARequestHandler)handler
{
    // check if route has already been added
    // do more fancy checking, like * case before /specific case
    // add route to array
    // replace {} with :
    NSString * path = [route.resource stringByReplacingOccurrencesOfString:@"}" withString:@""];
    path = [path stringByReplacingOccurrencesOfString:@"{" withString:@":"];
    [self.routingHTTPServer handleMethod:route.action withPath:path block:^(RouteRequest * rReq, RouteResponse * rRes) {
        IADevice * origin = nil;
        
        if (rReq.headers[@"X-IA-Origin"]) {
            
            /*This is super dumb*/
            NSString *originName = [rReq.headers[@"X-IA-Origin"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]; 
            origin = [self.intAirAct deviceWithName:originName];
        }
        IARequest * iaReq = [IARequest requestWithRouteRequest:rReq origin:origin route:route];
        IAResponse * iaRes = [IAResponse new];
        handler(iaReq, iaRes);
        [rRes copyValuesFromIAResponse:iaRes];
    }];
    return YES;
}

-(BOOL)start:(NSError *__autoreleasing *)errPtr
{
    return [self.routingHTTPServer start:errPtr];
}

-(void)stop
{
    [self.routingHTTPServer stop];
}

-(NSInteger)port
{
    int listeningPort = self.routingHTTPServer.listeningPort;
    if(listeningPort == 0) {
        return self.routingHTTPServer.port;
    } else {
        return listeningPort;
    }
}

-(void)setPort:(NSInteger)port
{
    self.routingHTTPServer.port = port;
}

@end
