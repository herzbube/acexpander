// -----------------------------------------------------------------------------
// AceXpander - a Mac OS X graphical user interface to the unace command line utility
//
// Copyright (C) 2004 Patrick Näf
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//
// To view the GNU General Public License, please choose the menu item
// Help:GNU General Public License, or see the file COPYING inside the
// application bundle.
//
// The author of this program can be contacted by email at
// acexpander@herzbube.ch
// -----------------------------------------------------------------------------


// Project includes
#import "AceXpanderThread.h"
#import "AceXpanderItem.h"
#import "AceXpanderController.h"
#import "AceXpanderPreferences.h"

// Constants
// Resource file names
static NSString* unaceFrontEndResourceName = @"unace.sh";
static NSString* unaceBundledResourceName = @"unace";
// Parameters for the unace frontend
static NSString* unaceFrontEndEnableDebug = @"1";
static NSString* unaceFrontEndDisableDebug = @"0";
static NSString* unaceFrontEndVersionParameter = @"--version";
static NSString* unaceFrontDestinationFolderParameter = @"--folder";
// Information about unace
static NSString* unaceCmdExtract = @"e";
static NSString* unaceCmdExtractWithFullPath = @"x";
static NSString* unaceCmdList = @"l";
static NSString* unaceCmdListVerbosely = @"v";
static NSString* unaceCmdTest = @"t";
static NSString* unaceSwitchShowComments = @"-c";
static NSString* unaceSwitchOverwriteFiles = @"-o";
static NSString* unaceSwitchUsePassword = @"-p";
static NSString* unaceSwitchAssumeYes = @"-y";


/// @brief This category declares private methods for the AceXpanderThread
/// class. 
@interface AceXpanderThread(Private)
- (void) dealloc;
- (void) runWithObject:(id)anObject;
- (void) processItem:(AceXpanderItem*)item withUnace:(NSString*)unaceExecutablePath;
+ (NSString*) determineUnaceExecutablePath;
- (NSString*) determineDestinationFolder:(NSString*)archiveFileName;
- (BOOL) stopRunning;
- (void) setStopRunning:(BOOL)stopRunning;
- (void) setIsRunning:(BOOL)isRunning;
@end

@implementation AceXpanderThread
// -----------------------------------------------------------------------------
/// @brief Initializes an AceXpanderThread object.
///
/// @note This is the designated initializer of AceXpanderThread.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  m_itemList = [[NSMutableArray array] retain];
  m_unaceSwitchList = [[NSMutableArray array] retain];
  m_runLock = [[NSLock alloc] init];
  m_stopRunningLock = [[NSLock alloc] init];
  m_isRunningLock = [[NSLock alloc] init];
  m_taskLock = [[NSLock alloc] init];
  [self setIsRunning:false];
  [self setStopRunning:false];

  // Return
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this AceXpanderThread object.
///
/// A command that is still running is stopped by this method.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  // Make sure that any still running command is stopped
  [self stop];

  // The following members are always filled with constants -> we don't have to
  // release these members
  // - m_unaceCommand
  // - m_unaceFrontendDebugParameter

  if (m_runLock)
    [m_runLock autorelease];
  if (m_stopRunningLock)
    [m_stopRunningLock autorelease];
  if (m_isRunningLock)
    [m_isRunningLock autorelease];
  if (m_taskLock)
    [m_taskLock autorelease];
  if (m_itemList)
    [m_itemList autorelease];
  if (m_unaceSwitchList)
    [m_unaceSwitchList autorelease];
  if (m_unaceTask)
    [m_unaceTask autorelease];
  if (m_destinationFolderAskWhenExpanding)
    [m_destinationFolderAskWhenExpanding autorelease];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Launches a new thread whose main method is runWithObject:().
// -----------------------------------------------------------------------------
- (void) run
{
  [NSThread detachNewThreadSelector:@selector(runWithObject:) toTarget:self withObject:nil];
}

