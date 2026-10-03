#pragma once

#include "configobject.hpp"

#include <qstring.h>
#include <qstringlist.h>
#include <qvariant.h>

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

class LauncherUseFuzzy : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(bool, apps, false)
    CONFIG_GLOBAL_PROPERTY(bool, actions, false)
    CONFIG_GLOBAL_PROPERTY(bool, schemes, false)
    CONFIG_GLOBAL_PROPERTY(bool, variants, false)
    CONFIG_GLOBAL_PROPERTY(bool, wallpapers, false)

public:
    explicit LauncherUseFuzzy(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class LauncherConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(bool, showOnHover, false)
    CONFIG_PROPERTY(int, maxShown, 7)
    CONFIG_PROPERTY(int, maxWallpapers, 9)
    CONFIG_GLOBAL_PROPERTY(QString, specialPrefix, u"@"_s)
    CONFIG_GLOBAL_PROPERTY(QString, actionPrefix, u">"_s)
    CONFIG_GLOBAL_PROPERTY(bool, enableDangerousActions, false)
    CONFIG_PROPERTY(int, dragThreshold, 50)
    CONFIG_GLOBAL_PROPERTY(bool, vimKeybinds, false)
    CONFIG_GLOBAL_PROPERTY(QStringList, favouriteApps)
    CONFIG_GLOBAL_PROPERTY(QStringList, hiddenApps)
    CONFIG_SUBOBJECT(LauncherUseFuzzy, useFuzzy)
    CONFIG_GLOBAL_PROPERTY(QVariantList, actions,
        {
            vmap({
                { u"name"_s, u"Calculator"_s },
                { u"icon"_s, u"calculate"_s },
                { u"description"_s, u"Do simple math equations (powered by Qalc)"_s },
                { u"command"_s, QStringList{ u"autocomplete"_s, u"calc"_s } },
            }),
            vmap({
                { u"name"_s, u"Scheme"_s },
                { u"icon"_s, u"palette"_s },
                { u"description"_s, u"Change the current colour scheme"_s },
                { u"command"_s, QStringList{ u"autocomplete"_s, u"scheme"_s } },
            }),
            vmap({
                { u"name"_s, u"Wallpaper"_s },
                { u"icon"_s, u"image"_s },
                { u"description"_s, u"Change the current wallpaper"_s },
                { u"command"_s, QStringList{ u"autocomplete"_s, u"wallpaper"_s } },
            }),
            vmap({
                { u"name"_s, u"Variant"_s },
                { u"icon"_s, u"colors"_s },
                { u"description"_s, u"Change the current scheme variant"_s },
                { u"command"_s, QStringList{ u"autocomplete"_s, u"variant"_s } },
            }),
            vmap({
                { u"name"_s, u"Agent"_s },
                { u"icon"_s, u"person_pin"_s },
                { u"description"_s, u"Select a Valorant agent theme"_s },
                { u"command"_s, QStringList{ u"autocomplete"_s, u"agent"_s } },
            }),
            vmap({
                { u"name"_s, u"Clipboard"_s },
                { u"icon"_s, u"content_paste_search"_s },
                { u"description"_s, u"Clipboard history: search, pin, paste (Stash)"_s },
                { u"command"_s, QStringList{ u"autocomplete"_s, u"clip"_s } },
            }),
            vmap({
                { u"name"_s, u"Night Ops"_s },
                { u"icon"_s, u"nightlight"_s },
                { u"description"_s, u"Toggle the blue-light filter"_s },
                { u"command"_s, QStringList{ u"valorant"_s, u"nightops"_s } },
            }),
            vmap({
                { u"name"_s, u"Check updates"_s },
                { u"icon"_s, u"system_update_alt"_s },
                { u"description"_s, u"Look for system, Flatpak and firmware updates (Patch Notes)"_s },
                { u"command"_s, QStringList{ u"valorant"_s, u"updates"_s } },
            }),
            vmap({
                { u"name"_s, u"Ring phone"_s },
                { u"icon"_s, u"ring_volume"_s },
                { u"description"_s, u"Find your phone through KDE Connect (Uplink)"_s },
                { u"command"_s, QStringList{ u"valorant"_s, u"ring"_s } },
            }),
            vmap({
                { u"name"_s, u"Next agent"_s },
                { u"icon"_s, u"skip_next"_s },
                { u"description"_s, u"Lock in the next Valorant agent theme"_s },
                { u"command"_s, QStringList{ u"valorant"_s, u"next"_s } },
            }),
            vmap({
                { u"name"_s, u"Previous agent"_s },
                { u"icon"_s, u"skip_previous"_s },
                { u"description"_s, u"Lock in the previous Valorant agent theme"_s },
                { u"command"_s, QStringList{ u"valorant"_s, u"prev"_s } },
            }),
            vmap({
                { u"name"_s, u"Valorant palette"_s },
                { u"icon"_s, u"swap_horiz"_s },
                { u"description"_s, u"Toggle between the Valorant palette and the wallpaper scheme"_s },
                { u"command"_s, QStringList{ u"valorant"_s, u"toggle"_s } },
            }),
            vmap({
                { u"name"_s, u"Random"_s },
                { u"icon"_s, u"casino"_s },
                { u"description"_s, u"Switch to a random wallpaper"_s },
                { u"command"_s, QStringList{ u"caelestia"_s, u"wallpaper"_s, u"-r"_s } },
            }),
            vmap({
                { u"name"_s, u"Light"_s },
                { u"icon"_s, u"light_mode"_s },
                { u"description"_s, u"Change the scheme to light mode"_s },
                { u"command"_s, QStringList{ u"setMode"_s, u"light"_s } },
            }),
            vmap({
                { u"name"_s, u"Dark"_s },
                { u"icon"_s, u"dark_mode"_s },
                { u"description"_s, u"Change the scheme to dark mode"_s },
                { u"command"_s, QStringList{ u"setMode"_s, u"dark"_s } },
            }),
            vmap({
                { u"name"_s, u"Shutdown"_s },
                { u"icon"_s, u"power_settings_new"_s },
                { u"description"_s, u"Shutdown the system"_s },
                { u"command"_s, QStringList{ u"poweroff"_s } },
                { u"dangerous"_s, true },
            }),
            vmap({
                { u"name"_s, u"Reboot"_s },
                { u"icon"_s, u"cached"_s },
                { u"description"_s, u"Reboot the system"_s },
                { u"command"_s, QStringList{ u"reboot"_s } },
                { u"dangerous"_s, true },
            }),
            vmap({
                { u"name"_s, u"Logout"_s },
                { u"icon"_s, u"exit_to_app"_s },
                { u"description"_s, u"Log out of the current session"_s },
                { u"command"_s, QStringList{ u"logout"_s } },
                { u"dangerous"_s, true },
            }),
            vmap({
                { u"name"_s, u"Lock"_s },
                { u"icon"_s, u"lock"_s },
                { u"description"_s, u"Lock the current session"_s },
                { u"command"_s, QStringList{ u"loginctl"_s, u"lock-session"_s } },
            }),
            vmap({
                { u"name"_s, u"Sleep"_s },
                { u"icon"_s, u"bedtime"_s },
                { u"description"_s, u"Suspend then hibernate"_s },
                { u"command"_s, QStringList{ u"suspendThenHibernate"_s } },
            }),
            vmap({
                { u"name"_s, u"Settings"_s },
                { u"icon"_s, u"settings"_s },
                { u"description"_s, u"Configure the shell"_s },
                { u"command"_s, QStringList{ u"caelestia"_s, u"shell"_s, u"nexus"_s, u"open"_s } },
            }),
        })

public:
    explicit LauncherConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_useFuzzy(new LauncherUseFuzzy(this)) {}
};

} // namespace caelestia::config
