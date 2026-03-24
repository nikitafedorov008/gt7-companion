import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/profile/profile_bloc.dart';
import '../blocs/profile/profile_event.dart';
import '../blocs/profile/profile_state.dart';

@RoutePage()
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nickController = TextEditingController();

  @override
  void dispose() {
    _nickController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final nickname = _nickController.text.trim();
    if (nickname.isEmpty) return;

    context.read<ProfileBloc>().add(
      ProfileEvent.loadPlayer(onlineId: nickname),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Player Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nickController,
              decoration: const InputDecoration(
                labelText: 'DG-Edge player nickname',
                hintText: 'e.g. nikitawolf008',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _refresh(),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.search),
              label: const Text('Load profile events'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<ProfileBloc, ProfileState>(
                builder: (context, state) {
                  if (state.error != null) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Error: ${state.error}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _refresh,
                          child: const Text('Try again'),
                        ),
                      ],
                    );
                  }

                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.events.isEmpty) {
                    return const Center(
                      child: Text('No player events loaded yet'),
                    );
                  }

                  return ListView.builder(
                    itemCount: state.events.length,
                    itemBuilder: (context, index) {
                      final event = state.events[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(event.eventType ?? 'Event'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (event.trackName != null)
                                Text('Track: ${event.trackName}'),
                              if (event.carName != null)
                                Text('Car: ${event.carName}'),
                              if (event.playerResult != null)
                                Text(
                                  'Position: ${event.playerResult!.globalPosition} / ${event.playerResult!.countryPosition}',
                                ),
                              if (event.playerResult?.time != null)
                                Text('Time: ${event.playerResult!.time}'),
                              if (event.playerResult?.timestamp != null)
                                Text(
                                  'Updated: ${event.playerResult!.timestamp}',
                                ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (event.isActive)
                                const Chip(label: Text('Active')),
                              if (event.isFuture)
                                const Chip(label: Text('Future')),
                              if (event.isEnded)
                                const Chip(label: Text('Ended')),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
