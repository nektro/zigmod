const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const Sha384 = std.crypto.hash.sha2.Sha384;
const Sha512 = std.crypto.hash.sha2.Sha512;
const Sha256 = std.crypto.hash.sha2.Sha256;
const Hmac256 = std.crypto.auth.hmac.sha2.HmacSha256;

pub const asn1 = @import("asn1.zig");
pub const x509 = @import("x509.zig");
pub const crypto = @import("crypto.zig");

const ciphers = @import("ciphersuites.zig");
pub const ciphersuites = ciphers.suites;

comptime {
    std.testing.refAllDecls(x509);
    std.testing.refAllDecls(asn1);
    std.testing.refAllDecls(crypto);
}

fn handshake_record_length(reader: anytype) !usize {
    return try record_length(0x16, reader);
}

pub fn record_length(t: u8, reader: anytype) !usize {
    try check_record_type(t, reader);
    var record_header: [4]u8 = undefined;
    try reader.readNoEof(&record_header);
    if (!mem.eql(u8, record_header[0..2], "\x03\x03") and !mem.eql(u8, record_header[0..2], "\x03\x01"))
        return error.ServerInvalidVersion;
    return mem.readIntSliceBig(u16, record_header[2..4]);
}

pub const ServerAlert = error{
    AlertCloseNotify,
    AlertUnexpectedMessage,
    AlertBadRecordMAC,
    AlertDecryptionFailed,
    AlertRecordOverflow,
    AlertDecompressionFailure,
    AlertHandshakeFailure,
    AlertNoCertificate,
    AlertBadCertificate,
    AlertUnsupportedCertificate,
    AlertCertificateRevoked,
    AlertCertificateExpired,
    AlertCertificateUnknown,
    AlertIllegalParameter,
    AlertUnknownCA,
    AlertAccessDenied,
    AlertDecodeError,
    AlertDecryptError,
    AlertExportRestriction,
    AlertProtocolVersion,
    AlertInsufficientSecurity,
    AlertInternalError,
    AlertUserCanceled,
    AlertNoRenegotiation,
    AlertUnsupportedExtension,
};

fn check_record_type(
    expected: u8,
    reader: anytype,
) (@TypeOf(reader).Error || ServerAlert || error{ ServerMalformedResponse, EndOfStream })!void {
    const record_type = try reader.readByte();
    // Alert
    if (record_type == 0x15) {
        // Skip SSL version, length of record
        try reader.skipBytes(4, .{});

        const severity = try reader.readByte();
        const err_num = try reader.readByte();
        return switch (err_num) {
            0 => error.AlertCloseNotify,
            10 => error.AlertUnexpectedMessage,
            20 => error.AlertBadRecordMAC,
            21 => error.AlertDecryptionFailed,
            22 => error.AlertRecordOverflow,
            30 => error.AlertDecompressionFailure,
            40 => error.AlertHandshakeFailure,
            41 => error.AlertNoCertificate,
            42 => error.AlertBadCertificate,
            43 => error.AlertUnsupportedCertificate,
            44 => error.AlertCertificateRevoked,
            45 => error.AlertCertificateExpired,
            46 => error.AlertCertificateUnknown,
            47 => error.AlertIllegalParameter,
            48 => error.AlertUnknownCA,
            49 => error.AlertAccessDenied,
            50 => error.AlertDecodeError,
            51 => error.AlertDecryptError,
            60 => error.AlertExportRestriction,
            70 => error.AlertProtocolVersion,
            71 => error.AlertInsufficientSecurity,
            80 => error.AlertInternalError,
            90 => error.AlertUserCanceled,
            100 => error.AlertNoRenegotiation,
            110 => error.AlertUnsupportedExtension,
            else => error.ServerMalformedResponse,
        };
    }
    if (record_type != expected)
        return error.ServerMalformedResponse;
}

fn Sha256Reader(comptime Reader: anytype) type {
    const State = struct {
        sha256: *Sha256,
        reader: Reader,
    };
    const S = struct {
        pub fn read(state: State, buffer: []u8) Reader.Error!usize {
            const amt = try state.reader.read(buffer);
            if (amt != 0) {
                state.sha256.update(buffer[0..amt]);
            }
            return amt;
        }
    };
    return std.io.Reader(State, Reader.Error, S.read);
}

fn sha256_reader(sha256: *Sha256, reader: anytype) Sha256Reader(@TypeOf(reader)) {
    return .{ .context = .{ .sha256 = sha256, .reader = reader } };
}

fn Sha256Writer(comptime Writer: anytype) type {
    const State = struct {
        sha256: *Sha256,
        writer: Writer,
    };
    const S = struct {
        pub fn write(state: State, buffer: []const u8) Writer.Error!usize {
            const amt = try state.writer.write(buffer);
            if (amt != 0) {
                state.sha256.update(buffer[0..amt]);
            }
            return amt;
        }
    };
    return std.io.Writer(State, Writer.Error, S.write);
}

fn sha256_writer(sha256: *Sha256, writer: anytype) Sha256Writer(@TypeOf(writer)) {
    return .{ .context = .{ .sha256 = sha256, .writer = writer } };
}

fn CertificateReaderState(comptime Reader: type) type {
    return struct {
        reader: Reader,
        length: usize,
        idx: usize = 0,
    };
}

fn CertificateReader(comptime Reader: type) type {
    const S = struct {
        pub fn read(state: *CertificateReaderState(Reader), buffer: []u8) Reader.Error!usize {
            const out_bytes = std.math.min(buffer.len, state.length - state.idx);
            const res = try state.reader.readAll(buffer[0..out_bytes]);
            state.idx += res;
            return res;
        }
    };

    return std.io.Reader(*CertificateReaderState(Reader), Reader.Error, S.read);
}

pub const CertificateVerifier = union(enum) {
    none,
    function: anytype,
    default,
};

pub fn CertificateVerifierReader(comptime Reader: type) type {
    return CertificateReader(Sha256Reader(Reader));
}

pub fn ClientConnectError(comptime verifier: CertificateVerifier, comptime Reader: type, comptime Writer: type) type {
    const Additional = error{
        ServerInvalidVersion,
        ServerMalformedResponse,
        EndOfStream,
        ServerInvalidCipherSuite,
        ServerInvalidCompressionMethod,
        ServerInvalidRenegotiationData,
        ServerInvalidECPointCompression,
        ServerInvalidProtocol,
        ServerInvalidExtension,
        ServerInvalidCurve,
        ServerInvalidSignature,
        ServerInvalidSignatureAlgorithm,
        ServerAuthenticationFailed,
        ServerInvalidVerifyData,
        PreMasterGenerationFailed,
        OutOfMemory,
    };
    const err_msg = "Certificate verifier function cannot be generic, use CertificateVerifierReader to get the reader argument type";
    return Reader.Error || Writer.Error || ServerAlert || Additional || switch (verifier) {
        .none => error{},
        .function => |f| @typeInfo(@typeInfo(@TypeOf(f)).Fn.return_type orelse
            @compileError(err_msg)).ErrorUnion.error_set || error{CertificateVerificationFailed},
        .default => error{CertificateVerificationFailed},
    };
}

