import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_fan_cooling/core/theme/app_colors.dart';
import 'package:smart_fan_cooling/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:smart_fan_cooling/features/hardware_monitor/data/services/hardware_monitor_service.dart';
import 'package:smart_fan_cooling/features/hardware_monitor/presentation/bloc/hardware_bloc.dart';
import 'package:smart_fan_cooling/features/profiles/data/repositories/profile_repository.dart';
import 'package:smart_fan_cooling/features/profiles/presentation/bloc/profile_bloc.dart';
import 'package:smart_fan_cooling/features/rgb_lighting/presentation/bloc/rgb_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartFanApp());
}

class SmartFanApp extends StatelessWidget {
  const SmartFanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<HardwareMonitorService>(
          create: (_) => HardwareMonitorService(),
        ),
        RepositoryProvider<ProfileRepository>(
          create: (_) => ProfileRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<HardwareBloc>(
            create: (context) => HardwareBloc(
              context.read<HardwareMonitorService>(),
            ),
          ),
          BlocProvider<ProfileBloc>(
            create: (context) => ProfileBloc(
              context.read<ProfileRepository>(),
            ),
          ),
          BlocProvider<RgbBloc>(
            create: (_) => RgbBloc(),
          ),
        ],
        child: MaterialApp(
          title: 'Llano Smart Fan Control Hub',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: AppColors.background,
            primaryColor: AppColors.primary,
            cardColor: AppColors.cardBg,
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              secondary: AppColors.secondary,
              surface: AppColors.surface,
            ),
          ),
          home: const DashboardScreen(),
        ),
      ),
    );
  }
}
