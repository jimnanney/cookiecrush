# -*- coding: utf-8 -*-
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project/template/ios'

begin
  require 'bundler'
  Bundler.require
rescue LoadError
end

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  app.name = 'cookiecrush'
  app.version = "0.0.1"
  app.device_family = [:ipad, :iphone]
  app.frameworks += ["SpriteKit", "AVFoundation"]
  app.interface_orientations = [:portrait, :landscape_left, :landscape_right, :portrait_upside_down]
end

desc "Run simulator on iPhone"
task :iphone4 do
    exec 'bundle exec rake device_name="iPhone 4s"'
end

desc "Run simulator on iPhone"
task :iphone5 do
    exec 'bundle exec rake device_name="iPhone 5"'
end

desc "Run simulator on iPhone"
task :iphone6 do
    exec 'bundle exec rake device_name="iPhone 6"'
end

desc "Run simulator in iPad Retina" 
task :retina do
    exec 'bundle exec rake device_name="iPad Retina"'
end

desc "Run simulator on iPad Air" 
task :ipad do
    exec 'bundle exec rake device_name="iPad Air"'
end
