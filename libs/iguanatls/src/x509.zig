const std = @import("std");
const Allocator = std.mem.Allocator;
const mem = std.mem;
const trait = std.meta.trait;

const asn1 = @import("asn1.zig");

// zig fmt: off
// http://www.iana.org/assignments/tls-parameters/tls-parameters.xhtml#tls-parameters-8
// @TODO add backing integer, values
pub const CurveId = enum {
    sect163k1, sect163r1, sect163r2, sect193r1,
    sect193r2, sect233k1, sect233r1, sect239k1,
    sect283k1, sect283r1, sect409k1, sect409r1,
    sect571k1, sect571r1, secp160k1, secp160r1,
    secp160r2, secp192k1, secp192r1, secp224k1,
    secp224r1, secp256k1, secp256r1, secp384r1,
    secp521r1,brainpoolP256r1, brainpoolP384r1,
    brainpoolP512r1, curve25519, curve448,
};
// zig fmt: on

pub const PublicKey = union(enum) {
    /// RSA public key
    rsa: struct {
        //Positive std.math.big.int.Const numbers.
        modulus: []const usize,
        exponent: []const usize,
    },
    /// Elliptic curve public key
    ec: struct {
        id: CurveId,
        /// Public curve point (uncompressed format)
        curve_point: []const u8,
    },

    pub fn deinit(self: @This(), alloc: *Allocator) void {
        switch (self) {
            .rsa => |rsa| {
                alloc.free(rsa.modulus);
                alloc.free(rsa.exponent);
            },
            .ec => |ec| alloc.free(ec.curve_point),
        }
    }

    pub fn eql(self: @This(), other: @This()) bool {
        if (@as(@TagType(@This()), self) != @as(@TagType(@This()), other))
            return false;
        switch (self) {
            .rsa => |mod_exp| return mem.eql(usize, mod_exp.exponent, other.rsa.exponent) and
                mem.eql(usize, mod_exp.modulus, other.rsa.modulus),
            .ec => |ec| return ec.id == other.ec.id and mem.eql(u8, ec.curve_point, other.ec.curve_point),
        }
    }
};

