module radosd.ioctx;

import deimos.rados;

import std.string;
import std.exception;
import core.stdc.stdlib;
import std.traits;
import core.sync.mutex;
public import core.stdc.time;
import core.stdc.string;

public import radosd.exception;

alias iocBack =  void delegate(ref IoCompletion ioc);

struct IoCompletion
{
	~this()
	{
		release();
	}

	void waitForComplete()
	{
		if(_c is null) return;
		int err = rados_aio_wait_for_complete(_c);
		enforce(err >= 0,new IoCompletionException(format("rados_aio_wait_for_complete rados_ioctx_t erro!: %s",strerror(-err))));
	}

	void waitForSafe()
	{
		if(_c is null) return;
		int err = rados_aio_wait_for_safe(_c);
		enforce(err >= 0,new IoCompletionException(format("rados_aio_wait_for_safe rados_ioctx_t erro!: %s",strerror(-err))));
	}

	void waitForCompleteAndCb()
	{
		if(_c is null) return;
		int err = rados_aio_wait_for_complete_and_cb(_c);
		enforce(err >= 0,new IoCompletionException(format("rados_aio_wait_for_complete rados_ioctx_t erro!: %s",strerror(-err))));
	}
	
	void waitForSafeAndCb()
	{
		if(_c is null) return;
		int err = rados_aio_wait_for_safe_and_cb(_c);
		enforce(err >= 0,new IoCompletionException(format("rados_aio_wait_for_safe rados_ioctx_t erro!: %s",strerror(-err))));
	}

	bool isComplete()
	{
		if(_c is null) return true;
		int err = rados_aio_is_complete(_c);
		return err != 0;
	}

	bool isCompleteAndCb()
	{
		if(_c is null) return true;
		int err = rados_aio_is_complete_and_cb(_c);
		return err != 0;
	}

	bool isSafe()
	{
		if(_c is null) return true;
		int err = rados_aio_is_safe(_c);
		return err != 0;
	}

	bool isSafeAndCb()
	{
		if(_c is null) return true;
		int err = rados_aio_wait_for_safe_and_cb(_c);
		return err != 0;
	}

	void cancel(IoCompletion com)
	{
		if(_c is null) return;
		int err = rados_aio_cancel(_io.ctx, _c);
		enforce(err >= 0,new IoCtxException(format("rados_aio_cancel data erro : %s",strerror(-err))));
	}

	void release()
	{
		if(_c)
			rados_aio_release(_c);
		_c = null;
	}

	@property ctx(){return _io;}
	@property name(){return _name;}
	@property readData(){return _data;}
	@property statPsize(){return _psize;}
	@property statPmtime(){return _pmtime;}

private:
	this(IoCtx io, const(char) * name,bool onlyCom)
	{
		_io = io;
		_name = name;
		int err = 0;
		if(onlyCom)
			err = rados_aio_create_completion((&this),&doSafe,null,&_c);
		else
			err = rados_aio_create_completion((&this),&doComplate,&doSafe,&_c);
		enforce(err >= 0,new IoCtxException(format("rados_aio_create_completion data erro : %s",strerror(-err))));
	}

	void do_completion()
	{
		if(_completion)
			_completion(this);
	}

	void do_safe()
	{
		if(_safe)
			_safe(this);
	}

	iocBack _completion = null;
	iocBack _safe = null;
	rados_completion_t _c;
	IoCtx _io;
	const(char) * _name;
	char[] _data;
	size_t _psize;
	time_t _pmtime;
}

class IoCtx
{
	alias IoCompletionPtr = IoCompletion *;

	this(rados_t cluster, string poolname)
	{
		_cluster = cluster;
		_poolname = cast(char *)poolname.toStringz;
		int err = rados_ioctx_create(_cluster,_poolname,  &_io);
		enforce(err >= 0,new IoCtxException(format("create rados_ioctx_t erro!: %s",strerror(-err))));
		_mutex = new Mutex();
		//_cbacks = new RedBlackTree!(IoCompletionPtr)();
	}

	~this()
	{
		if(_io) {
			rados_aio_flush(_io);
			rados_ioctx_destroy(_io);
		}
	}

	@property ctx(){return _io;}

	@property poolName(){return _poolname;}

	void write(T)(string name,T[] data, ulong offset = 0) if(isCharByte!T)
	{
		write(name.toStringz,data,offset);
	}

	void write(T)(const(char) * name,in T[] data, ulong offset) if(isCharByte!T)
	{
		int err = rados_write(_io, name,cast(const(char) *)data.ptr, data.length, offset);
		enforce(err >= 0,new IoCtxWriteException(format("rados_write data erro : %s",strerror(-err))));
	}

	void writeFull(T)(string name,T[] data, ulong offset = 0) if(isCharByte!T)
	{
		writeFull(name.toStringz,data,offset);
	}

