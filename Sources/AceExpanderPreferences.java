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
   public final static String BundledExecutablePath = "<bundled>";
   // Keys for the defaults
   public final static String MainWindowFrameName = "MainWindow";
   public final static String ResultWindowFrameName = "ResultWindow";
   public final static String QuitAppWhenMainWindowIsClosed = "QuitAppWhenMainWindowIsClosed";
   public final static String ShowResultWindow = "ShowResultWindow";
   public final static String ExecutablePath = "ExecutablePath";

   // The shared defaults object
   private NSUserDefaults m_userDefaults = null;

   // The preferences dialog
   private NSWindow m_preferencesDialog = null;

   // These variables are outlets and therefore initialized in the .nib
   private NSButton m_quitAppWhenMainWindowIsClosedButton;
   private NSPopUpButton m_setExecutablePathButton;

   // Other variables
   private boolean m_bPreferencesDialogCancelClicked = false;
   private String m_executablePath;   // Stores the entire path

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
   // Methods writing to/reading from the GUI
   // ======================================================================

   // Set up the various GUI elements to reflect the current defaults
   private void writeDefaultsToGUI()
   {
      // ------------------------------------------------------------
      // QuitAppWhenMainWindowIsClosed
      if (m_userDefaults.booleanForKey(QuitAppWhenMainWindowIsClosed))
         m_quitAppWhenMainWindowIsClosedButton.setState(NSCell.OnState);
      else
         m_quitAppWhenMainWindowIsClosedButton.setState(NSCell.OffState);

      // ------------------------------------------------------------
      // ExecutablePath
      m_executablePath = m_userDefaults.stringForKey(ExecutablePath);
      updateExecutablePathButton();
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
      // ------------------------------------------------------------
      // QuitAppWhenMainWindowIsClosed
      boolean bChecked;
      int iState = m_quitAppWhenMainWindowIsClosedButton.state();
      if (NSCell.OnState == iState)
         bChecked = true;
      else
         bChecked = false;
      if (bChecked != m_userDefaults.booleanForKey(QuitAppWhenMainWindowIsClosed))
      {
         m_userDefaults.setBooleanForKey(bChecked, QuitAppWhenMainWindowIsClosed);
      }

      // ------------------------------------------------------------
      // ExecutablePath
      // The full path is stored in m_executablePath, not the GUI)
      m_userDefaults.setObjectForKey(m_executablePath, ExecutablePath);
   }

   // ======================================================================
   // Methods that are actions, related to setting the executable
   // ======================================================================

   // Sets the executable path to a dummy default value which indicates
   // that the bundled version of unace will be used.
   public void setExecutableToBundled(Object sender)
   {
      m_executablePath = BundledExecutablePath;
      updateExecutablePathButton();
   }

   // Lets the user choose from an open panel which executable to use.
   public void setExecutableChooseLocation(Object sender)
   {
      NSOpenPanel openPanel = NSOpenPanel.openPanel();
      openPanel.setAllowsMultipleSelection(false);
      openPanel.setCanChooseDirectories(false);
      String directory = null;
      String selectedFile = null;
      NSArray fileTypes = null;
      int iResult = openPanel.runModalInDirectory(directory, selectedFile, fileTypes, m_preferencesDialog);
      if (NSPanel.OKButton == iResult)
      {
         // We trust the panel to return at least one item!
         m_executablePath = (String)openPanel.filenames().objectAtIndex(0);
      }

      // Update the button: the user's action selected a menu item -> this
      // must be undone even if the user clicked "cancel" on the open panel
      updateExecutablePathButton();
   }

   // No action, just a helper.
   // Updates the top-most menu item in the popup button, e.g. the menu
   // item that is visible when the button's popup menu is closed
   private void updateExecutablePathButton()
   {
      m_setExecutablePathButton.removeItemAtIndex(0);
      m_setExecutablePathButton.insertItemAtIndex(NSPathUtilities.lastPathComponent(m_executablePath), 0);
      m_setExecutablePathButton.selectItemAtIndex(0);
      // TODO: make it work! With this code, the image displayed when the
      // popup menu is closed is far too big!
      // NSMenuItem menuItem = m_setExecutablePathButton.itemAtIndex(0);
      // menuItem.setImage(new NSFileWrapper(m_executablePath, false).icon());
   }

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
}