pub fn parse_public_key(allocator: *Allocator, reader: anytype) !PublicKey {
    if ((try reader.readByte()) != 0x30)
        return error.MalformedDER;
    const seq_len = try asn1.der.parse_length(reader);

    if ((try reader.readByte()) != 0x06)
        return error.MalformedDER;
    const oid_bytes = try asn1.der.parse_length(reader);
    if (oid_bytes == 9 ) {
        // @TODO This fails in async if merged with the if
        if (!try reader.isBytes(&[9]u8{ 0x2A, 0x86, 0x48, 0x86, 0xF7, 0xD, 0x1, 0x1, 0x1 }))
            return error.MalformedDER;
        // OID is 1.2.840.113549.1.1.1
        // RSA key
        // Skip past the NULL
        const null_byte = try reader.readByte();
        if (null_byte != 0x05)
            return error.MalformedDER;
        const null_len = try asn1.der.parse_length(reader);
        if (null_len != 0x00)
            return error.MalformedDER;
        {
            // BitString next!
            if ((try reader.readByte()) != 0x03)
                return error.MalformedDER;
            _ = try asn1.der.parse_length(reader);
            const bit_string_unused_bits = try reader.readByte();
            if (bit_string_unused_bits != 0)
                return error.MalformedDER;

            if ((try reader.readByte()) != 0x30)
                return error.MalformedDER;
            _ = try asn1.der.parse_length(reader);

            // Modulus
            if ((try reader.readByte()) != 0x02)
                return error.MalformedDER;
            const modulus = try asn1.der.parse_int(allocator, reader);
            errdefer allocator.free(modulus.limbs);
            if (!modulus.positive) return error.MalformedDER;
            // Exponent
            if ((try reader.readByte()) != 0x02)
                return error.MalformedDER;
            const exponent = try asn1.der.parse_int(allocator, reader);
            errdefer allocator.free(exponent.limbs);
            if (!exponent.positive) return error.MalformedDER;
            return PublicKey{
                .rsa = .{
                    .modulus = modulus.limbs,
                    .exponent = exponent.limbs,
                },
            };
        }
    } else if (oid_bytes == 7) {
        // @TODO This fails in async if merged with the if
        if (!try reader.isBytes(&[7]u8{ 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x02, 0x01 }))
            return error.MalformedDER;
        // OID is 1.2.840.10045.2.1
        // Elliptical curve
        // We only support named curves, for which the parameter field is an OID.
        const oid_tag = try reader.readByte();
        if (oid_tag != 0x06)
            return error.MalformedDER;
        const curve_oid_bytes = try asn1.der.parse_length(reader);

        var key: PublicKey = undefined;
        if (curve_oid_bytes == 5) {
            if (!try reader.isBytes(&[4]u8{ 0x2B, 0x81, 0x04, 0x00 }))
                return error.MalformedDER;
            // 1.3.132.0.{34, 35}
            const last_byte = try reader.readByte();
            if (last_byte == 0x22)
                key.ec = .{ .id = .secp384r1, .curve_point = undefined }
            else if (last_byte == 0x23)
                key.ec = .{ .id = .secp521r1, .curve_point = undefined }
            else
                return error.MalformedDER;
        } else if (curve_oid_bytes == 8)
        {
            if (!try reader.isBytes(&[8]u8{ 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x3, 0x1, 0x7 }))
                return error.MalformedDER;
            key.ec = .{ .id = .secp256r1, .curve_point = undefined };
        } else {
            return error.MalformedDER;
        }

        if ((try reader.readByte()) != 0x03)
            return error.MalformedDER;
        const byte_len = try asn1.der.parse_length(reader);
        const unused_bits = try reader.readByte();
        const bit_count = (byte_len - 1) * 8 - unused_bits;
        if (bit_count % 8 != 0)
            return error.MalformedDER;
        const bit_memory = try allocator.alloc(u8, std.math.divCeil(usize, bit_count, 8) catch unreachable);
        errdefer allocator.free(bit_memory);
        try reader.readNoEof(bit_memory[0.. byte_len - 1]);

        key.ec.curve_point = bit_memory;
        return key;
    }
    return error.MalformedDER;
}

pub fn DecodeDERError(comptime Reader: type) type {
    return Reader.Error || error{
        MalformedPEM,
        MalformedDER,
        EndOfStream,
        OutOfMemory,
    };
}

