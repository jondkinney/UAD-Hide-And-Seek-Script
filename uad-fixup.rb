#!/usr/bin/env ruby
require 'fileutils'
require 'etc'

PARENT_PATH = '/Library/Application Support/Universal Audio'
PLUGIN_DIR = 'UAD-2 Powered Plug-Ins'
UNUSED_PLUGIN_DIR = "#{PLUGIN_DIR} Unused"
PLUGIN_PATH = "#{PARENT_PATH}/#{PLUGIN_DIR}"
UNUSED_PLUGIN_PATH = "#{PARENT_PATH}/#{UNUSED_PLUGIN_DIR}"
FILES_NOT_FOUND = []

# Create the path for unused plugins if it doesn't already exist
FileUtils.mkdir_p(UNUSED_PLUGIN_PATH)

user_dir = Etc.getlogin
uad_system_profile_file = "/Users/#{user_dir}/Desktop/UADSystemProfile.txt"

puts "!!!!! Reading UAD System Profile file from: #{uad_system_profile_file}..."
puts ''

class String
  # remove non-whitespace chars and multi-spaces
  def squish
    self.tr("\r\n\t", ' ').gsub(/ {2,}/, ' ')
  end

  # pad string on the right before referencing directories for a cleaner look
  def fix(size, padstr=' ')
    self[0...size].ljust(size, padstr) #or rjust
  end
end

unless File.file?(uad_system_profile_file)
  puts ">>>>> 'UADSystemProfile.txt' file not found on desktop."

  msg = %(>>>>> Please click 'Save Detailed System Profile' from the UAD
  Control Panel app's "System Info" tab and save the file to your desktop,
  then re-run this script.).squish
  puts msg

  exit
end


# Open UADSystemProfile.txt file, read it into memory, and close the file
file_handle = open uad_system_profile_file
content = file_handle.read
file_handle.close


msg = %(If this is your first time using this script OR you upgraded to a new
version of the UAD Software and it contains new plugins, it's recommended to
re-export your UADSystemProfile.txt file, and run the 'Move All' test.).squish
puts msg
puts ''

