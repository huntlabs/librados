import std.stdio;
import std.string;
import core.stdc.stdlib;
import deimos.rados;
import core.thread;
import std.datetime;
import core.sys.posix.pthread;

import radosd.ioctx;

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
	err = rados_connect(cluster);
	assert(err >= 0);
	scope(exit)rados_shutdown(cluster);

	IoCtx ctx = new IoCtx(cluster,"rbd");
	scope(exit)ctx.destroy;
	string named = "thw";
	auto name = named.toStringz();
	writeln("start get stat");
	ctx.asyncWrite(name,"hahahahahahhhhh",(ref IoCompletion c){
			writeln("++++++++++++++write data+++++++++");
			c.ctx.asyncStat(c.name,(ref IoCompletion com){
					writeln("the thw size is : ", com.statPsize);
					writeln("the thw write time is : ", SysTime.fromUnixTime(com.statPmtime).toISOExtString());
					com.ctx.asyncRead(com.name,com.statPsize,(ref IoCompletion com2){
							writeln("the thw data is : ", cast(string)com2.readData);
							com2.ctx.asyncRemove(com2.name,(ref IoCompletion comremove){
									writeln("--------------remove thw---------");
									comremove.release();
								});
							com2.release();
						});
					com.release();
				});
			c.release();
		});



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
	Thread.sleep(60.seconds);
	writeln("writeln suesss");
}
