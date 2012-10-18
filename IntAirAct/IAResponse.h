@interface IAResponse : NSObject

#define OK @200
#define CREATED @201

#define ERROR @400
#define NOT_FOUND @404

@property (strong) NSNumber * statusCode;
@property (strong) NSData * body;
@property (strong, readonly) NSMutableDictionary * metadata;

@end