	void writeFull(T)(const(char) * name,in T[] data, ulong offset) if(isCharByte!T)
	{
		int err = rados_write_full(_io, name,cast(const(char) *)data.ptr, data.length, offset);
		enforce(err >= 0,new IoCtxWriteException(format("rados_write_full data erro : %s",strerror(-err))));
	}

	void writeSame(T)(const(char) * name,in T[] data, size_t writelen, ulong offset) if(isCharByte!T)
	{
		int err = rados_write_full(_io, name,cast(const(char) *)data.ptr, data.length,writelen, offset);
		enforce(err >= 0,new IoCtxWriteException(format("rados_writesame data erro : %s",strerror(-err))));
	}

	void cloneRange(const(char) * dst, size_t dstOffset, const(char) * src, size_t srcOffset, size_t len)
	{
		int err = rados_clone_range(_io, dst,dstOffset, src,srcOffset, len);
		enforce(err >= 0,new IoCtxCloneException(format("rados_clone_range data erro : %s",strerror(-err))));
	}

	void append(T)(const(char) * name,in T[] data)if(isCharByte!T)
	{
		int err = rados_append(_io, name,cast(const(char) *)data.ptr, data.length,writelen);
		enforce(err >= 0,new IoCtxCloneException(format("rados_append data erro : %s",strerror(-err))));
	}

	void read(T)(const(char) * name,ref T[] data, ulong offset = 0) if(isMutilCharByte!T)
	in{assert(data.length > 0);}
	body{
		int err = rados_read(_io, name,cast(char*)data.ptr, data.length, offset);
		enforce(err >= 0,new IoCtxReadException(format("rados_write data erro : %s",strerror(-err))));
	}

	char[] read(const(char) * name,size_t readlen, ulong offset = 0)
	{
		char[] data = new char[readlen];
		int err = rados_read(_io, name,data.ptr, readlen, offset);
		enforce(err >= 0,new IoCtxReadException(format("rados_write data erro : %s",strerror(-err))));
		return data;
	}

	void remove(const(char) * name)
	{
		int err = rados_remove(_io, name);
		enforce(err >= 0,new IoCtxException(format("rados_remove data erro : %s",strerror(-err))));
	}

	void trunc(const(char) * name,ulong size)
	{
		int err = rados_trunc(_io, name,size);
		enforce(err >= 0,new IoCtxException(format("rados_trunc data erro : %s",strerror(-err))));
	}
	alias resize = trunc;

	void state(const(char) * name, ref ulong psize, ref time_t pmtime)
	{
		int err = rados_stat(_io, name,&psize,&pmtime);
		enforce(err >= 0,new IoCtxException(format("rados_stat data erro : %s",strerror(-err))));
	}

	void setxattr(T)(const(char) * name, const(char) * key, T[] value) if(isCharByte!T)
	{
		int err = rados_setxattr(_io, name,key,cast(const(char) *)value.ptr,value.length);
		enforce(err >= 0,new IoCtxAttrException(format("rados_setxattr data erro : %s",strerror(-err))));
	}

	int getxattr(T)(const(char) * name, const(char) * key,ref T[] value) if(isMutilCharByte!T)
	{
		int err = rados_getxattr(_io, name,key,cast(char *)value.ptr,value.length);
		enforce(err >= 0,new IoCtxAttrException(format("rados_getxattr data erro : %s",strerror(-err))));
		return err;
	}

	void rmxattr(const(char) * name, const(char) * key)
	{
		int err = rados_rmxattr(_io, name,key);
		enforce(err >= 0,new IoCtxAttrException(format("rados_rmxattr data erro : %s",strerror(-err))));
	}

	void getxattrs(const(char) * name, void delegate(string key, char[] value) cback)
	{
		rados_xattrs_iter_t iter;
		int err = rados_getxattrs(_io, name, &iter);
		enforce(err >= 0,new IoCtxAttrException(format("rados_rmxattr data erro : %s",strerror(-err))));
		scope(exit)rados_getxattrs_end(iter);
		char * key = null;
		char * value = null;
		size_t len = 0;
		bool getNext() {
			len = 0;
			key = null;
			value = null;
			err = rados_getxattrs_next(iter,&key,&value,&len);
			if( err != 0 || len <= 0 || key is null || value is null)
				return false;
			return true;
		}
		while(getNext())
		{
			cback(fromStringz(key).dup,value[0..len].dup);
		}
	}

	void asyncWrite(T)(const(char) * name,T[] data,iocBack thesafe, iocBack thecomplate = null, ulong offset = 0)
	{
		IoCompletion * com = newIoCompletion(name);
		scope(failure)removeIoCompletion(com);
		com._completion = thecomplate;
		com._safe = thesafe;
		int err = rados_aio_write(_io, name,com._c,cast(const(char) *)data.ptr,data.length,offset);
		enforce(err >= 0,new IoCtxWriteException(format("rados_rmxattr data erro : %s",strerror(-err))));
	}