// -----------------------------------------------------------------------------
/// @brief This is the main method of the command thread. It creates an
/// autorelease pool, processes all items that have previously been added, then
/// releases the autorelease pool.
///
/// At the end of each iteration, before processing of a new item begins, this
/// method checks whether it should abort the loop because an external source
/// has called stop:() (usually in reaction to the user clicking the "cancel"
/// button in the GUI).
// -----------------------------------------------------------------------------
- (void) runWithObject:(id)anObject
{
  // Some objects that need to be present
  if (! m_itemList)
    return;

  // Create an autorelease pool
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  if (! pool)
    return;

  // From now on, do not return without unlocking m_runLock
  if (m_runLock)
    [m_runLock lock];

  // Determine the path to the unace executable that we should use
  NSString* unaceExecutablePath = [AceXpanderThread determineUnaceExecutablePath];

  // Initialize members
  [self setIsRunning:true];
  [self setStopRunning:false];
  if (m_destinationFolderAskWhenExpanding)
  {
    [m_destinationFolderAskWhenExpanding autorelease];
    m_destinationFolderAskWhenExpanding = nil;
  }

  NSEnumerator* enumerator = [m_itemList objectEnumerator];
  AceXpanderItem* iterItem;
  while (iterItem = (AceXpanderItem*)[enumerator nextObject])
  {
    // We need to check the state because it might be possible that
    // in the meantime the item has become non-QUEUED through the
    // user's actions
    if (QueuedState != [iterItem state])
      continue;

    // Start processing
    [iterItem setState:ProcessingState];
    [self processItem:iterItem withUnace:unaceExecutablePath];

    // Abort if necessary
    if ([self stopRunning])
      break;
  }

  // Reset flags
  [self setIsRunning:false];
  // Clear the list to make this thread ready for submissions for the next run
  [m_itemList removeAllObjects];

  // Release the lock
  if (m_runLock)
    [m_runLock unlock];

  // Notify any observers that this thread has terminated
  // Note: do this ***AFTER*** releasing m_runLock to prevent a deadlock where
  // - the GUI thread is waiting on m_runLock in stop:(), because the
  //   user clicked the "cancel" button
  // - posting the notification leads to a GUI update of the "expand" button,
  //   which will then wait on a lock inside Cocoa that was already acquired
  //   by the GUI thread when the user clicked the "cancel" button
  [[NSNotificationCenter defaultCenter] postNotificationName:commandThreadHasFinishedNotification object:nil];

  // Release the autorelease pool
  [pool release];
}

// -----------------------------------------------------------------------------
/// @brief Terminates the command thread that is currently running.
///
/// This method does not return until the command thread has been terminated.
// -----------------------------------------------------------------------------
- (void) stop
{
  // This will stop the next iteration in the runWithObject() method
  [self setStopRunning:true];

  // The thread waits for the process, so we need to kill the process
  // in order for the thread to be able to check on the m_stopRunning
  // flag
  if (m_taskLock)
    [m_taskLock lock];
  if (nil != m_unaceTask && [m_unaceTask isRunning])
    [m_unaceTask terminate];
  if (m_taskLock)
    [m_taskLock unlock];

  // Try to acquire the run lock - we will get it as soon as runWithObject
  // returns
  [m_runLock lock];
  // We can release the lock immediately
  [m_runLock unlock];
}

// -----------------------------------------------------------------------------
/// @brief Updates the m_stopRunning flag to the value @a stopRunning.
///
/// This is an internal helper method that protects access to m_stopRunning.
// -----------------------------------------------------------------------------
- (void) setStopRunning:(BOOL)stopRunning
{
  if (m_stopRunningLock)
    [m_stopRunningLock lock];
  m_stopRunning = stopRunning;
  if (m_stopRunningLock)
    [m_stopRunningLock unlock];
}

