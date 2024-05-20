import 'package:collection/collection.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';

class LogsFragment extends StatelessWidget {
  const LogsFragment({super.key});

  _initActions(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final commonScaffoldState =
          context.findAncestorStateOfType<CommonScaffoldState>();
      commonScaffoldState?.actions = [
        IconButton(
          onPressed: () {
            showSearch(
              context: context,
              delegate: LogsSearchDelegate(
                logs: globalState.appController.appState.logs.reversed.toList(),
              ),
            );
          },
          icon: const Icon(Icons.search),
        )
      ];
    });
  }

  _buildList() {
    return Selector<AppState, List<Log>>(
      selector: (_, appState) => appState.logs,
      shouldRebuild: (prev, next) =>
          !const ListEquality<Log>().equals(prev, next),
      builder: (_, List<Log> logs, __) {
        if (logs.isEmpty) {
          return NullStatus(
            label: appLocalizations.nullLogsDesc,
          );
        }
        logs = logs.reversed.toList();
        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: logs.length,
          itemBuilder: (BuildContext context, int index) {
            final log = logs[index];
            return LogItem(
              key: ValueKey(log.dateTime),
              log: log,
            );
          },
          separatorBuilder: (BuildContext context, int index) {
            return const Divider(
              height: 0,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AppState, bool?>(
      selector: (_, appState) {
        return appState.currentLabel == 'logs' ||
            appState.viewMode == ViewMode.mobile &&
                appState.currentLabel == "tools";
      },
      builder: (_, isCurrent, child) {
        if (isCurrent == null || isCurrent) {
          _initActions(context);
        }
        return child!;
      },
      child: _buildList(),
    );
  }
}

class LogsSearchDelegate extends SearchDelegate {
  List<Log> logs = [];

  LogsSearchDelegate({
    required this.logs,
  });

  List<Log> get _results {
    final lowQuery = query.toLowerCase();
    return logs
        .where(
          (log) =>
              (log.payload?.toLowerCase().contains(lowQuery) ?? false) ||
              log.logLevel.name.contains(lowQuery),
        )
        .toList();
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          if (query.isEmpty) {
            close(context, null);
            return;
          }
          query = '';
        },
        icon: const Icon(Icons.clear),
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, null);
      },
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _results.length,
      itemBuilder: (BuildContext context, int index) {
        final log = _results[index];
        return LogItem(
          key: ValueKey(log.dateTime),
          log: log,
        );
      },
      separatorBuilder: (BuildContext context, int index) {
        return const Divider(
          height: 0,
        );
      },
    );
  }
}

class LogItem extends StatelessWidget {
  final Log log;

  const LogItem({
    super.key,
    required this.log,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: SelectableText(log.payload ?? ''),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: 8,
            ),
            child: SelectableText(
              "${log.dateTime}",
              style: context.textTheme.bodySmall
                  ?.copyWith(color: context.colorScheme.primary),
            ),
          ),
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(
              vertical: 8,
            ),
            child: CommonChip(
              label: log.logLevel.name,
            ),
          ),
        ],
      ),
    );
  }
}
