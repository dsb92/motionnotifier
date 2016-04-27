//
//  Hubs.m
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 24/02/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

#import "Hubs.h"

@interface Hubs () <NSURLConnectionDataDelegate, NSXMLParserDelegate>
@end

@implementation Hubs

NSString *HubEndpoint;
NSString *HubSasKeyName;
NSString *HubSasKeyValue;

- (void)SendNotificationASPNETBackend:(NSString*)pns UsernameTag:(NSString*)usernameTag
                              Message:(NSString*)message
{
    NSURLSession* session = [NSURLSession
                             sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil
                             delegateQueue:nil];
    
    // Pass the pns and username tag as parameters with the REST URL to the ASP.NET backend
    NSURL* requestURL = [NSURL URLWithString:[NSString
                                              stringWithFormat:@"%@/api/notifications?pns=%@&to_tag=%@", BACKEND_ENDPOINT, pns,
                                              usernameTag]];
    
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:requestURL];
    [request setHTTPMethod:@"POST"];
    
    // Get the mock authenticationheader from the register client
    NSString* authorizationHeaderValue = [NSString stringWithFormat:@"Basic %@",
                                          self.registerClient.authenticationHeader];
    [request setValue:authorizationHeaderValue forHTTPHeaderField:@"Authorization"];
    
    //Add the notification message body
    [request setValue:@"application/json;charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[message dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSLog(@"***Request: %@\n%@\n%@", requestURL, authorizationHeaderValue, message);
    
    // Execute the send notification REST API on the ASP.NET Backend
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                      {
                                          NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*) response;
                                          if (error || httpResponse.statusCode != 200)
                                          {
                                              NSString* status = [NSString stringWithFormat:@"Error Status for %@: %ld\nError: %@\n",
                                                                  pns, (long)httpResponse.statusCode, error];
                                              dispatch_async(dispatch_get_main_queue(),
                                                             ^{
                                                                 // Append text because all 3 PNS calls may also have information to view
                                                                 self.statusResult = [self.statusResult stringByAppendingString:status];
                                                             });
                                              
                                              NSLog(@"%@",status);
                                          }
                                          
                                          if (data != NULL)
                                          {
                                              _xmlParser = [[NSXMLParser alloc] initWithData:data];
                                              [_xmlParser setDelegate:self];
                                              [_xmlParser parse];
                                          }
                                      }];
    [dataTask resume];
}

-(void) setDeviceToken: (NSData*) deviceToken
{
    _deviceToken = deviceToken;
}

