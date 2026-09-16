# Optional maintenance helper. The generated .xcodeproj is included; opening
# and building in Xcode does not require Ruby or the xcodeproj gem.
require 'xcodeproj'

root = File.expand_path('..', __dir__)
Dir.chdir(root)
project = Xcodeproj::Project.new('Seconds.xcodeproj')
config_group = project.main_group.new_group('Configuration', 'Configuration')
config = config_group.new_file('Project.xcconfig')

project.build_configurations.each do |configuration|
  configuration.base_configuration_reference = config
  configuration.build_settings.merge!({
    'SDKROOT' => 'iphoneos',
    'CLANG_ENABLE_MODULES' => 'YES',
    'SWIFT_VERSION' => '5.0',
    'IPHONEOS_DEPLOYMENT_TARGET' => '18.0'
  })
end

app = project.new_target(:application, 'Seconds', :ios, '18.0')
widget = project.new_target(:app_extension, 'SecondsWidget', :ios, '18.0')
tests = project.new_target(:unit_test_bundle, 'SecondsTests', :ios, '18.0')

def add_sources(project, directory, targets)
  group = project.main_group.new_group(directory, directory)
  Dir.glob("#{directory}/*").sort.each do |path|
    next if File.directory?(path)
    reference = group.new_file(File.basename(path))
    targets.each { |target| target.source_build_phase.add_file_reference(reference) } if path.end_with?('.swift')
  end
end

add_sources(project, 'Shared', [app, widget])
add_sources(project, 'Seconds', [app])
add_sources(project, 'SecondsWidget', [widget])
add_sources(project, 'SecondsTests', [tests])
assets = project.main_group['Seconds'].new_file('Assets.xcassets')
app.resources_build_phase.add_file_reference(assets)

[app, widget, tests].each do |target|
  target.build_configurations.each do |configuration|
    configuration.base_configuration_reference = config
    configuration.build_settings.merge!({
      'GENERATE_INFOPLIST_FILE' => 'YES',
      'TARGETED_DEVICE_FAMILY' => '1',
      'SWIFT_VERSION' => '5.0',
      'SUPPORTED_PLATFORMS' => 'iphoneos iphonesimulator',
      'SUPPORTS_MACCATALYST' => 'NO',
      'SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD' => 'NO',
      'CODE_SIGN_STYLE' => 'Automatic'
    })
  end
end

app.build_configurations.each do |configuration|
  configuration.build_settings.merge!({
    'PRODUCT_BUNDLE_IDENTIFIER' => '$(BUNDLE_ID_PREFIX)',
    'INFOPLIST_FILE' => 'Seconds/Info.plist',
    'INFOPLIST_KEY_CFBundleDisplayName' => 'Seconds',
    'CODE_SIGN_ENTITLEMENTS' => 'Seconds/Seconds.entitlements',
    'ENABLE_PREVIEWS' => 'YES',
    'ASSETCATALOG_COMPILER_APPICON_NAME' => 'AppIcon',
    'LD_RUNPATH_SEARCH_PATHS' => '$(inherited) @executable_path/Frameworks'
  })
end

widget.build_configurations.each do |configuration|
  configuration.build_settings.merge!({
    'PRODUCT_BUNDLE_IDENTIFIER' => '$(BUNDLE_ID_PREFIX).widget',
    'INFOPLIST_FILE' => 'SecondsWidget/Info.plist',
    'INFOPLIST_KEY_CFBundleDisplayName' => 'Seconds',
    'CODE_SIGN_ENTITLEMENTS' => 'SecondsWidget/SecondsWidget.entitlements',
    'APPLICATION_EXTENSION_API_ONLY' => 'YES',
    'SKIP_INSTALL' => 'YES',
    'ENABLE_PREVIEWS' => 'YES',
    'LD_RUNPATH_SEARCH_PATHS' => '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks'
  })
end

tests.build_configurations.each do |configuration|
  configuration.build_settings.merge!({
    'PRODUCT_BUNDLE_IDENTIFIER' => '$(BUNDLE_ID_PREFIX).tests',
    'TEST_HOST' => '$(BUILT_PRODUCTS_DIR)/Seconds.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Seconds',
    'BUNDLE_LOADER' => '$(TEST_HOST)'
  })
end

app.add_dependency(widget)
tests.add_dependency(app)
embed = app.new_copy_files_build_phase('Embed App Extensions')
embed.dst_subfolder_spec = '13'
embed.add_file_reference(widget.product_reference).settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }

project.root_object.attributes['TargetAttributes'] = {
  app.uuid => { 'SystemCapabilities' => { 'com.apple.ApplicationGroups.iOS' => { 'enabled' => 1 } } },
  widget.uuid => { 'SystemCapabilities' => { 'com.apple.ApplicationGroups.iOS' => { 'enabled' => 1 } } }
}
project.save

scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app)
scheme.add_test_target(tests)
scheme.set_launch_target(app)
scheme.save_as('Seconds.xcodeproj', 'Seconds', true)