pub const TrustAnchor = struct {
    /// Subject distinguished name
    dn: []const u8,
    /// A "CA" anchor is deemed fit to verify signatures on certificates.
    /// A "non-CA" anchor is accepted only for direct trust (server's certificate
    /// name and key match the anchor).
    is_ca: bool = false,
    public_key: PublicKey,

    const CaptureState = struct {
        self: *TrustAnchor,
        allocator: *Allocator,
        dn_allocated: bool = false,
        pk_allocated: bool = false,
    };
    fn initSubjectDn(state: *CaptureState, tag_byte: u8, length: usize, reader: anytype) !void {
        const dn_mem = try state.allocator.alloc(u8, length);
        errdefer state.allocator.free(dn_mem);
        try reader.readNoEof(dn_mem);
        state.self.dn = dn_mem;
        state.dn_allocated = true;
    }

    fn processExtension(state: *CaptureState, tag_byte: u8, length: usize, reader: anytype) !void {
        const object_id = try asn1.der.parse_value(state.allocator, reader);
        defer object_id.deinit(state.allocator);
        if (object_id != .object_identifier) return error.DoesNotMatchSchema;
        if (object_id.object_identifier.len != 4)
            return;

        const data = object_id.object_identifier.data;
        // Basic constraints extension
        if (data[0] != 2 or data[1] != 5 or data[2] != 29 or data[3] != 15)
            return;

        const basic_constraints = try asn1.der.parse_value(state.allocator, reader);
        defer basic_constraints.deinit(state.allocator);
        if (basic_constraints != .bool)
            return error.DoesNotMatchSchema;
        state.self.is_ca = basic_constraints.bool;
    }

    fn initExtensions(state: *CaptureState, tag_byte: u8, length: usize, reader: anytype) !void {
        const schema = .{
            .sequence_of,
            .{ .capture, 0, .sequence },
        };
        const captures = .{
            state, processExtension,
        };
        try asn1.der.parse_schema(schema, captures, reader);
    }

    fn initPublicKeyInfo(state: *CaptureState, tag_byte: u8, length: usize, reader: anytype) !void {
        state.self.public_key = try parse_public_key(state.allocator, reader);
        state.pk_allocated = true;
    }

    /// Initialize a trusted anchor from distinguished encoding rules (DER) encoded data
    pub fn create(allocator: *Allocator, der_reader: anytype) DecodeDERError(@TypeOf(der_reader))!@This() {
        var self: @This() = undefined;
        self.is_ca = false;
        // https://tools.ietf.org/html/rfc5280#page-117
        const schema = .{
            .sequence, .{
                // tbsCertificate
                .{
                    .sequence,
                    .{
                        .{ .context_specific, 0 }, // version
                        .{.int}, // serialNumber
                        .{.sequence}, // signature
                        .{.sequence}, // issuer
                        .{.sequence}, // validity,
                        .{ .capture, 0, .sequence }, // subject
                        .{ .capture, 1, .sequence }, // subjectPublicKeyInfo
                        .{ .optional, .context_specific, 1 }, // issuerUniqueID
                        .{ .optional, .context_specific, 2 }, // subjectUniqueID
                        .{ .capture, 2, .optional, .context_specific, 3 }, // extensions
                    },
                },
                // signatureAlgorithm
                .{.sequence},
                // signatureValue
                .{.bit_string},
            },
        };

        var capture_state = CaptureState{
            .self = &self,
            .allocator = allocator,
        };
        const captures = .{
            &capture_state, initSubjectDn,
            &capture_state, initPublicKeyInfo,
            &capture_state, initExtensions,
        };

        errdefer {
            if (capture_state.dn_allocated)
                allocator.free(self.dn);
            if (capture_state.pk_allocated)
                self.public_key.deinit(allocator);
        }

        asn1.der.parse_schema(schema, captures, der_reader) catch |err| switch (err) {
            error.InvalidLength,
            error.InvalidTag,
            error.InvalidContainerLength,
            error.DoesNotMatchSchema,
            => return error.MalformedDER,
            else => |e| return e,
        };
        return self;
    }

    pub fn deinit(self: @This(), alloc: *Allocator) void {
        alloc.free(self.dn);
        self.public_key.deinit(alloc);
    }

    pub fn format(self: @This(), comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print(
            \\CERTIFICATE
            \\-----------
            \\IS CA: {}
            \\Subject distinguished name (encoded):
            \\{X}
            \\Public key:
            \\
        , .{ self.is_ca, self.dn });

        switch (self.public_key) {
            .rsa => |mod_exp| {
                const modulus = std.math.big.int.Const{ .positive = true, .limbs = mod_exp.modulus };
                const exponent = std.math.big.int.Const{ .positive = true, .limbs = mod_exp.exponent };
                try writer.print(
                    \\RSA
                    \\modulus: {}
                    \\exponent: {}
                    \\
                , .{
                    modulus,
                    exponent,
                });
            },
            .ec => |ec| {
                try writer.print(
                    \\EC (Curve: {})
                    \\point: {}
                    \\
                , .{
                    ec.id,
                    ec.curve_point,
                });
            },
        }

        try writer.writeAll(
            \\-----------
            \\
        );
    }
};

