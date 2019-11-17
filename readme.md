# UAD Hide and Seek Script

### Before running this script, save a detailed system profile to your Desktop



### Usage notes:

  * The plugins that this script alters are located in `/Library` so to move them around we need admin permissions.
  * That's why we have to use `sudo` and type your password.
  * This script only operates on plugins, and doesn't delete any files, it only created the necessary "unused" directories, and moves plugins into them.
  * The UADSystemProfile.txt file is required to be exported from


### Running the script

Run the script with the following command:

```
$ ruby uad-hide-and-seek.rb
```

This will prompt for which folder you want to operate on:

```
Which plugins do you want to alter? Type the number and press enter.
1. UAD Console
2. Pro Tools AAX
3. VST Plugins
4. VST Plugins (Mono)
5. Audio Units Plugins
```

Choose either 1 or 2 or 3 or 4 or 5 by typing that number and pressing enter.

#### Reading your authorizations from the UADSystemProfile.txt file
The script will try to read the UADSystemProfile.txt file from your desktop. If it is unable to do so, it'll prompt you to create that file.

#### 'Move All' test
If the UADSystemProfile.txt file can be read successfully, then the script asks if you want to try to test moving all of your plugins to the 'Unused' folder. I highly recommend opening up the directories in finder, and then trying this test. The script will output which UAD plugins should remain in each folder. If you have other extra ones, then this script may need to be updated to account for newly released plugins.

#### Doing the actual move
Once the test is successful, you can move all the plugins back from the 'Unused' folder to the main folder and re-run the script. This time just hit enter or type 'n' when it prompts to run the test, and the script will only move the unauthorized plugins to the 'Unused' folder.

Re-run the script for each folder you want to alter.
