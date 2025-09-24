const std = @import("std");

pub const PersistedQuery = struct {
    version: i32,
    sha256hash: []const u8,
};

pub const Extensions = struct {
    persistedQuery: PersistedQuery,
};

pub const GraphQuery = struct {
    operationName: []const u8,
    extensions: Extensions,
    variables: Variables,
};

pub const Variables = struct {
    channelLogin: []const u8,
};

pub const StreamMeta = struct {
    type_: []const u8,
};

pub const UserMeta = struct {
    stream: ?StreamMeta,
};

pub const MetaDataRoot = struct {
    user: UserMeta,
};

pub const StreamMetaBase = struct {
    data: MetaDataRoot,
};
