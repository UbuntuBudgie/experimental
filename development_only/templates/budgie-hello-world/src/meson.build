configurationData = configuration_data()
configurationData.set('PACKAGE_NAME', meson.project_name())
configurationData.set('LOCALE_DIR', LOCALE_DIR)
configure_file(input: 'config.h.in', output: 'config.h', configuration: configurationData)

install_data('HelloWorld.plugin', install_dir: LIB_INSTALL_DIR)

helloWorldSources = [
'HelloWorldApplet.vala', 
'widgets/HelloWorldPopover.vala'
]

helloWorldDependencies = [
dependency('gtk+-3.0', version: '>=3.18'), 
dependency('budgie-1.0', version: '>=2')
]

helloWorldValaArgs = [
'--pkg=config', 
'--vapidir=' + VAPI_DIR, 
'--target-glib=2.38', 
'--enable-deprecated'
]

helloWorldCArgs = [
'-include', 
'config.h'
]

shared_library('helloworld', helloWorldSources, dependencies: helloWorldDependencies, vala_args: helloWorldValaArgs, c_args: helloWorldCArgs, install: true, install_dir: LIB_INSTALL_DIR)