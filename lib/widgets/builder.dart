import 'package:fl_clash/models/models.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScrollOverBuilder extends StatefulWidget {
  final Widget Function(bool isOver) builder;

  const ScrollOverBuilder({
    super.key,
    required this.builder,
  });

  @override
  State<ScrollOverBuilder> createState() => _ScrollOverBuilderState();
}

class _ScrollOverBuilderState extends State<ScrollOverBuilder> {
  final isOverNotifier = ValueNotifier<bool>(false);

  @override
  void dispose() {
    super.dispose();
    isOverNotifier.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (scrollNotification) {
        isOverNotifier.value = scrollNotification.metrics.maxScrollExtent > 0;
        return true;
      },
      child: ValueListenableBuilder<bool>(
        valueListenable: isOverNotifier,
        builder: (_, isOver, __) {
          return widget.builder(isOver);
        },
      ),
    );
  }
}

class ProxiesActionsBuilder extends StatelessWidget {
  final Widget? child;
  final Widget Function(
    ProxiesActionsState state,
    Widget? child,
  ) builder;

  const ProxiesActionsBuilder({
    super.key,
    required this.child,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<AppState, ProxiesActionsState>(
      selector: (_, appState) => ProxiesActionsState(
        isCurrent: appState.currentLabel == "proxies",
        hasProvider: appState.providers.isNotEmpty,
      ),
      builder: (_, state, child) => builder(state, child),
      child: child,
    );
  }
}

typedef StateWidgetBuilder<T> = Widget Function(T state);

class ScaleBuilder extends StatelessWidget {
  final StateWidgetBuilder<double> builder;

  const ScaleBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<Config, double>(
      selector: (_, config) {
        return config.scaleProps.custom
            ? config.scaleProps.scale
            : 1;
      },
      builder: (_, state, __) {
        return builder(state);
      },
    );
  }
}

class LocaleBuilder extends StatelessWidget {
  final StateWidgetBuilder<String?> builder;

  const LocaleBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<Config, String?>(
      selector: (_, config) => config.locale,
      builder: (_, state, __) {
        return builder(state);
      },
    );
  }
}
