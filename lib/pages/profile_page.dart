import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../blocs/profile/profile_bloc.dart';
import '../blocs/profile/profile_event.dart';
import '../blocs/profile/profile_state.dart';
import '../models/gt7_sport_race_stats.dart';
import '../models/gt7_stats.dart';
import '../models/gt7_user_profile.dart';
import '../models/gt7_user_stats.dart';
import '../widgets/profile/gt7_stats_panel.dart';
import '../pages/login_page.dart';
import '../repositories/gt7_auth_repository.dart';
import '../services/gt7_api_service.dart';

@RoutePage()
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _lastLoadedPsnId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = context.read<Gt7AuthRepositoryImpl>();
      repo.init().then((_) {
        if (repo.isAuthenticated && repo.profile == null) {
          repo.fetchProfile().then((_) => _autoLoadDgEdgeEvents());
        } else if (repo.profile != null) {
          _autoLoadDgEdgeEvents();
        }
      });
    });
  }

  void _autoLoadDgEdgeEvents() {
    final repo = context.read<Gt7AuthRepositoryImpl>();
    final profile = repo.profile;
    if (profile == null || profile.npOnlineId.isEmpty) return;
    if (_lastLoadedPsnId == profile.npOnlineId) return;

    _lastLoadedPsnId = profile.npOnlineId;
    context.read<ProfileBloc>().add(
      ProfileEvent.loadPlayer(onlineId: profile.npOnlineId),
    );
  }

  Future<void> _login() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
    if (result == true && mounted) {
      final repo = context.read<Gt7AuthRepositoryImpl>();
      await repo.fetchProfile();
      _autoLoadDgEdgeEvents();
      setState(() {});
    }
  }

  Future<void> _logout() async {
    final repo = context.read<Gt7AuthRepositoryImpl>();
    await repo.logout();
    _lastLoadedPsnId = null;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<Gt7AuthRepositoryImpl>();
    final apiService = context.watch<Gt7ApiService>();
    final theme = Theme.of(context);

    if (!repo.isAuthenticated) {
      return _buildLoginPrompt(theme);
    }

    final profile = repo.profile;
    final stats = apiService.stats;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Cover + Driver + Avatar header
          _Gt7ProfileHeader(
            profile: profile,
            stats: stats,
            isLoading: repo.isLoading,
            onLogout: _logout,
          ),

          // Stats section
          if (profile != null) ...[
            _StatsSection(
              profile: profile,
              stats: stats,
              fullStats: apiService.fullStats,
              sportRaces: apiService.sportRaces,
            ),
            const SizedBox(height: 16),
            _AboutSection(profile: profile),
          ],

          // DG-Edge races
          const SizedBox(height: 16),
          _RacesSection(lastLoadedPsnId: _lastLoadedPsnId),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt(ThemeData theme) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_circle_outlined, size: 80, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Text('Sign in with PlayStation', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(
                'Connect your PSN account to see your GT7 profile, stats, and race history.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _login,
                icon: const Icon(Icons.login),
                label: const Text('Sign in via PSN'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0070D1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// GT7-style profile header with cover, driver photo, avatar, and ratings.
class _Gt7ProfileHeader extends StatelessWidget {
  const _Gt7ProfileHeader({
    required this.profile,
    required this.stats,
    required this.isLoading,
    required this.onLogout,
  });

  final Gt7UserProfile? profile;
  final Gt7UserStats? stats;
  final bool isLoading;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover photo
        if (profile?.coverUrl != null)
          Image.network(
            profile!.coverUrl!,
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const _CoverPlaceholder(),
          )
        else
          const _CoverPlaceholder(),

        // Driver photo overlay (right side)
        if (profile?.driverUrl != null)
          Positioned(
            right: 16,
            bottom: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                profile!.driverUrl!,
                height: 180,
                width: 120,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),

        // Gradient overlay at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 120,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, theme.scaffoldBackgroundColor],
              ),
            ),
          ),
        ),

        // Avatar + Name + Country + Followers
        Positioned(
          bottom: -40,
          left: 16,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.scaffoldBackgroundColor, width: 3),
                ),
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: theme.colorScheme.primary,
                  backgroundImage: profile?.avatarUrl != null
                      ? NetworkImage(profile!.avatarUrl!)
                      : null,
                  child: profile?.avatarUrl == null
                      ? Text(
                          profile?.nickName.isNotEmpty == true
                              ? profile!.nickName[0].toUpperCase()
                              : '?',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              // Name + PSN ID + Country + Followers
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (profile != null) ...[
                    Text(
                      profile!.nickName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '@${profile!.npOnlineId}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        if (profile!.countryCode.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              profile!.countryCode,
                              style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                        if (stats?.followers != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${stats!.followers} followers',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Logout button
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 8,
          child: IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Sign out',
            onPressed: onLogout,
          ),
        ),

        // Loading indicator
        if (isLoading && profile == null)
          const Positioned.fill(
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

/// Statistics block, laid out like the one on the GT7 profile page: the four
/// ratings in a row, then the grouped figures from `/stats/get`.
class _StatsSection extends StatelessWidget {
  const _StatsSection({
    required this.profile,
    required this.stats,
    required this.fullStats,
    required this.sportRaces,
  });

  final Gt7UserProfile profile;
  final Gt7UserStats? stats;
  final Gt7Stats? fullStats;
  final List<Gt7SportRaceStats> sportRaces;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          if (profile.greeting.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                children: [
                  Icon(Icons.waving_hand, size: 16, color: theme.colorScheme.secondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      profile.greeting,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // The four ratings, as the site shows them under the cover.
          if (stats != null)
            Gt7RatingRow(
              collectionLevel: stats!.collectionLevel,
              experience: fullStats?.profile.exp,
              license: stats!.license,
              driverRating: stats!.driverRating,
              driverRatingRatio: stats!.driverRatingRatio,
              safetyRating: stats!.safetyRating,
            ),

          const SizedBox(height: 16),

          // Grouped figures. Only rendered once /stats/get has answered —
          // there is nothing meaningful to show from the other endpoints.
          if (fullStats != null)
            Gt7StatsPanel(stats: fullStats!, sportRaces: sportRaces),
        ],
      ),
    );
  }
}


/// About me section.
class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.profile});
  final Gt7UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (profile.aboutMe.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About me', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(profile.aboutMe, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// Races section with DG-Edge events.
class _RacesSection extends StatelessWidget {
  const _RacesSection({required this.lastLoadedPsnId});
  final String? lastLoadedPsnId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, size: 20, color: theme.colorScheme.secondary),
              const SizedBox(width: 8),
              Text('Recent Races', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              if (lastLoadedPsnId != null) ...[
                const SizedBox(width: 8),
                Text(
                  '@$lastLoadedPsnId',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              return state.when(
                initial: () => Text(
                  'Sign in to see your race history',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (message) => Text(
                  'Error: $message',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                loaded: (onlineId, events, pagination, csrfToken) {
                  if (events.isEmpty) {
                    return Text(
                      'No race events found',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    );
                  }

                  return Column(
                    children: events.map((event) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(event.eventType ?? 'Event'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (event.trackName != null) Text('Track: ${event.trackName}'),
                              if (event.carName != null) Text('Car: ${event.carName}'),
                              if (event.playerResult != null)
                                Text('Position: ${event.playerResult!.globalPosition} / ${event.playerResult!.countryPosition}'),
                              if (event.playerResult?.time != null) Text('Time: ${event.playerResult!.time}'),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (event.isActive) const Chip(label: Text('Active')),
                              if (event.isFuture) const Chip(label: Text('Future')),
                              if (event.isEnded) const Chip(label: Text('Ended')),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 220,
      color: theme.colorScheme.primaryContainer,
      child: Center(
        child: Icon(
          Icons.landscape,
          size: 48,
          color: theme.colorScheme.onPrimaryContainer.withOpacity(0.3),
        ),
      ),
    );
  }
}