// -----------------------------------------------------------------------------
/// @brief Returns the value of the m_stopRunning flag. If true, a running
/// thread should terminate as soon as possible.
///
/// This is an internal helper method that protects access to m_stopRunning.
// -----------------------------------------------------------------------------
- (BOOL) stopRunning
{
  if (m_stopRunningLock)
    [m_stopRunningLock lock];
  // Make a copy that we can return after releasing the lock
  BOOL stopRunning = m_stopRunning;
  if (m_stopRunningLock)
    [m_stopRunningLock unlock];
  return stopRunning;
}

// -----------------------------------------------------------------------------
/// @brief Updates the m_isRunning flag to the value @a isRunning.
///
/// This is an internal helper method that protects access to m_isRunning.
// -----------------------------------------------------------------------------
- (void) setIsRunning:(BOOL)isRunning
{
  if (m_isRunningLock)
    [m_isRunningLock lock];
  m_isRunning = isRunning;
  if (m_isRunningLock)
    [m_isRunningLock unlock];
}

// -----------------------------------------------------------------------------
/// @brief Returns whether or not the command thread is currently running.
///
/// This is an internal helper method that protects access to m_isRunning.
// -----------------------------------------------------------------------------
- (BOOL) isRunning
{
  if (m_isRunningLock)
    [m_isRunningLock lock];
  // Make a copy that we can return after releasing the lock
  BOOL isRunning = m_isRunning;
  if (m_isRunningLock)
    [m_isRunningLock unlock];
  return isRunning;
}

// -----------------------------------------------------------------------------
/// @brief Adds @a item to the list of items that the command thread should
/// process when it is run the next time.
///
/// @a item will be skipped if its state is not #QueuedState when the command
/// thread runs the next time.
// -----------------------------------------------------------------------------
- (void) addItem:(AceXpanderItem*)item
{
  if (m_runLock)
    [m_runLock lock];

  // The array retains the object for us
  if (m_itemList)
    [m_itemList addObject:item];

  if (m_runLock)
    [m_runLock unlock];
}

// -----------------------------------------------------------------------------
/// @brief Removes @a item from the list of items that the command thread should
/// process when it is run the next time.
// -----------------------------------------------------------------------------
- (void) removeItem:(AceXpanderItem*)item
{
  if (m_runLock)
    [m_runLock lock];

  // The array releases the item for us
  if (m_itemList)
    [m_itemList removeObject:item];

  if (m_runLock)
    [m_runLock unlock];
}

// -----------------------------------------------------------------------------
/// @brief Tells the command thread that it should execute the command
/// @a command, using the other method parameters as command options, when it
/// is run the next time.
// -----------------------------------------------------------------------------
- (void) setCommand:(int)command
     overwriteFiles:(BOOL)overwriteFiles
    extractFullPath:(BOOL)extractFullPath
          assumeYes:(bool)assumeYes
       showComments:(BOOL)showComments
      listVerbosely:(BOOL)listVerbosely
        usePasswort:(BOOL)usePassword
           password:(NSString*)password
          debugMode:(BOOL)debugMode
{
  if (m_runLock)
    [m_runLock lock];

  m_unaceCommand = @"";
  [m_unaceSwitchList removeAllObjects];

  m_command = command;
  switch (command)
  {
    case ExpandCommand:
      if (extractFullPath)
        m_unaceCommand = unaceCmdExtractWithFullPath;
      else
        m_unaceCommand = unaceCmdExtract;
      break;
    case ListCommand:
      if (listVerbosely)
        m_unaceCommand = unaceCmdListVerbosely;
      else
        m_unaceCommand = unaceCmdList;
      break;
    case TestCommand:
      m_unaceCommand = unaceCmdTest;
      break;
    default:
    {
      NSString* errorDescription = [NSString stringWithFormat:@"Unexpected command code %d", command];
      [[NSNotificationCenter defaultCenter] postNotificationName:errorConditionOccurredNotification object:errorDescription];

      if (m_runLock)
        [m_runLock unlock];
      return;
    }
  }
  
  NSString* switchString;

  switchString = unaceSwitchOverwriteFiles;
  if (overwriteFiles) { switchString = [switchString stringByAppendingString:@"+"]; }
  else                { switchString = [switchString stringByAppendingString:@"-"]; }
  [m_unaceSwitchList addObject:switchString];

  switchString = unaceSwitchAssumeYes;
  if (assumeYes) { switchString = [switchString stringByAppendingString:@"+"]; }
  else           { switchString = [switchString stringByAppendingString:@"-"]; }
  [m_unaceSwitchList addObject:switchString];
  
  switchString = unaceSwitchShowComments;
  if (showComments) { switchString = [switchString stringByAppendingString:@"+"]; }
  else              { switchString = [switchString stringByAppendingString:@"-"]; }
  [m_unaceSwitchList addObject:switchString];

  if (usePassword)
  {
    switchString = [unaceSwitchUsePassword stringByAppendingString:password];
    [m_unaceSwitchList addObject:switchString];
  }

  if (debugMode)
    m_unaceFrontendDebugParameter = unaceFrontEndEnableDebug;
  else
    m_unaceFrontendDebugParameter = unaceFrontEndDisableDebug;

  if (m_runLock)
    [m_runLock unlock];
}

