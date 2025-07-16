import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:web_app/util.dart';
import 'package:web_app/view_resource/resource_detail.dart';
import 'package:provider/provider.dart';
import 'package:web_app/Analytics.dart';
import 'package:web_app/model.dart';

final typeIcon = const {
  'Online': Icons.wifi,
  'In Person': Icons.people_alt,
  'App': Icons.phone_iphone,
  'Hotline': Icons.phone,
  'Event': Icons.calendar_month,
  'Podcast': Icons.podcasts,
  'PDF': Icons.picture_as_pdf,
  'Game': Icons.casino,
  'Movement-based Activity': Icons.directions_run,
};

/// Summary view of a resource as a ListTile, suitable for display
/// in a scrolling list of resources.
class ResourceSummary extends StatelessWidget {
  ResourceSummary(
      {super.key, required this.resourceModel, required this.isSmallScreen});

  final Resource resourceModel;
  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    var description = resourceModel.description!;
    if (resourceModel.resourceType == 'Event') {
      final schedule = resourceModel.schedule!;
      final next = schedule.getNextDate(
        // Get 'next' date from yesterday, so that events
        // that are happening today are shown as today.
        after: DateTime.now().subtract(const Duration(days: 1)),
      );
      if (next != null) {
        description = "Next date: ${schedule.format(next)}\n${description}";
      }
    }

    Future<bool> setVisabilityStatus(bool isVisable) async {
      try {
        final resources = FirebaseFirestore.instance.collection('resources');
        await resources.doc(resourceModel.id).update({'isVisable': isVisable});
        return true;
      } catch (error) {
        return false;
      }
    }

    Widget managerButton(bool vis) {
      String visStatus = vis ? "Archive" : "Un-archive";
      return TextButton(
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
          backgroundColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
            if (states.contains(MaterialState.focused)) {
              return Theme.of(context).primaryColor.withOpacity(0.7);
            }
            return Theme.of(context).primaryColor;
          }),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
            side: BorderSide(color: Theme.of(context).primaryColor),
          )),
        ),
        onPressed: () {
          setVisabilityStatus(!vis).then((bool status) {
            String stringStatus = status
                ? "You have successfully ${visStatus.toLowerCase()}d this resource."
                : "There was a problem updating the resource.";
            showAlertDialog(context, stringStatus);
          });
        },
        child: Text(visStatus),
      );
    }

    final visable = (resourceModel.isVisable ?? true) || user != null;
    if (!visable) {
      return SizedBox.shrink();
    } else {
      return Container(
        height: 100,
        child: Card(
          color: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 30),
            dense: false,
            title: Text(
              resourceModel.name!, 
              textAlign: TextAlign.left,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              maxLines: isSmallScreen ? 1 : 1,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 18 : 25,
              ),
            ),
            subtitle: Text(
              description,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              softWrap: true,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 12 : 14,
              ),
            ),
            leading: (user == null)
                ? Icon(
                    typeIcon[resourceModel.resourceType] ?? Icons.help,
                    color: Colors.black,
                  )
                : managerButton(resourceModel.isVisable),
            trailing: Icon(
              Icons.arrow_forward_rounded,
              color: Colors.black,
            ),
            onTap: () {
              final homeAnalytics = Provider.of<HomeAnalytics>(context, listen: false);
              homeAnalytics.submitClickedResource(resourceModel.id);

             showDialog(
              context: context,
              builder: (dialogContext) {
                return ChangeNotifierProvider<HomeAnalytics>.value(
                  value: homeAnalytics,
                  child: ResourceDetail(resourceModel: resourceModel),
                );
              },
            );
            },
          ),
        ),
      );
    }
  }
}
