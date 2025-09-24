const std = @import("std");
const root = @import("root.zig");
const config = @import("config.zig");

pub const HttpClient = struct {
    allocator: std.mem.Allocator,
    headers: []const config.Header,
    base_url: []const u8,

    pub fn init(allocator: std.mem.Allocator, base_url: []const u8, headers: []const config.Header) HttpClient {
        return .{ .allocator = allocator, .headers = headers, .base_url = base_url };
    }

    pub fn postJson(self: *HttpClient, body: []const u8) ![]const u8 {
        var argv = std.ArrayListUnmanaged([]const u8){};
        defer argv.deinit(self.allocator);
        try argv.appendSlice(self.allocator, &.{ "curl", "-sS", "-k", "-X", "POST" });
        try argv.appendSlice(self.allocator, &.{ "-H", "Content-Type: application/json" });

        var header_allocs = std.ArrayListUnmanaged([]const u8){};
        defer {
            for (header_allocs.items) |s| self.allocator.free(s);
            header_allocs.deinit(self.allocator);
        }
        for (self.headers) |h| {
            const line = try std.fmt.allocPrint(self.allocator, "{s}: {s}", .{ h.key, h.value });
            try header_allocs.append(self.allocator, line);
            try argv.appendSlice(self.allocator, &.{ "-H", line });
        }

        try argv.appendSlice(self.allocator, &.{ "--data", body, self.base_url });

        var child = std.process.Child.init(argv.items, self.allocator);
        child.stdin_behavior = .Ignore;
        child.stdout_behavior = .Pipe;
        child.stderr_behavior = .Inherit;
        try child.spawn();

        var stdout_file = child.stdout.?;
        const resp = try stdout_file.readToEndAlloc(self.allocator, 1 << 20);
        const term = try child.wait();
        switch (term) {
            .Exited => |code| {
                if (code != 0) return error.CommandFailed;
            },
            else => return error.CommandFailed,
        }
        return resp;
    }
};
