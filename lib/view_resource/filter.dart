// Data, utils, and widgets for querying resource documents with various filters.
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:web_app/events/schedule.dart';

// Time
import 'package:web_app/common.dart';

/// A single item in a filter selection. The pair of category and value.
class FilterItem {
  FilterItem(this.category, this.value);

  String category;
  String value;

  @override
  int get hashCode => category.hashCode ^ value.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilterItem &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          value == other.value;
}

/// Useful metadata about the categories which can be filtered in a resource document.
class FilterCategory {
  FilterCategory(this.name, this.field,
      {required this.values, this.canHaveMultiple = false})
      : items = UnmodifiableListView(values.map((v) => FilterItem(name, v)));

  /// The category name
  final String name;

  /// The data field name (its key in Firestore documents)
  final String field;

  /// All possible values for this category, as they would appear in the data
  final UnmodifiableListView<String> values;

  /// Values as preconstructed FilterItem instances.
  final UnmodifiableListView<FilterItem> items;

  /// Can a resource have more than one value for this?
  final bool canHaveMultiple;
}

/// All available resource filter categories, their values, and other useful metadata.
final categories = UnmodifiableListView<FilterCategory>([
  FilterCategory("Type", "resourceType",
      values: UnmodifiableListView([
        "Online",
        "In Person",
        "App",
        "Hotline",
        "Event",
        "Podcast",
      ])),
  FilterCategory("Cultural Responsiveness", "culturalResponse",
      values: UnmodifiableListView([
        "Low Cultural Responsivness",
        "Medium Cultural Responsivness",
        "High Cultural Responsivness",
      ])),
  FilterCategory("Privacy", "privacy",
      values: UnmodifiableListView([
        "HIPAA Compliant",
        "Anonymous",
        "Mandatory Reporting",
        "None Stated",
      ]),
      canHaveMultiple: true),
  FilterCategory("Age Range", "agerange",
      values: UnmodifiableListView([
      'Under 18',
      '18-24',
      '24-65',
      '65+',
      'All ages'
      ])),
   FilterCategory("Health Focus", "healthFocus",
      values: UnmodifiableListView([
      'Anxiety',
      'Depression',
      'Stress Management',
      'Substance Abuse',
      'Grief and Loss',
      'Trama and PTSD',
      'Suicide Prevention',
      ]), canHaveMultiple: true ),
  FilterCategory("Event happening in the next", "nextDate",
      values: UnmodifiableListView([
        "Week",
        "Month",
        "3 Months",
      ])),
]);

/// Represents a complete resource filter query.
/// Includes a set of FilterItems (categorical filters)
/// and an optional search string to match by name.
class ResourceFilter {
  ResourceFilter(this.textual, this.categorical);

  static ResourceFilter empty() {
    return ResourceFilter(null, Set());
  }

  String? textual;
  Set<FilterItem> categorical;

  bool isSelected(FilterItem value) {
    return categorical.contains(value);
  }

  void addFilter(FilterItem value) {
    this.categorical.add(value);
  }

  void removeFilter(FilterItem value) {
    this.categorical.remove(value);
  }

  void setTextSearch(String? text) {
    this.textual = text;
  }

  void clear() {
    this.textual = null;
    this.categorical.clear();
  }
}

/// A popup dialog for making resource categorical filter selections.
class CategoryFilterDialog extends StatelessWidget {
  CategoryFilterDialog(
      {super.key, required this.filter, required this.onChanged});

  final ResourceFilter filter;
  final Function(ResourceFilter) onChanged;

  void updateFilter() {
    this.onChanged(filter);
  }

  Widget buildFilterChip(FilterItem item) {
    return CustomFilterChip(
      label: item.value,
      selected: filter.isSelected(item),
      onSelected: (bool selected) {
        if (selected) {
          filter.addFilter(item);
        } else {
          filter.removeFilter(item);
        }
        updateFilter();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Filter Categories',
              // You can change this to a dynamic title if needed
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icon(Icons.close),
              iconSize: 20,
              splashRadius: 20,
            ),
          ],
        ),
        ...categories.map((category) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(0, 12, 0, 3),
                child: Text(
                  category.name,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(0, 3, 0, 12),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: category.items.map(buildFilterChip).toList(),
                ),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }
}

