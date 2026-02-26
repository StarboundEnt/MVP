class Result<T> {
  final T? _data;
  final String? _error;

  const Result._(this._data, this._error);

  const Result.success(T data) : this._(data, null);

  const Result.failure(String error) : this._(null, error);

  bool get isSuccess => _error == null;
  bool get isFailure => _error != null;

  T? get data => _data;
  String? get error => _error;

  Result<U> map<U>(U Function(T data) transform) {
    if (isSuccess && _data != null) {
      try {
        return Result.success(transform(_data as T));
      } catch (e) {
        return Result.failure(e.toString());
      }
    }
    return Result.failure(_error ?? 'Unknown error');
  }

  Result<T> mapError(String Function(String error) transform) {
    if (isFailure && _error != null) {
      return Result.failure(transform(_error!));
    }
    return this;
  }

  U fold<U>(U Function(String error) onFailure, U Function(T data) onSuccess) {
    if (isSuccess && _data != null) {
      return onSuccess(_data as T);
    }
    return onFailure(_error ?? 'Unknown error');
  }

  T getOrThrow() {
    if (isSuccess && _data != null) {
      return _data as T;
    }
    throw Exception(_error ?? 'Unknown error');
  }

  T getOrDefault(T defaultValue) {
    return isSuccess && _data != null ? _data as T : defaultValue;
  }

  T getOrElse(T Function() defaultValue) {
    return isSuccess && _data != null ? _data as T : defaultValue();
  }

  Result<U> flatMap<U>(Result<U> Function(T data) transform) {
    if (isSuccess && _data != null) {
      return transform(_data as T);
    }
    return Result.failure(_error ?? 'Unknown error');
  }

  Result<T> filter(bool Function(T data) predicate, String errorMessage) {
    if (isSuccess && _data != null) {
      if (predicate(_data as T)) {
        return this;
      }
      return Result.failure(errorMessage);
    }
    return Result.failure(_error ?? 'Unknown error');
  }

  T? toNullable() => _data;
}

extension ResultListExtension<T> on List<Result<T>> {
  List<T> getSuccesses() =>
      where((result) => result.isSuccess && result.data != null)
          .map((result) => result.data as T)
          .toList();

  List<String> getFailures() =>
      where((result) => result.isFailure && result.error != null)
          .map((result) => result.error as String)
          .toList();

  bool get allSuccessful => every((result) => result.isSuccess);
  bool get anySuccessful => any((result) => result.isSuccess);
  bool get allFailed => every((result) => result.isFailure);
  bool get anyFailed => any((result) => result.isFailure);

  Result<List<T>> combine() {
    if (allSuccessful) {
      return Result.success(getSuccesses());
    }
    final failures = getFailures();
    return Result.failure(failures.join(', '));
  }
}

extension AsyncResultExtension<T> on Future<Result<T>> {
  Future<Result<U>> mapAsync<U>(Future<U> Function(T data) transform) async {
    final result = await this;
    if (result.isSuccess && result.data != null) {
      try {
        final transformed = await transform(result.data as T);
        return Result.success(transformed);
      } catch (e) {
        return Result.failure(e.toString());
      }
    }
    return Result.failure(result.error ?? 'Unknown error');
  }

  Future<Result<U>> flatMapAsync<U>(
    Future<Result<U>> Function(T data) transform,
  ) async {
    final result = await this;
    if (result.isSuccess && result.data != null) {
      return transform(result.data as T);
    }
    return Result.failure(result.error ?? 'Unknown error');
  }

  Future<U> foldAsync<U>(
    Future<U> Function(String error) onFailure,
    Future<U> Function(T data) onSuccess,
  ) async {
    final result = await this;
    if (result.isSuccess && result.data != null) {
      return onSuccess(result.data as T);
    }
    return onFailure(result.error ?? 'Unknown error');
  }
}
