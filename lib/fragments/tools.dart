import 'dart:io';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/fragments/about.dart';
import 'package:fl_clash/fragments/access.dart';
import 'package:fl_clash/fragments/application_setting.dart';
import 'package:fl_clash/fragments/config/config.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../widgets/widgets.dart';
import 'backup_and_recovery.dart';
import 'theme.dart';

class ToolsFragment extends StatefulWidget {
  const ToolsFragment({super.key});

  @override
  State<ToolsFragment> createState() => _ToolboxFragmentState();
}

class _ToolboxFragmentState extends State<ToolsFragment> {
  _buildNavigationMenuItem(NavigationItem navigationItem) {
    return ListItem.open(
      leading: navigationItem.icon,
      title: Text(Intl.message(navigationItem.label)),
      subtitle: navigationItem.description != null
          ? Text(Intl.message(navigationItem.description!))
          : null,
      delegate: OpenDelegate(
        title: Intl.message(navigationItem.label),
        widget: navigationItem.fragment,
      ),
    );
  }

  Widget _buildNavigationMenu(List<NavigationItem> navigationItems) {
    return Column(
      children: [
        for (final navigationItem in navigationItems) ...[
          _buildNavigationMenuItem(navigationItem),
          navigationItems.last != navigationItem
              ? const Divider(
                  height: 0,
                )
              : Container(),
        ]
      ],
    );
  }

  String _getLocaleString(Locale? locale) {
    if (locale == null) return appLocalizations.defaultText;
    return Intl.message(locale.toString());
  }

  List<Widget> _getOtherList() {
    return generateSection(
      title: appLocalizations.other,
      items: [
        ListItem.open(
          leading: const Icon(Icons.info),
          title: Text(appLocalizations.about),
          delegate: OpenDelegate(
            title: appLocalizations.about,
            widget: const AboutFragment(),
          ),
        ),
      ],
    );
  }

  List<Widget> _getSettingList() {
    return generateSection(
      title: appLocalizations.settings,
      items: [
        Selector<Config, String?>(
          selector: (_, config) => config.locale,
          builder: (_, localeString, __) {
            final subTitle = localeString ?? appLocalizations.defaultText;
            final currentLocale = other.getLocaleForString(localeString);
            return ListItem<Locale?>.options(
              leading: const Icon(Icons.language_outlined),
              title: Text(appLocalizations.language),
              subtitle: Text(Intl.message(subTitle)),
              delegate: OptionsDelegate(
                title: appLocalizations.language,
                options: [
                  null,
                  ...AppLocalizations.delegate.supportedLocales
                ],
                onChanged: (Locale? value) {
                  final config = context.read<Config>();
                  config.locale = value?.toString();
                },
                textBuilder: (locale) => _getLocaleString(locale),
                value: currentLocale,
              ),
            );
          },
        ),
        ListItem.open(
          leading: const Icon(Icons.style),
          title: Text(appLocalizations.theme),
          subtitle: Text(appLocalizations.themeDesc),
          delegate: OpenDelegate(
            title: appLocalizations.theme,
            widget: const ThemeFragment(),
            extendPageWidth: 360,
          ),
        ),
        ListItem.open(
          leading: const Icon(Icons.cloud_sync),
          title: Text(appLocalizations.backupAndRecovery),
          subtitle: Text(appLocalizations.backupAndRecoveryDesc),
          delegate: OpenDelegate(
            title: appLocalizations.backupAndRecovery,
            widget: const BackupAndRecovery(),
          ),
        ),
        if (Platform.isAndroid)
          ListItem.open(
            leading: const Icon(Icons.view_list),
            title: Text(appLocalizations.accessControl),
            subtitle: Text(appLocalizations.accessControlDesc),
            delegate: OpenDelegate(
              title: appLocalizations.appAccessControl,
              widget: const AccessFragment(),
            ),
          ),
        ListItem.open(
          leading: const Icon(Icons.edit),
          title: Text(appLocalizations.override),
          subtitle: Text(appLocalizations.overrideDesc),
          delegate: OpenDelegate(
            title: appLocalizations.override,
            widget: const ConfigFragment(),
          ),
        ),
        ListItem.open(
          leading: const Icon(Icons.settings),
          title: Text(appLocalizations.application),
          subtitle: Text(appLocalizations.applicationDesc),
          delegate: OpenDelegate(
            title: appLocalizations.application,
            widget: const ApplicationSettingFragment(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Selector<Config, String?>(
      selector: (_, config) => config.locale,
      builder: (_, __, ___) {
        final items = [
          Selector<AppState, MoreToolsSelectorState>(
            selector: (_, appState) {
              return MoreToolsSelectorState(
                navigationItems: appState.viewMode == ViewMode.mobile
                    ? appState.navigationItems.where(
                        (element) {
                          return element.modes
                              .contains(NavigationItemMode.more);
                        },
                      ).toList()
                    : [],
              );
            },
            builder: (_, state, __) {
              if (state.navigationItems.isEmpty) {
                return Container();
              }
              return Column(
                children: [
                  ListHeader(title: appLocalizations.more),
                  _buildNavigationMenu(state.navigationItems)
                ],
              );
            },
          ),
          ..._getSettingList(),
        ];
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, index) => items[index],
        );
      },
    );
  }
}
