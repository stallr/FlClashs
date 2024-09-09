import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/list.dart';
import 'package:flutter/material.dart';

@immutable
class Contributor {
  final String avatar;
  final String name;
  final String link;

  const Contributor({
    required this.avatar,
    required this.name,
    required this.link,
  });
}

class AboutFragment extends StatelessWidget {
  const AboutFragment({super.key});

  _checkUpdate(BuildContext context) async {
    final commonScaffoldState = context.commonScaffoldState;
    if (commonScaffoldState?.mounted != true) return;
    final data = await commonScaffoldState?.loadingRun<Map<String, dynamic>?>(
      request.checkForUpdate,
      title: appLocalizations.checkUpdate,
    );
    globalState.appController.checkUpdateResultHandle(
      data: data,
      handleError: true,
    );
  }

  List<Widget> _buildMoreSection(BuildContext context) {
    return generateSection(
      separated: false,
      title: appLocalizations.more,
      items: [
        ListItem(
          title: Text(appLocalizations.checkUpdate),
          onTap: () {
            _checkUpdate(context);
          },
        ),
        ListItem(
          title: const Text("Telegram"),
          onTap: () {
            globalState.openUrl(
              "https://t.me/FlClash",
            );
          },
          trailing: const Icon(Icons.launch),
        ),
        ListItem(
          title: Text(appLocalizations.project),
          onTap: () {
            globalState.openUrl(
              "https://github.com/$repository",
            );
          },
          trailing: const Icon(Icons.launch),
        ),
        ListItem(
          title: Text(appLocalizations.core),
          onTap: () {
            globalState.openUrl(
              "https://github.com/chen08209/Clash.Meta/tree/FlClash",
            );
          },
          trailing: const Icon(Icons.launch),
        ),
      ],
    );
  }

  List<Widget> _buildContributorsSection() {
    const contributors = [
      Contributor(
        avatar: "assets/images/avatars/june2.jpg",
        name: "June2",
        link: "https://t.me/Jibadong",
      ),
      Contributor(
        avatar: "assets/images/avatars/arue.jpg",
        name: "Arue",
        link: "https://t.me/xrcm6868",
      ),
    ];
    return generateSection(
      separated: false,
      title: appLocalizations.otherContributors,
      items: [
        ListItem(
          title: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Wrap(
              spacing: 24,
              children: [
                for (final contributor in contributors)
                  Avatar(
                    contributor: contributor,
                  ),
              ],
            ),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      ListTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Image.asset(
                    'assets/images/icon.png',
                    width: 64,
                    height: 64,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      globalState.packageInfo.version,
                      style: Theme.of(context).textTheme.labelLarge,
                    )
                  ],
                )
              ],
            ),
            const SizedBox(
              height: 24,
            ),
            Text(
              appLocalizations.desc,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      const SizedBox(
        height: 12,
      ),
      ..._buildContributorsSection(),
      ..._buildMoreSection(context),
    ];
    return Padding(
      padding: kMaterialListPadding.copyWith(
        top: 16,
        bottom: 16,
      ),
      child: generateListView(items),
    );
  }
}

class Avatar extends StatelessWidget {
  final Contributor contributor;

  const Avatar({
    super.key,
    required this.contributor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      child: Column(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircleAvatar(
              foregroundImage: AssetImage(
                contributor.avatar,
              ),
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            contributor.name,
            style: context.textTheme.bodySmall,
          )
        ],
      ),
      onTap: () {
        globalState.openUrl(contributor.link);
      },
    );
  }
}
