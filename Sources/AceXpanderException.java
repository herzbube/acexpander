//
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
//
// --------------------------------------------------------------------------------
//
// AceXpanderException.java
//
// This class represents an exception type specific to the AceXpander
// package. Since it is a sub-class of RuntimeException, methods can use
// it without having to declare a throws clause.
//

package ch.herzbube.acexpander;

public class AceXpanderException extends java.lang.RuntimeException
{
   // ======================================================================
   // Constructors
   // ======================================================================

   public AceXpanderException()
   {
      super();
   }

   public AceXpanderException(String message)
   {
      super(message);
   }
}
