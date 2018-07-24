configurationData = configuration_data()
configurationData.set('PACKAGE_NAME', meson.project_name())
configurationData.set('LOCALE_DIR', LOCALE_DIR)
configure_file(input: 'config.h.in', output: 'config.h', configuration: configurationData)

install_data('BudgieQuickNote.plugin', install_dir: LIB_INSTALL_DIR)

BudgieQuickNoteSources = [
'budgie-quicknote.vala'
]

BudgieQuickNoteDependencies = [
dependency('gtk+-3.0'), 
dependency('budgie-1.0'),
dependency('gio-2.0'),
meson.get_compiler('c').find_library('m', required: false)
]

BudgieQuickNoteValaArgs = [
'--pkg=config', 
'--vapidir=' + VAPI_DIR, 
'--target-glib=2.38',
]

BudgieQuickNoteCArgs = [
'-include', 
'config.h',
'-lm'
]

shared_library(
    'budgie-quicknote', 
    BudgieQuickNoteSources, 
    dependencies: BudgieQuickNoteDependencies, 
    vala_args: BudgieQuickNoteValaArgs, 
    c_args: BudgieQuickNoteCArgs, 
    install: true, 
    install_dir: LIB_INSTALL_DIR
)




