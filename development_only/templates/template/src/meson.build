configurationData = configuration_data()
configurationData.set('PACKAGE_NAME', meson.project_name())
configurationData.set('LOCALE_DIR', LOCALE_DIR)
configure_file(input: 'config.h.in', output: 'config.h', configuration: configurationData)

install_data('Template.plugin', install_dir: LIB_INSTALL_DIR)

TemplateSources = [
'TemplateApplet.vala'
]

TemplateDependencies = [
dependency('gtk+-3.0'), 
dependency('budgie-1.0'),
dependency('libpeas-gtk-1.0'),
meson.get_compiler('c').find_library('m', required: false)
]

TemplateValaArgs = [
'--pkg=config', 
'--vapidir=' + VAPI_DIR, 
'--target-glib=2.38',
]

TemplateCArgs = [
'-include', 
'config.h',
'-lm'
]

shared_library(
    'template', 
    TemplateSources, 
    dependencies: TemplateDependencies, 
    vala_args: TemplateValaArgs, 
    c_args: TemplateCArgs, 
    install: true, 
    install_dir: LIB_INSTALL_DIR
)