/// A chip widget for filter selections.
class CustomFilterChip extends StatefulWidget {
  final String label;
  final bool selected;
  final Function(bool) onSelected;

  CustomFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  _CustomFilterChipState createState() => _CustomFilterChipState();
}

class _CustomFilterChipState extends State<CustomFilterChip> {
  bool _isSelected = false;

  @override
  void initState() {
    super.initState();
    _isSelected = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(widget.label,
        style: TextStyle(
        color: _isSelected ? Colors.white : Colors.black ),),
      selected: _isSelected,
      onSelected: (bool selected) {
        setState(() {
          _isSelected = selected;
        });
        widget.onSelected(selected);
      },
      side: MaterialStateBorderSide.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.focused)) {
        return BorderSide(color: Colors.grey[700]!, width: 2);
      }
      return BorderSide.none;
      }),
    );
  }
}

/// Builds a resource query for the given filter.
Stream<QuerySnapshot> buildQuery(ResourceFilter filter) {
  // Start with a query on all verified resources.
  Query query = FirebaseFirestore.instance
      .collection('resources')
      .where('verified', isEqualTo: true);

  for (final category in categories) {
    if (category.field == 'nextDate') {
      // Skip processing next date -- it's won't be part of our Firestore query.
      continue;
    }

    // Collect all selected filters in this category
    final selectedValues = filter.categorical
        .where((e) => e.category == category.name)
        .map((e) => e.value)
        .toList();

    // If there are some, append a where clause to the query
    // TODO: uh oh, Firestore API complains if you have more than one
    // `whereIn` clause in a query. (I suspect it might also complain
    // about multiple `arrayContainsAny`.) We may have to make filter
    // chips act more like radio buttons -- at least for certain categories --
    // so that those queries can be "equals" rather than "in".
    if (selectedValues.isNotEmpty) {
      if (category.canHaveMultiple) {
        // If data is an array, we do an 'arrayContainsAny' query
        query = query.where(category.field, arrayContainsAny: selectedValues);
      } else {
        // If data is a single value, we do a 'whereIn' query.
        query = query.where(category.field, whereIn: selectedValues);
      }
    }
  }

  if (filter.textual != null) {
    // Append text search clause
    query = query.where('name', isEqualTo: filter.textual);
    // TODO: how can we improve match quality?
    // Issues:
    // - this is an exact match,
    // - only on name, and
    // - doesn't account for casing differences.
    // Ideal solution would be a proper search database like Solr or Elasticsearch.
  }

  return query.snapshots();
}

bool Function(QueryDocumentSnapshot) clientSideFilter(ResourceFilter filter) {
  // The Timeframe (nextDate) filter is handled without Firestore.
  final timeFrames = filter.categorical
      .where((e) => e.category == 'Event happening in the next')
      .map((e) => e.value)
      .toList();

  // If the user has selected some timeframe filters, return a filter function
  // the checks if events' next date is in the indicated range.
  if (timeFrames.isNotEmpty) {
    final dur = timeFrames.contains('3 Months')
        ? Duration(days: 90)
        : timeFrames.contains('Month')
            ? Duration(days: 30)
            : Duration(days: 7);
    final until = DateTime.now().add(dur);

    return (r) {
      if (r['resourceType'] == 'Event') {
        // Events are included if their next date is before the `until` date.
        final schedule = Schedule.fromJson(r['schedule']);
        final next = schedule.getNextDate();
        return next?.isBefore(until) ?? false;
      } else {
        // Non-events are filtered out.
        return false;
      }
    };
  }

  // TODO: will have to think about how to handle multiple filters
  // if and when we get there.

  // The empty filter is just accept everything!
  return (r) => true;
}
