import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class LocationSelectorDialog extends HookWidget {
  final Map<String, Map<String, List<String>>> locations = {
    'Living Room': {'Couch': [], 'Coffee Table': [], 'TV Stand': []},
    'Office': {'Desk': [], 'Bookshelf': [], 'Closet': []},
    'Kitchen': {
      'Counter': [],
      'Fridge': [
        'Top Shelf',
        'Middle Shelf',
        'Bottom Shelf',
        'Top',
        'Left Drawer',
        'Right Drawer',
        'Upper Drawer',
        'Lower Drawer'
      ],
      'Freezer': [
        'Top Shelf',
        'Middle Shelf',
        'Bottom Shelf',
        'Left Drawer',
        'Right Drawer',
        'Upper Drawer',
        'Lower Drawer'
      ],
      'Pantry': [],
      'Under Sink Cabinet': [],
      'Upper Cabinets': ['Top Shelf', 'Middle Shelf', 'Bottom Shelf'],
      'Lower Cabinets': ['Top Shelf', 'Middle Shelf', 'Bottom Shelf'],
    },
    'Bedroom': {'Dresser': [], 'Nightstand Left': [], 'Nightstand Right': []},
    'Bathroom': {'Cabinet': [], 'Under Sink Cabinet': [], 'Shower': [], 'Counter': []},
    'Guest Bathroom': {'Cabinet': [], 'Under Sink Cabinet': []},
    'Garage': {'Cabinet': [], 'Shelf': [], 'Workbench': []},
  };

  LocationSelectorDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selectedRoom = useState<String?>(null);
    final selectedArea = useState<String?>(null);
    final selectedSpecific = useState<String?>(null);
    final scrollController = useScrollController();

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        }
      });
      return null;
    }, [selectedRoom.value, selectedArea.value]);

    return AlertDialog(
      title: const Text('Select Location'),
      content: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSection('Room:', locations.keys.toList(), selectedRoom, (item) {
              selectedRoom.value = item;
              selectedArea.value = null;
              selectedSpecific.value = null;
            }),
            const SizedBox(height: 16),
            if (selectedRoom.value != null)
              _buildSection('Area:', locations[selectedRoom.value]!.keys.toList(), selectedArea,
                  (item) {
                selectedArea.value = item;
                selectedSpecific.value = null;
              }),
            const SizedBox(height: 16),
            if (selectedArea.value != null)
              _buildSection('Specific:', locations[selectedRoom.value]![selectedArea.value]!,
                  selectedSpecific, (item) {
                selectedSpecific.value = item;
              }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            String result = '';
            if (selectedRoom.value != null) {
              result += selectedRoom.value!;
              if (selectedArea.value != null) {
                result += ': ${selectedArea.value!}';
                if (selectedSpecific.value != null) {
                  result += ' (${selectedSpecific.value!})';
                }
              }
            }
            Navigator.of(context).pop(result);
          },
          child: const Text('Okay'),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<String> items, ValueNotifier<String?> selectedItem,
      void Function(String) onSelect) {
    items.sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ...items.map((item) => ChoiceChip(
                  label: Text(item),
                  selected: selectedItem.value == item,
                  onSelected: (selected) => onSelect(item),
                )),
            ActionChip(
              label: const Icon(Icons.add),
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }

  static Future<String> show(BuildContext context) async {
    final result =
        await showDialog<String>(context: context, builder: (context) => LocationSelectorDialog());
    return result ?? '';
  }
}