	void asyncWriteFull(T)(const(char) * name,T[] data,iocBack thesafe, iocBack thecomplate = null, ulong offset = 0)
	{
		IoCompletion * com = newIoCompletion(name);
		scope(failure)removeIoCompletion(com);
		com._completion = thecomplate;
		com._safe = thesafe;
		int err = rados_aio_write_full(_io, name,com._c,cast(const(char) *)data.ptr,data.length,offset);
		enforce(err >= 0,new IoCtxWriteException(format("rados_aio_write_full data erro : %s",strerror(-err))));
	}

	void asyncAppend(T)(const(char) * name,T[] data,iocBack thesafe, iocBack thecomplate = null, ulong offset = 0)
	{
		IoCompletion * com = newIoCompletion(name);
		scope(failure)removeIoCompletion(com);
		com._completion = thecomplate;
		com._safe = thesafe;
		int err = rados_aio_append(_io, name,com._c,cast(const(char) *)data.ptr,data.length,offset);
		enforce(err >= 0,new IoCtxWriteException(format("rados_aio_append data erro : %s",strerror(-err))));
	}

	void asyncWriteSame(T)(const(char) * name,T[] data,size_t wlen,iocBack thesafe, iocBack thecomplate = null, ulong offset = 0)
	{
		IoCompletion * com = newIoCompletion(name);
		scope(failure)removeIoCompletion(com);
		com._completion = thecomplate;
		com._safe = thesafe;
		int err = rados_aio_writesame(_io, name,com._c,cast(const(char) *)data.ptr,data.length,wlen,offset);
		enforce(err >= 0,new IoCtxWriteException(format("rados_aio_append data erro : %s",strerror(-err))));
	}

	void asyncRemove(const(char) * name,iocBack thesafe, iocBack thecomplate = null)
	{
		IoCompletion * com = newIoCompletion(name);
		scope(failure)removeIoCompletion(com);
		com._completion = thecomplate;
		com._safe = thesafe;
		int err = rados_aio_remove(_io, name,com._c);
		enforce(err >= 0,new IoCtxWriteException(format("rados_aio_remove data erro : %s",strerror(-err))));
	}

	void asyncRead(T)(const(char) * name,T[] data,iocBack thesafe, iocBack thecomplate = null, ulong offset = 0) if(isMutilCharByte!T)
	{
		IoCompletion * com = newIoCompletion(name);
		scope(failure)removeIoCompletion(com);
		com._completion = thecomplate;
		com._safe = thesafe;
		com._data = cast(char[])data;
		int err = rados_aio_read(_io, name,com._c,com._data.ptr,readLen,offset);
		enforce(err >= 0,new IoCtxWriteException(format("rados_aio_remove data erro : %s",strerror(-err))));
	}

	void asyncRead(const(char) * name,size_t readLen,iocBack thesafe, iocBack thecomplate = null, ulong offset = 0)
	{
		IoCompletion * com = newIoCompletion(name);
		scope(failure)removeIoCompletion(com);
		com._completion = thecomplate;
		com._safe = thesafe;
		com._data = new char[readLen];
		int err = rados_aio_read(_io, name,com._c,com._data.ptr,readLen,offset);
		enforce(err >= 0,new IoCtxWriteException(format("rados_aio_remove data erro : %s",strerror(-err))));
	}

	void asyncStat(const(char) * name,iocBack thecomplate)
	{
		IoCompletion * com = newIoCompletion(name,true);
		scope(failure)removeIoCompletion(com);
		com._safe = thecomplate;
		int err = rados_aio_stat(_io,name, com._c, &com._psize, &com._pmtime);
		enforce(err >= 0,new IoCtxException(format("rados_aio_cancel data erro : %s",strerror(-err))));
	}

protected:
	IoCompletion * newIoCompletion(const(char) * name, bool onlyCom = false)
	{
		IoCompletion * com = new IoCompletion(this,name,onlyCom);
		synchronized(_mutex){
			_cbacks[com] = 0;
		}
		return com;
	}

	void removeIoCompletion(IoCompletion * com)
	{
		if(com is null) return;
		synchronized(_mutex){
			_cbacks.remove(com);
		}
		import core.memory;
		destroy(*com);
		GC.free(com);
	}

private:
	rados_ioctx_t _io;
	rados_t _cluster;
	char * _poolname;
	int[IoCompletionPtr] _cbacks;
	Mutex _mutex;
}

template isMutilCharByte(T)
{
	enum bool isMutilCharByte = is(T == byte) || is(T == ubyte) || is(T == char) ;
}

template isCharByte(T)
{
	enum bool isCharByte = is(Unqual!T == byte) || is(Unqual!T == ubyte) || is(Unqual!T == char) ;
}

private:
import std.experimental.logger;

extern(C) void doComplate(rados_completion_t cb, void* arg)
{
	trace("doComplate doComplate");
	IoCompletion * com = cast(IoCompletion *) arg;
	com.do_completion();
}

extern(C) void doSafe(rados_completion_t cb, void* arg)
{
	trace("doSafe doSafe");
	IoCompletion * com = cast(IoCompletion *) arg;
	com.do_safe();
	com._io.removeIoCompletion(com);
}