// See http://howardhinnant.github.io/date_algorithms.html
// Timestamp in seconds, only supports A.D. dates
fn unix_timestamp_from_civil_date(year: u16, month: u8, day: u8) i64 {
    var y: i64 = year;
    if (month <= 2) y -= 1;
    const era = @divTrunc(y, 400);
    const yoe = y - era * 400; // [0, 399]
    const doy = @divTrunc((153 * (month + (if (month > 2) @as(i64, -3) else 9)) + 2), 5) + day - 1; // [0, 365]
    const doe = yoe * 365 + @divTrunc(yoe, 4) - @divTrunc(yoe, 100) + doy; // [0, 146096]
    return (era * 146097 + doe - 719468) * 86400;
}

fn read_der_utc_timestamp(reader: anytype) !i64 {
    var buf: [17]u8 = undefined;

    const tag = try reader.readByte();
    if (tag != 0x17)
        return error.CertificateVerificationFailed;
    const len = try asn1.der.parse_length(reader);
    if (len > 17)
        return error.CertificateVerificationFailed;

    try reader.readNoEof(buf[0..len]);
    const year = std.fmt.parseUnsigned(u16, buf[0..2], 10) catch
        return error.CertificateVerificationFailed;
    const month = std.fmt.parseUnsigned(u8, buf[2..4], 10) catch
        return error.CertificateVerificationFailed;
    const day = std.fmt.parseUnsigned(u8, buf[4..6], 10) catch
        return error.CertificateVerificationFailed;

    var time = unix_timestamp_from_civil_date(2000 + year, month, day);
    time += (std.fmt.parseUnsigned(i64, buf[6..8], 10) catch
        return error.CertificateVerificationFailed) * 3600;
    time += (std.fmt.parseUnsigned(i64, buf[8..10], 10) catch
        return error.CertificateVerificationFailed) * 60;

    if (buf[len - 1] == 'Z') {
        if (len == 13) {
            time += std.fmt.parseUnsigned(u8, buf[10..12], 10) catch
                return error.CertificateVerificationFailed;
        } else if (len != 11) {
            return error.CertificateVerificationFailed;
        }
    } else {
        if (len == 15) {
            if (buf[10] != '+' and buf[10] != '-')
                return error.CertificateVerificationFailed;

            var additional = (std.fmt.parseUnsigned(i64, buf[11..13], 10) catch
                return error.CertificateVerificationFailed) * 3600;
            additional += (std.fmt.parseUnsigned(i64, buf[13..15], 10) catch
                return error.CertificateVerificationFailed) * 60;

            time += if (buf[10] == '+') -additional else additional;
        } else if (len == 17) {
            if (buf[12] != '+' and buf[12] != '-')
                return error.CertificateVerificationFailed;
            time += std.fmt.parseUnsigned(u8, buf[10..12], 10) catch
                return error.CertificateVerificationFailed;

            var additional = (std.fmt.parseUnsigned(i64, buf[13..15], 10) catch
                return error.CertificateVerificationFailed) * 3600;
            additional += (std.fmt.parseUnsigned(i64, buf[15..17], 10) catch
                return error.CertificateVerificationFailed) * 60;

            time += if (buf[12] == '+') -additional else additional;
        } else return error.CertificateVerificationFailed;
    }
    return time;
}

fn check_cert_timestamp(time: i64, tag_byte: u8, length: usize, reader: anytype) !void {
    if (time < (try read_der_utc_timestamp(reader)))
        return error.CertificateVerificationFailed;
    if (time > (try read_der_utc_timestamp(reader)))
        return error.CertificateVerificationFailed;
}

fn add_cert_subject_dn(state: *VerifierCaptureState, _: u8, length: usize, reader: anytype) !void {
    state.list.items[state.list.items.len - 1].dn = state.fbs.buffer[state.fbs.pos .. state.fbs.pos + length];
}

fn add_cert_public_key(state: *VerifierCaptureState, _: u8, length: usize, reader: anytype) !void {
    state.list.items[state.list.items.len - 1].public_key = x509.parse_public_key(
        state.allocator,
        reader,
    ) catch |err| switch (err) {
        error.MalformedDER => return error.CertificateVerificationFailed,
        else => |e| return e,
    };
}

fn add_server_cert(state: *VerifierCaptureState, tag_byte: u8, length: usize, reader: anytype) !void {
    const is_ca = state.list.items.len != 0;

    const encoded_length = asn1.der.encode_length(length).slice();
    const cert_bytes = try state.allocator.alloc(u8, length + 1 + encoded_length.len);
    errdefer state.allocator.free(cert_bytes);
    cert_bytes[0] = tag_byte;
    mem.copy(u8, cert_bytes[1 .. 1 + encoded_length.len], encoded_length);

    try reader.readNoEof(cert_bytes[1 + encoded_length.len ..]);
    (try state.list.addOne(state.allocator)).* = .{
        .is_ca = is_ca,
        .bytes = cert_bytes,
        .dn = undefined,
        .public_key = undefined,
        .signature = asn1.BitString{ .data = &[0]u8{}, .bit_len = 0 },
        .signature_algorithm = undefined,
    };
    errdefer state.allocator.free(state.list.items[state.list.items.len - 1].signature.data);

    const schema = .{
        .sequence,
        .{
            .{ .context_specific, 0 }, // version
            .{.int}, // serialNumber
            .{.sequence}, // signature
            .{.sequence}, // issuer
            .{ .capture, 0, .sequence }, // validity
            .{ .capture, 1, .sequence }, // subject
            .{ .capture, 2, .sequence }, // subjectPublicKeyInfo
            .{ .optional, .context_specific, 1 }, // issuerUniqueID
            .{ .optional, .context_specific, 2 }, // subjectUniqueID
            .{ .optional, .context_specific, 3 }, // extensions
        },
    };

    const captures = .{
        std.time.timestamp(), check_cert_timestamp,
        state,                add_cert_subject_dn,
        state,                add_cert_public_key,
    };

    var fbs = std.io.fixedBufferStream(@as([]const u8, cert_bytes[1 + encoded_length.len ..]));
    state.fbs = &fbs;

    asn1.der.parse_schema_tag_len(tag_byte, length, schema, captures, fbs.reader()) catch |err| switch (err) {
        error.InvalidLength,
        error.InvalidTag,
        error.InvalidContainerLength,
        error.DoesNotMatchSchema,
        => return error.CertificateVerificationFailed,
        else => |e| return e,
    };
}

