#import "FSEventsListener.h"



void fsevents_callback(ConstFSEventStreamRef streamRef,
                       void * userData,
                       size_t numEvents,
                       void * eventPaths,
                       const FSEventStreamEventFlags eventFlags[],
                       const FSEventStreamEventId eventIds[]);

@implementation FSEventsListener

static FSEventsListener * instance = nil;

@synthesize listeners	= mListeners;


-(id)init
{
	self = [super init];
	if (self == nil)
		return nil;

	mListeners = [[NSMutableDictionary alloc] init];

	// create the context that will be associated to the stream. We pass a
	// pointer to the FSEventsListener instance as user data.
	FSEventStreamContext context = { 0, (void *)self, NULL, NULL, NULL };

	// create the event stream, with a flag telling that we want to watch file
	// level events. This will allow to directly retrieve the file names in the
	// callback, instead of just the name of the directory
	mFileStream = FSEventStreamCreate(NULL,
									  &fsevents_callback,
									  &context,
									  (CFArrayRef)[NSArray arrayWithObject:@"/"],
									  kFSEventStreamEventIdSinceNow,
									  (CFAbsoluteTime)0.2,
									  kFSEventStreamCreateFlagFileEvents);

	// start the stream on the main event loop
	FSEventStreamScheduleWithRunLoop(mFileStream,
									 CFRunLoopGetCurrent(),
									 kCFRunLoopDefaultMode);
	FSEventStreamStart(mFileStream);

	// init the globally accessible instance
	instance = self;

	return self;
}

-(void)dealloc
{
	// clear the instance
	instance = nil;

	// stop and clean event stream
	FSEventStreamStop(mFileStream);
	FSEventStreamUnscheduleFromRunLoop(mFileStream, 
									   CFRunLoopGetCurrent(),
									   kCFRunLoopDefaultMode);
	FSEventStreamInvalidate(mFileStream);
	FSEventStreamRelease(mFileStream);

	[mListeners release];
	[super dealloc];
}

+(FSEventsListener *)instance
{
	if (instance == nil)
	{
		[[FSEventsListener alloc] init];
	}
	return instance;
}

+(void)destroy
{
	if (instance != nil)
	{
		[instance release];
		instance = nil;
	}
}

/**
	ensure pathes are always formated the same way : except for the root '/'
	path, every path must NOT end with a trailing '/'
*/
-(NSString *)formatPath:(NSString *)path
{
	if ([path characterAtIndex:[path length] - 1] == '/')
	{
		return [path substringToIndex:[path length] - 1]; 
	}
	return [[path copy] autorelease];
}

-(void)addListener:(NSObject< FSEventListenerDelegate > *)listener forPath:(NSString *)path
{
	NSString * formatedPath = [self formatPath:path]; 
	NSMutableArray * listeners = [mListeners objectForKey:formatedPath];
	if (listeners == nil)
	{
		[mListeners setValue:[NSMutableArray arrayWithObject:listener] forKey:formatedPath];
	}
	else
	{
		[listeners addObject:listener];
	}
}

-(void)removeListener:(NSObject< FSEventListenerDelegate > *)listener forPath:(NSString *)path
{
	NSString * formatedPath = [self formatPath:path]; 
	NSMutableArray * listeners = [mListeners objectForKey:formatedPath];
	if (listeners != nil)
	{
		[listeners removeObject:listener];
	}
}

-(void)fileWasAdded:(NSString *)file
{
	NSString * path = [file stringByDeletingLastPathComponent];
	NSArray * listeners = [mListeners objectForKey:path];
	for (NSObject< FSEventListenerDelegate > * listener in listeners)
		[listener fileWasAdded:file];
}

-(void)fileWasRemoved:(NSString *)file
{
	NSString * path = [file stringByDeletingLastPathComponent];
	NSArray * listeners = [mListeners objectForKey:path];
	for (NSObject< FSEventListenerDelegate > * listener in listeners)
		[listener fileWasRemoved:file];
}

-(void)fileWasRenamed:(NSString *)oldFile to:(NSString *)newFile
{
	NSString * path = [newFile stringByDeletingLastPathComponent];
	NSArray * listeners = [mListeners objectForKey:path];
	for (NSObject< FSEventListenerDelegate > * listener in listeners)
		[listener fileWasRenamed:oldFile to:newFile];
}

-(void)directoryWasAdded:(NSString *)directory
{
	NSString * path = [directory stringByDeletingLastPathComponent];
	NSArray * listeners = [mListeners objectForKey:path];
	for (NSObject< FSEventListenerDelegate > * listener in listeners)
		[listener directoryWasAdded:directory];
}

-(void)directoryWasRemoved:(NSString *)directory
{
	NSString * path = [directory stringByDeletingLastPathComponent];
	NSArray * listeners = [mListeners objectForKey:path];
	for (NSObject< FSEventListenerDelegate > * listener in listeners)
		[listener directoryWasRemoved:directory];
}

-(void)directoryWasRenamed:(NSString *)oldDirectory to:(NSString *)newDirectory
{
	NSString * path = [newDirectory stringByDeletingLastPathComponent];
	NSArray * listeners = [mListeners objectForKey:path];
	for (NSObject< FSEventListenerDelegate > * listener in listeners)
		[listener directoryWasRenamed:oldDirectory to:newDirectory];
}

@end


#define CHECK_STREAM(x, y) if (((x) & (y)) == (y)) NSLog(@"    %s", #y);