pub const TrustAnchorChain = struct {
    data: std.ArrayList(TrustAnchor),

    pub fn from_pem(allocator: *Allocator, pem_reader: anytype) DecodeDERError(@TypeOf(pem_reader))!@This() {
        var self = @This(){ .data = std.ArrayList(TrustAnchor).init(allocator) };
        errdefer self.deinit();

        var it = pemCertificateIterator(pem_reader);
        while (try it.next()) |cert_reader| {
            var buffered = std.io.bufferedReader(cert_reader);
            const anchor = try TrustAnchor.create(allocator, buffered.reader());
            errdefer anchor.deinit(allocator);

            // This read forces the cert reader to find the `-----END`
            // @TODO Should work without this read, investigate
            _ = cert_reader.readByte() catch |err| switch (err) {
                error.EndOfStream => {
                    try self.data.append(anchor);
                    break;
                },
                else => |e| return e,
            };
            return error.MalformedDER;
        }
        return self;
    }

    pub fn deinit(self: @This()) void {
        const alloc = self.data.allocator;
        for (self.data.items) |ta| ta.deinit(alloc);
        self.data.deinit();
    }
};

fn PEMSectionReader(comptime Reader: type) type {
    const ReadError = Reader.Error || error{MalformedPEM};
    const S = struct {
        pub fn read(self: *PEMCertificateIterator(Reader), buffer: []u8) ReadError!usize {
            const end = "-----END ";
            var end_letters_matched: ?usize = null;

            var out_idx: usize = 0;
            if (self.waiting_chars_len > 0) {
                const rest_written = std.math.min(self.waiting_chars_len, buffer.len);
                while (out_idx < rest_written) : (out_idx += 1) {
                    buffer[out_idx] = self.waiting_chars[out_idx];
                }

                self.waiting_chars_len -= rest_written;
                if (self.waiting_chars_len != 0) {
                    std.mem.copy(u8, self.waiting_chars[0..], self.waiting_chars[rest_written..]);
                }

                if (out_idx == buffer.len) {
                    return out_idx;
                }
            }

            var base64_buf: [4]u8 = undefined;
            var base64_idx: usize = 0;

            while (true) {
                var byte = self.reader.readByte() catch |err| switch (err) {
                    error.EndOfStream => {
                        if (self.skip_to_newline_exit) {
                            self.state = .none;
                            return 0;
                        }
                        return error.MalformedPEM;
                    },
                    else => |e| return e,
                };

                if (self.skip_to_newline_exit) {
                    if (byte == '\n') {
                        self.skip_to_newline_exit = false;
                        self.state = .none;
                        return 0;
                    }
                    continue;
                }

                if (byte == '\n' or byte == '\r') {
                    self.empty_line = true;
                    continue;
                }
                defer self.empty_line = false;

                if (end_letters_matched) |*matched| {
                    if (end[matched.*] == byte) {
                        matched.* += 1;
                        if (matched.* == end.len) {
                            self.skip_to_newline_exit = true;
                            if (out_idx > 0)
                                return out_idx
                            else
                                continue;
                        }
                        continue;
                    } else return error.MalformedPEM;
                } else if (self.empty_line and end[0] == byte) {
                    end_letters_matched = 1;
                    continue;
                }

                base64_buf[base64_idx] = byte;
                base64_idx += 1;
                if (base64_idx == base64_buf.len) {
                    base64_idx = 0;

                    const out_len = std.base64.standard_decoder.calcSize(&base64_buf) catch
                        return error.MalformedPEM;
                    const rest_chars = if (out_len > buffer.len - out_idx)
                        out_len - (buffer.len - out_idx)
                    else
                        0;
                    const buf_chars = out_len - rest_chars;

                    var res_buffer: [3]u8 = undefined;
                    std.base64.standard_decoder_unsafe.decode(res_buffer[0..out_len], &base64_buf);

                    var i: u3 = 0;
                    while (i < buf_chars) : (i += 1) {
                        buffer[out_idx] = res_buffer[i];
                        out_idx += 1;
                    }

                    if (rest_chars > 0) {
                        mem.copy(u8, &self.waiting_chars, res_buffer[i..]);
                        self.waiting_chars_len = @intCast(u2, rest_chars);
                    }
                    if (out_idx == buffer.len)
                        return out_idx;
                }
            }
        }
    };
    return std.io.Reader(*PEMCertificateIterator(Reader), ReadError, S.read);
}

