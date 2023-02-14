DemoAppletSources = ['demo.vala', 'demo-dropdown.vala']

DemoAppletDependencies = [
    dependency('gtk+-3.0', version: '>=3.18'),
    dependency('libpeas-gtk-1.0'),
    dependency('budgie-raven-plugin-1.0'),
    meson.get_compiler('c').find_library('m', required: false)
]

install_data('demo.plugin', install_dir: LIB_INSTALL_DIR)

shared_library(meson.project_name(),
               DemoAppletSources,
               dependencies: DemoAppletDependencies,
               install: true, install_dir: LIB_INSTALL_DIR)