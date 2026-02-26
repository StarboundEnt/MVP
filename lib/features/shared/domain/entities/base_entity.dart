import 'package:equatable/equatable.dart';

/// Base entity class that all domain entities should extend
/// 
/// Provides common functionality for:
/// - Identity comparison
/// - Immutability
/// - JSON serialization contracts
abstract class BaseEntity extends Equatable {
  /// Unique identifier for the entity
  final String id;
  
  /// Timestamp when entity was created
  final DateTime createdAt;
  
  /// Timestamp when entity was last updated
  final DateTime updatedAt;

  const BaseEntity({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert entity to JSON representation
  Map<String, dynamic> toJson();

  /// Create entity from JSON representation
  /// This method should be implemented by concrete classes
  /// as a static factory method

  @override
  List<Object?> get props => [id];

  @override
  bool get stringify => true;

  /// Check if entity is valid
  bool get isValid => id.isNotEmpty;

  /// Create a copy of this entity with updated timestamp
  BaseEntity copyWithUpdatedAt(DateTime updatedAt);
}

/// Value object base class for domain value objects
abstract class ValueObject extends Equatable {
  const ValueObject();

  @override
  bool get stringify => true;

  /// Check if value object is valid
  bool get isValid;

  /// Get validation errors if any
  List<String> get validationErrors => [];
}

/// Result wrapper for operations that can fail
class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  const Result._({
    this.data,
    this.error,
    required this.isSuccess,
  });

  /// Create successful result
  factory Result.success(T data) {
    return Result._(
      data: data,
      isSuccess: true,
    );
  }

  /// Create failure result
  factory Result.failure(String error) {
    return Result._(
      error: error,
      isSuccess: false,
    );
  }

  /// Check if result is failure
  bool get isFailure => !isSuccess;

  /// Transform successful result
  Result<U> map<U>(U Function(T data) transform) {
    if (isSuccess && data != null) {
      try {
        return Result.success(transform(data!));
      } catch (e) {
        return Result.failure(e.toString());
      }
    }
    return Result.failure(error ?? 'Unknown error');
  }

  /// Handle result with callbacks
  U fold<U>(
    U Function(String error) onFailure,
    U Function(T data) onSuccess,
  ) {
    if (isSuccess && data != null) {
      return onSuccess(data!);
    }
    return onFailure(error ?? 'Unknown error');
  }
}

/// Base repository interface
abstract class Repository {
  /// Get entity by ID
  Future<Result<T>> getById<T extends BaseEntity>(String id);
  
  /// Save entity
  Future<Result<T>> save<T extends BaseEntity>(T entity);
  
  /// Delete entity
  Future<Result<void>> delete(String id);
  
  /// Get all entities
  Future<Result<List<T>>> getAll<T extends BaseEntity>();
}