abstract class Repository<T> {
  Future<T?> findById(String id);

  Future<List<T>> findAll();
}