fn set_signature_algorithm(state: *VerifierCaptureState, _: u8, length: usize, reader: anytype) !void {
    const oid_tag = try reader.readByte();
    if (oid_tag != 0x06)
        return error.CertificateVerificationFailed;

    const oid_length = try asn1.der.parse_length(reader);
    if (oid_length == 9) {
        var oid_bytes: [9]u8 = undefined;
        try reader.readNoEof(&oid_bytes);

        const cert = &state.list.items[state.list.items.len - 1];
        if (mem.eql(u8, &oid_bytes, &[_]u8{ 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01 })) {
            cert.signature_algorithm = .rsa;
        } else if (mem.eql(u8, &oid_bytes, &[_]u8{ 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x04 })) {
            cert.signature_algorithm = .rsa_md5;
        } else if (mem.eql(u8, &oid_bytes, &[_]u8{ 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x05 })) {
            cert.signature_algorithm = .rsa_sha1;
        } else if (mem.eql(u8, &oid_bytes, &[_]u8{ 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x0B })) {
            cert.signature_algorithm = .rsa_sha256;
        } else if (mem.eql(u8, &oid_bytes, &[_]u8{ 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x0C })) {
            cert.signature_algorithm = .rsa_sha384;
        } else if (mem.eql(u8, &oid_bytes, &[_]u8{ 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x0D })) {
            cert.signature_algorithm = .rsa_sha512;
        } else {
            return error.CertificateVerificationFailed;
        }
        return;
    } else if (oid_length == 10) {
        // @TODO
        // ECDSA + <Hash> algorithms
    }

    return error.CertificateVerificationFailed;
}

fn set_signature_value(state: *VerifierCaptureState, tag: u8, length: usize, reader: anytype) !void {
    const unused_bits = try reader.readByte();
    const bit_count = (length - 1) * 8 - unused_bits;
    const signature_bytes = try state.allocator.alloc(u8, length - 1);
    errdefer state.allocator.free(signature_bytes);
    try reader.readNoEof(signature_bytes);
    state.list.items[state.list.items.len - 1].signature = .{
        .data = signature_bytes,
        .bit_len = bit_count,
    };
}

fn verify_signature(
    allocator: *Allocator,
    signature_algorithm: SignatureAlgorithm,
    signature: asn1.BitString,
    hash: []const u8,
    public_key: x509.PublicKey,
) !bool {
    // @TODO ECDSA algorithms
    if (public_key != .rsa) return false;
    const prefix: []const u8 = switch (signature_algorithm) {
        // Deprecated hash algos
        .rsa_md5, .rsa_sha1 => return false,
        // @TODO How does this one work?
        .rsa => return false,
        .rsa_sha256 => &[_]u8{
            0x30, 0x31, 0x30, 0x0d, 0x06,
            0x09, 0x60, 0x86, 0x48, 0x01,
            0x65, 0x03, 0x04, 0x02, 0x01,
            0x05, 0x00, 0x04, 0x20,
        },
        .rsa_sha384 => &[_]u8{
            0x30, 0x41, 0x30, 0x0d, 0x06,
            0x09, 0x60, 0x86, 0x48, 0x01,
            0x65, 0x03, 0x04, 0x02, 0x02,
            0x05, 0x00, 0x04, 0x30,
        },
        .rsa_sha512 => &[_]u8{
            0x30, 0x51, 0x30, 0x0d, 0x06,
            0x09, 0x60, 0x86, 0x48, 0x01,
            0x65, 0x03, 0x04, 0x02, 0x03,
            0x05, 0x00, 0x04, 0x40,
        },
    };

    // RSA hash verification with PKCS 1 V1_5 padding
    const modulus = std.math.big.int.Const{ .limbs = public_key.rsa.modulus, .positive = true };
    const exponent = std.math.big.int.Const{ .limbs = public_key.rsa.exponent, .positive = true };
    if (modulus.bitCountAbs() != signature.bit_len)
        return false;

    // encrypt the signature using the RSA key
    // @TODO better algorithm, this is probably slow as hell
    var encrypted_signature = try std.math.big.int.Managed.initSet(allocator, @as(usize, 1));
    defer encrypted_signature.deinit();

    {
        var curr_exponent = try exponent.toManaged(allocator);
        defer curr_exponent.deinit();

        const curr_base_limbs = try allocator.alloc(
            usize,
            std.math.divCeil(usize, signature.data.len, @sizeOf(usize)) catch unreachable,
        );
        const curr_base_limb_bytes = @ptrCast([*]u8, curr_base_limbs)[0..signature.data.len];
        mem.copy(u8, curr_base_limb_bytes, signature.data);
        mem.reverse(u8, curr_base_limb_bytes);
        var curr_base = (std.math.big.int.Mutable{
            .limbs = curr_base_limbs,
            .positive = true,
            .len = curr_base_limbs.len,
        }).toManaged(allocator);
        defer curr_base.deinit();

        // encrypted = signature ^ key.exponent MOD key.modulus
        while (curr_exponent.toConst().orderAgainstScalar(0) == .gt) {
            if (curr_exponent.isOdd()) {
                try encrypted_signature.ensureMulCapacity(encrypted_signature.toConst(), curr_base.toConst());
                try encrypted_signature.mul(encrypted_signature.toConst(), curr_base.toConst());
                try llmod(&encrypted_signature, modulus);
            }
            try curr_base.sqr(curr_base.toConst());
            try llmod(&curr_base, modulus);
            try curr_exponent.shiftRight(curr_exponent, 1);
        }
        try llmod(&encrypted_signature, modulus);
    }
    // EMSA-PKCS1-V1_5-ENCODE
    if (encrypted_signature.limbs.len * @sizeOf(usize) < signature.data.len)
        return false;

    const enc_buf = @ptrCast([*]u8, encrypted_signature.limbs.ptr)[0..signature.data.len];
    mem.reverse(u8, enc_buf);

    if (enc_buf[0] != 0x00 or enc_buf[1] != 0x01)
        return false;
    if (!mem.endsWith(u8, enc_buf, hash))
        return false;
    if (!mem.endsWith(u8, enc_buf[0 .. enc_buf.len - hash.len], prefix))
        return false;
    if (enc_buf[enc_buf.len - hash.len - prefix.len - 1] != 0x00)
        return false;
    for (enc_buf[2 .. enc_buf.len - hash.len - prefix.len - 1]) |c| {
        if (c != 0xff) return false;
    }

    return true;
}

fn certificate_verify_signature(
    allocator: *Allocator,
    signature_algorithm: SignatureAlgorithm,
    signature: asn1.BitString,
    bytes: []const u8,
    public_key: x509.PublicKey,
) !bool {
    // @TODO ECDSA algorithms
    if (public_key != .rsa) return false;

    var hash_buf: [64]u8 = undefined;
    var hash: []u8 = undefined;

    switch (signature_algorithm) {
        // Deprecated hash algos
        .rsa_md5, .rsa_sha1 => return false,
        // @TODO How does this one work?
        .rsa => return false,

        .rsa_sha256 => {
            Sha256.hash(bytes, hash_buf[0..32], .{});
            hash = hash_buf[0..32];
        },
        .rsa_sha384 => {
            Sha384.hash(bytes, hash_buf[0..48], .{});
            hash = hash_buf[0..48];
        },
        .rsa_sha512 => {
            Sha512.hash(bytes, hash_buf[0..64], .{});
            hash = &hash_buf;
        },
    }
    return try verify_signature(allocator, signature_algorithm, signature, hash, public_key);
}

// res = res mod N
fn llmod(res: *std.math.big.int.Managed, n: std.math.big.int.Const) !void {
    var temp = try std.math.big.int.Managed.init(res.allocator);
    defer temp.deinit();
    try temp.divTrunc(res, res.toConst(), n);
}

