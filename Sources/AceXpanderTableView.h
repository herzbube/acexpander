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
@class AceXpanderModel;


// -----------------------------------------------------------------------------
/// @brief The AceXpanderTableView class is subclassed from NSTableView only
/// for the sake of implementing the NSDraggingDestination protocol.
///
/// This protocol makes it possible for the user to drag&drop files into the
/// area of the table in the GUI.
///
/// An AceXpanderTableView is instantiated when the application's .nib file is
/// loaded. AceXpanderTableView implements the NSNibAwaking protocol so that
/// it can initialize itself correctly after .nib loading has finished.
///
/// @note Because AceXpanderTableView subclasses NSTableView, it is
/// initialized using initWithCoder:(). This is explained in the AppKit
/// documentation for awakeFromNib().
///
/// @todo Do we have to implement other initializers than initWithCoder:()
/// from base classes?
// -----------------------------------------------------------------------------
@interface AceXpanderTableView : NSTableView
{
@private
  /// @name Outlets
  /// @brief These variables are outlets and therefore initialized in the .nib
  //@{
  AceXpanderModel* m_theModel;
  //@}

  /// @brief Determines whether the table view should be displayed highlighted
  /// when the table view is drawn next (in order to indicate that the
  /// drag is accepted).
  BOOL m_highlight;
}

/// @name Initializers
//@{
- (id) initWithCoder:(NSCoder*)decoder;
//@}

@end
