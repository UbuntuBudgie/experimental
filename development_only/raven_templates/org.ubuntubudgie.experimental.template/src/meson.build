TemplateWidgetSources = ['template.vala']

TemplateWidgetDependencies = [
    dependency('gtk+-3.0', version: '>=3.18'), 
    dependency('libpeas-gtk-1.0'),
    dependency('budgie-raven-plugin-1.0'),
    meson.get_compiler('c').find_library('m', required: false)
]

install_data('template.plugin', install_dir: LIB_INSTALL_DIR)

shared_library(meson.project_name(), TemplateWidgetSources, dependencies: TemplateWidgetDependencies, install: true, install_dir: LIB_INSTALL_DIR)