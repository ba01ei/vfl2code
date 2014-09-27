#!/usr/bin/env ruby

`ln -sf #{File.join(File.expand_path(File.dirname(__FILE__)),"vfl2code.rb")} /usr/bin/`
`rm -rf ~/Library/Services/vfl2code.workflow`
`cp -r #{File.expand_path(File.dirname(__FILE__))}/vfl2code.workflow ~/Library/Services/`
