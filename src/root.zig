const std = @import("std");
const config = @import("config.zig");
const model = @import("graph.zig");
const http = @import("http.zig");

// Public library API
pub fn init() void {}

pub fn add(a: anytype, b: anytype) @TypeOf(a + b) {
    return a + b;
}

pub fn fetch_buf(allocator: std.mem.Allocator, config_path: []const u8, log_path: []const u8, out_buf: []u8) ![]u8 {
    var cfg = try config.loadConfig(allocator, config_path);
    defer cfg.deinit(allocator);

    const lf_opt: ?std.fs.File = std.fs.cwd().openFile(log_path, .{ .mode = .read_write }) catch std.fs.cwd().createFile(log_path, .{}) catch null;
    if (lf_opt) |lf_val| {
        var lf = lf_val;
        defer lf.close();
        _ = lf.writeAll("Booting...\n") catch {};
        const line1 = std.fmt.allocPrint(allocator, "Got bubs: {d}\n", .{cfg.bub.bubs.len}) catch null;
        if (line1) |l| {
            _ = lf.writeAll(l) catch {};
            allocator.free(l);
        }
        const line2 = std.fmt.allocPrint(allocator, "Baseurl: {s}\n", .{cfg.bub.base_url}) catch null;
        if (line2) |l| {
            _ = lf.writeAll(l) catch {};
            allocator.free(l);
        }
    }

    const persisted: model.PersistedQuery = .{
        .version = 1,
        .sha256hash = "059c4653b788f5bdb2f5a2d2a24b0ddc3831a15079001a3d927556a96fb0517f",
    };

    // Collect results
    const results = try fetch(allocator, cfg.bub.base_url, cfg.bub.headers, persisted, cfg.bub.bubs);
    defer freeResults(allocator, results);

    // Serialize to provided buffer
    var fbs = std.io.fixedBufferStream(out_buf);
    var w = fbs.writer();
    for (results) |r| {
        try w.print("{s}: {s}\n", .{ r.channel, r.kind });
    }
    return fbs.getWritten();
}

pub const StreamInfo = struct {
    channel: []const u8,
    kind: []const u8,
};

pub fn freeResults(allocator: std.mem.Allocator, results: []StreamInfo) void {
    for (results) |r| {
        allocator.free(r.channel);
        allocator.free(r.kind);
    }
    allocator.free(results);
}

pub fn fetch(
    allocator: std.mem.Allocator,
    base_url: []const u8,
    headers: []const config.Header,
    persisted: model.PersistedQuery,
    channels: []const []const u8,
) ![]StreamInfo {
    var list = std.ArrayListUnmanaged(StreamInfo){};
    errdefer {
        for (list.items) |it| {
            allocator.free(it.channel);
            allocator.free(it.kind);
        }
        list.deinit(allocator);
    }

    var client_local = http.HttpClient.init(allocator, base_url, headers);
    for (channels) |chan_login| {
        const body = try std.fmt.allocPrint(
            allocator,
            "{{\"operationName\":\"{s}\",\"extensions\":{{\"persistedQuery\":{{\"version\":{d},\"sha256hash\":\"{s}\"}}}},\"variables\":{{\"channelLogin\":\"{s}\"}}}}",
            .{ "StreamMetadata", persisted.version, persisted.sha256hash, chan_login },
        );
        defer allocator.free(body);
        const resp = try client_local.postJson(body);
        defer allocator.free(resp);
        const needle = "\"type\":\"";
        var kind_copy = try allocator.dupe(u8, "");
        if (std.mem.indexOf(u8, resp, needle)) |idx| {
            const start = idx + needle.len;
            if (std.mem.indexOfScalarPos(u8, resp, start, '"')) |end| {
                const s = resp[start..end];
                allocator.free(kind_copy);
                kind_copy = try allocator.dupe(u8, s);
            }
        }
        const channel_copy = try allocator.dupe(u8, chan_login);
        try list.append(allocator, .{ .channel = channel_copy, .kind = kind_copy });
    }

    return try list.toOwnedSlice(allocator);
}
