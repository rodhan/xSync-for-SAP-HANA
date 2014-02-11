#import <Foundation/Foundation.h>


/**
	This defines a little protocol which should be implemented by objects that
	want to be notified of file changes (objects set as delegate of the
	FSEventsListener class)
*/
@protocol FSEventListenerDelegate< NSObject >

@required

-(void)fileWasAdded:(NSString *)file;
-(void)fileWasRemoved:(NSString *)file;
-(void)fileWasRenamed:(NSString *)oldFile to:(NSString *)newFile;

-(void)directoryWasAdded:(NSString *)directory;
-(void)directoryWasRemoved:(NSString *)directory;
-(void)directoryWasRenamed:(NSString *)oldDirectory to:(NSString *)newDirectory;

@end


/**
	This class is a little helper to create file system events listeners. It
	allow to schedule event watching on a particular directory, and specify a
	delegate which will be called on each supported event.
*/
@interface FSEventsListener
	: NSObject
{

@private

	NSDictionary *		mListeners;
	FSEventStreamRef	mFileStream;

}

@property (assign)	NSDictionary *	listeners;

-(id)init;
-(void)dealloc;

// singleton handling
+(FSEventsListener *)instance;
+(void)destroy;

// handle listeners
-(void)addListener:(NSObject< FSEventListenerDelegate > *)listener forPath:(NSString *)path;
-(void)removeListener:(NSObject< FSEventListenerDelegate > *)listener forPath:(NSString *)path;

// utils
-(NSString *)formatPath:(NSString *)path;

// used to dispatch events to listeners
-(void)fileWasAdded:(NSString *)file;
-(void)fileWasRemoved:(NSString *)file;
-(void)fileWasRenamed:(NSString *)oldFile to:(NSString *)newFile;
-(void)directoryWasAdded:(NSString *)directory;
-(void)directoryWasRemoved:(NSString *)directory;
-(void)directoryWasRenamed:(NSString *)oldDirectory to:(NSString *)newDirectory;

@end

