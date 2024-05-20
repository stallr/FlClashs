import 'package:fl_clash/state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../enum/enum.dart';
import '../models/models.dart';
import '../common/common.dart';
import '../widgets/widgets.dart';

class ProxiesFragment extends StatefulWidget {
  const ProxiesFragment({super.key});

  @override
  State<ProxiesFragment> createState() => _ProxiesFragmentState();
}

class _ProxiesFragmentState extends State<ProxiesFragment>
    with TickerProviderStateMixin {
  TabController? _tabController;

  _initActions() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final commonScaffoldState =
          context.findAncestorStateOfType<CommonScaffoldState>();
      final items = [
        CommonPopupMenuItem(
          action: ProxiesSortType.none,
          label: appLocalizations.defaultSort,
          iconData: Icons.sort,
        ),
        CommonPopupMenuItem(
            action: ProxiesSortType.delay,
            label: appLocalizations.delaySort,
            iconData: Icons.network_ping),
        CommonPopupMenuItem(
            action: ProxiesSortType.name,
            label: appLocalizations.nameSort,
            iconData: Icons.sort_by_alpha),
      ];
      commonScaffoldState?.actions = [
        Selector<Config, ProxiesSortType>(
          selector: (_, config) => config.proxiesSortType,
          builder: (_, proxiesSortType, __) {
            return CommonPopupMenu<ProxiesSortType>.radio(
              items: items,
              onSelected: (value) {
                final config = context.read<Config>();
                config.proxiesSortType = value;
              },
              selectedValue: proxiesSortType,
            );
          },
        )
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return DelayTestButtonContainer(
      child: Selector<AppState, bool>(
        selector: (_, appState) => appState.currentLabel == 'proxies',
        builder: (_, isCurrent, child) {
          if (isCurrent) {
            _initActions();
          }
          return child!;
        },
        child: Selector3<AppState, Config, ClashConfig, ProxiesSelectorState>(
          selector: (_, appState, config, clashConfig) {
            final currentGroups = appState.currentGroups;
            final groupNames = currentGroups.map((e) => e.name).toList();
            return ProxiesSelectorState(
              groupNames: groupNames,
            );
          },
          shouldRebuild: (prev, next) {
            if (prev.groupNames.length != next.groupNames.length) {
              _tabController?.dispose();
              _tabController = null;
            }
            return prev != next;
          },
          builder: (_, state, __) {
            _tabController ??= TabController(
              length: state.groupNames.length,
              vsync: this,
            );
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TabBar(
                  controller: _tabController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  dividerColor: Colors.transparent,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  overlayColor:
                      const WidgetStatePropertyAll(Colors.transparent),
                  tabs: [
                    for (final groupName in state.groupNames)
                      Tab(
                        text: groupName,
                      ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      for (final groupName in state.groupNames)
                        KeepContainer(
                          key: ObjectKey(groupName),
                          child: ProxiesTabView(
                            groupName: groupName,
                          ),
                        ),
                    ],
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }
}

class ProxiesTabView extends StatelessWidget {
  final String groupName;

  const ProxiesTabView({
    super.key,
    required this.groupName,
  });

  List<Proxy> _sortOfName(List<Proxy> proxies) {
    return List.of(proxies)
      ..sort(
        (a, b) => other.sortByChar(a.name, b.name),
      );
  }

  List<Proxy> _sortOfDelay(BuildContext context, List<Proxy> proxies) {
    final appState = context.read<AppState>();
    return proxies = List.of(proxies)
      ..sort(
        (a, b) {
          final aDelay = appState.getDelay(a.name);
          final bDelay = appState.getDelay(b.name);
          if (aDelay == null && bDelay == null) {
            return 0;
          }
          if (aDelay == null || aDelay == -1) {
            return 1;
          }
          if (bDelay == null || bDelay == -1) {
            return -1;
          }
          return aDelay.compareTo(bDelay);
        },
      );
  }

  _getProxies(
    BuildContext context,
    List<Proxy> proxies,
    ProxiesSortType proxiesSortType,
  ) {
    if (proxiesSortType == ProxiesSortType.delay) {
      return _sortOfDelay(context, proxies);
    }
    if (proxiesSortType == ProxiesSortType.name) return _sortOfName(proxies);
    return proxies;
  }

  double _getItemHeight(BuildContext context) {
    final measure = globalState.appController.measure;
    return 12 * 2 +
        measure.bodyMediumHeight * 2 +
        measure.bodySmallHeight +
        measure.labelSmallHeight +
        8 * 2;
  }

  int _getColumns(ViewMode viewMode) {
    switch (viewMode) {
      case ViewMode.mobile:
        return 2;
      case ViewMode.laptop:
        return 3;
      case ViewMode.desktop:
        return 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector2<AppState, Config, ProxiesTabViewSelectorState>(
      selector: (_, appState, config) {
        return ProxiesTabViewSelectorState(
          proxiesSortType: config.proxiesSortType,
          sortNum: appState.sortNum,
          group: appState.getGroupWithName(groupName)!,
          viewMode: appState.viewMode,
        );
      },
      builder: (_, state, __) {
        final proxies = _getProxies(
          context,
          state.group.all,
          state.proxiesSortType,
        );
        return Align(
          alignment: Alignment.topCenter,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _getColumns(state.viewMode),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              mainAxisExtent: _getItemHeight(context),
            ),
            itemCount: proxies.length,
            itemBuilder: (_, index) {
              final proxy = proxies[index];
              return ProxyCard(
                key: ValueKey('$groupName.${proxy.name}'),
                proxy: proxy,
                groupName: groupName,
              );
            },
          ),
        );
      },
    );
  }
}

class ProxyCard extends StatelessWidget {
  final String groupName;
  final Proxy proxy;

  const ProxyCard({
    super.key,
    required this.groupName,
    required this.proxy,
  });

  @override
  Widget build(BuildContext context) {
    final measure = globalState.appController.measure;
    return Selector3<AppState, Config, ClashConfig, ProxiesCardSelectorState>(
      selector: (_, appState, config, clashConfig) {
        final group = appState.getGroupWithName(groupName)!;
        bool isSelected = config.currentSelectedMap[group.name] == proxy.name ||
            (config.currentSelectedMap[group.name] == null &&
                group.now == proxy.name);
        return ProxiesCardSelectorState(
          isSelected: isSelected,
        );
      },
      builder: (_, state, __) {
        return CommonCard(
          isSelected: state.isSelected,
          onPressed: () {
            final appController = globalState.appController;
            final group = appController.appState.getGroupWithName(groupName)!;
            if (group.type != GroupType.Selector) {
              globalState.showSnackBar(
                context,
                message: appLocalizations.notSelectedTip,
              );
              return;
            }
            globalState.appController.config.updateCurrentSelectedMap(
              groupName,
              proxy.name,
            );
            globalState.appController.changeProxy();
          },
          selectWidget: Container(
            alignment: Alignment.topRight,
            margin: const EdgeInsets.all(8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.secondaryContainer,
              ),
              child: const SelectIcon(),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: measure.bodyMediumHeight * 2,
                  child: Text(
                    proxy.name,
                    maxLines: 2,
                    style: context.textTheme.bodyMedium?.copyWith(
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                SizedBox(
                  height: measure.bodySmallHeight,
                  child: Selector<AppState, String>(
                    selector: (context, appState) => appState.getDesc(
                      proxy.type,
                      proxy.name,
                    ),
                    builder: (_, desc, __) {
                      return TooltipText(
                        text: Text(
                          desc,
                          style: context.textTheme.bodySmall?.copyWith(
                            overflow: TextOverflow.ellipsis,
                            color:
                                context.textTheme.bodySmall?.color?.toLight(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                SizedBox(
                  height: measure.labelSmallHeight,
                  child: Selector<AppState, int?>(
                    selector: (context, appState) => appState.getDelay(
                      proxy.name,
                    ),
                    builder: (_, delay, __) {
                      return FadeBox(
                        child: Builder(
                          builder: (_) {
                            if (delay == null) {
                              return Container();
                            }
                            if (delay == 0) {
                              return SizedBox(
                                height: measure.labelSmallHeight,
                                width: measure.labelSmallHeight,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              );
                            }
                            return Text(
                              delay > 0 ? '$delay ms' : "Timeout",
                              style: context.textTheme.labelSmall?.copyWith(
                                overflow: TextOverflow.ellipsis,
                                color: other.getDelayColor(
                                  delay,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class DelayTestButtonContainer extends StatefulWidget {
  final Widget child;

  const DelayTestButtonContainer({
    super.key,
    required this.child,
  });

  @override
  State<DelayTestButtonContainer> createState() =>
      _DelayTestButtonContainerState();
}

class _DelayTestButtonContainerState extends State<DelayTestButtonContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  _healthcheck() async {
    if (globalState.healthcheckLock) return;
    _controller.forward();
    globalState.appController.healthcheck();
    Future.delayed(httpTimeoutDuration + moreDuration, () {
      _controller.reverse();
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 300,
      ),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0,
          1,
          curve: Curves.elasticInOut,
        ),
      ),
    );
    _opacity = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0,
          1,
          curve: Curves.easeIn,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FloatLayout(
      floatingWidget: FloatWrapper(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, child) {
            return SizedBox(
              width: 56,
              height: 56,
              child: Transform.scale(
                scale: _scale.value,
                child: Opacity(
                  opacity: _opacity.value,
                  child: child!,
                ),
              ),
            );
          },
          child: FloatingActionButton(
            heroTag: null,
            onPressed: _healthcheck,
            child: const Icon(Icons.network_ping),
          ),
        ),
      ),
      child: widget.child,
    );
  }
}
