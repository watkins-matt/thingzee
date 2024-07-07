import 'package:flutter/material.dart';

class AnimatedListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext, T) itemBuilder;
  final Duration duration;
  final GlobalKey<AnimatedListState>? listKey;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const AnimatedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.duration = const Duration(milliseconds: 300),
    this.listKey,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
  });

  @override
  AnimatedListViewState<T> createState() => AnimatedListViewState<T>();
}

class AnimatedListViewState<T> extends State<AnimatedListView<T>> {
  late final GlobalKey<AnimatedListState> _listKey;
  late List<T> _items;

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: _listKey,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      initialItemCount: _items.length,
      itemBuilder: (context, index, animation) {
        return SizeTransition(
          sizeFactor: animation,
          child: FadeTransition(
            opacity: animation,
            child: widget.itemBuilder(context, _items[index]),
          ),
        );
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

  Widget _buildRemovedItem(BuildContext context, T item, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: widget.itemBuilder(context, item),
      ),
    );
  }

  void _insertItem(int index, T item) {
    _listKey.currentState?.insertItem(index, duration: widget.duration);
  }

  void _removeItem(int index) {
    final removedItem = _items[index];
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildRemovedItem(context, removedItem, animation),
      duration: widget.duration,
    );
  }

  void _updateList() {
    final newItems = widget.items;
    final oldItems = _items;

    for (int i = oldItems.length - 1; i >= 0; i--) {
      if (!newItems.contains(oldItems[i])) {
        _removeItem(i);
      }
    }

    for (int i = 0; i < newItems.length; i++) {
      if (!oldItems.contains(newItems[i])) {
        _insertItem(i, newItems[i]);
      }
    }

    _items = List.from(newItems);
  }
}
