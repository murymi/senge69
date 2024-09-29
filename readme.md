## Simple cryptographic message exchange with chacha20 stream cypher with diffie helman key exchange algorithm.

### ChaCha20
ChaCha20 is a stream cipher developed by Daniel J. Bernstein. Its original design expands a
256-bit key into 2^64 randomly accessible streams, each containing 2^64 randomly
accessible 64-byte (512 bits) blocks. It is a variant of Salsa20 with better diffusion.
ChaCha20 doesn’t require any lookup tables and avoids the possibility of timing attacks.
Internally, ChaCha20 works like a block cipher used in counter mode. It includes an internal
block counter to avoid incrementing the nonce after each block.
Two variants of the ChaCha20 cipher are implemented in libsodium:
The original ChaCha20 cipher with a 64-bit nonce and a 64-bit counter, allowing a
practically unlimited amount of data to be encrypted with the same (key, nonce) pair.
The IETF variant increases the nonce size to 96 bits, but reduces the counter size down
to 32 bits, allowing only up to 256 GB of data to be safely encrypted with a given
(key, nonce) pair.

### dh X25519
Using the key exchange API, two parties can securely compute a set of shared keys using
their peer’s public key and their own secret key.
This API was introduced in libsodium 1.0.12.
Sodium provides an API to multiply a point on the Curve25519 curve.
This can be used as a building block to construct key exchange mechanisms, or more
generally to compute a public key from a secret key.

### example
```zig
    const address = try net.Address.parseIp4("127.0.0.1", 3000);
    var server = try address.listen(.{.reuse_address = true, .reuse_port = true});
    
    while (true) {
        const connection = try server.accept();
        var proto = try protocal.Proto.init(connection.stream);
        try proto.write("zenge");
    }

````