fn PEMCertificateIterator(comptime Reader: type) type {
    return struct {
        pub const SectionReader = PEMSectionReader(Reader);
        pub const NextError = SectionReader.Error || error{EndOfStream};

        reader: Reader,
        // Internal state for the iterator and the current reader.
        skip_to_newline_exit: bool = false,
        empty_line: bool = false,
        waiting_chars: [4]u8 = undefined,
        waiting_chars_len: u2 = 0,
        state: enum {
            none,
            in_section_name,
            in_cert,
            in_other,
        } = .none,

        pub fn next(self: *@This()) NextError!?SectionReader {
            const end = "-----END ";
            const begin = "-----BEGIN ";
            const certificate = "CERTIFICATE";
            const x509_certificate = "X.509 CERTIFICATE";

            var line_empty = true;
            var end_letters_matched: ?usize = null;
            var begin_letters_matched: ?usize = null;
            var certificate_letters_matched: ?usize = null;
            var x509_certificate_letters_matched: ?usize = null;
            var skip_to_newline = false;
            var return_after_skip = false;

            var base64_buf: [4]u8 = undefined;
            var base64_buf_idx: usize = 0;

            // Called next before reading all of the previous cert.
            if (self.state == .in_cert) {
                self.waiting_chars_len = 0;
            }

            while (true) {
                var last_byte = false;
                const byte = self.reader.readByte() catch |err| switch (err) {
                    error.EndOfStream => blk: {
                        if (line_empty and self.state == .none) {
                            return null;
                        } else {
                            last_byte = true;
                            break :blk '\n';
                        }
                    },
                    else => |e| return e,
                };

                if (skip_to_newline) {
                    if (last_byte)
                        return null;
                    if (byte == '\n') {
                        if (return_after_skip) {
                            return SectionReader{ .context = self };
                        }
                        skip_to_newline = false;
                        line_empty = true;
                    }
                    continue;
                } else if (byte == '\r' or byte == '\n') {
                    line_empty = true;
                    continue;
                }

                defer line_empty = byte == '\n' or (line_empty and byte == ' ');

                switch (self.state) {
                    .none => {
                        if (begin_letters_matched) |*matched| {
                            if (begin[matched.*] != byte)
                                return error.MalformedPEM;

                            matched.* += 1;
                            if (matched.* == begin.len) {
                                self.state = .in_section_name;
                                line_empty = true;
                                begin_letters_matched = null;
                            }
                        } else if (begin[0] == byte) {
                            begin_letters_matched = 1;
                        } else if (mem.indexOfScalar(u8, &std.ascii.spaces, byte) != null) {
                            if (last_byte) return null;
                        } else return error.MalformedPEM;
                    },
                    .in_section_name => {
                        if (certificate_letters_matched) |*matched| {
                            if (certificate[matched.*] != byte) {
                                self.state = .in_other;
                                skip_to_newline = true;
                                continue;
                            }
                            matched.* += 1;
                            if (matched.* == certificate.len) {
                                self.state = .in_cert;
                                certificate_letters_matched = null;
                                skip_to_newline = true;
                                return_after_skip = true;
                            }
                        } else if (x509_certificate_letters_matched) |*matched| {
                            if (x509_certificate[matched.*] != byte) {
                                self.state = .in_other;
                                skip_to_newline = true;
                                continue;
                            }
                            matched.* += 1;
                            if (matched.* == x509_certificate.len) {
                                self.state = .in_cert;
                                x509_certificate_letters_matched = null;
                                skip_to_newline = true;
                                return_after_skip = true;
                            }
                        } else if (line_empty and certificate[0] == byte) {
                            certificate_letters_matched = 1;
                        } else if (line_empty and x509_certificate[0] == byte) {
                            x509_certificate_letters_matched = 1;
                        } else if (line_empty) {
                            self.state = .in_other;
                            skip_to_newline = true;
                        } else unreachable;
                    },
                    .in_other, .in_cert => {
                        if (end_letters_matched) |*matched| {
                            if (end[matched.*] != byte) {
                                end_letters_matched = null;
                                skip_to_newline = true;
                                continue;
                            }
                            matched.* += 1;
                            if (matched.* == end.len) {
                                self.state = .none;
                                end_letters_matched = null;
                                skip_to_newline = true;
                            }
                        } else if (line_empty and end[0] == byte) {
                            end_letters_matched = 1;
                        }
                    },
                }
            }
        }
    };
}

