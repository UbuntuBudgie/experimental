
custom_target('plugin-file-workspaces',
    input : 'HelloWorldApplet.plugin.in',
    output : 'HelloWorldApplet.plugin',
    command : ['cp', '@INPUT@', '@OUTPUT@'],
    install : true,
    install_dir: PLUGINS_INSTALL_DIR,
)

applet_budgie_hello_world_sources = [
    'HelloWorldPlugin.vala',
    'HelloWorldApplet.vala',
    'HelloWorldPopover.vala',
]

applet_budgie_hello_world_deps = [
    libplugin_vapi,
    dep_gtk3,
    dep_peas,
    link_libplugin,
]

shared_library(
    'budgiehelloworldapplet',
    applet_budgie_hello_world_sources,
    dependencies: applet_budgie_hello_world_deps,
    vala_args: [
        '--pkg', 'libpeas-1.0',
        '--pkg', 'gtk+-3.0',
    ],
    install: true,
    install_dir: PLUGINS_INSTALL_DIR,
)
