export 'get_storage_adapter_stub.dart'
    if (dart.library.io) 'get_storage_adapter_impl.dart'
    if (dart.library.html) 'get_storage_adapter_impl.dart'
    show createGetStorageAdapter;