const SignatureAlgorithm = enum {
    rsa,
    rsa_md5,
    rsa_sha1,
    rsa_sha256,
    rsa_sha384,
    rsa_sha512,
    // @TODO ECDSA versions
};

const ServerCertificate = struct {
    bytes: []const u8,
    dn: []const u8,
    public_key: x509.PublicKey,
    signature: asn1.BitString,
    signature_algorithm: SignatureAlgorithm,
    is_ca: bool,
};

const VerifierCaptureState = struct {
    list: std.ArrayListUnmanaged(ServerCertificate),
    allocator: *Allocator,
    // Used in `add_server_cert` to avoid an extra allocation
    fbs: *std.io.FixedBufferStream([]const u8),
};

pub fn default_cert_verifier(
    allocator: *std.mem.Allocator,
    reader: anytype,
    certs_bytes: usize,
    trusted_certificates: []const x509.TrustAnchor,
    hostname: []const u8,
) !x509.PublicKey {
    var capture_state = VerifierCaptureState{
        .list = try std.ArrayListUnmanaged(ServerCertificate).initCapacity(allocator, 3),
        .allocator = allocator,
        .fbs = undefined,
    };
    defer {
        for (capture_state.list.items) |cert| {
            cert.public_key.deinit(allocator);
            allocator.free(cert.bytes);
            allocator.free(cert.signature.data);
        }
        capture_state.list.deinit(allocator);
    }

    const schema = .{
        .sequence, .{
            // tbsCertificate
            .{ .capture, 0, .sequence },
            // signatureAlgorithm
            .{ .capture, 1, .sequence },
            // signatureValue
            .{ .capture, 2, .bit_string },
        },
    };
    const captures = .{
        &capture_state, add_server_cert,
        &capture_state, set_signature_algorithm,
        &capture_state, set_signature_value,
    };

    var bytes_read: u24 = 0;
    while (bytes_read < certs_bytes) {
        const cert_length = try reader.readIntBig(u24);

        asn1.der.parse_schema(schema, captures, reader) catch |err| switch (err) {
            error.InvalidLength,
            error.InvalidTag,
            error.InvalidContainerLength,
            error.DoesNotMatchSchema,
            => return error.CertificateVerificationFailed,
            else => |e| return e,
        };

        bytes_read += 3 + cert_length;
    }
    if (bytes_read != certs_bytes)
        return error.CertificateVerificationFailed;

    const chain = capture_state.list.items;
    var i: usize = 0;
    while (i < chain.len - 1) : (i += 1) {
        if (!try certificate_verify_signature(
            allocator,
            chain[i].signature_algorithm,
            chain[i].signature,
            chain[i].bytes,
            chain[i + 1].public_key,
        )) {
            return error.CertificateVerificationFailed;
        }
    }

    for (chain) |cert| {
        for (trusted_certificates) |trusted| {
            // Try to find an exact match to a trusted certificate
            if (cert.is_ca == trusted.is_ca and mem.eql(u8, cert.dn, trusted.dn) and
                cert.public_key.eql(trusted.public_key))
            {
                const key = chain[0].public_key;
                chain[0].public_key = x509.PublicKey{
                    .ec = .{
                        .id = undefined,
                        .curve_point = &[0]u8{},
                    },
                };
                return key;
            }

            if (!trusted.is_ca)
                continue;

            if (try certificate_verify_signature(
                allocator,
                cert.signature_algorithm,
                cert.signature,
                cert.bytes,
                trusted.public_key,
            )) {
                const key = chain[0].public_key;
                chain[0].public_key = x509.PublicKey{
                    .ec = .{
                        .id = undefined,
                        .curve_point = &[0]u8{},
                    },
                };
                return key;
            }
        }
    }
    return error.CertificateVerificationFailed;
}

pub fn extract_cert_public_key(allocator: *Allocator, reader: anytype, length: usize) !x509.PublicKey {
    const CaptureState = struct {
        pub_key: x509.PublicKey,
        allocator: *Allocator,
    };
    var capture_state = CaptureState{
        .pub_key = undefined,
        .allocator = allocator,
    };

    var pub_key: x509.PublicKey = undefined;
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
                    .{.sequence}, // validity
                    .{.sequence}, // subject
                    .{ .capture, 0, .sequence }, // subjectPublicKeyInfo
                    .{ .optional, .context_specific, 1 }, // issuerUniqueID
                    .{ .optional, .context_specific, 2 }, // subjectUniqueID
                    .{ .optional, .context_specific, 3 }, // extensions
                },
            },
            // signatureAlgorithm
            .{.sequence},
            // signatureValue
            .{.bit_string},
        },
    };
    const captures = .{
        &capture_state, struct {
            fn f(state: *CaptureState, tag: u8, _: usize, subreader: anytype) !void {
                state.pub_key = x509.parse_public_key(state.allocator, subreader) catch |err| switch (err) {
                    error.MalformedDER => return error.ServerMalformedResponse,
                    else => |e| return e,
                };
            }
        }.f,
    };

    const cert_length = try reader.readIntBig(u24);
    asn1.der.parse_schema(schema, captures, reader) catch |err| switch (err) {
        error.InvalidLength,
        error.InvalidTag,
        error.InvalidContainerLength,
        error.DoesNotMatchSchema,
        => return error.ServerMalformedResponse,
        else => |e| return e,
    };
    errdefer capture_state.pub_key.deinit(allocator);

    try reader.skipBytes(length - cert_length - 3, .{});
    return capture_state.pub_key;
}

