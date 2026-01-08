/// Initialise a `Token` with your full bbcode data string, and it will return
/// the first token inside the string.  Use `token.next()` to read more tokens.
pub const Token = struct {
    /// `text` or `whitespace`, `eof` or a bbcode tag, i.e. `italic`
    type: Type = .undefined,

    /// text content, whitespace content, or the bbcode tag value, i.e. `[table=3] has a value of `3`
    value: []const u8 = "",

    /// `open` when starting bbcode, i.e. `[b]` or 'close` when ending bbcode, i.e. `[/b]`
    state: TagState = .undefined,

    /// Contains the remaining data that appears after the current token.
    data: []const u8 = "",

    pub const Type = enum {
        undefined,
        whitespace,
        text,
        eof,
        br,
        bold,
        italic,
        underline,
        strikethrough,
        superscript,
        subscript,
        size,
        colour,
        blur,
        url,
        email,
        img,
        bbvideo,
        quote,
        code,
        list,
        ul,
        ol,
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
        left,
        right,
        centre,
        spoiler,

        /// Maps a bbcode tag string to the corresponding enum value.
        pub fn parse(value: []const u8) @This() {
            if (std.ascii.eqlIgnoreCase(value, "b")) return .bold;
            if (std.ascii.eqlIgnoreCase(value, "i")) return .italic;
            if (std.ascii.eqlIgnoreCase(value, "u")) return .underline;
            if (std.ascii.eqlIgnoreCase(value, "s")) return .strikethrough;
            if (std.ascii.eqlIgnoreCase(value, "sup")) return .superscript;
            if (std.ascii.eqlIgnoreCase(value, "sub")) return .subscript;
            if (std.ascii.eqlIgnoreCase(value, "size")) return .size;
            if (std.ascii.eqlIgnoreCase(value, "colour")) return .colour;
            if (std.ascii.eqlIgnoreCase(value, "color")) return .color;
            if (std.ascii.eqlIgnoreCase(value, "spoiler")) return .spoiler;
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
            if (std.ascii.eqlIgnoreCase(value, "ul")) return .list;
            if (std.ascii.eqlIgnoreCase(value, "ol")) return .list;
            if (std.ascii.eqlIgnoreCase(value, "*")) return .li;
            if (std.ascii.eqlIgnoreCase(value, "line")) return .line;
            if (std.ascii.eqlIgnoreCase(value, "br")) return .br;
            if (std.ascii.eqlIgnoreCase(value, "align")) return .@"align";
            if (std.ascii.eqlIgnoreCase(value, "h")) return .heading;
            if (std.ascii.eqlIgnoreCase(value, "nfo")) return .nfo;
            if (std.ascii.eqlIgnoreCase(value, "pipes")) return .pipes;
            if (std.ascii.eqlIgnoreCase(value, "table")) return .table;
            if (std.ascii.eqlIgnoreCase(value, "row")) return .row;
            if (std.ascii.eqlIgnoreCase(value, "tr")) return .row;
            if (std.ascii.eqlIgnoreCase(value, "cell")) return .cell;
            if (std.ascii.eqlIgnoreCase(value, "td")) return .cell;
            if (std.ascii.eqlIgnoreCase(value, "rate")) return .rate;
            if (std.ascii.eqlIgnoreCase(value, "left")) return .left;
            if (std.ascii.eqlIgnoreCase(value, "right")) return .right;
            if (std.ascii.eqlIgnoreCase(value, "centre")) return .centre;
            if (std.ascii.eqlIgnoreCase(value, "center")) return .centre;
            if (std.ascii.eqlIgnoreCase(value, "pre")) return .pre;
            if (std.ascii.eqlIgnoreCase(value, "youtube")) return .youtube;
            return .undefined;
        }
    };

    /// If a token contains a bbcode tag, it is an `open` or `close` tag.
    pub const TagState = enum {
        undefined,
        open,
        close,
    };

    /// Return the first token that appears inside a data string.
    pub fn init(data: []const u8) Token {
        const t = Token{ .data = data };
        return t.next();
    }

    /// Return the next token that appears after this token.
    pub fn next(self: *const Token) Token {
        if (self.data.len == 0) return .{
            .data = self.data,
            .type = .eof,
        };

        // Read a whitespace token if we see whitespace
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
            };
        }

        // Read a bbcode token if we see the token start character
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
            return .{
                .data = self.data[i..],
                .value = self.data[value_start..value_end],
                .type = Type.parse(self.data[field_start..field_end]),
                .state = state,
            };
        }

        // Read pure text until the next whitespace or bbcode token appears.
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
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
