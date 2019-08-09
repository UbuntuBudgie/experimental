project(
  'previews',
  ['vala', 'c'],
  version: '0.1',
  license: 'GPL3+',
  meson_version: '>= 0.40.0'
)


application_id = 'budgie-previews'

prefix = get_option('prefix')
bindir = join_paths(prefix, get_option('bindir'))
libdir = join_paths(prefix, get_option('libdir'))
datadir = join_paths(prefix, get_option('datadir'))
sysconfdir = join_paths(prefix, get_option('sysconfdir'))
pkgdatadir = join_paths(libdir, application_id)


subdir('src')
subdir('data')

install_data('schema/org.ubuntubudgie.plugins.budgie-wpreviews.gschema.xml',
    install_dir: '/usr/share/glib-2.0/schemas'
)

meson.add_install_script('meson_post_install')