pub fn client_connect(
    options: anytype,
    hostname: []const u8,
) ClientConnectError(
    options.cert_verifier,
    @TypeOf(options.reader),
    @TypeOf(options.writer),
)!Client(
    @TypeOf(options.reader),
    @TypeOf(options.writer),
    options.ciphersuites,
    @hasField(@TypeOf(options), "protocols"),
) {
    const Options = @TypeOf(options);
    if (@TypeOf(options.cert_verifier) != CertificateVerifier and
        @TypeOf(options.cert_verifier) != @Type(.EnumLiteral))
        @compileError("cert_verifier should be of type CertificateVerifier");

    if (!@hasField(Options, "temp_allocator"))
        @compileError("Option tuple is missing field 'temp_allocator'");
    if (options.cert_verifier == .default) {
        if (!@hasField(Options, "trusted_certificates"))
            @compileError("Option tuple is missing field 'trusted_certificates' for .default cert_verifier");
    }

    const has_alpn = comptime @hasField(Options, "protocols");
    var handshake_record_hash = Sha256.init(.{});
    const reader = options.reader;
    const writer = options.writer;
    const hashing_reader = sha256_reader(&handshake_record_hash, reader);
    const hashing_writer = sha256_writer(&handshake_record_hash, writer);

    var client_random: [32]u8 = undefined;
    const rand = if (!@hasField(Options, "rand"))
        std.crypto.random
    else
        options.rand;

    rand.bytes(&client_random);

    var server_random: [32]u8 = undefined;

    if (options.ciphersuites.len == 0)
        @compileError("Must provide at least one ciphersuite.");
    const ciphersuite_bytes = 2 * options.ciphersuites.len + 2;
    // @TODO Make sure the individual lengths are u16s
    const alpn_bytes = if (has_alpn) blk: {
        var sum: usize = 0;
        for (options.protocols) |proto| {
            sum += proto.len;
        }
        break :blk 6 + options.protocols.len + sum;
    } else 0;
    var protocol: if (has_alpn) []const u8 else void = undefined;
    {
        const client_hello_start = comptime blk: {
            // TODO: We assume the compiler is running in a little endian system
            var starting_part: [46]u8 = [_]u8{
                // Record header: Handshake record type, protocol version, handshake size
                0x16, 0x03,      0x01,      undefined, undefined,
                // Handshake message type, bytes of client hello
                0x01, undefined, undefined, undefined,
                // Client version (hardcoded to TLS 1.2 even for TLS 1.3)
                0x03,
                0x03,
            } ++ ([1]u8{undefined} ** 32) ++ [_]u8{
                // Session ID
                0x00,
            } ++ mem.toBytes(@byteSwap(u16, ciphersuite_bytes));
            // using .* = mem.asBytes(...).* or mem.writeIntBig didn't work...

            // Same as above, couldnt achieve this with a single buffer.
            // TLS_EMPTY_RENEGOTIATION_INFO_SCSV
            var ciphersuite_buf: []const u8 = &[2]u8{ 0x00, 0x0f };
            for (options.ciphersuites) |cs, i| {
                // Also check for properties of the ciphersuites here
                if (cs.key_exchange != .ecdhe)
                    @compileError("Non ECDHE key exchange is not supported yet.");
                if (cs.hash != .sha256)
                    @compileError("Non SHA256 hash algorithm is not supported yet.");

                ciphersuite_buf = ciphersuite_buf ++ mem.toBytes(@byteSwap(u16, cs.tag));
            }

            var ending_part: [13]u8 = [_]u8{
                // Compression methods (no compression)
                0x01,      0x00,
                // Extensions length
                undefined, undefined,
                // Extension: server name
                // id, length, length of entry
                0x00,      0x00,
                undefined, undefined,
                undefined, undefined,
                // entry type, length of bytes
                0x00,      undefined,
                undefined,
            };
            break :blk starting_part ++ ciphersuite_buf ++ ending_part;
        };

        var msg_buf = client_hello_start.ptr[0..client_hello_start.len].*;
        mem.writeIntBig(u16, msg_buf[3..5], @intCast(u16, alpn_bytes + hostname.len + 0x59 + ciphersuite_bytes));
        mem.writeIntBig(u24, msg_buf[6..9], @intCast(u24, alpn_bytes + hostname.len + 0x55 + ciphersuite_bytes));
        mem.copy(u8, msg_buf[11..43], &client_random);
        mem.writeIntBig(u16, msg_buf[48 + ciphersuite_bytes ..][0..2], @intCast(u16, alpn_bytes + hostname.len + 0x2C));
        mem.writeIntBig(u16, msg_buf[52 + ciphersuite_bytes ..][0..2], @intCast(u16, hostname.len + 5));
        mem.writeIntBig(u16, msg_buf[54 + ciphersuite_bytes ..][0..2], @intCast(u16, hostname.len + 3));
        mem.writeIntBig(u16, msg_buf[57 + ciphersuite_bytes ..][0..2], @intCast(u16, hostname.len));
        try writer.writeAll(msg_buf[0..5]);
        try hashing_writer.writeAll(msg_buf[5..]);
    }
    try hashing_writer.writeAll(hostname);
    // @TODO Fix this with wikipedia test, add secp384r1 support (then app options.curves but default to all when not there (also do this for ciphersuites))
    if (has_alpn) {
        var msg_buf = [6]u8{ 0x00, 0x10, undefined, undefined, undefined, undefined };
        mem.writeIntBig(u16, msg_buf[2..4], @intCast(u16, alpn_bytes - 4));
        mem.writeIntBig(u16, msg_buf[4..6], @intCast(u16, alpn_bytes - 6));
        try hashing_writer.writeAll(&msg_buf);
        for (options.protocols) |proto| {
            try hashing_writer.writeByte(@intCast(u8, proto.len));
            try hashing_writer.writeAll(proto);
        }
    }
    try hashing_writer.writeAll(&[35]u8{
        // Extension: supported groups, for now just x25519 (00 1D) and secp384r1 (00 0x18)
        0x00, 0x0A, 0x00, 0x06, 0x00, 0x04, 0x00, 0x1D, 0x00, 0x18,
        // Extension: EC point formats => uncompressed point format
        0x00, 0x0B, 0x00, 0x02, 0x01, 0x00,
        // Extension: Signature algorithms
        // RSA/PKCS1/SHA256, RSA/PKCS1/SHA512
        0x00, 0x0D, 0x00, 0x06,
        0x00, 0x04, 0x04, 0x01, 0x06, 0x01,
        // Extension: Renegotiation Info => new connection
        0xFF, 0x01, 0x00, 0x01,
        0x00,
        // Extension: SCT (signed certificate timestamp)
        0x00, 0x12, 0x00, 0x00,
    });

    // Read server hello
    var ciphersuite: u16 = undefined;
    {
        const length = try handshake_record_length(reader);
        if (length < 44)
            return error.ServerMalformedResponse;
        {
            var hs_hdr_and_server_ver: [6]u8 = undefined;
            try hashing_reader.readNoEof(&hs_hdr_and_server_ver);
            if (hs_hdr_and_server_ver[0] != 0x02)
                return error.ServerMalformedResponse;
            if (!mem.eql(u8, hs_hdr_and_server_ver[4..6], "\x03\x03"))
                return error.ServerInvalidVersion;
        }
        try hashing_reader.readNoEof(&server_random);

        // Just skip the session id for now
        const sess_id_len = try hashing_reader.readByte();
        if (sess_id_len != 0)
            try hashing_reader.skipBytes(sess_id_len, .{});

        {
            ciphersuite = try hashing_reader.readIntBig(u16);
            var found = false;
            inline for (options.ciphersuites) |cs| {
                if (ciphersuite == cs.tag) {
                    found = true;
                    // TODO This segfaults stage1
                    // break;
                }
            }
            if (!found)
                return error.ServerInvalidCipherSuite;
        }

        // Compression method
        if ((try hashing_reader.readByte()) != 0x00)
            return error.ServerInvalidCompressionMethod;

        const exts_length = try hashing_reader.readIntBig(u16);
        var ext_byte_idx: usize = 0;
        while (ext_byte_idx < exts_length) {
            var ext_tag: [2]u8 = undefined;
            try hashing_reader.readNoEof(&ext_tag);

            const ext_len = try hashing_reader.readIntBig(u16);
            ext_byte_idx += 4 + ext_len;
            if (ext_tag[0] == 0xFF and ext_tag[1] == 0x01) {
                // Renegotiation info
                const renegotiation_info = try hashing_reader.readByte();
                if (ext_len != 0x01 or renegotiation_info != 0x00)
                    return error.ServerInvalidRenegotiationData;
            } else if (ext_tag[0] == 0x00 and ext_tag[1] == 0x00) {
                // Server name
                if (ext_len != 0)
                    try hashing_reader.skipBytes(ext_len, .{});
            } else if (ext_tag[0] == 0x00 and ext_tag[1] == 0x0B) {
                const format_count = try hashing_reader.readByte();
                var found_uncompressed = false;
                var i: usize = 0;
                while (i < format_count) : (i += 1) {
                    const byte = try hashing_reader.readByte();
                    if (byte == 0x0)
                        found_uncompressed = true;
                }
                if (!found_uncompressed)
                    return error.ServerInvalidECPointCompression;
            } else if (has_alpn and ext_tag[0] == 0x00 and ext_tag[1] == 0x10) {
                const alpn_ext_len = try hashing_reader.readIntBig(u16);
                if (alpn_ext_len != ext_len - 2)
                    return error.ServerMalformedResponse;
                const str_len = try hashing_reader.readByte();
                var buf: [256]u8 = undefined;
                try hashing_reader.readNoEof(buf[0..str_len]);
                const found = for (options.protocols) |proto| {
                    if (mem.eql(u8, proto, buf[0..str_len])) {
                        protocol = proto;
                        break true;
                    }
                } else false;
                if (!found)
                    return error.ServerInvalidProtocol;
                try hashing_reader.skipBytes(alpn_ext_len - str_len - 1, .{});
            } else return error.ServerInvalidExtension;
        }
        if (ext_byte_idx != exts_length)
            return error.ServerMalformedResponse;
    }
    // Read server certificates
    var certificate_public_key: x509.PublicKey = undefined;
    {
        const length = try handshake_record_length(reader);
        {
            var handshake_header: [4]u8 = undefined;
            try hashing_reader.readNoEof(&handshake_header);
            if (handshake_header[0] != 0x0b)
                return error.ServerMalformedResponse;
        }
        const certs_length = try hashing_reader.readIntBig(u24);
        const cert_verifier: CertificateVerifier = options.cert_verifier;
        switch (cert_verifier) {
            .none => certificate_public_key = try extract_cert_public_key(
                options.temp_allocator,
                hashing_reader,
                certs_length,
            ),
            .function => |f| {
                var reader_state = CertificateReaderState(@TypeOf(hashing_reader)){
                    .reader = hashing_reader,
                    .length = certs_length,
                };
                var cert_reader = CertificateReader(@TypeOf(hashing_reader)){ .context = &reader_state };
                certificate_public_key = try f(cert_reader);
                try hashing_reader.skipBytes(reader_state.length - reader_state.idx, .{});
            },
            .default => certificate_public_key = try default_cert_verifier(
                options.temp_allocator,
                hashing_reader,
                certs_length,
                options.trusted_certificates,
                hostname,
            ),
        }
    }
    errdefer certificate_public_key.deinit(options.temp_allocator);
    // Read server ephemeral public key
    var server_public_key_buf: [97]u8 = undefined;
    var curve_id: enum { x25519, secp384r1 } = undefined;
    {
        const length = try handshake_record_length(reader);
        {
            var handshake_header: [4]u8 = undefined;
            try hashing_reader.readNoEof(&handshake_header);
            if (handshake_header[0] != 0x0c)
                return error.ServerMalformedResponse;

            // Only x25519 and secp384r1 supported for now.
            var curve_bytes: [3]u8 = undefined;
            try hashing_reader.readNoEof(&curve_bytes);
            curve_id = if (mem.eql(u8, &curve_bytes, "\x03\x00\x1D"))
                .x25519
            else if (mem.eql(u8, &curve_bytes, "\x03\x00\x18"))
                .secp384r1
            else
                return error.ServerInvalidCurve;
        }

        const pub_key_len = try hashing_reader.readByte();
        if ((curve_id == .x25519 and pub_key_len != 32) or
            (curve_id == .secp384r1 and pub_key_len != 97))
            return error.ServerMalformedResponse;
        try hashing_reader.readNoEof(server_public_key_buf[0..pub_key_len]);
        if (curve_id == .secp384r1 and server_public_key_buf[0] != 0x04)
            return error.ServerMalformedResponse;

        // Signed public key
        const signature_id = try hashing_reader.readIntBig(u16);
        const signature_len = try hashing_reader.readIntBig(u16);

        var hash_buf: [64]u8 = undefined;
        var hash: []const u8 = undefined;
        const signature_algoritm: SignatureAlgorithm = switch (signature_id) {
            // RSA/PKCS1/SHA256
            0x0401 => block: {
                var sha256 = Sha256.init(.{});
                sha256.update(&client_random);
                sha256.update(&server_random);
                switch (curve_id) {
                    .x25519 => sha256.update("\x03\x00\x1D\x20"),
                    .secp384r1 => sha256.update("\x03\x00\x18\x20"),
                }
                sha256.update(server_public_key_buf[0..pub_key_len]);
                sha256.final(hash_buf[0..32]);
                hash = hash_buf[0..32];
                break :block .rsa_sha256;
            },
            // RSA/PKCS1/SHA512
            0x0601 => block: {
                var sha512 = Sha512.init(.{});
                sha512.update(&client_random);
                sha512.update(&server_random);
                switch (curve_id) {
                    .x25519 => sha512.update("\x03\x00\x1D"),
                    .secp384r1 => sha512.update("\x03\x00\x18"),
                }
                sha512.update(&[1]u8{pub_key_len});
                sha512.update(server_public_key_buf[0..pub_key_len]);
                sha512.final(hash_buf[0..64]);
                hash = hash_buf[0..64];
                break :block .rsa_sha512;
            },
            else => return error.ServerInvalidSignatureAlgorithm,
        };
        const signature_bytes = try options.temp_allocator.alloc(u8, signature_len);
        defer options.temp_allocator.free(signature_bytes);
        try hashing_reader.readNoEof(signature_bytes);

        if (!try verify_signature(
            options.temp_allocator,
            signature_algoritm,
            .{ .data = signature_bytes, .bit_len = signature_len * 8 },
            hash,
            certificate_public_key,
        ))
            return error.ServerInvalidSignature;

        certificate_public_key.deinit(options.temp_allocator);
        certificate_public_key = x509.PublicKey{ .ec = .{ .id = undefined, .curve_point = &[0]u8{} } };
    }
    // Read server hello done
    {
        const length = try handshake_record_length(reader);
        const is_bytes = try hashing_reader.isBytes("\x0e\x00\x00\x00");
        if (length != 4 or !is_bytes)
            return error.ServerMalformedResponse;
    }

    // Generate keys for the session
    const client_key_pair: extern union {
        x25519: std.crypto.dh.X25519.KeyPair,
        secp384r1: crypto.ecc.KeyPair(crypto.ecc.SECP384R1),
    } = switch (curve_id) {
        .x25519 => while (true) {
            var seed: [32]u8 = undefined;
            rand.bytes(&seed);
            const tmp = std.crypto.dh.X25519.KeyPair.create(seed) catch continue;
            break .{ .x25519 = tmp };
        } else unreachable,
        .secp384r1 => blk: {
            var seed: [48]u8 = undefined;
            rand.bytes(&seed);
            break :blk .{ .secp384r1 = crypto.ecc.make_key_pair(crypto.ecc.SECP384R1, seed) };
        },
    };

    // Client key exchange
    switch (curve_id) {
        .x25519 => {
            try writer.writeAll(&[5]u8{ 0x16, 0x03, 0x03, 0x00, 0x25 });
            try hashing_writer.writeAll(&[5]u8{ 0x10, 0x00, 0x00, 0x21, 0x20 });
            try hashing_writer.writeAll(&client_key_pair.x25519.public_key);
        },
        .secp384r1 => {
            try writer.writeAll(&[5]u8{ 0x16, 0x03, 0x03, 0x00, 0x66 });
            try hashing_writer.writeAll(&[6]u8{ 0x10, 0x00, 0x00, 0x62, 0x61, 0x04 });
            try hashing_writer.writeAll(&client_key_pair.secp384r1.public_key);
        },
    }
    // Client encryption keys calculation for ECDHE_RSA cipher suites with SHA256 hash
    var master_secret: [48]u8 = undefined;
    var key_data: ciphers.KeyData(options.ciphersuites) = undefined;
    {
        var pre_master_secret_buf: [96]u8 = undefined;
        const pre_master_secret = switch (curve_id) {
            .x25519 => blk: {
                pre_master_secret_buf[0..32].* = std.crypto.dh.X25519.scalarmult(
                    client_key_pair.x25519.secret_key,
                    server_public_key_buf[0..32].*,
                ) catch
                    return error.PreMasterGenerationFailed;
                break :blk pre_master_secret_buf[0..32];
            },
            .secp384r1 => blk: {
                pre_master_secret_buf = crypto.ecc.scalarmult(
                    crypto.ecc.SECP384R1,
                    server_public_key_buf[1..].*,
                    &client_key_pair.secp384r1.secret_key,
                ) catch
                    return error.PreMasterGenerationFailed;
                break :blk pre_master_secret_buf[0..48];
            },
        };

        var seed: [77]u8 = undefined;
        seed[0..13].* = "master secret".*;
        seed[13..45].* = client_random;
        seed[45..77].* = server_random;

        var a1: [32 + seed.len]u8 = undefined;
        Hmac256.create(a1[0..32], &seed, pre_master_secret);
        var a2: [32 + seed.len]u8 = undefined;
        Hmac256.create(a2[0..32], a1[0..32], pre_master_secret);

        a1[32..].* = seed;
        a2[32..].* = seed;

        var p1: [32]u8 = undefined;
        Hmac256.create(&p1, &a1, pre_master_secret);
        var p2: [32]u8 = undefined;
        Hmac256.create(&p2, &a2, pre_master_secret);

        master_secret[0..32].* = p1;
        master_secret[32..48].* = p2[0..16].*;

        // Key expansion
        seed[0..13].* = "key expansion".*;
        seed[13..45].* = server_random;
        seed[45..77].* = client_random;
        a1[32..].* = seed;
        a2[32..].* = seed;

        const KeyExpansionState = struct {
            seed: *const [77]u8,
            a1: *[32 + seed.len]u8,
            a2: *[32 + seed.len]u8,
            master_secret: *const [48]u8,
        };

        const next_32_bytes = struct {
            inline fn f(
                state: *KeyExpansionState,
                comptime chunk_idx: comptime_int,
                chunk: *[32]u8,
            ) void {
                if (chunk_idx == 0) {
                    Hmac256.create(state.a1[0..32], state.seed, state.master_secret);
                    Hmac256.create(chunk, state.a1, state.master_secret);
                } else if (chunk_idx % 2 == 1) {
                    Hmac256.create(state.a2[0..32], state.a1[0..32], state.master_secret);
                    Hmac256.create(chunk, state.a2, state.master_secret);
                } else {
                    Hmac256.create(state.a1[0..32], state.a2[0..32], state.master_secret);
                    Hmac256.create(chunk, state.a1, state.master_secret);
                }
            }
        }.f;
        var state = KeyExpansionState{
            .seed = &seed,
            .a1 = &a1,
            .a2 = &a2,
            .master_secret = &master_secret,
        };

        key_data = ciphers.key_expansion(options.ciphersuites, ciphersuite, &state, next_32_bytes);
    }

    // Client change cipher spec and client handshake finished
    {
        try writer.writeAll(&[6]u8{
            // Client change cipher spec
            0x14, 0x03, 0x03,
            0x00, 0x01, 0x01,
        });
        // The message we need to encrypt is the following:
        // 0x14 0x00 0x00 0x0c
        // <12 bytes of verify_data>
        // seed = "client finished" + SHA256(all handshake messages)
        // a1 = HMAC-SHA256(key=MasterSecret, data=seed)
        // p1 = HMAC-SHA256(key=MasterSecret, data=a1 + seed)
        // verify_data = p1[0..12]
        var verify_message: [16]u8 = undefined;
        verify_message[0..4].* = "\x14\x00\x00\x0C".*;
        {
            var seed: [47]u8 = undefined;
            seed[0..15].* = "client finished".*;
            // We still need to update the hash one time, so we copy
            // to get the current digest here.
            var hash_copy = handshake_record_hash;
            hash_copy.final(seed[15..47]);

            var a1: [32 + seed.len]u8 = undefined;
            Hmac256.create(a1[0..32], &seed, &master_secret);
            a1[32..].* = seed;
            var p1: [32]u8 = undefined;
            Hmac256.create(&p1, &a1, &master_secret);
            verify_message[4..16].* = p1[0..12].*;
        }
        handshake_record_hash.update(&verify_message);

        inline for (options.ciphersuites) |cs| {
            if (cs.tag == ciphersuite) {
                try cs.raw_write(
                    256,
                    rand,
                    &key_data,
                    writer,
                    [3]u8{ 0x16, 0x03, 0x03 },
                    0,
                    &verify_message,
                );
            }
        }
    }

    // Server change cipher spec
    {
        const length = try record_length(0x14, reader);
        const next_byte = try reader.readByte();
        if (length != 1 or next_byte != 0x01)
            return error.ServerMalformedResponse;
    }
    // Server handshake finished
    {
        const length = try handshake_record_length(reader);

        var verify_message: [16]u8 = undefined;
        verify_message[0..4].* = "\x14\x00\x00\x0C".*;
        {
            var seed: [47]u8 = undefined;
            seed[0..15].* = "server finished".*;
            handshake_record_hash.final(seed[15..47]);
            var a1: [32 + seed.len]u8 = undefined;
            Hmac256.create(a1[0..32], &seed, &master_secret);
            a1[32..].* = seed;
            var p1: [32]u8 = undefined;
            Hmac256.create(&p1, &a1, &master_secret);
            verify_message[4..16].* = p1[0..12].*;
        }

        inline for (options.ciphersuites) |cs| {
            if (cs.tag == ciphersuite) {
                if (!try cs.check_verify_message(&key_data, length, reader, verify_message))
                    return error.ServerInvalidVerifyData;
            }
        }
    }

    return Client(@TypeOf(reader), @TypeOf(writer), options.ciphersuites, has_alpn){
        .ciphersuite = ciphersuite,
        .key_data = key_data,
        .state = ciphers.client_state_default(options.ciphersuites, ciphersuite),
        .rand = rand,
        .parent_reader = reader,
        .parent_writer = writer,
        .protocol = protocol,
    };
}

