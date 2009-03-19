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
// AceExpanderContentItem.java
//
// Every object of this class represents one item inside an ACE archive.
// Objects of this class are created when the output of the list command
// of unace is parsed. Objects exist as long as the associated
// AceExpanderItem object exists, or until another list command is
// executed with the associated AceExpanderItem.
//

package ch.herzbube.aceexpander;

import com.apple.cocoa.foundation.*;
import com.apple.cocoa.application.*;


public class AceExpanderContentItem
{
   // ======================================================================
   // Member variables
   // ======================================================================

   // Constants
   public final static int FIELD_DATE = 1;
   public final static int FIELD_TIME = 2;
   public final static int FIELD_PACKED = 3;
   public final static int FIELD_SIZE = 4;
   public final static int FIELD_RATIO = 5;
   public final static int FIELD_FILENAME = 6;
   public final static int MAX_FIELDS = 6;

   // Content line which contains the still assembled attributes
   private String m_contentLine;
   // Attributes that are filled when the contentLine is parsed
   private String m_date;
   private String m_time;
   private String m_packed;
   private String m_size;
   private String m_ratio;
   private String m_fileName;

   // ======================================================================
   // Constructors
   // ======================================================================

   public AceExpanderContentItem() {}

   public AceExpanderContentItem(String contentLine)
   {
      if (! setAndParseContentLine(contentLine))
      {
         // TODO: throw an exception
      }
   }

   // ======================================================================
   // Accessor methods
   // ======================================================================

   public String getContentLine()
   {
      return m_contentLine;
   }
   // Setting the content line clears all attributes
   public void setContentLine(String contentLine)
   {
      m_contentLine = contentLine;
      clearAttributes();
   }
   
   public String getDate()
   {
      return m_date;
   }
   public void setDate(String date)
   {
      m_date = date;
   }

   public String getTime()
   {
      return m_time;
   }
   public void setTime(String time)
   {
      m_time = time;
   }

   public String getPacked()
   {
      return m_packed;
   }
   public void setPacked(String packed)
   {
      m_packed = packed;
   }

   public String getSize()
   {
      return m_size;
   }
   public void setSize(String size)
   {
      m_size = size;
   }

   public String getRatio()
   {
      return m_ratio;
   }
   public void setRatio(String ratio)
   {
      m_ratio = ratio;
   }

   public String getFileName()
   {
      return m_fileName;
   }
   public void setFileName(String fileName)
   {
      m_fileName = fileName;
   }

   // ======================================================================
   // Other methods
   // ======================================================================

   // Tries to parse the currently set content line into attributes that
   // this object can hold. Returns true for success, false if anything
   // goes wrong. Even if something unexpected happens, the method tries
   // to continue and fill as many attributes as possible.
   //
   // All attributes are cleared, even if the line to parse contains not
   // enough tokens/fields for all of them. After parsing has completed,
   // the individual attributes can be queried by their accessor methods.
   public boolean parseContentLine()
   {
      boolean bSuccess = true;   // we're optimistic

      java.util.StringTokenizer tokenizer = new java.util.StringTokenizer(m_contentLine);
      int iFieldIndex = 0;
      while (tokenizer.hasMoreElements())
      {
         iFieldIndex++;
         String token = (String)tokenizer.nextElement();
         
         switch (iFieldIndex)
         {
            case FIELD_DATE:
               m_date = token;
               break;
            case FIELD_TIME:
               m_time = token;
               break;
            case FIELD_PACKED:
               m_packed = token;
               break;
            case FIELD_SIZE:
               m_size = token;
               break;
            case FIELD_RATIO:
               m_ratio = token;
               break;
            case FIELD_FILENAME:
               m_fileName = token;
               break;
            default:
               // Should never happen
               bSuccess = false;
               break;
         }
      }

      return bSuccess;
   }

   // Convenience method that both sets and parses the given content line
   public boolean setAndParseContentLine(String contentLine)
   {
      setContentLine(contentLine);   // this also clears all attributes
      return parseContentLine();
   }

   // Clears all attributes, but leaves the contentLine untouched
   private void clearAttributes()
   {
      m_date = "";
      m_time = "";
      m_packed = "";
      m_size = "";
      m_ratio = "";
      m_fileName = "";
   }
}