// -----------------------------------------------------------------------------
/// @brief Launches unace in a separate process to get information about the
/// executable's version.
///
/// This method is synchronous, i.e. it does @not launch a thread to execute
/// the unace binary. This method is simply a convenient way to get at the
/// unace binary's version information.
///
/// @return a version string, or nil if something goes wrong
///
/// @note This is a class method.
// -----------------------------------------------------------------------------
+ (NSString*) unaceVersion
{
  NSString* unaceExecutablePath = [AceXpanderThread determineUnaceExecutablePath];
  if (! unaceExecutablePath)
    return nil;

  NSMutableArray* arguments = [NSMutableArray array];
  [arguments addObject:unaceExecutablePath];
  [arguments addObject:unaceFrontEndVersionParameter];
  
  // Create pipe
  NSPipe* stdoutPipe = [NSPipe pipe];
  // Create and configure task
  NSTask* unaceTask = [[NSTask alloc] init];
  [unaceTask setStandardOutput:stdoutPipe]; 
  [unaceTask setLaunchPath:[[NSBundle mainBundle] pathForResource:unaceFrontEndResourceName ofType:nil]];
  [unaceTask setArguments:arguments];

  // The result we want to return
  NSString* messageStdout = nil;

  // Execute task and wait for its termination
  @try
  {
    [unaceTask launch];
    [unaceTask waitUntilExit];

    // Evaluate task result
    int exitValue = [unaceTask terminationStatus];
    if (0 == exitValue)
    {
      NSFileHandle* readHandle = [stdoutPipe fileHandleForReading];
      NSData* stdoutData = [readHandle readDataToEndOfFile];
      messageStdout = [[NSString alloc] initWithData:stdoutData encoding:NSASCIIStringEncoding];
    }
  }
  @catch(NSException* exception)
  {
    // Notify the error handler that an error has occurred
    [[NSNotificationCenter defaultCenter] postNotificationName:errorConditionOccurredNotification
                                                        object:[exception reason]];
  }

  // Release objects
  [unaceTask autorelease];

  // Return entire standard output as the version string
  if (messageStdout)
    return [[messageStdout retain] autorelease];
  else
    return nil;
}