pub fn Client(
    comptime _Reader: type,
    comptime _Writer: type,
    comptime _ciphersuites: anytype,
    comptime has_protocol: bool,
) type {
    return struct {
        const ReaderError = _Reader.Error || ServerAlert || error{ ServerMalformedResponse, ServerInvalidVersion };
        pub const Reader = std.io.Reader(*@This(), ReaderError, read);
        pub const Writer = std.io.Writer(*@This(), _Writer.Error, write);

        ciphersuite: u16,
        client_seq: u64 = 1,
        server_seq: u64 = 1,
        key_data: ciphers.KeyData(_ciphersuites),
        state: ciphers.ClientState(_ciphersuites),
        rand: *std.rand.Random,

        parent_reader: _Reader,
        parent_writer: _Writer,

        protocol: if (has_protocol) []const u8 else void,

        pub fn reader(self: *@This()) Reader {
            return .{ .context = self };
        }

        pub fn writer(self: *@This()) Writer {
            return .{ .context = self };
        }

        pub fn read(self: *@This(), buffer: []u8) ReaderError!usize {
            inline for (_ciphersuites) |cs| {
                if (self.ciphersuite == cs.tag) {
                    // @TODO Make this buffer size configurable
                    return try cs.read(
                        1024,
                        &@field(self.state, cs.name),
                        &self.key_data,
                        self.parent_reader,
                        &self.server_seq,
                        buffer,
                    );
                }
            }
            unreachable;
        }

        pub fn write(self: *@This(), buffer: []const u8) _Writer.Error!usize {
            if (buffer.len == 0) return 0;

            inline for (_ciphersuites) |cs| {
                if (self.ciphersuite == cs.tag) {
                    // @TODO Make this buffer size configurable
                    const curr_bytes = @truncate(u16, std.math.min(buffer.len, 1024));
                    try cs.raw_write(
                        1024,
                        self.rand,
                        &self.key_data,
                        self.parent_writer,
                        [3]u8{ 0x17, 0x03, 0x03 },
                        self.client_seq,
                        buffer[0..curr_bytes],
                    );
                    self.client_seq += 1;
                    return curr_bytes;
                }
            }
            unreachable;
        }

        pub fn close_notify(self: *@This()) !void {
            inline for (_ciphersuites) |cs| {
                if (self.ciphersuite == cs.tag) {
                    try cs.raw_write(
                        1024,
                        self.rand,
                        &self.key_data,
                        self.parent_writer,
                        [3]u8{ 0x15, 0x03, 0x03 },
                        self.client_seq,
                        "\x01\x00",
                    );
                    self.client_seq += 1;
                    return;
                }
            }
            unreachable;
        }
    };
}

