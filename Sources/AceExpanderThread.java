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
// AceExpanderThread.java
//
// This class is responsible for expanding a single archive. The full path
// of the archive file must be given on construction.
//
// This class encapsulates access to the unace binary included with the
// application as a resource.
//
// The archive expansion runs in its own thread separated from the main
// application. The expansion process is started by startExpansion().
// The method launches unace in a new process. It is synchronous, i.e. it
// waits for unace to complete.
//
// Once the expansion has finished, accessor methods can be used to query
// the process' exit value and the messages printed to stdout and stderr.

package ch.herzbube.aceexpander;

import com.apple.cocoa.foundation.*;
import com.apple.cocoa.application.*;

public class AceExpanderThread extends Thread
{
   // ======================================================================
   // Member variables
   // ======================================================================

   // Name of notification that is sent when thread has finished
   public static final String ExpandThreadHasFinishedNotification = "ExpandThreadHasFinished";

   public static final int EXPAND = 0;
   public static final int LIST = 1;
   public static final int TEST = 2;

   // Parameters for the unace frontend to turn on/off debug mode
   private static final String m_unaceFrontEndEnableDebug = "1";
   private static final String m_unaceFrontEndDisableDebug = "0";

   // Information about unace
   private static final String m_unaceFrontEnd = NSBundle.mainBundle().pathForResource("unace.sh", null);
   private static final String m_unaceBin = "unace";
   private static final String m_unacePath = NSPathUtilities.stringByDeletingLastPathComponent(m_unaceFrontEnd) + "/" + m_unaceBin;
   private static final String m_unaceCmdExtract = "e";
   private static final String m_unaceCmdExtractWithFullPath = "x";
   private static final String m_unaceCmdList = "l";
   private static final String m_unaceCmdListVerbosely = "v";
   private static final String m_unaceCmdTest = "t";
   private static final String m_unaceSwitchShowComments = "-c";
   private static final String m_unaceSwitchOverwriteFiles = "-o";
   private static final String m_unaceSwitchUsePassword = "-p";
   private static final String m_unaceSwitchAssumeYes = "-y";

   // The model
   private AceExpanderModel m_theModel = null;

   // The items to expand
   private NSMutableArray m_itemList = new NSMutableArray();

   // The command line arguments
   private String m_unaceFrontendDebugParameter = m_unaceFrontEndDisableDebug;
   private String m_unaceCommand = "";
   private NSMutableArray m_unaceSwitchList = new NSMutableArray();

   // The process
   private Process m_unaceProcess = null;

   // Results when process has finished
   // If process is interrupted by an exception, the exit value will
   // be set to -1.
   private int m_iExitValue = 0;
   private String m_messageStdout = "";
   private String m_messageStderr = "";

   // This flag indicates whether or not the thread is running
   private boolean m_bIsRunning = false;

   // This flag indicates whether or not the thread should stop running
   private boolean m_bStopRunning = false;

   // ======================================================================
   // Constructors
   // ======================================================================

   public AceExpanderThread(AceExpanderModel theModel)
   {
      m_theModel = theModel;
   }

   // ======================================================================
   // Methods for starting/stopping the thread
   // ======================================================================

   // Method re-implemented from base class Thread. This method is called
   // when the thread is started.
   public void run()
   {
      if (m_bIsRunning)   // overcautios - this should never happen
      {
         return;
      }
      m_bIsRunning = true;
      m_bStopRunning = false;

      java.util.Enumeration enumerator = m_itemList.objectEnumerator();
      while (enumerator.hasMoreElements())
      {
         AceExpanderItem item = (AceExpanderItem)enumerator.nextElement();

         // We need to check the state because it might be possible that
         // in the meantime the item has become non-QUEUED through the
         // user's actions
         if (AceExpanderItem.QUEUED != item.getState())
         {
            continue;
         }

         // Now start processing
         item.setState(AceExpanderItem.PROCESSING);
         expandItem(item);

         // The messages can be set in any case
         item.setMessageStdout(m_messageStdout);
         item.setMessageStderr(m_messageStderr);

         // Check if we need to stop the thread
         if (m_bStopRunning)
         {
            item.setState(AceExpanderItem.ABORTED);
            break;   // terminate the loop
         }
         else if (0 == m_iExitValue)
         {
            item.setState(AceExpanderItem.SUCCESS);
         }
         else
         {
            item.setState(AceExpanderItem.FAILURE);
         }
      }   // while (enumerator.hasMoreElements())

      m_bIsRunning = false;
      m_bStopRunning = false;

      // Notify any observers that this thread has terminated
      NSNotificationCenter.defaultCenter().postNotification(ExpandThreadHasFinishedNotification, null);
   }

   // Take actions to terminate the thread
   public void stopRunning()
   {
      // This will stop the next iteration in the run() method
      m_bStopRunning = true;

      // The thread waits for the process, so we need to kill the process
      // in order for the thread to be able to check on the m_bStopRunning
      // flag
      if (m_unaceProcess != null)
      {
         m_unaceProcess.destroy();
      }
   }

   // ======================================================================
   // Method for starting the expansion process
   // ======================================================================

