import 'package:flutter/material.dart';

class AnimatedListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext, T) itemBuilder;
  final Duration duration;
  final GlobalKey<AnimatedListState>? listKey;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final void Function(T) onDismiss;
  final Color dismissBackgroundColor;
  final IconData dismissIcon;

  const AnimatedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.onDismiss,
    this.duration = const Duration(milliseconds: 300),
    this.listKey,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
    this.dismissBackgroundColor = Colors.red,
    this.dismissIcon = Icons.delete,
  });

  @override
  AnimatedListViewState<T> createState() => AnimatedListViewState<T>();
}

class AnimatedListViewState<T> extends State<AnimatedListView<T>> {
  late final GlobalKey<AnimatedListState> _listKey;
  late List<T> _items;
  final Map<int, T> _removingItems = {};

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: _listKey,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      initialItemCount: _items.length,
      itemBuilder: (context, index, animation) {
        return _buildAnimatedItem(context, index, animation);
      },
    );
  }

  @override
  void didUpdateWidget(AnimatedListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateList();
  }

  @override
  void initState() {
    super.initState();
    _listKey = widget.listKey ?? GlobalKey<AnimatedListState>();
    _items = List.from(widget.items);
  }

  Widget _buildAnimatedItem(BuildContext context, int index, Animation<double> animation) {
    if (index < 0 || index >= _items.length) {
      return const SizedBox.shrink();
    }

    final item = _removingItems[index] ?? _items[index];

    return Dismissible(
      key: ValueKey(item),
      background: _buildDismissibleBackground(DismissDirection.startToEnd),
      secondaryBackground: _buildDismissibleBackground(DismissDirection.endToStart),
      onDismissed: (_) => _handleDismiss(item),
      child: SizeTransition(
        sizeFactor: animation,
        child: FadeTransition(
          opacity: animation,
          child: widget.itemBuilder(context, item),
        ),
      ),
    );
  }

  Widget _buildDismissibleBackground(DismissDirection direction) {
    return Container(
      color: widget.dismissBackgroundColor,
      alignment:
          direction == DismissDirection.startToEnd ? Alignment.centerLeft : Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(widget.dismissIcon, color: Colors.white),
      ),
    );
  }

  void _handleDismiss(T item) {
    final index = _items.indexOf(item);
    if (index != -1) {
      _removeItem(index, animate: false);
      widget.onDismiss(item);
    }
  }

  void _insertItem(int index, T item) {
    if (index < 0 || index > _items.length) return;

    _items.insert(index, item);
    _listKey.currentState?.insertItem(index, duration: widget.duration);
  }

  void _removeItem(int index, {bool animate = true}) {
    if (index < 0 || index >= _items.length) return;

    final removedItem = _items[index];

    if (animate) {
      _removingItems[index] = removedItem;
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => _buildAnimatedItem(context, index, animation),
        duration: widget.duration,
      );
      Future.delayed(widget.duration, () {
        if (mounted) {
          setState(() {
            _removingItems.remove(index);
          });
        }
      });
    } else {
      _listKey.currentState?.removeItem(
        index,
        (_, __) => const SizedBox.shrink(),
        duration: Duration.zero,
      );
    }

    _items.removeAt(index);
  }

  void _updateList() {
    final newItems = widget.items;
    final oldItems = _items;

    for (int i = oldItems.length - 1; i >= 0; i--) {
      if (!newItems.contains(oldItems[i]) && !_removingItems.containsValue(oldItems[i])) {
        _removeItem(i);
      }
    }

    for (int i = 0; i < newItems.length; i++) {
      if (i >= oldItems.length || newItems[i] != oldItems[i]) {
        _insertItem(i, newItems[i]);
      }
    }

    _items = List.from(newItems);
  }
}
