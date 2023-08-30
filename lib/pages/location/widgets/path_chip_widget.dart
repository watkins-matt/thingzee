import 'package:flutter/material.dart';

typedef PathCallback = void Function(String path);

class PathChipWidget extends StatelessWidget {
  final String fullPath;
  final PathCallback onTap;
  final ScrollController scrollController = ScrollController();

  PathChipWidget({required this.fullPath, required this.onTap}) : super(key: ValueKey(fullPath));

  @override
  Widget build(BuildContext context) {
    List<String> pathComponents = fullPath.split('/')..removeWhere((element) => element.isEmpty);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }
    });

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        controller: scrollController,
        itemCount: pathComponents.length, // Set the item count
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: const EdgeInsets.all(4),
            child: ActionChip(
              label: Text(pathComponents[index]),
              onPressed: () {
                // Generate the path up to this chip and trigger the callback
                String pathUpToChip = '/${pathComponents.sublist(0, index + 1).join('/')}';
                onTap(pathUpToChip);
              },
            ),
          );
        },
      ),
    );
  }
}
