import std.stdio;
import std.string;
import core.stdc.stdlib;
import deimos.rados;
import core.thread;
import std.datetime;
import core.sys.posix.pthread;
import core.memory;

import radosd.ioctx;
import core.stdc.string;
import std.exception;

void main()
{
	writeln("Edit source/app.d to start your project.");
	writeln(Thread.getThis.id);
	rados_t cluster;
	string cluster_name = "ceph";
	string user_name = "client.admin";
	ulong flags;

	int err = rados_create2(&cluster,cluster_name.toStringz,user_name.toStringz,flags);
	err = rados_conf_read_file(cluster, "/etc/ceph/ceph.conf".toStringz);
	if(err < 0){
		writeln("=====",strerror(-err));
	}
	err = rados_connect(cluster);
	if(err < 0){
		writeln("=====  ====err ",err , " --",strerror(-err));
	}
	assert(err >= 0);
	scope(exit)rados_shutdown(cluster);

	IoCtx ctx = new IoCtx(cluster,"rbd");
	scope(exit)ctx.destroy;
	string attrsname = "1222222.tsqwqwewewxtexs.bpg";
	auto name = attrsname.toStringz();
	//	try{
	//		ctx.getxattrs(name,(string key, char[] value){
	//				writeln("key is : ", key, "   value is : ", value);
	//			});
	//	} catch ( IoCtxException e)
	//	{
	//		writeln("get new tttt",e.toString);
	//	}
	writeln("-----------------------");
	try{

		ctx.setxattr(name,"state".toStringz,cast(char[])("full"));
		ctx.trunc(name,1024);
		//		char[256] value;
		//		char[] hv = value[];
		//		int s = ctx.getxattr(name,"hahah".toStringz,hv);
		//		char[] tv = hv[0..s];
		//		writeln("getxattr hahah is  : ", tv);
	} catch ( IoCtxException e)
	{
		writeln("ctx.trunc",e.toString);
	}

	writeln("start get stat");
	ctx.asyncWrite(name,"hahahahahahhhhh",(ref IoCompletion c){
			collectException({
					//			auto th = Thread.getThis();
					//			if(th is null){
					//				writeln("th thread is null!!!!");
					//				th = thread_attachThis();
					//			}
					//			writeln("++++++++++++++write data+++++++++", th.id);
					c.ctx.asyncStat(c.name,(ref IoCompletion com){
							collectException({
									auto th = Thread.getThis();
									if(th is null){
										writeln("th thread is null!!!!");
										th = thread_attachThis();
									} 
									writeln("call back thread id  is : ", th.id);
									ctx.getxattrs(com.name,(string key, char[] value){
											writeln("key is : ", key, "   value is : ", value);
										});
									writeln("the thw size is : ", com.statPsize);
									writeln("the thw write time is : ", SysTime.fromUnixTime(com.statPmtime).toISOExtString());
									com.ctx.asyncRead(com.name,com.statPsize,(ref IoCompletion com2){
											collectException({
													auto th = Thread.getThis();
													if(th is null){
														writeln("th thread is null!!!!");
														th = thread_attachThis();
													} 
													writeln("call back thread id  is : ", th.id);
													int size = com2.getReturnValue();
													writeln("---------the thw data length is : ", size);
													char[] data = com2.readData;
													data = data[0..size];
													writeln("the thw data is : ", cast(string)data);
													com2.ctx.asyncRemove(com2.name,(ref IoCompletion comremove){
															collectException({
																	auto th = Thread.getThis();
																	if(th is null){
																		writeln("th thread is null!!!!");
																		th = thread_attachThis();
																	} 
																	writeln("call back thread id  is : ", th.id);
																	writeln("--------------remove thw---------");
																}());});
												}());});
								}());});
				}());});

	

	//	writeln("connect sessues !");
	//	rados_ioctx_t io;
	//	string poolname = "rbd";
	//	err = rados_ioctx_create(cluster, poolname.toStringz, &io);
	//	assert(err >= 0);
	//	scope(exit) rados_ioctx_destroy(io);
	//
	//	rados_completion_t wcb;
	//	err =  rados_aio_create_completion(null,&write1Overvoid,&writeOvervoid,&wcb);
	//	assert(err >= 0);
	//	string data = "hello worldddddd";
	//	err = rados_aio_write(io,"thw".toStringz,wcb,data.ptr,data.length,0);
	//	assert(err >= 0);
	//	writeln("start  write !");
	//	Thread.sleep(10.seconds);
	//	rados_aio_wait_for_safe(wcb);
	writeln("wait 60 seconds");
	Thread.sleep(20.seconds);
	writeln("writeln suesss");
}
