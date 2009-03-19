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
#import "AceXpanderTask.h"
#import "AceXpanderItem.h"
#import "AceXpanderGlobals.h"


/// @brief This category declares private methods for the AceXpanderTask class.
@interface AceXpanderTask(Private)
- (void) dealloc;
- (BOOL) terminated;
@end

@implementation AceXpanderTask
// -----------------------------------------------------------------------------
/// @brief Initializes an AceXpanderTask object.
///
/// @note This is the designated initializer of AceXpanderTask.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  // Init members
  m_terminated = false;

  // Return
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this AceXpanderTask object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  if (m_task)
    [m_task autorelease];
  if (m_unaceExecutablePath)
    [m_unaceExecutablePath autorelease];
  if (m_destinationFolder)
    [m_destinationFolder autorelease];
  if (m_unaceFrontendDebugParameter)
    [m_unaceFrontendDebugParameter autorelease];
  if (m_unaceCommand)
    [m_unaceCommand autorelease];
  if (m_unaceSwitchList)
    [m_unaceSwitchList autorelease];
  if (m_item)
    [m_item autorelease];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Configures this AceXpanderTask with the full path to the unace
/// executable.
///
/// This parameter is mandatory.
// -----------------------------------------------------------------------------
- (void) setUnaceExecutablePath:(NSString*)unaceExecutablePath
{
  if (m_unaceExecutablePath == unaceExecutablePath)
    return;
  if (m_unaceExecutablePath)
    [m_unaceExecutablePath autorelease];
  if (unaceExecutablePath)
    m_unaceExecutablePath = [unaceExecutablePath retain];
  else
    m_unaceExecutablePath = nil;
}

// -----------------------------------------------------------------------------
/// @brief Configures this AceXpanderTask with the full path to the destination
/// folder into which the archive should be expanded.
///
/// This parameter is required only if the unace command is #ExpandCommand.
// -----------------------------------------------------------------------------
- (void) setDestinationFolder:(NSString*)destinationFolder
{
  if (m_destinationFolder == destinationFolder)
    return;
  if (m_destinationFolder)
    [m_destinationFolder autorelease];
  if (destinationFolder)
    m_destinationFolder = [destinationFolder retain];
  else
    m_destinationFolder = nil;
}

// -----------------------------------------------------------------------------
/// @brief Configures this AceXpanderTask with a debug switch for the unace
/// frontend shell script located within the application bundle.
///
/// This parameter is optional.
// -----------------------------------------------------------------------------
- (void) setUnaceFrontendDebugParameter:(NSString*)unaceFrontendDebugParameter
{
  if (m_unaceFrontendDebugParameter == unaceFrontendDebugParameter)
    return;
  if (m_unaceFrontendDebugParameter)
    [m_unaceFrontendDebugParameter autorelease];
  if (unaceFrontendDebugParameter)
    m_unaceFrontendDebugParameter = [unaceFrontendDebugParameter retain];
  else
    m_unaceFrontendDebugParameter = nil;
}

// -----------------------------------------------------------------------------
/// @brief Configures this AceXpanderTask with the command to execute, both in
/// its numerical and in its string form (i.e. a switch for the unace binary).
///
/// This parameter is mandatory.
// -----------------------------------------------------------------------------
- (void) setUnaceCommand:(int)command commandSwitch:(NSString*)unaceCommand
{
  if (m_unaceCommand == unaceCommand)
    return;
  if (m_unaceCommand)
    [m_unaceCommand autorelease];
  if (unaceCommand)
    m_unaceCommand = [unaceCommand retain];
  else
    m_unaceCommand = nil;

  m_command = command;
}

// -----------------------------------------------------------------------------
/// @brief Configures this AceXpanderTask with a number of switches for the
/// unace binary.
///
/// This parameter is mandatory.
// -----------------------------------------------------------------------------
- (void) setUnaceSwitchList:(NSArray*)unaceSwitchList
{
  if (m_unaceSwitchList == unaceSwitchList)
    return;
  if (m_unaceSwitchList)
    [m_unaceSwitchList autorelease];
  if (unaceSwitchList)
    m_unaceSwitchList = [unaceSwitchList retain];
  else
    m_unaceSwitchList = nil;
}

// -----------------------------------------------------------------------------
/// @brief Configures this AceXpanderTask with the AceXpanderItem object that
/// represents the archive file to be processed.
///
/// This parameter is mandatory.
// -----------------------------------------------------------------------------
- (void) setItem:(AceXpanderItem*)item
{
  if (m_item == item)
    return;
  if (m_item)
    [m_item autorelease];
  if (item)
    m_item = [item retain];
  else
    m_item = nil;
}

