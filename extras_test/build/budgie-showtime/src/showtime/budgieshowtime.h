/* budgieshowtime.h generated by valac 0.42.2, the Vala compiler, do not modify */


#ifndef __BUDGIE_SHOWTIME_SRC_SHOWTIME_BUDGIESHOWTIME_H__
#define __BUDGIE_SHOWTIME_SRC_SHOWTIME_BUDGIESHOWTIME_H__

#include <glib.h>
#include <gtk/gtk.h>
#include <gio/gio.h>
#include <libpeas/peas.h>
#include <plugin.h>
#include <stdlib.h>
#include <string.h>
#include <glib-object.h>

G_BEGIN_DECLS


#define BUDGIE_SHOW_TIME_APPLET_TYPE_BUDGIE_SHOW_TIME_SETTINGS (budgie_show_time_applet_budgie_show_time_settings_get_type ())
#define BUDGIE_SHOW_TIME_APPLET_BUDGIE_SHOW_TIME_SETTINGS(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), BUDGIE_SHOW_TIME_APPLET_TYPE_BUDGIE_SHOW_TIME_SETTINGS, BudgieShowTimeAppletBudgieShowTimeSettings))
#define BUDGIE_SHOW_TIME_APPLET_BUDGIE_SHOW_TIME_SETTINGS_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), BUDGIE_SHOW_TIME_APPLET_TYPE_BUDGIE_SHOW_TIME_SETTINGS, BudgieShowTimeAppletBudgieShowTimeSettingsClass))
#define BUDGIE_SHOW_TIME_APPLET_IS_BUDGIE_SHOW_TIME_SETTINGS(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), BUDGIE_SHOW_TIME_APPLET_TYPE_BUDGIE_SHOW_TIME_SETTINGS))
#define BUDGIE_SHOW_TIME_APPLET_IS_BUDGIE_SHOW_TIME_SETTINGS_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), BUDGIE_SHOW_TIME_APPLET_TYPE_BUDGIE_SHOW_TIME_SETTINGS))
#define BUDGIE_SHOW_TIME_APPLET_BUDGIE_SHOW_TIME_SETTINGS_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), BUDGIE_SHOW_TIME_APPLET_TYPE_BUDGIE_SHOW_TIME_SETTINGS, BudgieShowTimeAppletBudgieShowTimeSettingsClass))

typedef struct _BudgieShowTimeAppletBudgieShowTimeSettings BudgieShowTimeAppletBudgieShowTimeSettings;
typedef struct _BudgieShowTimeAppletBudgieShowTimeSettingsClass BudgieShowTimeAppletBudgieShowTimeSettingsClass;
typedef struct _BudgieShowTimeAppletBudgieShowTimeSettingsPrivate BudgieShowTimeAppletBudgieShowTimeSettingsPrivate;

#define BUDGIE_SHOW_TIME_APPLET_TYPE_PLUGIN (budgie_show_time_applet_plugin_get_type ())
#define BUDGIE_SHOW_TIME_APPLET_PLUGIN(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), BUDGIE_SHOW_TIME_APPLET_TYPE_PLUGIN, BudgieShowTimeAppletPlugin))
#define BUDGIE_SHOW_TIME_APPLET_PLUGIN_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), BUDGIE_SHOW_TIME_APPLET_TYPE_PLUGIN, BudgieShowTimeAppletPluginClass))
#define BUDGIE_SHOW_TIME_APPLET_IS_PLUGIN(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), BUDGIE_SHOW_TIME_APPLET_TYPE_PLUGIN))
#define BUDGIE_SHOW_TIME_APPLET_IS_PLUGIN_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), BUDGIE_SHOW_TIME_APPLET_TYPE_PLUGIN))
#define BUDGIE_SHOW_TIME_APPLET_PLUGIN_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), BUDGIE_SHOW_TIME_APPLET_TYPE_PLUGIN, BudgieShowTimeAppletPluginClass))

