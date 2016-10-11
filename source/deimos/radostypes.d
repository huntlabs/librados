module deimos.radostypes;
extern (C):

/**
 * @struct obj_watch_t
 * One item from list_watchers
 */
struct obj_watch_t
{
    char[256] addr;
    long watcher_id;
    ulong cookie;
    uint timeout_seconds;
}

/**
 * @defines
 *
 * Pass as nspace argument to rados_ioctx_set_namespace()
 * before calling rados_nobjects_list_open() to return
 * all objects in all namespaces.
 */
enum LIBRADOS_ALL_NSPACES = "\001";