-(void) createAndSetAuthenticationHeaderWithUsername:(NSString*)username
                                         AndPassword:(NSString*)password;
{
    NSString* headerValue = [NSString stringWithFormat:@"%@:%@", username, password];
    
    NSData* encodedData = [[headerValue dataUsingEncoding:NSUTF8StringEncoding] base64EncodedDataWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
    
    self.registerClient.authenticationHeader = [[NSString alloc] initWithData:encodedData
                                                                     encoding:NSUTF8StringEncoding];
}

-(void)ParseConnectionString
{
    NSArray *parts = [HUBFULLACCESS componentsSeparatedByString:@";"];
    NSString *part;
    
    if ([parts count] != 3)
    {
        NSException* parseException = [NSException exceptionWithName:@"ConnectionStringParseException"
                                                              reason:@"Invalid full shared access connection string" userInfo:nil];
        
        @throw parseException;
    }
    
    for (part in parts)
    {
        if ([part hasPrefix:@"Endpoint"])
        {
            HubEndpoint = [NSString stringWithFormat:@"https%@",[part substringFromIndex:11]];
        }
        else if ([part hasPrefix:@"SharedAccessKeyName"])
        {
            HubSasKeyName = [part substringFromIndex:20];
        }
        else if ([part hasPrefix:@"SharedAccessKey"])
        {
            HubSasKeyValue = [part substringFromIndex:16];
        }
    }
}


-(NSString*) generateSasToken:(NSString*)uri
{
    NSString *targetUri;
    NSString* utf8LowercasedUri = NULL;
    NSString *signature = NULL;
    NSString *token = NULL;
    
    @try
    {
        // Add expiration
        uri = [uri lowercaseString];
        utf8LowercasedUri = [self CF_URLEncodedString:uri];
        targetUri = [utf8LowercasedUri lowercaseString];
        NSTimeInterval expiresOnDate = [[NSDate date] timeIntervalSince1970];
        int expiresInMins = 60; // 1 hour
        expiresOnDate += expiresInMins * 60;
        UInt64 expires = trunc(expiresOnDate);
        NSString* toSign = [NSString stringWithFormat:@"%@\n%qu", targetUri, expires];
        
        // Get an hmac_sha1 Mac instance and initialize with the signing key
        const char *cKey  = [HubSasKeyValue cStringUsingEncoding:NSUTF8StringEncoding];
        const char *cData = [toSign cStringUsingEncoding:NSUTF8StringEncoding];
        unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
        CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
        NSData *rawHmac = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
        signature = [self CF_URLEncodedString:[rawHmac base64EncodedStringWithOptions:0]];
        
        // Construct authorization token string
        token = [NSString stringWithFormat:@"SharedAccessSignature sig=%@&se=%qu&skn=%@&sr=%@",
                 signature, expires, HubSasKeyName, targetUri];
    }
    @catch (NSException *exception)
    {
        [self MessageBox:@"Exception Generating SaS Token" message:[exception reason]];
    }
    @finally
    {
        if (utf8LowercasedUri != NULL)
            CFRelease((CFStringRef)utf8LowercasedUri);
        if (signature != NULL)
            CFRelease((CFStringRef)signature);
    }
    
    return token;
}

-(void)SendToEnabledPlatforms
{
    NSString* json = [NSString stringWithFormat:@"\"%@\"",self.notificationMessage];
    
    self.statusResult = @"";
    
    [self SendNotificationASPNETBackend:@"apns" UsernameTag:self.recipientName Message:json];
}

- (void)SendNotificationRESTAPI
{
    NSURLSession* session = [NSURLSession
                             sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                             delegate:nil delegateQueue:nil];
    
    // Apple Notification format of the notification message
    NSString *json = [NSString stringWithFormat:@"{\"aps\":{\"alert\":\"%@\"}}",
                      self.notificationMessage];
    
    // Construct the message's REST endpoint
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/messages/%@", HubEndpoint,
                                       HUBNAME, API_VERSION]];
    
    // Generate the token to be used in the authorization header
    NSString* authorizationToken = [self generateSasToken:[url absoluteString]];
    
    //Create the request to add the APNs notification message to the hub
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json;charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    
    // Signify Apple notification format
    [request setValue:@"apple" forHTTPHeaderField:@"ServiceBusNotification-Format"];
    
    //Authenticate the notification message POST request with the SaS token
    [request setValue:authorizationToken forHTTPHeaderField:@"Authorization"];
    
    //Add the notification message body
    [request setHTTPBody:[json dataUsingEncoding:NSUTF8StringEncoding]];
    
    // Send the REST request
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                      {
                                          NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*) response;
                                          if (error || (httpResponse.statusCode != 200 && httpResponse.statusCode != 201))
                                          {
                                              NSLog(@"\nError status: %d\nError: %@", httpResponse.statusCode, error);
                                          }
                                          if (data != NULL)
                                          {
                                              self.xmlParser = [[NSXMLParser alloc] initWithData:data];
                                              [self.xmlParser setDelegate:self];
                                              [self.xmlParser parse];
                                          }
                                      }];
    [dataTask resume];
}

//===[ Implement NSXMLParserDelegate methods ]===

-(void)parserDidStartDocument:(NSXMLParser *)parser
{
    self.statusResult = @"";
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
 namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
   attributes:(NSDictionary *)attributeDict
{
    NSString * element = [elementName lowercaseString];
    NSLog(@"*** New element parsed : %@ ***",element);
    
    if ([element isEqualToString:@"code"] | [element isEqualToString:@"detail"])
    {
        self.currentElement = element;
    }
}

-(void) parser:(NSXMLParser *)parser foundCharacters:(NSString *)parsedString
{
    self.statusResult = [self.statusResult stringByAppendingString:
                         [NSString stringWithFormat:@"%@ : %@\n", self.currentElement, parsedString]];
}

-(void)parserDidEndDocument:(NSXMLParser *)parser
{
    // Set the status label text on the UI thread
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       
                   });
}

-(NSString *)CF_URLEncodedString:(NSString *)inputString
{
    return (__bridge NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)inputString,
                                                                        NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8);
}

-(void)MessageBox:(NSString *)title message:(NSString *)messageText
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:messageText delegate:self
                                          cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
}

@end
