#install_data(
#    'chardata',
#    install_dir: join_paths(datadir, application_id)
#)


#install_data(
#    'quickchar-autostart.desktop',
#    install_dir: join_paths(sysconfdir, 'xdg', 'autostart')
#)

BDE_LOC=join_paths(datadir, 'budgie-extras-daemon')
substprog = find_program('subst.py')

mytarget1 = custom_target('preview_allbackward',
  output : 'preview_allbackward.bde',
  input : 'preview_allbackward.bde.in',
  command : [substprog, '@INPUT@', BDE_LOC, '@OUTPUT@'],
  install : true,
  install_dir : BDE_LOC
)

mytarget2 = custom_target('preview_allforward',
  output : 'preview_allforward.bde',
  input : 'preview_allforward.bde.in',
  command : [substprog, '@INPUT@', BDE_LOC, '@OUTPUT@'],
  install : true,
  install_dir : BDE_LOC
)

mytarget3 = custom_target('preview_currentbackward',
  output : 'preview_curentbackward.bde',
  input : 'preview_currentbackward.bde.in',
  command : [substprog, '@INPUT@', BDE_LOC, '@OUTPUT@'],
  install : true,
  install_dir : BDE_LOC
)

mytarget4 = custom_target('preview_currentforward',
  output : 'preview_currentforward.bde',
  input : 'preview_currentforward.bde.in',
  command : [substprog, '@INPUT@', BDE_LOC, '@OUTPUT@'],
  install : true,
  install_dir : BDE_LOC
)
