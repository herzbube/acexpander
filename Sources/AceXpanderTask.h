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


// Cocoa
#import <Cocoa/Cocoa.h>

// Forward declarations
@class AceXpanderItem;


// -----------------------------------------------------------------------------
/// @brief The AceXpanderTask class is a wrapper for NSTask.
///
/// Each AceXpanderTask object is used only once. It executes an unace command
/// (i.e. expand, list, test) by launching a new system process (= task) that
/// executes the unace binary with the correct command line arguments.
///
/// After initializing, clients must configure an AceXpanderTask object by
/// invoking the various set...() methods. No particular order is necessary
/// when invoking these methods. After configuration is complete, clients may
/// invoke launch:() to execute the command.
///
/// @note The launch:() method of AceXpanderTask does not return until the
/// system process has finished. This is different from the launch:() method
/// provided by NSTask.
// -----------------------------------------------------------------------------
@interface AceXpanderTask : NSObject
{
@private
  /// @brief The task
  NSTask* m_task;

  /// @brief The command line arguments
  //@{
  NSString* m_unaceExecutablePath;
  NSString* m_destinationFolder;
  int m_command;
  NSString* m_unaceCommand;
  NSMutableArray* m_unaceSwitchList;
  AceXpanderItem* m_item;
  //@}

  /// @brief Is true if this task was terminated
  BOOL m_terminated;

  /// @brief This lock protects access to the m_terminated flag
  NSLock* m_terminatedLock;
  /// @brief This lock protects access to the member m_task
  NSLock* m_taskLock;
}

/// @name Initializers
//@{
- (id) init;
//@}

/// @name Task configuration
//@{
- (void) setUnaceExecutablePath:(NSString*)unaceExecutablePath;
- (void) setDestinationFolder:(NSString*)destinationFolder;
- (void) setUnaceCommand:(int)command commandSwitch:(NSString*)unaceCommand;
- (void) setUnaceSwitchList:(NSArray*)unaceSwitchList;
- (void) setItem:(AceXpanderItem*)item;
//@}

/// @name Start/stop task
//@{
- (void) launch;
- (void) terminate;
- (BOOL) isRunning;
+ (NSString*) unaceVersion:(NSString*)unaceExecutablePath;
//@}

@end