void fsevents_callback(ConstFSEventStreamRef streamRef,
                       void * userData,
                       size_t numEvents,
                       void * eventPaths,
                       const FSEventStreamEventFlags eventFlags[],
                       const FSEventStreamEventId eventIds[])
{
	static NSString * previousRenamedPath = nil;
	FSEventsListener * eventListener = (FSEventsListener *)userData;
	size_t	i;
	char ** paths	= eventPaths;
	for (i = 0; i < numEvents; ++i)
	{
		NSString * newName = [NSString stringWithFormat:@"%s", paths[i]];

		// first, we handle events WITHOUT the renamed flag. Those are simple
		// event, like "created", "removed". Note that when a device is mounted,
		// or unmounted, a corresponding "created" or "removed" event is
		// triggered, so we don't need to handle mount/unmount event.

		if ((eventFlags[i] & kFSEventStreamEventFlagItemRenamed) == 0)
		{	
			if (eventFlags[i] & kFSEventStreamEventFlagItemRemoved)
			{
				// a file or directory was permanently deleted
				if (eventFlags[i] & kFSEventStreamEventFlagItemIsFile)
				{
					[eventListener fileWasRemoved:newName];
				}
				else if (eventFlags[i] & kFSEventStreamEventFlagItemIsDir)
				{
					[eventListener directoryWasRemoved:newName];
				}
			}
			else if (eventFlags[i] & kFSEventStreamEventFlagItemCreated)
			{
				// a file or directory was copied/created
				if (eventFlags[i] & kFSEventStreamEventFlagItemIsFile)
				{
					[eventListener fileWasAdded:newName];
				}
				else if (eventFlags[i] & kFSEventStreamEventFlagItemIsDir)
				{
					[eventListener directoryWasAdded:newName];
				}
			}
		}
		else
		{

			// here, the "renamed" flag is present. From what I can guess
			// through experiments, when a file is renamed, or moved, or sent
			// to the trash, it triggers 2 successive renamed events. The first
			// contains the source file, the second the destination file.
			// So I just use a static string to store the first event path and
			// detect if it's the first or second event.

			if (previousRenamedPath == nil)
			{
				previousRenamedPath = [newName retain];
			}
			else
			{
				NSString * newDir = [newName stringByDeletingLastPathComponent];
				NSString * oldName = previousRenamedPath;
				NSString * oldDir = [oldName stringByDeletingLastPathComponent];
				if (eventFlags[i] & kFSEventStreamEventFlagItemIsFile)
				{
					if ([oldDir isEqualToString:newDir])
					{
						// both directory are the same : file renamed
						[eventListener fileWasRenamed:oldName to:newName];
					}
					else
					{
						// directories are different, the file was moved
						[eventListener fileWasAdded:newName];
						[eventListener fileWasRemoved:oldName];
					}
				}
				else if (eventFlags[i] & kFSEventStreamEventFlagItemIsDir)
				{
					if ([oldDir isEqualToString:newDir])
					{
						// both directory are the same : renamed
						[eventListener directoryWasRenamed:oldName to:newName];
					}
					else
					{
						// directories are different, the directory was moved
						[eventListener directoryWasAdded:newName];
						[eventListener directoryWasRemoved:oldName];
					}
				}

				// reset the previous renamed path.
                previousRenamedPath = nil;
				//SAFE_RELEASE(previousRenamedPath);
			}
		}
#if defined(DEBUG)
//		NSLog(@"event [%d] [%d] [%s]", (int)eventIds[i], eventFlags[i], paths[i]);
//		CHECK_STREAM(eventFlags[i], kFSEventStreamEventFlagNone);
//		CHECK_STREAM(eventFlags[i], kFSEventStreamEventFlagMustScanSubDirs);
//		CHECK_STREAM(eventFlags[i], kFSEventStreamEventFlagUserDropped);
//		CHECK_STREAM(eventFlags[i], kFSEventStreamEventFlagKernelDropped);
//		CHECK_STREAM(eventFlags[i], kFSEventStreamEventFlagEventIdsWrapped);
//		CHECK_STREAM(eventFlags[i], kFSEventStreamEventFlagHistoryDone);
//		CHECK_STREAM(eventFlags[i], kFSEventStreamEventFlagRootChanged);
//		CHECK_STREAM(eventFlags[i], kFSEventStreamEventFlagMount);
//		CHECK_STREAM(eventFlags[i], kFSEventStreamEventFlagUnmount);
//		CHECK_STREAM(eventFlags[i], kFSEventStreamEventFlagItemCreated);
//		CHECK_STREAM(eventFlags[i], kFSEventStreamEventFlagItemRemoved);
//		CHECK_STREAM(eventFlags[i], kFSEventStreamEventFlagItemInodeMetaMod);
//		CHECK_STREAM(eventFlags[i], kFSEventStreamEventFlagItemRenamed);
//		CHECK_STREAM(eventFlags[i], kFSEventStreamEventFlagItemModified);
//		CHECK_STREAM(eventFlags[i], kFSEventStreamEventFlagItemFinderInfoMod);
//		CHECK_STREAM(eventFlags[i], kFSEventStreamEventFlagItemChangeOwner);
//		CHECK_STREAM(eventFlags[i], kFSEventStreamEventFlagItemXattrMod);
//		CHECK_STREAM(eventFlags[i], kFSEventStreamEventFlagItemIsFile);
//		CHECK_STREAM(eventFlags[i], kFSEventStreamEventFlagItemIsDir);
//		CHECK_STREAM(eventFlags[i], kFSEventStreamEventFlagItemIsSymlink);
#endif // _DEBUG
	}
}