// -----------------------------------------------------------------------------
/// @brief Launches the system process (= task) that executes the unace binary
/// previously configured.
///
/// The AceXpanderItem object passed earlier with setItem:() is updated with
/// the results of the command.
// -----------------------------------------------------------------------------
- (void) launch
{
  if (! m_item)
    return;

  // Start processing
  [m_item setState:ProcessingState];

  // Get the item's filename
  NSString* fileName = [m_item fileName];

  // Get path to the unace front-end inside the application bundle
  NSString* unaceFrontEnd = [[NSBundle mainBundle] pathForResource:unaceFrontEndResourceName ofType:nil];
  
  // Check for important arguments
  BOOL failed = false;
  if (! fileName || ! m_unaceExecutablePath || ! m_unaceCommand || ! m_unaceSwitchList || ! unaceFrontEnd)
    failed = true;
  // m_destinationFolder is only required for ExpandCommand
  else if (ExpandCommand == m_command && ! m_destinationFolder)
    failed = true;
  if (failed)
  {
    [m_item setState:FailureState];
    [m_item setMessageStdout:nil messageStderr:nil containsListing:NO];
    return;
  }

  // Build command line
  // Note: it is important that the command line is built in a way that retains
  // spaces in path names! Also, special care must be taken that no empty
  // strings are passed as arguments to unace because it is confused by this
  // and will try to expand an archive named ".ace" (empty string followed by
  // extension ".ace")
  NSMutableArray* arguments = [NSMutableArray array];
  [arguments addObject:m_unaceExecutablePath];
  if (m_destinationFolder)
  {
    [arguments addObject:unaceFrontDestinationFolderParameter];
    [arguments addObject:m_destinationFolder];
  }
  if (m_unaceFrontendDebugParameter)
    [arguments addObject:m_unaceFrontendDebugParameter];
  [arguments addObject:m_unaceCommand];
  [arguments addObjectsFromArray:m_unaceSwitchList];
  [arguments addObject:fileName];

  /// @todo change working directory first so that the stuff that
  /// gets un-archived by unace is placed in the right directory
  /// If the process correctly inherits the working directory, we
  /// can do without the shell front end and execute unace directly.

  // Create pipe
  NSPipe* stdoutPipe = [NSPipe pipe];
  NSPipe* stderrPipe = [NSPipe pipe];
  // Create and configure task
  m_task = [[NSTask alloc] init];
  [m_task setStandardOutput:stdoutPipe]; 
  [m_task setStandardError:stderrPipe]; 
  [m_task setLaunchPath:unaceFrontEnd];
  [m_task setArguments:arguments];

  // Execute task and wait for its termination
  @try
  {
    [m_task launch];
    [m_task waitUntilExit];
  }
  @catch(NSException* exception)
  {
    // Notify the error handler that an error has occurred
    [[NSNotificationCenter defaultCenter] postNotificationName:errorConditionOccurredNotification
                                                        object:[exception reason]];
  }

  // Check if the task was aborted
  if ([self terminated])
    [m_item setState:AbortedState];
  else
  {
    // Evaluate task result
    int exitValue = [m_task terminationStatus];
    if (0 != exitValue)
      [m_item setState:FailureState];
    else
      [m_item setState:SuccessState];
  }

  // Get standard output and error messages
  NSFileHandle* stdoutReadHandle = [stdoutPipe fileHandleForReading];
  NSData* stdoutData = [stdoutReadHandle readDataToEndOfFile];
  NSString* messageStdout = [[NSString alloc] initWithData:stdoutData encoding:NSASCIIStringEncoding];
  NSFileHandle* stdErrReadHandle = [stderrPipe fileHandleForReading];
  NSData* stderrData = [stdErrReadHandle readDataToEndOfFile];
  NSString* messageStderr = [[NSString alloc] initWithData:stderrData encoding:NSASCIIStringEncoding];
  [m_item setMessageStdout:messageStdout
           messageStderr:messageStderr
         containsListing:(m_command == ListCommand)];
  if (messageStdout)
    [messageStdout autorelease];
  if (messageStderr)
    [messageStderr autorelease];

  NSAlert* alert = [NSAlert alertWithMessageText:@"xxx!"
                                   defaultButton:@"foo"
                                 alternateButton:nil
                                     otherButton:nil
                       informativeTextWithFormat:messageStdout];
  [alert setAlertStyle:NSCriticalAlertStyle];
  int buttonClicked = [alert runModal];
  
  // Cleanup
  [m_task release];
  m_task = nil;
}

// -----------------------------------------------------------------------------
/// @brief Terminates the command process that is currently running.
///
/// This method does nothing if no command process is currently running.
// -----------------------------------------------------------------------------
- (void) terminate
{
  /// @todo protect this, is called from the GUI thread context
  m_terminated = true;
  if (m_task && [m_task isRunning])
    [m_task terminate];
}

// -----------------------------------------------------------------------------
/// @brief Returns whether the command process was forcefully terminated by
/// terminate:().
// -----------------------------------------------------------------------------
- (BOOL) terminated
{
  /// @todo protect this, is called from the AceXpanderThread context
  return m_terminated;
}

// -----------------------------------------------------------------------------
/// @brief Returns whether or not the command process is currently running.
// -----------------------------------------------------------------------------
- (BOOL) isRunning
{
  /// @todo protect this, is called from the GUI thread context
  if (m_task)
    return [m_task isRunning];
  else
    return false;
}

// -----------------------------------------------------------------------------
/// @brief Launches unace in a separate process to get information about the
/// executable's version.
///
/// @a unaceExecutablePath is the path to the unace binary that should be
/// queried for the version information.
///
/// @return a version string, or nil if something goes wrong
///
/// @note This is a class method.
// -----------------------------------------------------------------------------
+ (NSString*) unaceVersion:(NSString*)unaceExecutablePath
{
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

@end
