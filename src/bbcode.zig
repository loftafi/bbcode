pub const Token = struct {
    type: Type = .undefined,
    value: []const u8 = "",
    state: TagState = .undefined,

    data: []const u8 = "",

    pub const Type = enum {
        undefined,
        whitespace,
        text,
        br,
        bold,
        italic,
        underline,
        strikethrough,
        superscript,
        subscript,
        size,
        color,
        blur,
        url,
        email,
        img,
        bbvideo,
        quote,
        code,
        list,
        li,
        line,
        @"align",
        heading,
        nfo,
        pipes,
        table,
        row,
        cell,
        rate,
        eof,

        pub fn parse(value: []const u8) @This() {
            if (std.ascii.eqlIgnoreCase(value, "b")) return .bold;
            if (std.ascii.eqlIgnoreCase(value, "i")) return .italic;
            if (std.ascii.eqlIgnoreCase(value, "u")) return .underline;
            if (std.ascii.eqlIgnoreCase(value, "s")) return .strikethrough;
            if (std.ascii.eqlIgnoreCase(value, "sup")) return .superscript;
            if (std.ascii.eqlIgnoreCase(value, "sub")) return .subscript;
            if (std.ascii.eqlIgnoreCase(value, "size")) return .size;
            if (std.ascii.eqlIgnoreCase(value, "color")) return .color;
            if (std.ascii.eqlIgnoreCase(value, "blur")) return .blur;
            if (std.ascii.eqlIgnoreCase(value, "size")) return .size;
            if (std.ascii.eqlIgnoreCase(value, "url")) return .url;
            if (std.ascii.eqlIgnoreCase(value, "email")) return .email;
            if (std.ascii.eqlIgnoreCase(value, "img")) return .img;
            if (std.ascii.eqlIgnoreCase(value, "bbvideo")) return .bbvideo;
            if (std.ascii.eqlIgnoreCase(value, "img")) return .img;
            if (std.ascii.eqlIgnoreCase(value, "quote")) return .quote;
            if (std.ascii.eqlIgnoreCase(value, "code")) return .code;
            if (std.ascii.eqlIgnoreCase(value, "list")) return .list;
            if (std.ascii.eqlIgnoreCase(value, "*")) return .li;
            if (std.ascii.eqlIgnoreCase(value, "line")) return .line;
            if (std.ascii.eqlIgnoreCase(value, "br")) return .br;
            if (std.ascii.eqlIgnoreCase(value, "align")) return .@"align";
            if (std.ascii.eqlIgnoreCase(value, "h")) return .heading;
            if (std.ascii.eqlIgnoreCase(value, "nfo")) return .nfo;
            if (std.ascii.eqlIgnoreCase(value, "pipes")) return .pipes;
            if (std.ascii.eqlIgnoreCase(value, "table")) return .table;
            if (std.ascii.eqlIgnoreCase(value, "row")) return .row;
            if (std.ascii.eqlIgnoreCase(value, "cell")) return .cell;
            if (std.ascii.eqlIgnoreCase(value, "rate")) return .rate;
            return .undefined;
        }
    };

    pub const TagState = enum {
        undefined,
        open,
        close,
    };

    pub fn init(data: []const u8) Token {
        const t = Token{ .data = data };
        return t.next();
    }

    pub fn next(self: *const Token) Token {
        if (self.data.len == 0) return .{
            .data = self.data,
            .type = .eof,
            .value = "",
            .state = .undefined,
        };

        if (is_whitespace(self.data[0])) {
            var i: usize = 1;
            while (i < self.data.len) {
                if (!is_whitespace(self.data[i])) break;
                i += 1;
            }
            return .{
                .data = self.data[i..],
                .value = self.data[0..i],
                .type = .whitespace,
                .state = .undefined,
            };
        }

        if (self.data[0] == '[') {
            var i: usize = 1;
            var field_start: usize = 1;
            var field_end: usize = 1;
            var value_start: usize = 0;
            var value_end: usize = 0;
            var state: TagState = .open;
            if (i < self.data.len and self.data[i] == '/') {
                state = .close;
                i += 1;
                field_start += 1;
                field_end += 1;
            }
            while (i < self.data.len) {
                const c = self.data[i];
                if (c == ']') {
                    field_end = i;
                    break;
                }
                if (c == '=' or (c >= '0' and c <= '9')) {
                    field_end = i;
                    break;
                }
                i += 1;
                field_end = i;
            }
            if (i < self.data.len) {
                const c = self.data[i];
                if (c == ']') {
                    i += 1;
                } else {
                    if (c == '=') i += 1;
                    value_start = i;
                    value_end = i;
                    while (i < self.data.len) {
                        const d = self.data[i];
                        if (d == ']') {
                            value_end = i;
                            i += 1;
                            break;
                        }
                        i += 1;
                        value_end = i;
                    }
                }
            }
            //err("full {s} => {s}", .{ self.data[0..i], self.data[field_start..field_end] });
            return .{
                .data = self.data[i..],
                //.value = self.data[0..i],
                .value = self.data[value_start..value_end],
                .type = Type.parse(self.data[field_start..field_end]),
                .state = state,
            };
        }

        var i: usize = 0;
        while (i < self.data.len) {
            const c = self.data[i];
            if (is_whitespace(c)) break;
            if (c == '[') break;
            i += 1;
        }
        return .{
            .data = self.data[i..],
            .value = self.data[0..i],
            .type = .text,
            .state = .undefined,
        };
    }
};