// -----------------------------------------------------------------------------
/// @brief Processes the archive that @a item represents in a separate process.
/// Waits for the process to terminate.
///
/// @a unaceExecutablePath is the path to the unace binary that should be
/// used to launch the process.
///
/// @a item is updated with a new state (usually either #SuccessState or
/// #FailureState) and the messages acquired from the process' standard output
/// and standard error.
// -----------------------------------------------------------------------------
- (void) processItem:(AceXpanderItem*)item withUnace:(NSString*)unaceExecutablePath
{
  if (! item || ! unaceExecutablePath)
    return;
  NSString* fileName = [item fileName];

  // Destination folder is required only if we expand
  NSString* destinationFolder = nil;
  if (ExpandCommand == m_command)
  {
    destinationFolder = [self determineDestinationFolder:fileName];
    if (! destinationFolder)
    {
      [item setState:FailureState];
      [item setMessageStdout:nil messageStderr:nil containsListing:NO];
      return;
    }
  }

  // Build command line
  // Note: it is important that the command line is built in a way that retains
  // spaces in path names! Also, special care must be taken that no empty
  // strings are passed as arguments to unace because it is confused by this
  // and will try to expand an archive named ".ace" (empty string followed by
  // extension ".ace")
  NSMutableArray* arguments = [NSMutableArray array];
  [arguments addObject:unaceExecutablePath];
  if (destinationFolder)
  {
    [arguments addObject:unaceFrontDestinationFolderParameter];
    [arguments addObject:destinationFolder];
  }
  [arguments addObject:m_unaceFrontendDebugParameter];
  [arguments addObject:m_unaceCommand];
  NSEnumerator* enumerator = [m_unaceSwitchList objectEnumerator];
  NSString* iterSwitch;
  while (iterSwitch = (NSString*)[enumerator nextObject])
    [arguments addObject:iterSwitch];
  [arguments addObject:fileName];

  /// @todo change working directory first so that the stuff that
  /// gets un-archived by unace is placed in the right directory
  /// If the process correctly inherits the working directory, we
  /// can do without the shell front end and execute unace directly.

  // Create pipe
  NSPipe* stdoutPipe = [NSPipe pipe];
  NSPipe* stderrPipe = [NSPipe pipe];
  // Create and configure task
  if (m_taskLock)
    [m_taskLock lock];
  m_unaceTask = [[NSTask alloc] init];
  [m_unaceTask setStandardOutput:stdoutPipe]; 
  [m_unaceTask setStandardError:stderrPipe]; 
  [m_unaceTask setLaunchPath:[[NSBundle mainBundle] pathForResource:unaceFrontEndResourceName ofType:nil]];
  [m_unaceTask setArguments:arguments];

  // Execute task and wait for its termination
  @try
  {
    [m_unaceTask launch];
    // While we wait for the task's termination, we release the lock that
    // allows for task termination by stop:()
    if (m_taskLock)
      [m_taskLock unlock];
    [m_unaceTask waitUntilExit];
    if (m_taskLock)
      [m_taskLock lock];
  }
  @catch(NSException* exception)
  {
    // Notify the error handler that an error has occurred
    [[NSNotificationCenter defaultCenter] postNotificationName:errorConditionOccurredNotification
                                                        object:[exception reason]];
  }

  // Check if we need to stop the thread
  if ([self stopRunning])
  {
    [item setState:AbortedState];
    [item setMessageStdout:nil
             messageStderr:nil
           containsListing:(m_command == ListCommand)];
  }
  else
  {
    // Evaluate task result
    int exitValue = [m_unaceTask terminationStatus];
    if (0 != exitValue)
      [item setState:FailureState];
    else
      [item setState:SuccessState];

    // Get standard output and error messages
    NSFileHandle* stdoutReadHandle = [stdoutPipe fileHandleForReading];
    NSData* stdoutData = [stdoutReadHandle readDataToEndOfFile];
    NSString* messageStdout = [[NSString alloc] initWithData:stdoutData encoding:NSASCIIStringEncoding];
    NSFileHandle* stdErrReadHandle = [stderrPipe fileHandleForReading];
    NSData* stderrData = [stdErrReadHandle readDataToEndOfFile];
    NSString* messageStderr = [[NSString alloc] initWithData:stderrData encoding:NSASCIIStringEncoding];
    [item setMessageStdout:messageStdout
             messageStderr:messageStderr
                containsListing:(m_command == ListCommand)];
    if (messageStdout)
      [messageStdout autorelease];
    if (messageStderr)
      [messageStderr autorelease];
  }

  [m_unaceTask autorelease];
  m_unaceTask = nil;
  if (m_taskLock)
    [m_taskLock unlock];
}

