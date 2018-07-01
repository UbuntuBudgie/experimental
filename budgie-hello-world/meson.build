project(
    'org.ubuntubudgie.applet.hello-world',
    ['c', 'vala'],
    version: '0.1.0',
    license: [
        'GPL-2.0'
    ],
    default_options: [
        'c_std=c11',
    ],
)

am_cflags = [
    '-fstack-protector',
    '-pedantic',
    '-Wstrict-prototypes',
    '-Wundef',
    '-Werror-implicit-function-declaration',
    '-Wformat',
    '-Wformat-security',
    '-Werror=format-security',
    '-Wconversion',
    '-Wunused-variable',
    '-Wunreachable-code',
    '-Wall',
    '-W',
]

add_global_arguments(am_cflags, language: 'c')
meson.add_install_script('meson_post_install.sh')

# Budgie needs a minimum 3.22 GNOME stack
gnome_minimum_version = '>= 3.22.0'

dep_gtk3 = dependency('gtk+-3.0', version: gnome_minimum_version)
dep_glib = dependency('glib-2.0', version: '>= 2.46.0')
dep_peas = dependency('libpeas-1.0', version: '>= 1.8.0')

# Global path variable
prefix = get_option('prefix')
libdir = join_paths(prefix, get_option('libdir'))
datadir = join_paths(prefix, get_option('datadir'))

PIXMAPS_DIR = join_paths(datadir, 'pixmaps')
PLUGINS_INSTALL_DIR = join_paths(prefix, libdir, 'budgie-desktop', 'plugins', meson.project_name())

subdir('src')