test "HTTPS request on wikipedia main page" {
    const sock = try std.net.tcpConnectToHost(std.testing.allocator, "en.wikipedia.org", 443);
    defer sock.close();

    var fbs = std.io.fixedBufferStream(@embedFile("../test/DigiCertHighAssuranceEVRootCA.crt.pem"));
    var trusted_chain = try x509.TrustAnchorChain.from_pem(std.testing.allocator, fbs.reader());
    defer trusted_chain.deinit();

    // @TODO Remove this once std.crypto.rand works in .evented mode
    var rand = blk: {
        var seed: [std.rand.DefaultCsprng.secret_seed_length]u8 = undefined;
        try std.os.getrandom(&seed);
        break :blk &std.rand.DefaultCsprng.init(seed).random;
    };

    var client = try client_connect(.{
        .rand = rand,
        .reader = sock.reader(),
        .writer = sock.writer(),
        .cert_verifier = .default,
        .temp_allocator = std.testing.allocator,
        .trusted_certificates = trusted_chain.data.items,
        .ciphersuites = ciphersuites.all,
        .protocols = &[_][]const u8{"http/1.1"},
    }, "en.wikipedia.org");
    defer client.close_notify() catch {};

    std.testing.expectEqualStrings("http/1.1", client.protocol);
    try client.writer().writeAll("GET /wiki/Main_Page HTTP/1.1\r\nHost: en.wikipedia.org\r\nAccept: */*\r\n\r\n");

    {
        const header = try client.reader().readUntilDelimiterAlloc(std.testing.allocator, '\n', std.math.maxInt(usize));
        std.testing.expectEqualStrings("HTTP/1.1 200 OK", mem.trim(u8, header, &std.ascii.spaces));
        std.testing.allocator.free(header);
    }

    // Skip the rest of the headers expect for Content-Length
    var content_length: ?usize = null;
    hdr_loop: while (true) {
        const header = try client.reader().readUntilDelimiterAlloc(std.testing.allocator, '\n', std.math.maxInt(usize));
        defer std.testing.allocator.free(header);

        const hdr_contents = mem.trim(u8, header, &std.ascii.spaces);
        if (hdr_contents.len == 0) {
            break :hdr_loop;
        }

        if (mem.startsWith(u8, hdr_contents, "Content-Length: ")) {
            content_length = try std.fmt.parseUnsigned(usize, hdr_contents[16..], 10);
        }
    }
    std.testing.expect(content_length != null);
    const html_contents = try std.testing.allocator.alloc(u8, content_length.?);
    defer std.testing.allocator.free(html_contents);

    try client.reader().readNoEof(html_contents);
}

