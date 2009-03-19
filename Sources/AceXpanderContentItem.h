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


// -----------------------------------------------------------------------------
/// @brief The AceXpanderContentItem class represents one item inside an ACE
/// archive.
///
/// AceXpanderContentItem objects are created when an AceXpanderItem object is
/// processed by the "list" command of unace. The AceXpanderItem object parses
/// the output of the list command and creates one AceXpanderContentItem for
/// each line in the output that it identifies as an item in the ACE archive.
/// The following excerpt of a list command's output shows how such an item
/// line typically looks like:
///
/// @verbatim
/// Date    Time     Packed      Size  Ratio  File           
///
/// 17.06.03 03:30       10680     38617   27%  bibtex/abbrvdin.bst
/// 17.06.03 03:29        2096     43065    4%  *bibtex/alphadin.bst
/// [...]
/// @endverbatim
///
/// AceXpanderContentItem provides getter methods for each attribute of the
/// archive item. If an archive item's filename is prefixed with an asterisk
/// ("*"), the item is interpreted to be protected by a password.
///
/// An AceXpanderContentItem object exists as long as its associated
/// AceXpanderItem object exists, or until another list command processes the
/// associated AceXpanderItem.
///
/// @note AceXpanderContentItem objects are immutable, i.e. their content
/// cannot be changed after they are initialized.
// -----------------------------------------------------------------------------
@interface AceXpanderContentItem : NSObject
{
@private
  NSString* m_date;
  NSString* m_time;
  NSString* m_packed;
  NSString* m_size;
  NSString* m_ratio;
  NSString* m_fileName;
  BOOL m_passwordProtected;
}

/// @name Initializers
//@{
- (id) initWithLine:(NSString*)contentLine;
//@}

/// @name Accessors
//@{
- (NSString*) date;
- (NSString*) time;
- (NSString*) packed;
- (NSString*) size;
- (NSString*) ratio;
- (NSString*) fileName;
- (BOOL) passwordProtected;
//@}

@end