// -----------------------------------------------------------------------------
/// @brief Returns the path to the unace executable that should be used
/// according to the user defaults.
///
/// @note This is a class method.
// -----------------------------------------------------------------------------
+ (NSString*) determineUnaceExecutablePath
{
  NSString* unaceExecutablePath = [[NSUserDefaults standardUserDefaults] stringForKey:executablePathKey];
  if (! unaceExecutablePath || [unaceExecutablePath isEqualToString:bundledExecutablePath])
    return [[NSBundle mainBundle] pathForResource:unaceBundledResourceName ofType:nil];
  else
    return unaceExecutablePath;
}

// -----------------------------------------------------------------------------
/// @brief Tries to determine the destination folder where the archive contents
/// should be expanded from the various user default settings.
///
/// This method must be called once for each item processed by the thread. The
/// reason is because one or both of the following user preferences might be
/// set:
/// - "DestinationFolderType" is set to "SameAsArchive"
/// - "CreateSurroundingFolder" is set to true
///
/// If "DestinationFolderType" is "AskWhenExpanding", this method lets the user
/// choose a folder from an NSOpenPanel. It does so only for the first item of
/// the current thread run.
/// 
/// @note This method does not @e create the destination folder if it doesn't
/// exist yet - this is the responsibility of the unace front-end shell script.
///
/// @return the destination folder, or nil if the folder could not be
/// determined (e.g. because the user was queried for a folder, but she clicked
/// the "cancel" button in the NSOpenPanel).
// -----------------------------------------------------------------------------
- (NSString*) determineDestinationFolder:(NSString*)archiveFileName
{
  NSString* destinationFolder = nil;

  NSString* destinationFolderType = [[NSUserDefaults standardUserDefaults] stringForKey:destinationFolderTypeKey];
  if ([destinationFolderType isEqualToString:destinationFolderTypeSameAsArchive])
    destinationFolder = [archiveFileName stringByDeletingLastPathComponent];
  else if ([destinationFolderType isEqualToString:destinationFolderTypeFixedLocation])
    destinationFolder = [[NSUserDefaults standardUserDefaults] stringForKey:destinationFolderKey];
  else if ([destinationFolderType isEqualToString:destinationFolderTypeAskWhenExpanding])
  {
    // Only query the user if she hasn't chosen a folder yet.
    if (! m_destinationFolderAskWhenExpanding)
    {
      NSOpenPanel* openPanel = [NSOpenPanel openPanel];
      if (! openPanel)
        return nil;
      [openPanel setAllowsMultipleSelection:NO];
      [openPanel setCanChooseFiles:NO];
      [openPanel setCanChooseDirectories:YES];
      NSString* directory = nil;
      NSString* selectedFile = nil;
      NSArray* fileTypes = nil;
      int iResult = [openPanel runModalForDirectory:directory file:selectedFile types:fileTypes];
      // Remember the user's answer to prevent querying in subsequent calls to
      // this method
      if (NSOKButton == iResult)
      {
        // We trust the panel to return at least one item!
        m_destinationFolderAskWhenExpanding = (NSString*)[[openPanel filenames] objectAtIndex:0];
        if (m_destinationFolderAskWhenExpanding)
          [m_destinationFolderAskWhenExpanding retain];
      }
      // The user cancelled the query -> the process should be aborted
      else
        return nil;
    }

    // Use the folder that the user chose when she was queried during the first
    // item's processing
    destinationFolder = m_destinationFolderAskWhenExpanding;
  }

  // If user defaults say so, add an additional surrounding folder to the
  // destination folder.
  if ([[NSUserDefaults standardUserDefaults] boolForKey:createSurroundingFolderKey])
  {
    destinationFolder = [[[destinationFolder stringByAppendingString:@"/"]
                                            stringByAppendingString:[archiveFileName lastPathComponent]]
                                             stringByAppendingString:@" Folder"];
  }

  if (destinationFolder)
    return [[destinationFolder retain] autorelease];
  else
    return nil;
}

@end
