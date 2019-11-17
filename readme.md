# UAD Hide and Seek Script

### Before running this script, save a detailed system profile to your desktop

* The `UADSystemProfile.txt` file is required to be exported to the desktop for this script to know for which plugins you have valid authorizations.

    ![image](https://user-images.githubusercontent.com/4521/69005051-c391d680-08e1-11ea-8cf7-d85fa5af8fac.png)
    
    **Note:** You should re-export this file each time you upgrade the UAD software as it'll have new plugins in the list that this script can operate on.


### Usage notes:

* The UAD plugins that this script alters are located in `/Library` so to move them around we need admin permissions.
  * That's why we have to use `sudo` and type your password.
* This script only operates on UAD plugins and their folders. It creates the necessary 'Unused' folders, and moves plugins from their main folders into the newly created 'Unused' folders.
* The script will optionally delete any existing 'Unused' folders (that the script created) each time it runs. 
  * This is to allow for the script to work well after a fresh install of the UAD software when all the plugins need to be moved to the 'Unused' folder again. Remember to re-export the `UADSystemProfile.txt` when you upgrade!
  * Without deleting the existing 'Unused' folders, the newly install plugins from a UAD software upgrade will not move properly because the script checks to see if a plugin already exists in the destination 'Unused' folder before moving it there.

### Downloading the script

1. Download a zip of this repo to your Downloads folder. See below.
    ![image](https://user-images.githubusercontent.com/4521/69011535-06c76600-0931-11ea-8d8b-1df3e5faa342.png)

1. With the mouse, double click the "UAD-Hide-And-Seek-Script-master.zip" file in your Downloads folder to unzip it.

### Running the script

1. Open `Terminal.app` from the `/Applications/Utilities` folder.
1. At the terminal, change into the unzipped folder called `UAD-Hide-And-Seek-Script-master` by executing the following command:

       cd ~/Downloads/UAD-Hide-And-Seek-Script-master
1. Now type: `sudo ruby uad-hide` and press the `tab` key.
1. If the terminal fills in the rest of the file name so the screen is showing `sudo ruby uad-hide-and-seek.rb` at the command prompt, then you're golden.
1. Press the `enter` key and the script will run, prompting for which folder to operate on:

       Which plugins do you want to alter? Type the number and press enter.
       1. UAD Console
       2. Pro Tools AAX
       3. VST Plugins
       4. VST Plugins (Mono)
       5. Audio Units Plugins

    Choose either `1` or `2` or `3` or `4` or `5` by typing that number at the command line and pressing the `enter` key.

**Notes:**
  * I'd recommend making the terminal window large so you can see the logging output and messages helping you along the way. Read all the output.
  * Also, I highly recommend opening up the folders that are being worked on in the finder so you can see the result of what the script did and verify that both folders exist and they have both the authorized and unauthorized plugins in them that you'd expect.
  * Remember - nothing magic is going on here. We're just automating the movement of some plugins from their main folder to a folder where the DAW or UAD Console doesn't know how to load them.


#### Reading your authorizations from the exported Detailed System Profile
The script will try to read the `UADSystemProfile.txt` file from your desktop. If it is unable to do so, it'll prompt you to create that file. See the first section of this Readme for tips on how to export that file to your desktop.

#### The 'Move All' test
If the `UADSystemProfile.txt` file can be read successfully, then the script asks if you want to try to test moving all of your plugins to the 'Unused' folder. I highly recommend opening up the directories in finder, and then trying this test. The script will attempt to go through the entire `UADSystemProfile.txt` file parsing the name out of each plugin and moving ALL of them to the 'Unused' folder. 

If this succeeds, the script will output which 1 to 5 UAD plugins should remain in the main plugin folder. Plugins like the `UAD Console Recall.vst` and `UAD CS-1.vst` aren't authorized or not (and aren't listed in the `UADSystemProfile.txt` file, so they aren't ever moved by this script), they are just part of the UAD system and are required to be in the main plugin folder for things to work properly. 

**Note:** If you have extra plugins not in the list that look like actual musical UAD plugins (the newly released Avalon 737, for example), then this script may need to be updated to account for newly released plugins. The prompts attempt to help you alter the script yourself to accomodate those new releases. Alternatively you can create an issue on this repo and I can take a look at updating the script.

#### Doing the actual move
Once the 'Move All' test is successful, you should do a little cleanup and then re-run the script to actually get things situated properly. To clean things up before the re-run:

1. Manually move all the plugins back from the 'Unused' folder to the main folder via drag and drop. **This is important** so that the script can re-run and move only the unauthorized plugins out.
    * Alternatively you can re-install the UAD software entirely to restore the plugins, but that's time consuming.
    * Protip: if you hold down the `Command` key when draging the group of plugins from the 'Unused' folder back to the main one, macOS will _move_ the files, instead of copying them. This is faster and cleaner, but optional. Copying back to the main folder will work just fine.
1. Optionally you can manually delete any of the 'Unused' folders that were created.
    * The script will also prompt to automatically delete the 'Unused' folders that is has created each time the script is run. Empty 'Unused' folders will also be recreated by the script as needed, so you don't have to manually create or delete them if you don't want to. However, if you like control over what is deleted, go ahead and perform this action manually.
1. Re-run the script. 
    * This time just hit enter to accept the default of not running the test (or type 'n' and enter) and the script will only move the _unauthorized_ plugins to the proper 'Unused' folder.

Re-run the script for each folder you want to alter!
