#!/usr/bin/env ruby

FOLDER_PATH = File.expand_path(File.dirname(__FILE__))
`ln -sf #{File.join(FOLDER_PATH,"vfl2code.rb")} /usr/bin/`
`rm -rf ~/Library/Services/vfl2code.workflow`
`cp -r #{File.join(FOLDER_PATH,"/vfl2code.workflow")} ~/Library/Services/`

CODE_SNIPPET_PATH = "~/Library/Developer/Xcode/UserData/CodeSnippets"

`cp #{File.join(FOLDER_PATH,"vflobjc.codesnippet")} #{CODE_SNIPPET_PATH}`
`cp #{File.join(FOLDER_PATH,"vflswift.codesnippet")} #{CODE_SNIPPET_PATH}`

puts "Setup finished. Please restart Xcode."
