#import "IAServer.h"

@class RKObjectLoader;
@class RKObjectManager;
@class RKObjectMappingProvider;
@class RKObjectMappingResult;
@class RKObjectRouter;
@class RKObjectSerializer;
@class SDServiceDiscovery;

@class IAAction;
@class IACapability;
@class IADevice;
@class IARoute;
@class IARequest;
@class IAResponse;

extern NSString * IADeviceFound;
extern NSString * IADeviceLost;

typedef void (^IADeviceFoundHandler)(IADevice * device, BOOL ownDevice);
typedef void (^IADeviceLostHandler)(IADevice * device);

@interface IAIntAirAct : NSObject

/** A Set of all the capabilities this device has. */
@property (nonatomic, strong) NSMutableSet * supportedRoutes;

/** A list of all the currently available devices. */
@property (readonly) NSSet * devices;

/** `YES` if IntAirAct is running, `NO` otherwise. */
@property (readonly) BOOL isRunning;

/** IntAirAct's RKObjectMappingProvider. This is used to add and retrieve object mappings.
 
 A usage example:
 
    RKObjectMapping * mapping = [RKObjectMapping mappingForClass:[Contact class]];
    [mapping mapAttributesFromSet:@"firstName", @"lastName", nil];
    [intairact.objectMappingProvider setMapping:mapping forKeyPath:@"contacts"];
 */
@property (nonatomic, strong, readonly) RKObjectMappingProvider * objectMappingProvider;

/** Returns the current device if it has been found yet, `nil` otherwise. */
@property (nonatomic, strong, readonly) IADevice * ownDevice;

/** The port on which to listen on. Default is 0. This means the system will find a free port. */
@property (nonatomic) NSInteger port;

/** IntAirAct's RKObjectRouter. This is used to setup default route mappings for objects.
 
 Use this to setup default routes for serializable Objects like this:
 
    [intairact.router routeClass:[Contact class] toResourcePath:@"/contacts/:identifier"];
 
 This automatically maps all GET, POST, PUT and DELETE calls to /contacts/:identifier.
 */
@property (nonatomic, strong, readonly) RKObjectRouter * router;

/** Standard Constructor.
 
 Instantiates IntAirAct, but does not start it.
 */
-(id)init;

-(id)initWithServer:(NSObject<IAServer> *)server andServiceDiscovery:(SDServiceDiscovery*)serviceDiscovery;

/** Standard Deconstructor.
 
 Stops the server, and clients, and releases any resources connected with this instance.
 */
-(void)dealloc;

/** Attempts to start IntAirAct.
 
 A usage example:
 
    NSError *err = nil;
    if (![intairact start:&er]]) {
        NSLog(@"Error starting IntAirAct: %@", err);
    }
 
 @param errPtr An optional NSError instance.
 @return Returns `YES` if successful, `NO` on failure and sets the errPtr (if given).
 
 */
-(BOOL)start:(NSError **)errPtr;

/** Stops IntAirAct. */
-(void)stop;

/** Add an action to the server.
 
 @param action the name of the action
 @param selector the selector that is executed when the action is called
 @param target the target on which to execute the selector
 */
-(void)addAction:(NSString *)action withSelector:(SEL)selector andTarget:(id)target;

/** Adds a de- and a serialization mapping to the objectMappingProvider for the specified class.
 
 A usage example:
 
    [intairact addMappingForClass:[Contact class] withKeypath:@"contacts" withAttributes:@"firstName", @"lastName", nil];
 
 @param className The class to be de-/serialized.
 @param keyPath The keypath to use for the mapping. This has to be unique to the application.
 @param attributeKeyPath An attribute to map.
 @param ... A comma separated list of attributes to map.
 */
-(void)addMappingForClass:(Class)className withKeypath:(NSString *)keyPath withAttributes:(NSString *)attributeKeyPath, ...  NS_REQUIRES_NIL_TERMINATION;

/** Execute an action on a specific device.
 
 If you specify a handler block the return parameter will be set on the action.parameters array.
 
 @param action the action to execute.
 @param device the device on which to execute the action.
 @param handler a block for handling errors or return parameters.
 */
-(void)callAction:(IAAction *)action onDevice:(IADevice *)device withHandler:(void (^)(IAAction * action, NSError * error))handler;

/**
 @param data the data to deserialize
 */
-(RKObjectMappingResult *)deserializeObject:(id)data;

/** Get an array of devices with a certain capability.
 
 @param capability the capability which the devices should have.
 
 @return an array of devices with the specified capability.
 */
-(NSArray *)devicesWithCapability:(IACapability *)capability;

/** Return an RKObjectManager for the specified device.
 
 @param device the device for which we want an RKObjectManager.
 
 @return an RKObjectManager for the specified device
 */
-(RKObjectManager *)objectManagerForDevice:(IADevice *)device;

/** Returns a resourcePath for a specified resource.
 
 @param resource the resource to get the path for
 @param manager the object manager 
 
 @return the resourcePath for the specified resource
 */
-(NSString *)resourcePathFor:(NSObject *)resource forObjectManager:(RKObjectManager *)manager;

/** Return an RKObjectSerializer for the specified object.
 
 @param object the object for which to get an RKObjectSerializer for
 
 @return An RKObjectSerializer for the specified object.
 */
-(RKObjectSerializer *)serializerForObject:(id)object;

-(BOOL)route:(IARoute*)route withHandler:(IARequestHandler)block;

-(void)removeObserver:(id)observer;
-(id)addHandlerForDeviceFound:(IADeviceFoundHandler)handler;
-(id)addHandlerForDeviceLost:(IADeviceLostHandler)handler;

@end
