# Lapsey

Terrible name, I know, but a fun little weekend project in SwiftUI. My circle of friends got into Lapse recently, so naturally I thought it would be fun to reverse engineer and break!

Right now this is a super barebones proof of concept, honestly, the original app does a great job of handling all the hard stuff. This just sneaks around their uploading API to upload existing photos. Then it links to the official app to handle everything else!

Lots of credit goes to [lapsepy](https://github.com/quintindunn/lapsepy) for inspiring this project; though I ended up just intercepting most the requests myself, it was a good starting point for figuring out the API.

## Usage

You'll need a Mac and Xcode to build this. However, feel free to try and [sideload it](https://sidestore.io/) by using the .ipa file in the Releases section (doesn't exist yet). I promise I'm not malicious, but I totally get (and encourage) you compiling this yourself.

Feel free to open a PR to improve on my doubtlessly horrible Swift. Enjoy!
