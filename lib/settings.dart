import 'package:flutter/material.dart';
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
                          title: const Text('Mode apprentissage'),
                          subtitle: const Text(
                              'Retiens les réponses, et privilégie les questions difficiles'),
                          value: settingsNotifier.apprentissage,
                          onChanged: (v) {
                            // Update the notifier, then call the local setState for the modal.
                            setModalState(() {
                              settingsNotifier.apprentissage = v;
                            });
                          },
                        ),
                        SwitchListTile(
                          title: const Text('Inverser les cartes'),
                          subtitle: const Text(
                              'Inverse la face caché et la visible des cartes'),
                          value: settingsNotifier.reverseCardOrientation,
                          onChanged: (v) {
                            // Update the notifier, then call the local setState for the modal.
                            setModalState(() {
                              settingsNotifier.reverseCardOrientation = v;
                            });
                          },
                        ),
                        SwitchListTile(
                          title: const Text('Mélanger l\'orientation'),
                          subtitle: const Text(
                              'Chaque carte aura une orientation aléatoire'),
                          value: settingsNotifier.mixCardOrientation,
                          onChanged: (v) {
                            // Update the notifier, then call the local setState for the modal.
                            setModalState(() {
                              settingsNotifier.mixCardOrientation = v;
                            });
                          },
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
