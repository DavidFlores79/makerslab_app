import os
import argparse
from string import Template

def create_feature_structure(feature_name):
    base_path = f"lib/features/{feature_name}"
    feature_class = feature_name.title().replace('_', '')
    feature_name_snake_case = feature_name.lower() # Para nombres de archivo como investment_local_datasource

    # --- Plantillas actualizadas o añadidas ---

    # Plantilla para el BLOC (CORREGIDA)
    bloc_template = Template('''import 'package:flutter_bloc/flutter_bloc.dart';
import '${feature_name_snake_case}_event.dart';
import '${feature_name_snake_case}_state.dart';
import '../../domain/usecases/get_${feature_name_snake_case}_data_usecase.dart';

class ${feature_class}sBloc extends Bloc<${feature_class}sEvent, ${feature_class}sState> {
  final Get${feature_class}DataUseCase get${feature_class}Data;

  ${feature_class}sBloc({
    required this.get${feature_class}Data,
  }) : super(InitialDataLoading()) {
    on<Load${feature_class}s>(_onLoad${feature_class}s);
  }

  Future<void> _onLoad${feature_class}s(
    Load${feature_class}s event,
    Emitter<${feature_class}sState> emit,
  ) async {
    emit(${feature_class}sLoading());
    final result = await get${feature_class}Data();
    result.fold(
      (error) => emit(${feature_class}sError(error.message)),
      (data) => emit(${feature_class}sLoaded(data: data)), // CAMBIO AQUÍ: 'data' en lugar de '${feature_name_snake_case}s'
    );
  }
}''')

    # Plantilla para el ESTADO (CORREGIDA)
    state_template = Template('''import '../../domain/entities/${feature_name_snake_case}_entity.dart';

abstract class ${feature_class}sState {}

class InitialDataLoading extends ${feature_class}sState {}

class ${feature_class}sLoading extends ${feature_class}sState {}

class ${feature_class}sLoaded extends ${feature_class}sState {
  final List<${feature_class}Entity> data; // CAMBIO AQUÍ: 'data' en lugar de 'investments'

  ${feature_class}sLoaded({required this.data}); // CAMBIO AQUÍ: 'data' en lugar de 'investments'
}

class ${feature_class}sError extends ${feature_class}sState {
  final String message;
  ${feature_class}sError(this.message);
}''')

    # Plantilla para el EVENTO
    event_template = Template('''abstract class ${feature_class}sEvent {}

class Load${feature_class}s extends ${feature_class}sEvent {}''')

    # Plantilla para la ENTIDAD
    entity_template = Template('''class ${feature_class}Entity {
  final String id;

  ${feature_class}Entity({
    required this.id,
  });
}''')

    # Plantilla para el REPOSITORIO ABSTRACTO
    repository_abstract_template = Template('''import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/${feature_name_snake_case}_entity.dart';

abstract class ${feature_class}Repository {
  Future<Either<Failure, List<${feature_class}Entity>>> get${feature_class}Data();
}''')

    # Plantilla para la IMPLEMENTACIÓN del REPOSITORIO
    repository_impl_template = Template('''import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/${feature_name_snake_case}_entity.dart';
import '../../domain/repositories/${feature_name_snake_case}_repository.dart';
import '../datasources/${feature_name_snake_case}_local_datasource.dart';

class ${feature_class}RepositoryImpl implements ${feature_class}Repository {
  final ${feature_class}LocalDatasource localDatasource;

  ${feature_class}RepositoryImpl({
    required this.localDatasource,
  });

  @override
  Future<Either<Failure, List<${feature_class}Entity>>> get${feature_class}Data() async {
    try {
      final data = await localDatasource.get${feature_class}Data(); // CAMBIO AQUÍ: 'data' en lugar de '${feature_name_snake_case}s'
      return Right(data); // CAMBIO AQUÍ: 'data' en lugar de '${feature_name_snake_case}s'
    } on CacheException catch (e, stackTrace) {
      return Left(CacheFailure(e.message, stackTrace));
    }
  }
}''')

    # Plantilla para el DATASOURCE LOCAL ABSTRACTO
    local_datasource_abstract_template = Template('''import '../../domain/entities/${feature_name_snake_case}_entity.dart';

abstract class ${feature_class}LocalDatasource {
  Future<List<${feature_class}Entity>> get${feature_class}Data();
}''')

    # Plantilla para la IMPLEMENTACIÓN del DATASOURCE LOCAL
    local_datasource_impl_template = Template('''import 'package:logger/logger.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/${feature_name_snake_case}_entity.dart';
import '../datasources/${feature_name_snake_case}_local_datasource.dart';

class ${feature_class}LocalDatasourceImpl implements ${feature_class}LocalDatasource {
  final Logger logger;

  ${feature_class}LocalDatasourceImpl({required this.logger});

  @override
  Future<List<${feature_class}Entity>> get${feature_class}Data() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      logger.i("Obteniendo ${feature_name_snake_case}s localmente...");
      return sample${feature_class}s;
    } catch (e, stackTrace) {
      logger.e('Error getting local data for ${feature_name_snake_case}', error: e, stackTrace: stackTrace);
      throw CacheException('Error al obtener ${feature_name_snake_case}s locales', stackTrace);
    }
  }
}

final List<${feature_class}Entity> sample${feature_class}s = [
  ${feature_class}Entity(id: '${feature_name_snake_case}-001'),
  ${feature_class}Entity(id: '${feature_name_snake_case}-002'),
];
''')

    # Plantilla para el USECASE (ajustada para el repositorio modificado)
    usecase_template = Template('''import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/${feature_name_snake_case}_entity.dart';
import '../repositories/${feature_name_snake_case}_repository.dart';

class Get${feature_class}DataUseCase {
  final ${feature_class}Repository repository;

  Get${feature_class}DataUseCase(this.repository);

  Future<Either<Failure, List<${feature_class}Entity>>> call() async {
    return await repository.get${feature_class}Data();
  }
}''')

    # Plantilla genérica para archivos sin contenido específico que no deben ser borrados
    default_empty_template = Template('''// Este archivo fue generado automáticamente como parte de la estructura.
// Puedes añadir contenido aquí si es necesario.
// Ruta: ${file_path}
''')

    # --- Definición de la estructura de carpetas y archivos ---
    structure = {
        "data": {
            "datasources": [
                f"{feature_name_snake_case}_local_datasource.dart",
                f"{feature_name_snake_case}_local_datasource_impl.dart",
                f"{feature_name_snake_case}_remote_datasource.dart"
            ],
            "models": [
                f"{feature_name_snake_case}_model.dart"
            ],
            "repositories": [
                f"{feature_name_snake_case}_repository_impl.dart"
            ]
        },
        "domain": {
            "entities": [
                f"{feature_name_snake_case}_entity.dart"
            ],
            "repositories": [
                f"{feature_name_snake_case}_repository.dart"
            ],
            "usecases": [
                f"get_{feature_name_snake_case}_data_usecase.dart"
            ]
        },
        "presentation": {
            "pages": [
                f"{feature_name_snake_case}_page.dart"
            ],
            "bloc": [
                f"{feature_name_snake_case}_bloc.dart",
                f"{feature_name_snake_case}_state.dart",
                f"{feature_name_snake_case}_event.dart"
            ]
        }
    }

    # --- Lógica de creación ---
    for layer, subdirs in structure.items():
        for subdir, files in subdirs.items():
            dir_path = os.path.join(base_path, layer, subdir)
            os.makedirs(dir_path, exist_ok=True)

            for file in files:
                file_path = os.path.join(dir_path, file)
                with open(file_path, 'w') as f:
                    if file == f"{feature_name_snake_case}_bloc.dart":
                        f.write(bloc_template.substitute(feature_name_snake_case=feature_name_snake_case, feature_class=feature_class))
                    elif file == f"{feature_name_snake_case}_state.dart":
                        f.write(state_template.substitute(feature_name_snake_case=feature_name_snake_case, feature_class=feature_class))
                    elif file == f"{feature_name_snake_case}_event.dart":
                        f.write(event_template.substitute(feature_name_snake_case=feature_name_snake_case, feature_class=feature_class))
                    elif file == f"{feature_name_snake_case}_entity.dart":
                        f.write(entity_template.substitute(feature_name_snake_case=feature_name_snake_case, feature_class=feature_class))
                    elif file == f"{feature_name_snake_case}_repository.dart":
                        f.write(repository_abstract_template.substitute(feature_name_snake_case=feature_name_snake_case, feature_class=feature_class))
                    elif file == f"{feature_name_snake_case}_repository_impl.dart":
                        f.write(repository_impl_template.substitute(feature_name_snake_case=feature_name_snake_case, feature_class=feature_class))
                    elif file == f"{feature_name_snake_case}_local_datasource.dart":
                        f.write(local_datasource_abstract_template.substitute(feature_name_snake_case=feature_name_snake_case, feature_class=feature_class))
                    elif file == f"{feature_name_snake_case}_local_datasource_impl.dart":
                        f.write(local_datasource_impl_template.substitute(feature_name_snake_case=feature_name_snake_case, feature_class=feature_class))
                    elif file == f"get_{feature_name_snake_case}_data_usecase.dart":
                        f.write(usecase_template.substitute(feature_name_snake_case=feature_name_snake_case, feature_class=feature_class))
                    # Archivos que se mantienen con una plantilla por defecto si no hay contenido específico
                    else:
                        f.write(default_empty_template.substitute(file_path=file_path))


    print(f"Estructura completa para la feature '{feature_name}' creada exitosamente!")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Crear estructura de feature Flutter con BLoC completo')
    parser.add_argument('feature', type=str, help='Nombre de la feature a crear')
    args = parser.parse_args()

    create_feature_structure(args.feature)