msg = %(This test will ensure your regular plugin folder doesn't contain extra
plugins that this script doesn't know about.).squish
puts msg
puts ''

puts "More output will guide you once the test is finished. Run test now? (N/y)"

user_input = gets # prompt user for 'Move All' test.

if ['','n'].include?(user_input.chomp.downcase) # hitting enter accepts default of 'N'
  testing = false
else
  testing = true
end

puts '' unless user_input.chomp == '' # avoid unsightly extra line break if accepting the default by hitting enter without typing 'n'

if testing
  puts ">>>>> 'Move All' test initiated."
else
  puts ">>>>> Skipping 'Move All' test."
end

puts "!!!!! Beginning to move #{testing == true ? 'ALL KNOWN' : 'unauthorized'} plugins to '#{UNUSED_PLUGIN_PATH}'"
puts ''

unauthorized_plugs =
  content
    .split("UAD-2 Plug-in Authorizations").last.strip # Get the content of the UAD System Profile text dump AFTER the "UAD-2 Plug-in Authorizations" heading (this is the list of plugins) and strip the whitespace characters from the front and back of the multi-line string
    .split("\r\n") # split the string into an array on each newline
    .select{|a| a.match(/.*#{testing == true ? '' : 'Demo'}.*/)} # only select the plugins that are NOT authorized, which is indicated by having "Demo" after a colon, like so - "UAD Putnam Microphone Collection: Demo not started"
    .map{|a| a.split(":").first} # get the plugin name without the colon by splitting the string at the colon and taking the first half of the string
    .map{|a| "#{a}.vst"} # add the .vst extension to the plugin name which is recgonized as a folder on macOS
    .sort # order the list alphabetically (helped with testing)


def move_file(plugs)
  plugs.each do |plug|
    # Check if the plugin was already moved. Some collections include plugs
    # that can also be purchased one-off, so we need to account for that
    if File.exist?("#{UNUSED_PLUGIN_PATH}/#{plug}")
      puts "#{plug}".fix(55,'.') + " exists in '#{UNUSED_PLUGIN_DIR}' folder. Skipping..."
      next # display the warning, but don't attempt to move it again.
    end

    begin
      # Do the move (which is really a rename of the file in unix)
      FileUtils.mv("#{PLUGIN_PATH}/#{plug}", "#{UNUSED_PLUGIN_PATH}")
      puts "#{plug}".fix(55,'.') + " is unauthorized. Moving to '#{UNUSED_PLUGIN_DIR}' folder."
    rescue Errno::ENOENT
      # Add the not found file to our FILES_NOT_FOUND array to report on later
      FILES_NOT_FOUND << "#{PLUGIN_PATH}/#{plug}"
      puts ''
      puts "#{plug}".fix(55,'.') + " File not found: #{PLUGIN_PATH}/#{plug}"
      puts ''
    end
  end
end

unauthorized_plugs.each do |plug|
  plugs = []

  # Fix naming inconsistencies (I didn't think this list was going to be this big!)
  case plug
  when /UAD AKG BX 20 Spring Reverb.vst/
    plugs << "UAD AKG BX 20.vst"
  when /UAD AMS RMX16 Digital Reverb.vst/
    plugs << "UAD AMS RMX16.vst"
  when /UAD AMS RMX16 Expanded Digital Reverb.vst/
    plugs << "UAD AMS RMX16 Expanded.vst"
  when /UAD API 2500 Bus Compressor.vst/
    plugs << "UAD API 2500.vst"
  when /UAD API 500 EQ Collection.vst/
    plugs << "UAD API 550A.vst"
    plugs << "UAD API 560.vst"
  when /UAD Ampeg B15N Bass Amplifier.vst/
    plugs << "UAD Ampeg B15N.vst"
  when /UAD Ampeg SVT-3 Pro Bass Amplifier.vst/
    plugs << "UAD Ampeg SVT3Pro.vst"
  when /UAD Ampeg SVT-VR Bass Amplifier.vst/
    plugs << "UAD Ampeg SVTVR.vst"
  when /UAD Bermuda Triangle Distortion.vst/
    plugs << "UAD Bermuda Triangle.vst"
  when /UAD Cambridge EQ.vst/
    plugs << "UAD Cambridge.vst"
  when /UAD Chandler GAV19T Guitar Amplifier.vst/
    plugs << "UAD Chandler GAV19T.vst"
  when /UAD Chandler Limited Curve Bender EQ.vst/
    plugs << "UAD Chandler Limited Curve Bender.vst"
  when /UAD Dangerous BAX EQ Collection.vst/
    plugs << "UAD Dangerous BAX EQ Master.vst"
    plugs << "UAD Dangerous BAX EQ Mix.vst"
  when /UAD Diezel Herbert Amplifier.vst/
    plugs << "UAD Diezel Herbert.vst"
  when /UAD DreamVerb Room Modeler.vst/
    plugs << "UAD DreamVerb.vst"
  when /UAD ENGL 646 VS Guitar Amplifier.vst/
    plugs << "UAD ENGL E646 VS.vst"
  when /UAD ENGL 765 RT Guitar Amplifier.vst/
    plugs << "UAD ENGL E765 RT.vst"
  when /UAD ENGL Savage 120 Guitar Amplifier.vst/
    plugs << "UAD ENGL Savage 120.vst"
  when /UAD Eden WT800 Bass Amplifier.vst/
    plugs << "UAD Eden WT800.vst"
  when /UAD Empirical Labs EL8 Distressor Compressor.vst/
    plugs << "UAD Empirical Labs Distressor.vst"
  when /UAD Fender 55 Tweed Deluxe Amplifier.vst/
    plugs << "UAD Fender 55 Tweed Deluxe.vst"
  when /UAD Friedman Amplifiers Collection.vst/
    plugs << "UAD Friedman BE100.vst"
    plugs << "UAD Friedman DS40.vst"
  when /UAD Friedman Buxom Betty Amplifier.vst/
    plugs << "UAD Friedman Buxom Betty.vst"
  when /UAD Fuchs Overdrive Supreme 50 Amplifier.vst/
    plugs << "UAD Fuchs Overdrive Supreme 50.vst"
  when /UAD Fuchs Train II Guitar Amplifier.vst/
    plugs << "UAD Fuchs Train II.vst"
  when /UAD Gallien-Krueger 800RB Bass Amplifier.vst/
    plugs << "UAD Gallien Krueger 800RB.vst"
  when /UAD Harrison 32C EQ.vst/
    plugs << "UAD Harrison 32C.vst"
    plugs << "UAD Harrison 32C SE.vst"
  when /UAD Helios Type 69 Legacy EQ.vst/
    plugs << "UAD Helios Type 69 Legacy.vst"
  when /UAD Helios Type 69 Preamp and EQ Collection.vst/
    plugs << "UAD Helios Type 69.vst"
  when /UAD Ibanez Tube Screamer TS808 Overdrive.vst/
    plugs << "UAD Ibanez Tube Screamer TS808.vst"
  when /UAD Korg SDD-3000 Digital Delay.vst/
    plugs << "UAD Korg SDD-3000.vst"
  when /UAD Lexicon 480L Digital Reverb and Effects.vst/
    plugs << "UAD Lexicon 480L.vst"
  when /UAD Little Labs IBP Phase Alignment.vst/
    plugs << "UAD Little Labs IBP.vst"
  when /UAD Maag EQ4 EQ.vst/
    plugs << "UAD Maag EQ4.vst"
  when /UAD Manley VOXBOX Channel Strip.vst/
    plugs << "UAD Manley VOXBOX.vst"
  when /UAD Manley Variable Mu Limiter.vst/
    plugs << "UAD Manley Variable Mu.vst"
  when /UAD Marshall Bluesbreaker 1962 Amplifier.vst/
    plugs << "UAD Marshall Bluesbreaker 1962.vst"
  when /UAD Marshall JMP 2203 Amplifier.vst/
    plugs << "UAD Marshall JMP 2203.vst"
  when /UAD Marshall Plexi Super Lead 1959 Amplifier.vst/
    plugs << "UAD Marshall Plexi Super Lead 1959.vst"
  when /UAD Marshall Silver Jubilee 2555 Amplifier.vst/
    plugs << "UAD Marshall Silver Jubilee 2555.vst"
  when /UAD Massenburg DesignWorks MDWEQ5 EQ.vst/
    plugs << "UAD MDWEQ5-3B.vst"
    plugs << "UAD MDWEQ5-5B.vst"
  when /UAD Millennia NSEQ-2 EQ.vst/
    plugs << "UAD Millennia NSEQ-2.vst"
  when /UAD Moog Multimode Filter Collection.vst/
    plugs << "UAD Moog Multimode Filter SE.vst"
    plugs << "UAD Moog Multimode Filter XL.vst"
    plugs << "UAD Moog Multimode Filter.vst"
  when /UAD Moog Multimode Legacy Filter.vst/
    plugs << "UAD Moog Multimode Filter.vst"
  when /UAD Neve 1073 Legacy EQ.vst/
    plugs << "UAD Neve 1073 Legacy.vst"
  when /UAD Neve 1073 Preamp and EQ Collection.vst/
    plugs << "UAD Neve 1073.vst"
    plugs << "UAD Neve 1073SE Legacy.vst"
  when /UAD Neve 1081 EQ.vst/
    plugs << "UAD Neve 1081.vst"
    plugs << "UAD Neve 1081SE.vst"
  when /UAD Neve 31102 EQ.vst/
    plugs << "UAD Neve 31102.vst"
    plugs << "UAD Neve 31102SE.vst"
  when /UAD Neve 88RS Channel Strip Collection.vst/
    plugs << "UAD Neve 88RS.vst"
    plugs << "UAD Neve 88RS Legacy.vst"
  when /UAD OTO Biscuit 8-bit Filter Effects.vst/
    plugs << "UAD OTO Biscuit 8-bit Effects.vst"
  when /UAD Ocean Way Microphone Collection.vst/
    plugs << "UAD Ocean Way Mic Collection.vst"
    plugs << "UAD Ocean Way Mic Collection 180.vst"
  when /UAD Oxford Envolution Envelope Shaper.vst/
    plugs << "UAD Oxford Envolution.vst"
  when /UAD Oxford Limiter V2.vst/
    plugs << "UAD Oxford Limiter.vst"
  when /UAD Oxide Tape Recorder.vst/
    plugs << "UAD Oxide Tape.vst"
  when /UAD Pure Plate Reverb.vst/
    plugs << "UAD Pure Plate.vst"
  when /UAD Putnam Microphone Collection.vst/
    plugs << "UAD Putnam Mic Collection.vst"
    plugs << "UAD Putnam Mic Collection 180.vst"
  when /UAD SPL TwinTube Saturation.vst/
    plugs << "UAD SPL TwinTube.vst"
  when /UAD SSL 4000 E Channel Strip Collection.vst/
    plugs << "UAD SSL E Channel Strip.vst"
  when /UAD SSL 4000 E Legacy Channel Strip.vst/
    plugs << "UAD SSL E Channel Strip Legacy.vst"
  when /UAD SSL 4000 G Bus Compressor Collection.vst/
    plugs << "UAD SSL G Bus Compressor.vst"
  when /UAD SSL 4000 G Legacy Bus Compressor.vst/
    plugs << "UAD SSL G Bus Compressor Legacy.vst"
  when /UAD Suhr PT100 Amplifier.vst/
    plugs << "UAD Suhr PT100.vst"
  when /UAD Suhr SE100 Amplifier.vst/
    plugs << "UAD Suhr SE100.vst"
  when /UAD Summit Audio TLA-100A Compressor.vst/
    plugs << "UAD Summit Audio TLA-100A.vst"
  when /UAD Thermionic Culture Vulture Distortion.vst/
    plugs << "UAD Thermionic Culture Vulture.vst"
  when /UAD Tonelux Tilt EQ.vst/
    plugs << "UAD Tonelux Tilt.vst"
    plugs << "UAD Tonelux Tilt Live.vst"
  when /UAD Townsend Labs Sphere Mic Modeler.vst/
    plugs << "UAD Townsend Labs Sphere.vst"
    plugs << "UAD Townsend Labs Sphere 180.vst"
  when /UAD Trident A-Range EQ.vst/
    plugs << "UAD Trident A-Range.vst"
  when /UAD Tube-Tech CL 1B Compressor.vst/
    plugs << "UAD Tube-Tech CL 1B.vst"
  when /UAD Tube-Tech EQ Collection.vst/
    plugs << "UAD Tube-Tech ME 1B.vst"
    plugs << "UAD Tube-Tech PE 1C.vst"
  when /UAD UA 175B and 176 Tube Compressor Collection.vst/
    plugs << "UAD UA 175-B.vst"
    plugs << "UAD UA 176.vst"
  when /UAD UA 610-A Tube Preamp and EQ.vst/
    plugs << "UAD UA 610-A.vst"
  when /UAD Valley People Dyna-mite Dynamics.vst/
    plugs << "UAD Valley People Dyna-mite.vst"
  when /UAD Vertigo VSC-2 Compressor.vst/
    plugs << "UAD Vertigo VSC-2.vst"
  when /UAD Vertigo VSM-3 Saturator.vst/
    plugs << "UAD Vertigo VSM-3.vst"
  when /UAD bx_digital V2 EQ.vst/
    plugs << "UAD bx_digital V2.vst"
    plugs << "UAD bx_digital V2 Mono.vst"
  when /UAD bx_digital V3 EQ Collection.vst/
    plugs << "UAD bx_digital V3.vst"
    plugs << "UAD bx_digital V3 mix.vst"
  when /UAD bx_subsynth Subharmonic Synth.vst/
    plugs << "UAD bx_subsynth.vst"
  when /UAD elysia alpha compressor.vst/
    plugs << "UAD elysia alpha master.vst"
    plugs << "UAD elysia alpha mix.vst"
  when /UAD Ampeg SVT-VR Classic Bass Amplifier.vst/
    plugs << "UAD Ampeg SVTVR Classic.vst"
  when /UAD Ampex ATR-102 Tape Recorder.vst/
    plugs << "UAD Ampex ATR-102.vst"
  when /UAD Cooper Time Cube Delay.vst/
    plugs << "UAD Cooper Time Cube.vst"
  when /UAD EMT 140 Plate Reverb.vst/
    plugs << "UAD EMT 140.vst"
  when /UAD EMT 250 Digital Reverb.vst/
    plugs << "UAD EMT 250.vst"
  when /UAD Empirical Labs EL7 FATSO Compressor.vst/
    plugs << "UAD Empirical Labs FATSO Jr.vst"
    plugs << "UAD Empirical Labs FATSO Sr.vst"
  when /UAD Fairchild 670 Legacy Limiter.vst/
    plugs << "UAD Fairchild 670 Legacy.vst"
  when /UAD Fairchild Tube Limiter Collection.vst/
    plugs << "UAD Fairchild 660.vst"
    plugs << "UAD Fairchild 670.vst"
  when /UAD Lexicon 224 Digital Reverb.vst/
    plugs << "UAD Lexicon 224.vst"
  when /UAD Little Labs VOG Bass Enhancer.vst/
    plugs << "UAD Little Labs VOG.vst"
  when /UAD Manley Massive Passive EQ Collection.vst/
    plugs << "UAD Manley Massive Passive.vst"
    plugs << "UAD Manley Massive Passive MST.vst"
  when /UAD Marshall Plexi Classic Amplifier.vst/
    plugs << "UAD Marshall Plexi Classic.vst"
  when /UAD Neve 33609 Compressor.vst/
    plugs << "UAD Neve 33609.vst"
    plugs << "UAD Neve 33609SE.vst"
  when /UAD Neve 88RS Legacy Channel Strip.vst/
    plugs << "UAD Neve 88RS Legacy.vst"
  when /UAD Ocean Way Studios Room Modeler.vst/
    plugs << "UAD Ocean Way Studios.vst"
  when /UAD Precision K-Stereo Ambience Recovery.vst/
    plugs << "UAD Precision K-Stereo.vst"
  when /UAD Precision Mix Rack Collection.vst/
    plugs << "UAD Precision Channel Strip.vst"
    plugs << "UAD Precision Reflection Engine.vst"
    plugs << "UAD Precision Delay Mod.vst"
    plugs << "UAD Precision Delay Mod L.vst"
  when /UAD Precision Multiband Compressor.vst/
    plugs << "UAD Precision Multiband.vst"
  when /UAD Pultec EQP-1A Legacy EQ.vst/
    plugs << "UAD Pultec EQP-1A Legacy.vst"
  when /UAD Pultec Passive EQ Collection.vst/
    plugs << "UAD Pultec EQP-1A.vst"
    plugs << "UAD Pultec HLF-3C.vst"
    plugs << "UAD Pultec MEQ-5.vst"
  when /UAD Pultec-Pro Legacy EQ.vst/
    plugs << "UAD Pultec-Pro Legacy.vst"
  when /UAD Raw Distortion.vst/
    plugs << "UAD Raw.vst"
  when /UAD RealVerb-Pro Room Modeler.vst/
    plugs << "UAD RealVerb-Pro.vst"
  when /UAD Roland CE-1 Chorus.vst/
    plugs << "UAD Roland CE-1.vst"
  when /UAD Roland Dimension D Chorus.vst/
    plugs << "UAD Roland Dimension D.vst"
  when /UAD Roland RE-201 Tape Delay.vst/
    plugs << "UAD Roland RE-201.vst"
  when /UAD Studer A800 Tape Recorder.vst/
    plugs << "UAD Studer A800.vst"
  when /UAD Teletronix LA-2A Legacy Leveler.vst/
    plugs << "UAD Teletronix LA-2A Legacy.vst"
  when /UAD Teletronix LA-2A Leveler Collection.vst/
    plugs << "UAD Teletronix LA-2.vst"
    plugs << "UAD Teletronix LA-2A Gray.vst"
    plugs << "UAD Teletronix LA-2A Silver.vst"
  when /UAD Teletronix LA-3A Leveler.vst/
    plugs << "UAD LA3A.vst"
  when /UAD UA 1176 Limiter Collection.vst/
    plugs << "UAD UA 1176 Rev A.vst"
    plugs << "UAD UA 1176LN Rev E.vst"
    plugs << "UAD UA 1176AE.vst"
  when /UAD UA 1176LN Legacy Limiter.vst/
    plugs << "UAD UA 1176LN Legacy.vst"
  when /UAD UA 1176SE Legacy Limiter.vst/
    plugs << "UAD UA 1176SE Legacy.vst"
  when /UAD UA 610-B Tube Preamp and EQ.vst/
    plugs << "UAD UA 610-B.vst"
  when /UAD dbx 160 Compressor.vst/
    plugs << "UAD dbx 160.vst"
  when /UAD UAD Avalon VT-737sp Channel Strip.vst/
    plugs << "UAD Avalon VT-737sp.vst"
  when /UAD Diezel VH4 Amplifier.vst/
    plugs << "UAD Diezel VH4.vst"
  # when /UAD Plugin Name From UADSystemProfile.txt file.vst/
  #   plugs << "UAD Name Here As It Appears In The Plugin Folder.vst"

    # Add more when statements above ☝️  as new plugins are released. Ensure to
    # add .vst to the plugin name referenced in the UADSystemProfile.txt file
  else
    # Keep the name the same, they didn't change it between the name in the
    # UADSystemProfile.txt file and the plugin in the plugins folder.
    plugs << plug
  end

  # do the actual work to move the file(s)
  move_file(plugs)
end

if testing == true
  puts ''
  puts "Finished moving ALL KNOWN plugins to '#{UNUSED_PLUGIN_PATH}'"

  puts ''
  puts "Your '#{PLUGIN_PATH}' Directory should only contain the following required stock plugins:"
  puts ''

  puts "  UAD CS-1.vst"
  puts "  UAD Input Strip Header.vst"
  puts "  UAD Internal.vst"
  puts "  UAD Mic Input Strip Header.vst"
  puts "  UAD Talkback Input Strip Header.vst"

  puts ''
  msg = %(If it contains additional plugins, please update this script to be
  aware of the newly released plugins and then re-run it until the list
  matches.).squish
  puts msg
  puts ''

  msg = %(Once the 'Move All' test is successful in moving all non-stock
  plugins without any "File not found" errors, manually open the 'Unused'
  plugins folder, drag all plugins back to the regular plugin folder, and
  re-run this script to move only your unauthorized plugins to the 'Unused'
  folder by choosing 'N' when prompted to run the 'Move All' test.).squish
  puts msg
  puts ''

  msg = %(Alternatively, if you aren't able to update the script, you can still
  run it and then manually manage the remaining newly released plugins by
  moving the plugin files between the regular and 'Unused' plugin folders
  referenced in this script.).squish
  puts msg
end

if FILES_NOT_FOUND.length > 0
  puts ''
  puts "The following files were not found:"
  puts "-----------------------------------"
  puts FILES_NOT_FOUND.join("\n")
  puts ''
  msg = %(To fix these "File not found" errors, add an additional 'when' entry
  to the case statement. This translates the plugin name from your
  UADSystemProfile.txt file to what exists in your '#{PLUGIN_PATH}' folder.
  These changes are usually as simple as removing words like 'EQ' or 'Channel
  Strip' or 'Amplifier' or 'Compressor' from the end of the name.).squish
  puts msg
  puts ''

  msg = %(This is quite easy and there are many examples in the script. When
  the Avalon VT-737sp was released, I had to add translations for it to the end of
  the case statement after the UAD dbx 160 lines that looked like this:).squish
  puts msg
  puts ''

  puts %(when /UAD dbx 160 Compressor.vst/
  plugs << "UAD dbx 160.vst")
  puts ''

  puts 'I added these Avalon lines below the dbx lines shown above.'
  puts ''

  msg = %(when /UAD UAD Avalon VT-737sp Channel Strip.vst/
  plugs << "UAD Avalon VT-737sp.vst")
  puts msg
end
