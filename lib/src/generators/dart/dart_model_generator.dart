import 'dart:io';

import 'package:mason/mason.dart';
import 'package:supagen/src/utils/extensions/extensions.dart';

class DartModelGenerator {
  final Logger logger;

  DartModelGenerator({
    required this.logger,
  });

  Future<void> generate({
    required String projectName,
    required Map<String, dynamic> tableDefinitions,
    String command = 'init',
  }) async {
    String path = './$projectName/lib/models';
    if (command == 'import') {
      path = './lib/models';

      if (!Directory(path).existsSync()) {
        throw '❌ Unable to find Dart models in: $path';
      }
    }
    logger.info('Generating Dart models in: $path...');

    final target = DirectoryGeneratorTarget(
      Directory.fromUri(Uri.parse(path)),
    );

    logger.info('Fetching Dart model template...');
    final brick = Brick.git(
      const GitPath(
        'https://github.com/supagen/supagen_bricks.git',
        path: 'bricks/dart/model',
      ),
    );
    final generator = await MasonGenerator.fromBrick(brick);
    logger.info('Dart model template fetched successfully!');

    for (final table in tableDefinitions.keys) {
      logger.info('Generating Dart model for table: $table...');
      final definitionProperties =
          tableDefinitions[table]['properties'] as Map<String, dynamic>;

      final properties = [];
      final propertiesTypes = [];

      for (final property in definitionProperties.keys) {
        final type = definitionProperties[property]['format'] as String;
        final dartType = type.toDartDataType();
        propertiesTypes.add('$dartType? ${property.camelCase}');
        properties.add(property.camelCase);
      }
      await generator.generate(target, vars: <String, dynamic>{
        'name': table.singularize,
        'properties_types': propertiesTypes,
        'properties': properties,
      });
      logger.info('Dart model generated successfully for table: $table');
    }

    logger.info('Dart models generated successfully in: $path');
  }
}
