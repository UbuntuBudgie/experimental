project('budgie-screenshot',
	['vala', 'c'],
	version: '0.0.1',
	meson_version: '>= 0.40.0'
)

#i18n = import('i18n')
gnome = import('gnome')


message('Looking for dependencies')

vala_version_required = '0.40.0'
vala = meson.get_compiler('vala')

add_project_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    language: 'c'
)

am_cflags = []
add_global_arguments(am_cflags, language: 'c')

# Global path variable
#intltool = find_program('intltool-merge')
prefix = get_option('prefix')
libdir = join_paths(prefix, get_option('libdir'))
libexecdir = get_option('libexecdir')
datadir = join_paths(prefix, get_option('datadir'))
bindir = get_option('bindir')
sysconfdir = get_option('sysconfdir')

#podir = join_paths(meson.source_root(), 'po')

if libexecdir == 'libexec'
    libexecdir = join_paths(prefix, libexecdir)
endif
if bindir == 'bin'
	bindir = join_paths(prefix, bindir)
endif


resource_data = files(
  'icons/clipboard-shot-symbolic.svg',
  'icons/selectscreen-symbolic.svg',
  'icons/selectwindow-symbolic.svg',
  'icons/trash-shot-symbolic.svg',
  'icons/edit-shot-symbolic.svg',
  'icons/save-shot-symbolic.svg',
  'icons/selectselection-symbolic.svg',
  'icons/shootscreen-symbolic.svg',
  'icons/saveshot-noaccess-symbolic.svg',
  'screenshothome.ui',
  'aftershot.ui',
)

install_data('icons/org.buddiesofbudgie.screenshot.svg',
    install_dir: join_paths(datadir, 'icons', 'hicolor', 'scalable', 'apps')
)


control_sources = [
  'screenshot.vala',
  'budgie_screenshot_init.vala',
]

ScreenshotControlDependencies = [
dependency('gtk+-3.0'),
dependency('gstreamer-1.0'),
dependency('cairo'),
dependency('gdk-3.0'),
dependency('gio-2.0'),
meson.get_compiler('c').find_library('m', required: false)
]

control_sources += gnome.compile_resources(
  'screenshot-resources',
  'screenshot.gresource.xml',
  source_dir: 'icons',
  export: true,
  c_name: 'screenshot',
)

ScreenshotValaArgs = [
    '--target-glib=2.38',
]

main_sources = [
  'screenshot_main.vala',
]

ScreenshotMainDependencies = [
dependency('gtk+-3.0'),
]

SCREENSHOT_PATH=join_paths(libdir, 'budgie-desktop', 'screenshot')

executable(
    'screenshot-control', control_sources,
    dependencies: ScreenshotControlDependencies,
    install: true,
    vala_args: ScreenshotValaArgs,
    install_dir: SCREENSHOT_PATH,
)

executable(
    'budgie-screenshot', main_sources,
    dependencies: ScreenshotMainDependencies,
    install: true,
    vala_args: ScreenshotValaArgs,
    install_dir: bindir,
)


install_data('schema/org.buddiesofbudgie.screenshot.gschema.xml',
    install_dir: join_paths(datadir, 'glib-2.0', 'schemas')
)

substprog = find_program('subst.py')
podir=''

desktop_file = 'org.buddiesofbudgie.screenshot.desktop'
mytargetw = custom_target('screenshot',
  output : desktop_file,
  input : desktop_file + '.in',
  command : [substprog, '@INPUT@', bindir, '@OUTPUT@', podir],
  install : true,
  install_dir : join_paths(datadir, 'applications')
)

meson.add_install_script('meson_post_install.py')
