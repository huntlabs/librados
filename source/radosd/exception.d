module radosd.exception;

import std.exception;

class RadosException : Exception
{
	mixin basicExceptionCtors;
}

class IoCtxException : RadosException
{
	mixin basicExceptionCtors;
}

class IoCtxWriteException : IoCtxException
{
	mixin basicExceptionCtors;
}

class IoCtxReadException : IoCtxException
{
	mixin basicExceptionCtors;
}

class IoCtxAttrException : IoCtxException
{
	mixin basicExceptionCtors;
}

class IoCtxCloneException : IoCtxException
{
	mixin basicExceptionCtors;
}

class IoCompletionException : IoCtxException
{
	mixin basicExceptionCtors;
}

