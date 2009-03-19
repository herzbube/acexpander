//
// AceExpander - a Mac OS X graphical user interface to the unace command line utility
//
// Copyright (C) 2004 Patrick NŠf
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
// aceexpander@herzbube.ch
//
// --------------------------------------------------------------------------------
//
// AceExpanderItem.java
//
// This class references an ACE archive in the file system and, at the same
// time, is represented in the application's GUI by a row in the table of
// archives.
//
// An item always has one of the following states:
//  - QUEUED: This is the initial state when the item is created. An item
//    may also re-enter this state if it was previously in state SKIP,
//    ABORTED, SUCCESS or FAILURE. When the item list is processed, every
//    item in the list that has this state is processed.
//  - SKIP: When the item list is processed, items with this state are
//    ignored
//  - PROCESSING: When the application starts processing an item, the
//    item is moved from being QUEUED to this state.
//  - ABORTED: When an item is in the state PROCESSING and the processing
//    is stopped forcefully, the item moves to this state
//  - SUCCESS: When the application finishes processing an item and it
//    was expanded successfully, the item moves to this state.
//  - FAILURE: as with SUCCESS, but an error occurred during processing
//

package ch.herzbube.aceexpander;

import com.apple.cocoa.foundation.*;
import com.apple.cocoa.application.*;

public class AceExpanderItem
{
   // ======================================================================
   // Member variables
   // ======================================================================

   public final static int QUEUED = 0;
   public final static int SKIP = 1;
   public final static int PROCESSING = 2;
   public final static int ABORTED = 3;
   public final static int SUCCESS = 4;
   public final static int FAILURE = 5;

   private AceExpanderModel m_theModel;
   private String m_fileName = "";
   private NSImage m_icon = null;
   private int m_iState = QUEUED;
   private String m_messageStdout = "";
   private String m_messageStderr = "";

   // ======================================================================
   // Constructors
   // ======================================================================

   public AceExpanderItem(String fileName, AceExpanderModel theModel)
   {
      m_fileName = fileName;
      UpdateIcon();

      // TODO: throw an exception when theModel is null
      m_theModel = theModel;
   }

   // ======================================================================
   // Accessor methods
   // ======================================================================

   public String getFileName()
   {
      return m_fileName;
   }

   public void setFilename(String fileName)
   {
      m_fileName = fileName;
      UpdateIcon();

      m_theModel.itemHasChanged(this);
   }

   public NSImage getIcon()
   {
      return m_icon;
   }

   public int getState()
   {
      return m_iState;
   }

   public String getStateAsString()
   {
      switch (m_iState)
      {
         case QUEUED:
            return "Queued";
         case SKIP:
            return "Skip";
         case PROCESSING:
            return "Processing";
         case ABORTED:
            return "Aborted";
         case SUCCESS:
            return "Success";
         case FAILURE:
            return "Failure";
         default:
            return "Undefined";
      }
   }

   public void setState(int iState)
   {
      if (QUEUED != iState && SKIP != iState && PROCESSING != iState
          && ABORTED != iState && SUCCESS != iState && FAILURE != iState)
      {
         // TODO: throw an exception
         return;
      }
      m_iState = iState;
      
      m_theModel.itemHasChanged(this);
   }

   public String getMessageStdout()
   {
      return m_messageStdout;
   }

   public void setMessageStdout(String messageStdout)
   {
      m_messageStdout = messageStdout;
   }

   public String getMessageStderr()
   {
      return m_messageStderr;
   }

   public void setMessageStderr(String messageStderr)
   {
      m_messageStderr = messageStderr;
   }

   // ======================================================================
   // Methods
   // ======================================================================

   // Fetch the icon for the currently set file name
   private void UpdateIcon()
   {
      // false = the wrapper is not for a symlink
      m_icon = new NSFileWrapper(m_fileName, false).icon();
   }
}
