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
// AceExpanderPreferences.java
//
// This class is a mini-controller for the Preferences dialog. It is also
// responsible to set up defaults in the NSRegistration domain.
//

package ch.herzbube.aceexpander;

import com.apple.cocoa.foundation.*;
import com.apple.cocoa.application.*;

public class AceExpanderPreferences
{
   // ======================================================================
   // Member variables
   // ======================================================================

   // Constants
   private final static String RegistrationDomainDefaultsFileName = "RegistrationDomainDefaults.plist";
   private final static String PreferencesDialogNibName = "PreferencesDialog";
   // Keys for the defaults
   public final static String MainWindowFrameName = "MainWindow";
   public final static String QuitAppWhenMainWindowIsClosed = "QuitAppWhenMainWindowIsClosed";

   // The shared defaults object
   private NSUserDefaults m_userDefaults = null;

   // The preferences dialog
   private NSWindow m_preferencesDialog = null;

   // These variables are outlets and therefore initialized in the .nib
   private NSButton m_quitAppWhenMainWindowIsClosedButton;

   // Other variables
   private boolean m_bPreferencesDialogCancelClicked = false;

   // ======================================================================
   // Constructors
   // ======================================================================

   public AceExpanderPreferences()
   {
      // Stored in a member variable because it is frequently used
      m_userDefaults = NSUserDefaults.standardUserDefaults();
      loadDefaultsToRegistrationDomain();
   }

   // ======================================================================
   // Methods that manage opening/closing the preferences dialog
   // ======================================================================
   
   public void showPreferencesDialog()
   {
      NSApplication theApp = NSApplication.sharedApplication();
      // Load the .nib if not yet done. m_preferencesDialog is an outlet
      // and is set when the .nib is loaded.
      if (null == m_preferencesDialog)
      {
         theApp.loadNibNamed(PreferencesDialogNibName, this);
      }
      // Configure the GUI with values read from the defaults
      writeDefaultsToGUI();

      // Prepare and run the dialog. The sheet is attached to
      // m_mainWindow
      theApp.beginSheet(m_preferencesDialog, null, null, null, null);
      theApp.runModalForWindow(m_preferencesDialog);

      // -------------------------------------------------
      // --- At this point the modal dialog is running ---
      // -------------------------------------------------

      // Clean up and close the dialog
      theApp.endSheet(m_preferencesDialog);
      m_preferencesDialog.orderOut(this);   // remove dialog from screen
   }

   public void preferencesDialogOKClicked(Object sender)
   {
      readDefaultsFromGUI();
      m_bPreferencesDialogCancelClicked = false;
      NSApplication.sharedApplication().stopModal();
   }

   public void preferencesDialogCancelClicked(Object sender)
   {
      m_bPreferencesDialogCancelClicked = true;
      NSApplication.sharedApplication().stopModal();
   }
   
   // ======================================================================
   // Methods that are actions and therefore connected in the .nib.
   // ======================================================================

   // ======================================================================
   // Methods
   // ======================================================================

   // Read the defaults for the NSRegistration domain from a file
   // inside the application bundle
   private void loadDefaultsToRegistrationDomain()
   {
      NSBundle mainBundle = NSBundle.mainBundle();
      // TODO: check what happens if defaults are not there...
      java.io.File defaultsFile = new java.io.File(mainBundle.pathForResource(RegistrationDomainDefaultsFileName, null));
      NSData defaultsXMLData = new NSData(defaultsFile);
      Object defaultsObject = NSPropertyListSerialization.
         propertyListFromData(defaultsXMLData,
                              NSPropertyListSerialization.PropertyListImmutable,
                              null, null);
      // Did we get a valid property list?
      if (null == defaultsObject)
      {
         // TODO: throw an exception or do something
      }

      // Make sure that we got an NSMutableDictionary. I have not found
      // this documented anywhere in Apple's topics/examples/documentation.
      // The example by Apple only shows the way until we get the Object
      // result from the call to propertyListFromData()
      String defaultsObjectType = defaultsObject.getClass().getName();
      if ("com.apple.cocoa.foundation.NSMutableDictionary" == defaultsObjectType)
      {
         m_userDefaults.registerDefaults((NSMutableDictionary)defaultsObject);
      }
      else
      {
         // TODO: throw an exception or do something...
      }
   }

   // Set up the various GUI elements to reflect the current defaults
   private void writeDefaultsToGUI()
   {
      if (m_userDefaults.booleanForKey(QuitAppWhenMainWindowIsClosed))
         m_quitAppWhenMainWindowIsClosedButton.setState(NSCell.OnState);
      else
         m_quitAppWhenMainWindowIsClosedButton.setState(NSCell.OffState);
   }

   // Analyzes the state of the various GUI elements and sets the
   // appropriate defaults in the application domain.
   // Note: Defaults are only set if their new value is different from the
   // value already stored in the user defaults. The effect of this is
   // that if the user never changes a default's value from the value stored
   // in the NSRegistration domain, the default is never written to the
   // application domain. As soon as the user changes the default's value
   // for the first time, it is written to the application domain. It
   // remains there, even if the user changes its value back to the value
   // stored in the NSRegistration domain.
   private void readDefaultsFromGUI()
   {
      boolean bChecked;
      int iState = m_quitAppWhenMainWindowIsClosedButton.state();
      if (NSCell.OnState == iState)
         bChecked = true;
      else
         bChecked = false;
      System.out.println("bChecked = " + bChecked);
      System.out.println("defaults = " + m_userDefaults.booleanForKey(QuitAppWhenMainWindowIsClosed));
      if (bChecked != m_userDefaults.booleanForKey(QuitAppWhenMainWindowIsClosed))
      {
         m_userDefaults.setBooleanForKey(bChecked, QuitAppWhenMainWindowIsClosed);
      }
   }
}
