import 'package:flutter/material.dart';

class DraggableBottomSheet extends StatefulWidget {
  final Widget child;
  const DraggableBottomSheet({super.key, required this.child});

  @override
  State<DraggableBottomSheet> createState() => _DraggableBottomSheetState();
}

class _DraggableBottomSheetState extends State<DraggableBottomSheet> {
  static const double grabberHeight = 40;
  static const double minSheetHeight = 100;
  double _bottomSheetHeight = grabberHeight;
  double _dragStartYPosition = 0;
  double _currentSheetHeight = minSheetHeight;
  late double _maxSheetHeight;

  @override
  Widget build(BuildContext context) {
    _maxSheetHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 10),
          curve: Curves.easeOut,
          height: _bottomSheetHeight,
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Container(
                    width: 75,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                        maxHeight: double.infinity,
                      ),
                      child: widget.child,
                    );
                  },
                ),
              )
            ],
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: GestureDetector(
            onVerticalDragStart: _onVerticalDragStart,
            onVerticalDragUpdate: _onVerticalDragUpdate,
            onVerticalDragEnd: _onVerticalDragEnd,
            behavior: HitTestBehavior.translucent,
            child: Container(
              height: grabberHeight,
              color: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_bottomSheetHeight < MediaQuery.of(context).size.height * 0.2) {
      setState(() {
        _bottomSheetHeight = grabberHeight;
      });
    }
  }

  void _onVerticalDragStart(DragStartDetails details) {
    _dragStartYPosition = details.globalPosition.dy;
    _currentSheetHeight = _bottomSheetHeight;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    double dragDistance = details.globalPosition.dy - _dragStartYPosition;
    setState(() {
      double newHeight = _currentSheetHeight - dragDistance;
      _bottomSheetHeight = newHeight.clamp(minSheetHeight, _maxSheetHeight);
    });
  }
}
