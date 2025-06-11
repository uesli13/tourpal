/// Base repository interface defining common CRUD operations
/// Following the Repository Pattern for data abstraction
abstract class BaseRepository<T, ID> {
  /// Create a new entity
  Future<T> create(T entity);
  
  /// Read an entity by ID
  Future<T?> findById(ID id);
  
  /// Update an existing entity
  Future<T> update(T entity);
  
  /// Delete an entity by ID
  Future<void> delete(ID id);
  
  /// Check if an entity exists
  Future<bool> exists(ID id);
  
  /// Get all entities (with optional pagination)
  Future<List<T>> findAll({int? limit, String? cursor});
}

/// Repository interface for querying operations
abstract class QueryableRepository<T> {
  /// Find entities by field value
  Future<List<T>> findBy(String field, dynamic value, {int? limit});
  
  /// Find entities with complex queries
  Future<List<T>> findWhere(Map<String, dynamic> conditions, {int? limit});
  
  /// Search entities with text query
  Future<List<T>> search(String query, {int? limit});
  
  /// Count entities matching conditions
  Future<int> count([Map<String, dynamic>? conditions]);
}

/// Repository interface for real-time operations
abstract class StreamRepository<T, ID> {
  /// Stream changes for an entity by ID
  Stream<T?> watchById(ID id);
  
  /// Stream changes for all entities
  Stream<List<T>> watchAll({int? limit});
  
  /// Stream changes for entities matching conditions
  Stream<List<T>> watchWhere(Map<String, dynamic> conditions, {int? limit});
}