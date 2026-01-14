
project('org.ubuntubudgie.experimental.template',
        ['vala', 'c'],
        version: '0.1.0',
        meson_version: '>=0.57.0',
        license: 'GPL3')

gnome = import('gnome')

# Global path variable
prefix = get_option('prefix')
libdir = join_paths(prefix, get_option('libdir'))
datadir = join_paths(prefix, get_option('datadir'))

PIXMAPS_DIR = join_paths(datadir, 'pixmaps')
SCHEMA_DIR = join_paths(get_option('datadir'), 'glib-2.0', 'schemas')

budgie_version = get_option('budgie-version')

# -Dbudgie-version option limits to 3.0 / 2.0 / 1.0
if budgie_version == '3.0'
        # 10.10.x
        peas_dep = dependency('libpeas-2')
        raven_dep = dependency('budgie-raven-plugin-3.0')
elif budgie_version == '2.0'
        # 10.9.4
        peas_dep = dependency('libpeas-2')
        raven_dep = dependency('budgie-raven-plugin-2.0')
else
        # 10.9.3 and earlier
        peas_dep = dependency('libpeas-1.0')
        raven_dep = dependency('budgie-raven-plugin-1.0')
endif

LIB_INSTALL_DIR = join_paths(prefix, libdir, 'budgie-desktop', 'raven-plugins', meson.project_name())

subdir('src')
subdir('icons')
subdir('schemas')

message('Installing applet...')
gnome.post_install(glib_compile_schemas: true)