fn is_whitespace(c: u8) bool {
    return c == ' ' or c == '\n' or c == '\t' or c == '\r';
}

test "read bbcode" {
    var token = Token.init("  abc   def\n[b]hat[/b][table=30][/table][h3]heading[/h3]");
    try expectEqual(.whitespace, token.type);
    try expectEqualStrings("  ", token.value);

    token = token.next();
    try expectEqual(.text, token.type);
    try expectEqualStrings("abc", token.value);

    token = token.next();
    try expectEqual(.whitespace, token.type);
    try expectEqualStrings("   ", token.value);

    token = token.next();
    try expectEqual(.text, token.type);
    try expectEqualStrings("def", token.value);

    token = token.next();
    try expectEqual(.whitespace, token.type);
    try expectEqualStrings("\n", token.value);

    token = token.next();
    try expectEqual(.bold, token.type);
    try expectEqual(.open, token.state);
    //try expectEqualStrings("b", token.value);

    token = token.next();
    try expectEqual(.text, token.type);
    try expectEqualStrings("hat", token.value);

    token = token.next();
    try expectEqual(.bold, token.type);
    try expectEqual(.close, token.state);
    try expectEqualStrings("", token.value);

    token = token.next();
    try expectEqual(.table, token.type);
    try expectEqual(.open, token.state);
    try expectEqualStrings("30", token.value);

    token = token.next();
    try expectEqual(.table, token.type);
    try expectEqual(.close, token.state);
    try expectEqualStrings("", token.value);

    token = token.next();
    try expectEqual(.heading, token.type);
    try expectEqual(.open, token.state);
    try expectEqualStrings("3", token.value);

    token = token.next();
    try expectEqual(.text, token.type);
    try expectEqualStrings("heading", token.value);

    token = token.next();
    try expectEqual(.heading, token.type);
    try expectEqual(.close, token.state);
    try expectEqualStrings("3", token.value);

    token = token.next();
    try expectEqual(.eof, token.type);
}

test "fail bbcode" {
    {
        var token = Token.init("abc[b");
        try expectEqual(.text, token.type);
        try expectEqualStrings("abc", token.value);
        token = token.next();
        try expectEqual(.bold, token.type);
        try expectEqualStrings("", token.value);
        token = token.next();
        try expectEqual(.eof, token.type);
    }
    {
        var token = Token.init("abc[b=");
        try expectEqual(.text, token.type);
        try expectEqualStrings("abc", token.value);
        token = token.next();
        try expectEqual(.bold, token.type);
        try expectEqualStrings("", token.value);
        token = token.next();
        try expectEqual(.eof, token.type);
    }
    {
        var token = Token.init("abc[");
        try expectEqual(.text, token.type);
        try expectEqualStrings("abc", token.value);
        token = token.next();
        try expectEqual(.undefined, token.type);
        try expectEqualStrings("", token.value);
        token = token.next();
        try expectEqual(.eof, token.type);
    }
}

const std = @import("std");
const err = std.log.err;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
