import 'package:focuslock/core/di/injection_container.config.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection_container.dart';



final sl = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async => sl.init();

Future<void> init() async {
  await configureDependencies();
}
