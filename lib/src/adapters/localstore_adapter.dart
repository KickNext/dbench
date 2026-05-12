export 'localstore_adapter_stub.dart'
    if (dart.library.io) 'localstore_adapter_impl.dart'
    if (dart.library.html) 'localstore_adapter_impl.dart'
    show createLocalstoreAdapter;