/// Iterator of io.Reader that each decode one certificate from the PEM reader.
/// Readers do not have to be fully consumed until end of stream, but they must be
/// read from in order.
/// Iterator.SectionReader is the type of the io.Reader, Iterator.NextError is the error
/// set of the next() function.
pub fn pemCertificateIterator(reader: anytype) PEMCertificateIterator(@TypeOf(reader)) {
    return .{ .reader = reader };
}

pub const NameElement = struct {
    // Encoded OID without tag
    oid: asn1.ObjectIdentifier,
    // Destination buffer
    buf: []u8,
    status: enum {
        not_found,
        found,
        errored,
    },
};

const github_pem = @embedFile("../test/github.pem");
const github_der = @embedFile("../test/github.der");

fn expected_pem_certificate_chain(bytes: []const u8, certs: []const []const u8) !void {
    var fbs = std.io.fixedBufferStream(bytes);

    var it = pemCertificateIterator(fbs.reader());
    var idx: usize = 0;
    while (try it.next()) |cert_reader| : (idx += 1) {
        const result_bytes = try cert_reader.readAllAlloc(std.testing.allocator, std.math.maxInt(usize));
        defer std.testing.allocator.free(result_bytes);
        std.testing.expectEqualSlices(u8, certs[idx], result_bytes);
    }
    if (idx != certs.len) {
        std.debug.panic("Read {} certificates, wanted {}", .{ idx, certs.len });
    }
    std.testing.expect((try it.next()) == null);
}

fn expected_pem_certificate(bytes: []const u8, cert_bytes: []const u8) !void {
    try expected_pem_certificate_chain(bytes, &[1][]const u8{cert_bytes});
}

test "pemCertificateIterator" {
    try expected_pem_certificate(github_pem, github_der);
    try expected_pem_certificate(
        \\-----BEGIN BOGUS-----
        \\-----END BOGUS-----
        \\
            ++
            github_pem,
        github_der,
    );

    try expected_pem_certificate_chain(
        github_pem ++
            \\
            \\-----BEGIN BOGUS-----
            \\-----END BOGUS-----
            \\
            ++ github_pem,
        &[2][]const u8{ github_der, github_der },
    );

    try expected_pem_certificate_chain(
        \\-----BEGIN BOGUS-----
        \\-----END BOGUS-----
        \\
    ,
        &[0][]const u8{},
    );

    // Try reading byte by byte from a cert reader
    {
        var fbs = std.io.fixedBufferStream(github_pem ++ "\n" ++ github_pem);
        var it = pemCertificateIterator(fbs.reader());

        // Read a couple of bytes from the first reader, then skip to the next
        {
            const first_reader = (try it.next()) orelse return error.NoCertificate;
            var first_few: [8]u8 = undefined;
            const bytes = try first_reader.readAll(&first_few);
            std.testing.expectEqual(first_few.len, bytes);
            std.testing.expectEqualSlices(u8, github_der[0..bytes], &first_few);
        }

        const next_reader = (try it.next()) orelse return error.NoCertificate;
        var idx: usize = 0;
        while (true) : (idx += 1) {
            const byte = next_reader.readByte() catch |err| switch (err) {
                error.EndOfStream => break,
                else => |e| return e,
            };
            if (github_der[idx] != byte) {
                std.debug.panic("index {}: expected 0x{X}, found 0x{X}", .{ idx, github_der[idx], byte });
            }
        }
        std.testing.expectEqual(github_der.len, idx);
        std.testing.expect((try it.next()) == null);
    }
}

test "TrustAnchorChain" {
    var fbs = std.io.fixedBufferStream(github_pem);
    const chain = try TrustAnchorChain.from_pem(std.testing.allocator, fbs.reader());
    defer chain.deinit();
}
