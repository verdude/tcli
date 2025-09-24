const std = @import("std");

pub const Header = struct {
    key: []const u8,
    value: []const u8,
};

pub const MainBub = struct {
    base_url: []const u8,
    bubs: []const []const u8,
    headers: []const Header,
};

pub const Config = struct {
    bub: MainBub,

    pub fn deinit(self: *Config, allocator: std.mem.Allocator) void {
        allocator.free(self.bub.base_url);
        for (self.bub.bubs) |bub_str| allocator.free(bub_str);
        allocator.free(self.bub.bubs);
        for (self.bub.headers) |h| {
            allocator.free(h.key);
            allocator.free(h.value);
        }
        allocator.free(self.bub.headers);
    }
};

fn trimSpace(s: []const u8) []const u8 {
    return std.mem.trim(u8, s, " \t\r\n");
}

fn unquoteIfNeeded(s: []const u8) []const u8 {
    const t = trimSpace(s);
    if (t.len >= 2 and t[0] == '"' and t[t.len - 1] == '"') return t[1 .. t.len - 1];
    return t;
}

fn parseArrayOfStrings(allocator: std.mem.Allocator, raw: []const u8) ![]const []const u8 {
    const t = trimSpace(raw);
    if (t.len < 2 or t[0] != '[' or t[t.len - 1] != ']') {
        return error.InvalidArraySyntax;
    }
    const inner = trimSpace(t[1 .. t.len - 1]);
    if (inner.len == 0) return allocator.alloc([]const u8, 0);

    var list = std.ArrayListUnmanaged([]const u8){};
    defer list.deinit(allocator);

    var it = std.mem.splitScalar(u8, inner, ',');
    while (it.next()) |piece| {
        const v = unquoteIfNeeded(piece);
        const duped = try allocator.dupe(u8, v);
        try list.append(allocator, duped);
    }
    return try list.toOwnedSlice(allocator);
}

pub fn loadConfig(allocator: std.mem.Allocator, path: []const u8) !Config {
    var file = try std.fs.cwd().openFile(path, .{ .mode = .read_only });
    defer file.close();
    const stat = try file.stat();
    const content = try file.readToEndAlloc(allocator, stat.size);
    defer allocator.free(content);

    var base_url_buf: ?[]const u8 = null;
    var bubs_buf = std.ArrayListUnmanaged([]const u8){};
    defer bubs_buf.deinit(allocator);
    var headers_buf = std.ArrayListUnmanaged(Header){};
    defer headers_buf.deinit(allocator);

    const Section = enum { none, bub, bub_headers };
    var section: Section = .none;

    // Support for multiline arrays (only needed for `bubs`)
    var reading_bubs_array = false;
    var bubs_accum = std.ArrayListUnmanaged(u8){};
    defer bubs_accum.deinit(allocator);
    var bubs_bracket_depth: i32 = 0;

    var line_it = std.mem.splitScalar(u8, content, '\n');
    while (line_it.next()) |line_raw| {
        var line = line_raw;
        // Strip comments starting with '#'
        if (std.mem.indexOfScalar(u8, line, '#')) |idx| {
            line = line[0..idx];
        }
        line = trimSpace(line);
        if (line.len == 0) continue;

        // Sections
        if (std.mem.eql(u8, line, "[bub]")) {
            section = .bub;
            continue;
        }
        if (std.mem.eql(u8, line, "[bub.headers]")) {
            section = .bub_headers;
            continue;
        }

        // If currently reading a multiline bubs array, keep accumulating
        if (reading_bubs_array) {
            // Add a separating space to avoid token sticking
            if (bubs_accum.items.len > 0) try bubs_accum.append(allocator, ' ');
            try bubs_accum.appendSlice(allocator, line);
            // Update bracket depth
            var i: usize = 0;
            while (i < line.len) : (i += 1) {
                const c = line[i];
                if (c == '[') bubs_bracket_depth += 1 else if (c == ']') bubs_bracket_depth -= 1;
            }
            if (bubs_bracket_depth <= 0) {
                // Finished accumulating, parse now
                const arr = try parseArrayOfStrings(allocator, bubs_accum.items);
                // Replace if set twice
                for (bubs_buf.items) |s| allocator.free(s);
                bubs_buf.clearRetainingCapacity();
                for (arr) |s| try bubs_buf.append(allocator, s);
                allocator.free(arr);
                reading_bubs_array = false;
                bubs_accum.clearRetainingCapacity();
            }
            continue;
        }

        switch (section) {
            .bub => {
                if (std.mem.indexOfScalar(u8, line, '=')) |eq| {
                    const key = trimSpace(line[0..eq]);
                    const val = trimSpace(line[eq + 1 ..]);
                    if (std.mem.eql(u8, key, "baseUrl")) {
                        const unq = unquoteIfNeeded(val);
                        if (base_url_buf != null) return error.DuplicateBaseUrl;
                        base_url_buf = try allocator.dupe(u8, unq);
                    } else if (std.mem.eql(u8, key, "bubs")) {
                        // If value contains an opening bracket without closing on the same line,
                        // start accumulating multiline array.
                        var open_count: i32 = 0;
                        var close_count: i32 = 0;
                        var j: usize = 0;
                        while (j < val.len) : (j += 1) {
                            if (val[j] == '[') open_count += 1 else if (val[j] == ']') close_count += 1;
                        }
                        if (open_count > close_count) {
                            // Begin multiline accumulation
                            reading_bubs_array = true;
                            bubs_bracket_depth = open_count - close_count;
                            // seed the accumulator with current value
                            try bubs_accum.appendSlice(allocator, val);
                        } else {
                            const arr = try parseArrayOfStrings(allocator, val);
                            for (arr) |s| try bubs_buf.append(allocator, s);
                            allocator.free(arr);
                        }
                    }
                }
            },
            .bub_headers => {
                if (std.mem.indexOfScalar(u8, line, '=')) |eq| {
                    const key_raw = trimSpace(line[0..eq]);
                    const val_raw = trimSpace(line[eq + 1 ..]);
                    if (key_raw.len == 0) continue;
                    const k = try allocator.dupe(u8, key_raw);
                    const v = try allocator.dupe(u8, unquoteIfNeeded(val_raw));
                    try headers_buf.append(allocator, .{ .key = k, .value = v });
                }
            },
            .none => {},
        }
    }

    if (base_url_buf == null) return error.MissingBaseUrl;

    const bubs = try bubs_buf.toOwnedSlice(allocator);
    const headers = try headers_buf.toOwnedSlice(allocator);

    return .{ .bub = .{ .base_url = base_url_buf.?, .bubs = bubs, .headers = headers } };
}
