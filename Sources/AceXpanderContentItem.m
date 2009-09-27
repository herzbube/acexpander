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
// herzbube@herzbube.ch
// -----------------------------------------------------------------------------


// Project includes
#import "AceXpanderContentItem.h"
#import "AceXpanderGlobals.h"


/// @brief This category declares private methods for the AceXpanderContentItem
/// class.
@interface AceXpanderContentItem(Private)
- (id) init;
- (void) dealloc;
- (bool) parseContentLine:(NSString*)contentLine;
@end


@implementation AceXpanderContentItem

// -----------------------------------------------------------------------------
/// @brief This initializer always returns @e nil.
// -----------------------------------------------------------------------------
- (id) init
{
  // Invoke designated initializer, which will always return nil
  return [self initWithLine:nil];
}

// -----------------------------------------------------------------------------
/// @brief Initializes an AceXpanderContentItem object representing the archive
/// item described by @a contentLine.
///
/// If @a contentLine is @e nil, or cannot be properly parsed, the
/// AceXpanderContentItem cannot be initialized and this method returns @e nil.
///
/// @note This is the designated initializer of AceXpanderContentItem.
// -----------------------------------------------------------------------------
- (id) initWithLine:(NSString*)contentLine
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  else if (! contentLine)
  {
    [self release];
    return nil;
  }

  if (! [self parseContentLine:contentLine])
  {
    NSString* errorDescription = @"AceXpanderContentItem::parseContentLine:() returned an error.";
    [[NSNotificationCenter defaultCenter] postNotificationName:errorConditionOccurredNotification object:errorDescription];
    [self release];
    return nil;
  }

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this AceXpanderContentItem object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  if (m_date)
    [m_date autorelease];
  if (m_time)
    [m_time autorelease];
  if (m_packed)
    [m_packed autorelease];
  if (m_size)
    [m_size autorelease];
  if (m_ratio)
    [m_ratio autorelease];
  if (m_fileName)
    [m_fileName autorelease];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Tries to parse @a contentLine and set the attributes of this
/// AceXpanderContentItem with the resulting values.
///
/// This method works along the lines of "best effort", i.e. if @a contentLine
/// does not contain enough tokens/fields for all attributes of this
/// AceXpanderContentItem, this method tries to fill as many of them as
/// possible.
///
/// @note This is an internal helper method. It is called exactly once per
/// object, from initWithLine:().
///
/// @return true if parsing was successful, false if not
// -----------------------------------------------------------------------------
- (bool) parseContentLine:(NSString*)contentLine
{
  if (! contentLine)
    return false;

  m_passwordProtected = false;

  // Assume that tokens are separated by spaces
  NSEnumerator* enumerator = [[contentLine componentsSeparatedByString:@" "] objectEnumerator];
  int iFieldIndex = 0;
  id anObject;
  while (anObject = [enumerator nextObject])
  {
    NSString* token = (NSString*)anObject;
    // Assume that a zero-length token was produced as a result of two
    // consecutive spaces -> ignore it
    if ([token length] == 0)
      continue;
    switch (iFieldIndex)
    {
      case 0:
        m_date = [token retain];
        break;
      case 1:
        m_time = [token retain];
        break;
      case 2:
        m_packed = [token retain];
        break;
      case 3:
        m_size = [token retain];
        break;
      case 4:
        m_ratio = [token retain];
        break;
      case 5:
        m_fileName = [token retain];
        m_passwordProtected = [m_fileName hasPrefix:@"*"];
        break;
      default:
        // Should never happen
        return false;
    }
    iFieldIndex++;
  }

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Returns the "date" attribute of this AceXpanderContentItem.
// -----------------------------------------------------------------------------
- (NSString*) date
{
  if (m_date)
    return [[m_date retain] autorelease];
  else
    return nil;
}

// -----------------------------------------------------------------------------
/// @brief Returns the "time" attribute of this AceXpanderContentItem.
// -----------------------------------------------------------------------------
- (NSString*) time
{
  if (m_time)
    return [[m_time retain] autorelease];
  else
    return nil;
}

// -----------------------------------------------------------------------------
/// @brief Returns the "packed" attribute of this AceXpanderContentItem.
// -----------------------------------------------------------------------------
- (NSString*) packed
{
  if (m_packed)
    return [[m_packed retain] autorelease];
  else
    return nil;
}

// -----------------------------------------------------------------------------
/// @brief Returns the "size" attribute of this AceXpanderContentItem.
// -----------------------------------------------------------------------------
- (NSString*) size
{
  if (m_size)
    return [[m_size retain] autorelease];
  else
    return nil;
}

// -----------------------------------------------------------------------------
/// @brief Returns the "ratio" attribute of this AceXpanderContentItem.
// -----------------------------------------------------------------------------
- (NSString*) ratio
{
  if (m_ratio)
    return [[m_ratio retain] autorelease];
  else
    return nil;
}

// -----------------------------------------------------------------------------
/// @brief Returns the "file name" attribute of this AceXpanderContentItem.
// -----------------------------------------------------------------------------
- (NSString*) fileName
{
  if (m_fileName)
    return [[m_fileName retain] autorelease];
  else
    return nil;
}

// -----------------------------------------------------------------------------
/// @brief Returns whether this AceXpanderContentItem represents a password
/// protected archive item.
// -----------------------------------------------------------------------------
- (BOOL) passwordProtected
{
  return m_passwordProtected;
}


@end
