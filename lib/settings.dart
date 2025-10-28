import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'main.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<StatefulWidget> createState() => _SettingState();
}

class _SettingState extends State<Settings> {
  @override
  void initState() {
    super.initState();
    settingsNotifier.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 10,
      left: 10,
      child: IconButton(
        onPressed: () {
          showModalBottomSheet<void>(
            context: context,
            useRootNavigator: true,
            builder: (BuildContext context) {
              // Use StatefulBuilder to give the bottom sheet's content its own state.
              return StatefulBuilder(
                builder: (BuildContext context, StateSetter setModalState) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Paramètres',
                            style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor)),
                        const Divider(
                          indent: 20,
                          endIndent: 20,
                        ),
                        SwitchListTile(
                          title: const Text('Mode apprentissage', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text(
                              'Retiens les réponses, et privilégie les questions difficiles',
                              style: TextStyle(fontSize: 13)),
                          value: settingsNotifier.apprentissage,
                          onChanged: (v) {
                            // Update the notifier, then call the local setState for the modal.
                            setModalState(() {
                              settingsNotifier.apprentissage = v;
                            });
                          },
                        ),
                        SwitchListTile(
                          title: const Text('Inverser les cartes', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text(
                              'Inverse la face caché et la visible des cartes',
                              style: TextStyle(fontSize: 13)),
                          value: settingsNotifier.reverseCardOrientation,
                          onChanged: (v) {
                            // Update the notifier, then call the local setState for the modal.
                            setModalState(() {
                              settingsNotifier.reverseCardOrientation = v;
                            });
                          },
                        ),
                        SwitchListTile(
                          title: const Text('Mélanger l\'orientation', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text(
                              'Chaque carte aura une orientation aléatoire',
                              style: TextStyle(fontSize: 13)),
                          value: settingsNotifier.mixCardOrientation,
                          onChanged: (v) {
                            // Update the notifier, then call the local setState for the modal.
                            setModalState(() {
                              settingsNotifier.mixCardOrientation = v;
                            });
                          },
                        ),
                        const Divider(),
                        Text(
                          "Bugs, Nouveaux Quiz, Questions :",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        GestureDetector(
                          onTap: () async {
                            const url =
                                'mailto:flash.card@clsn.fr?subject=Bug, Nouveaux Quiz, Question&body=';
                            if (await canLaunchUrlString(url)) {
                              await launchUrlString(url);
                            } else {
                              throw 'Could not launch $url';
                            }
                          },
                          child: Text(
                            "flash.card@clsn.fr",
                            style:
                                Theme.of(context).textTheme.bodyLarge!.copyWith(
                                      color: Theme.of(context).primaryColor,
                                      // underline in color of primaryColor
                                      decoration: TextDecoration.underline,
                                      decorationColor:
                                          Theme.of(context).primaryColor,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
        icon: Icon(
          size: 25,
          Icons.settings_outlined,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
