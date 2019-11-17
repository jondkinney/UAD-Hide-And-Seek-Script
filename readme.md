# UAD Hide and Seek Script

### Before running this script, save a detailed system profile to your Desktop

![image](https://user-images.githubusercontent.com/4521/69005051-c391d680-08e1-11ea-8cf7-d85fa5af8fac.png)

### Usage notes:

  * The plugins that this script alters are located in `/Library` so to move them around we need admin permissions.
  * That's why we have to use `sudo` and type your password.
  * This script only operates on plugins and their directories, it creates the necessary "unused" directories, and moves plugins into them.
  * The script will optionally delete an existing 'Unused' folder before re-running. This is to allow for the script to work well after a fresh install of the UAD software when all the plugins need to be moved to the 'Unused' folder again. Without deleting the existing 'Unused' directory, the plugins will not move because the script checks to see if a plugin already exists in the destination folder before moving it there.
  * The `UADSystemProfile.txt` file is required to be exported to the Desktop for this script to know for which plugins you have valid authorizations.


### Downloading the script

1. Download a zip of this repo to your Downloads folder. See below.
1. With the mouse, double click the "UAD-Hide-And-Seek-Script-master.zip" file to unzip it.

![image](https://user-images.githubusercontent.com/4521/69011321-05953980-092f-11ea-86c7-b93bc43e199c.png)

### Running the script

1. Open `Terminal.app` from the `/Applications/Utilities` folder.
1. At the terminal, change into the unzipped folder called `UAD-Hide-And-Seek-Script-master` by executing the following command (without quotes):
    cd ~/Downloads/UAD-Hide-And-Seek-Script-master
1. Now type: `sudo ruby uad-hide` (without quotes)
1. Press the `tab` key
1. If the terminal fills in the rest of the file name so the screen is showing `ruby uad-hide-and-seek.rb` at the command prompt, then you're golden.
1. Press enter and the script will run, prompting for which folder to operate on:

```
Which plugins do you want to alter? Type the number and press enter.
1. UAD Console
2. Pro Tools AAX
3. VST Plugins
4. VST Plugins (Mono)
5. Audio Units Plugins
```

Choose either 1 or 2 or 3 or 4 or 5 by typing that number at the command line and pressing enter.

**Notes:**
  * I'd recommend making the terminal window large so you can see the logging output and messages helping you along the way. Read all the output.
  * Also, I highly recommend opening up the folders that are being worked on in the finder so you can see the result of what the script did and verify that both folders exist and they have both the authorized and unauthorized plugins in them that you'd expect.
  * Remember - nothing magic is going on here. We're just automating the movement of some plugs from their main folder to a folder where the DAW or UAD Console doesn't know how to load them.


#### Reading your authorizations from the UADSystemProfile.txt file
The script will try to read the UADSystemProfile.txt file from your desktop. If it is unable to do so, it'll prompt you to create that file.

#### The 'Move All' test
If the UADSystemProfile.txt file can be read successfully, then the script asks if you want to try to test moving all of your plugins to the 'Unused' folder. I highly recommend opening up the directories in finder, and then trying this test. The script will attempt to go through the entire UADSystemProfile.txt file parsing the name out of each plugin and moving ALL of them to the 'Unused' folder. If this succeeds, the script will output which 1-5 UAD plugins should remain in the main plugin folder. Plugs like `UAD Console Recall.vst` and `UAD CS-1.vst` aren't authorized or not, they are just part of the UAD system and are required to be in the main plugin folder for things to work properly. If you have extra plugins not in the list, then this script may need to be updated to account for newly released plugins.

#### Doing the actual move
Once the test is successful, you should do a little cleanup and then re-run it for real. 

1. Manually move all the plugins back from the 'Unused' folder to the main folder via drag and drop. **This is important!** Alternatively you can re-install the UAD software entirely to restore the plugins, but that's timeconsuling and a pain.
1. Optionally you can manually delete any of the 'Unused' folders that were created (the script will also prompt to automatically delete them each time it's run, and the empty 'Unused' folders will also be recreated by the script as needed, so you don't have to manually delete them if you don't want to).
1. Re-run the script. 
    * This time just hit enter to accept the default of not running the test (or type 'n' and enter) and the script will only move the _unauthorized_ plugins to the proper 'Unused' folder.

Re-run the script for each folder you want to alter!