typedef struct _BudgieShowTimeAppletPlugin BudgieShowTimeAppletPlugin;
typedef struct _BudgieShowTimeAppletPluginClass BudgieShowTimeAppletPluginClass;
typedef struct _BudgieShowTimeAppletPluginPrivate BudgieShowTimeAppletPluginPrivate;

#define BUDGIE_SHOW_TIME_APPLET_TYPE_APPLET (budgie_show_time_applet_applet_get_type ())
#define BUDGIE_SHOW_TIME_APPLET_APPLET(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), BUDGIE_SHOW_TIME_APPLET_TYPE_APPLET, BudgieShowTimeAppletApplet))
#define BUDGIE_SHOW_TIME_APPLET_APPLET_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), BUDGIE_SHOW_TIME_APPLET_TYPE_APPLET, BudgieShowTimeAppletAppletClass))
#define BUDGIE_SHOW_TIME_APPLET_IS_APPLET(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), BUDGIE_SHOW_TIME_APPLET_TYPE_APPLET))
#define BUDGIE_SHOW_TIME_APPLET_IS_APPLET_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), BUDGIE_SHOW_TIME_APPLET_TYPE_APPLET))
#define BUDGIE_SHOW_TIME_APPLET_APPLET_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), BUDGIE_SHOW_TIME_APPLET_TYPE_APPLET, BudgieShowTimeAppletAppletClass))

typedef struct _BudgieShowTimeAppletApplet BudgieShowTimeAppletApplet;
typedef struct _BudgieShowTimeAppletAppletClass BudgieShowTimeAppletAppletClass;
typedef struct _BudgieShowTimeAppletAppletPrivate BudgieShowTimeAppletAppletPrivate;

struct _BudgieShowTimeAppletBudgieShowTimeSettings {
	GtkGrid parent_instance;
	BudgieShowTimeAppletBudgieShowTimeSettingsPrivate * priv;
};

struct _BudgieShowTimeAppletBudgieShowTimeSettingsClass {
	GtkGridClass parent_class;
};

struct _BudgieShowTimeAppletPlugin {
	PeasExtensionBase parent_instance;
	BudgieShowTimeAppletPluginPrivate * priv;
};

struct _BudgieShowTimeAppletPluginClass {
	PeasExtensionBaseClass parent_class;
};

struct _BudgieShowTimeAppletApplet {
	BudgieApplet parent_instance;
	BudgieShowTimeAppletAppletPrivate * priv;
};

struct _BudgieShowTimeAppletAppletClass {
	BudgieAppletClass parent_class;
};


GType budgie_show_time_applet_budgie_show_time_settings_get_type (void) G_GNUC_CONST;
BudgieShowTimeAppletBudgieShowTimeSettings* budgie_show_time_applet_budgie_show_time_settings_new (GSettings* settings);
BudgieShowTimeAppletBudgieShowTimeSettings* budgie_show_time_applet_budgie_show_time_settings_construct (GType object_type,
                                                                                                         GSettings* settings);
void budgie_show_time_applet_budgie_show_time_settings_set_initialautopos (BudgieShowTimeAppletBudgieShowTimeSettings* self);
GType budgie_show_time_applet_plugin_get_type (void) G_GNUC_CONST;
BudgieShowTimeAppletPlugin* budgie_show_time_applet_plugin_new (void);
BudgieShowTimeAppletPlugin* budgie_show_time_applet_plugin_construct (GType object_type);
GType budgie_show_time_applet_applet_get_type (void) G_GNUC_CONST;
BudgieShowTimeAppletApplet* budgie_show_time_applet_applet_new (void);
BudgieShowTimeAppletApplet* budgie_show_time_applet_applet_construct (GType object_type);
void budgie_show_time_applet_applet_initialiseLocaleLanguageSupport (BudgieShowTimeAppletApplet* self);
const gchar* budgie_show_time_applet_applet_get_uuid (BudgieShowTimeAppletApplet* self);
void budgie_show_time_applet_applet_set_uuid (BudgieShowTimeAppletApplet* self,
                                              const gchar* value);
void peas_register_types (GTypeModule* module);


G_END_DECLS

#endif
