require 'xcodeproj'

project_path = 'Aurora.xcodeproj'
project = Xcodeproj::Project.open(project_path)

widget_target = project.targets.find { |t| t.name == 'AuroraWidgetExtension' }
if widget_target.nil?
  puts "Widget target not found"
  exit 1
end

theme_file_ref = project.files.find { |f| f.path =~ /Theme\.swift$/ }
if theme_file_ref.nil?
  puts "Theme.swift not found"
  exit 1
end

unless widget_target.source_build_phase.files_references.include?(theme_file_ref)
  widget_target.source_build_phase.add_file_reference(theme_file_ref)
  project.save
  puts "Added Theme.swift to AuroraWidgetExtension"
else
  puts "Theme.swift is already in AuroraWidgetExtension"
end