test "HTTPS request on twitch oath2 endpoint" {
    const sock = try std.net.tcpConnectToHost(std.testing.allocator, "id.twitch.tv", 443);
    defer sock.close();

    // @TODO Remove this once std.crypto.rand works in .evented mode
    var rand = blk: {
        var seed: [std.rand.DefaultCsprng.secret_seed_length]u8 = undefined;
        try std.os.getrandom(&seed);
        break :blk &std.rand.DefaultCsprng.init(seed).random;
    };

    var client = try client_connect(.{
        .rand = rand,
        .temp_allocator = std.testing.allocator,
        .reader = sock.reader(),
        .writer = sock.writer(),
        .cert_verifier = .none,
        .ciphersuites = ciphersuites.all,
        .protocols = &[_][]const u8{"http/1.1"},
    }, "id.twitch.tv");
    defer client.close_notify() catch {};

    try client.writer().writeAll("GET /oauth2/validate HTTP/1.1\r\nHost: id.twitch.tv\r\nAccept: */*\r\n\r\n");
    var content_length: ?usize = null;
    hdr_loop: while (true) {
        const header = try client.reader().readUntilDelimiterAlloc(std.testing.allocator, '\n', std.math.maxInt(usize));
        defer std.testing.allocator.free(header);

        const hdr_contents = mem.trim(u8, header, &std.ascii.spaces);
        if (hdr_contents.len == 0) {
            break :hdr_loop;
        }

        if (mem.startsWith(u8, hdr_contents, "Content-Length: ")) {
            content_length = try std.fmt.parseUnsigned(usize, hdr_contents[16..], 10);
        }
    }
    std.testing.expect(content_length != null);
    const html_contents = try std.testing.allocator.alloc(u8, content_length.?);
    defer std.testing.allocator.free(html_contents);

    try client.reader().readNoEof(html_contents);
}