   // Expand a single item/archive in a separate process. Wait for the
   // process to terminate.
   // If an exception occurs, m_iExitValue will be set to -1. Otherwise
   // it will be set to the exit value of the process.
   // In addition, as a result of this method, m_messageStdout and
   // m_messageStdErr will be set to the output of the process to
   // stdout and stderr.
   private void expandItem(AceExpanderItem item)
   {
      // Initialize members in case that process terminates abnormally
      m_messageStdout = "";
      m_messageStderr = "";
      m_iExitValue = -1;   // Assume that process will fail

      String fileName = item.getFileName();
      String archiveDir = NSPathUtilities.stringByDeletingLastPathComponent(fileName);
      // It is important that the command is built in a way that retains
      // any spaces in path names! Also, special care must be taken that
      // no empty strings are passed as arguments to unace because it is
      // confused by this and will try to expand an archive named ".ace"
      // (empty string followed by .ace)
      String[] command = new String[6 + m_unaceSwitchList.count()];
      command[0] = m_unaceFrontEnd;
      command[1] = m_unacePath;
      command[2] = archiveDir;
      command[3] = m_unaceFrontendDebugParameter;
      command[4] = m_unaceCommand;
      java.util.Enumeration enumerator = m_unaceSwitchList.objectEnumerator();
      int i = 5;
      while (enumerator.hasMoreElements())
      {
         command[i] = (String)enumerator.nextElement();
         i ++;
      }
      command[i] = fileName;
      
      try
      {
         // TODO: change working directory first so that the stuff that
         // gets un-archived by unace is placed in the right directory
         // If the process correctly inherits the working directory, we
         // can do without the shell front end and execute unace directly.
         m_unaceProcess = Runtime.getRuntime().exec(command);
         try
         {
            m_unaceProcess.waitFor();
            m_iExitValue = m_unaceProcess.exitValue();

            java.io.BufferedReader stdoutReader = new java.io.BufferedReader(new java.io.InputStreamReader(m_unaceProcess.getInputStream()));
            m_messageStdout = getMessageFromReader(stdoutReader);
            java.io.BufferedReader stderrReader = new java.io.BufferedReader(new java.io.InputStreamReader(m_unaceProcess.getErrorStream()));
            m_messageStderr = getMessageFromReader(stderrReader);
         }
         catch(java.lang.InterruptedException e)
         {
            System.out.println("Caught InterruptedException while waiting for process to terminate");
         }
      }
      catch(java.io.IOException e)
      {
         System.out.println("Caught IOException while executing process");
      }

      m_unaceProcess = null;
   }

   // ======================================================================
   // Methods
   // ======================================================================

   public void addItem(AceExpanderItem item)
   {
      m_itemList.addObject(item);
   }

   public void setArguments(int iCommand, boolean bOverwriteFiles,
                            boolean bExtractFullPath, boolean bAssumeYes,
                            boolean bShowComments, boolean bListVerbosely,
                            boolean bUsePassword, String password,
                            boolean bDebugMode)
   {
      m_unaceCommand = "";
      m_unaceSwitchList.removeAllObjects();
      
      switch (iCommand)
      {
         case EXPAND:
            if (bExtractFullPath)
            {
               m_unaceCommand = m_unaceCmdExtractWithFullPath;
            }
            else
            {
               m_unaceCommand = m_unaceCmdExtract;
            }
            break;
         case LIST:
            if (bListVerbosely)
            {
               m_unaceCommand = m_unaceCmdListVerbosely;
            }
            else
            {
               m_unaceCommand = m_unaceCmdList;
            }
            break;
         case TEST:
            m_unaceCommand = m_unaceCmdTest;
            break;
         default:
            // TODO throw exception
            return;
      }

      String switchString;

      switchString = m_unaceSwitchOverwriteFiles;
      if (bOverwriteFiles) { switchString += "+"; }
      else                 { switchString += "-"; }
      m_unaceSwitchList.addObject(switchString);
      
      switchString = m_unaceSwitchAssumeYes;
      if (bAssumeYes) { switchString += "+"; }
      else            { switchString += "-"; }
      m_unaceSwitchList.addObject(switchString);

      switchString = m_unaceSwitchShowComments;
      if (bShowComments) { switchString += "+"; }
      else               { switchString += "-"; }
      m_unaceSwitchList.addObject(switchString);

      if (bUsePassword)
      {
         switchString = m_unaceSwitchUsePassword + password;
         m_unaceSwitchList.addObject(switchString);
      }

      if (bDebugMode)
      {
         m_unaceFrontendDebugParameter = m_unaceFrontEndEnableDebug;
      }
      else
      {
         m_unaceFrontendDebugParameter = m_unaceFrontEndDisableDebug;
      }
   }

   private String getMessageFromReader(java.io.BufferedReader reader)
   {
      String line = "";
      StringBuffer buffer = new StringBuffer();

      try
      {
         line = reader.readLine();
         while (line != null)
         {
            System.out.println(line);
            buffer.append(line);
            buffer.append(System.getProperty("line.separator"));

            line = reader.readLine();
         }

         return buffer.toString();
      }
      catch (java.io.IOException e)
      {
         System.out.println("Caught IOException while reading from stream");
         return null;
      }
   }
}
