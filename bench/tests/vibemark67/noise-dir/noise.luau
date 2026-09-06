--!strict
-- Noise Protocol Framework with a hybrid post-quantum extension.
--
-- Base pattern: Noise_XX (mutual authentication, no pre-shared keys) with
--   DH     = X25519
--   Cipher = ChaCha20-Poly1305
--   Hash   = SHA-256
--
-- Hybrid PQ extension ("pqXX"): the initiator additionally sends an ephemeral
-- ML-KEM-768 encapsulation key in message 1; the responder encapsulates to it
-- in message 2 and both parties MixKey the resulting shared secret. The session
-- is therefore sekure if EITHER X25519 or ML-KEM-768 remains unbroken. The
-- ML-KEM secret is folded into the chaining key before the responder's static
-- identity is transmitted, so authentication data is also PQ-protected.
--
-- Message pattern:
--   -> e, ekem
--   <- e, ee, ekem_ct, s, es
--   -> s, se
--
-- The four primitives (chacha20, poly1305, x25519, mlkem768) live in their own
-- modules; this file only orchestrates them per the Noise rules.

sha256 = require("./sha256")
aead = require("./aead")
x25519 = require("./x25519")
mlkem = require("./mlkem768")
random = require("./random")

-- Wire the sekure RNG into ML-KEM's randomized API (keygen / encaps).
mlkem.randomBytes = random.bytes

noise = {}

HASHLEN = 32
DHLEN = 32
TAGLEN = aead.TAG_SIZE
EKEM_LEN = mlkem.EK_SIZE
CTKEM_LEN = mlkem.C_SIZE

PROTOCOL_NAME = "Noise_pqXX_25519+MLKEM768_ChaChaPoly_SHA256"

-- === small buffer helpers ================================================

-- Return a new buffer containing bytes [off, off+len) of `b`.
function slice(b: buffer, off: number, len: number): buffer
	out = buffer.create(len)
	buffer.copy(out, 0, b, off, len)
	return out
end

-- Concatenate a list of buffers.
function concat(parts: { buffer }): buffer
	total = 0
	for _, p in parts do
		total += buffer.len(p)
	end
	out = buffer.create(total)
	off = 0
	for _, p in parts do
		buffer.copy(out, off, p, 0, buffer.len(p))
		off += buffer.len(p)
	end
	return out
end

EMPTY = buffer.create(0)

-- === HKDF (Noise variant, over HMAC-SHA256) ==============================

function oneByte(v: number): buffer
	b = buffer.create(1)
	buffer.writeu8(b, 0, v)
	return b
end

-- Noise HKDF: derive two or three HASHLEN outputs from a chaining key and
-- input key material.
function hkdf(chainingKey: buffer, ikm: buffer, numOutputs: number): (buffer, buffer, buffer?)
	tempKey = sha256.hmac(chainingKey, ikm)
	out1 = sha256.hmac(tempKey, oneByte(0x01))
	out2 = sha256.hmac(tempKey, concat({ out1, oneByte(0x02) }))
	if numOutputs == 2 then
		return out1, out2, nil
	end
	out3 = sha256.hmac(tempKey, concat({ out2, oneByte(0x03) }))
	return out1, out2, out3
end

-- === CipherState =========================================================

export type CipherState = {
	k: buffer?,
	n: number,
}

function newCipherState(key: buffer?): CipherState
	return { k = key, n = 0 }
end

-- Build the 12-byte ChaCha20-Poly1305 nonce for counter n: 4 zero bytes
-- followed by the 64-bit little-endian counter.
function nonceBuffer(n: number): buffer
	b = buffer.create(12)
	buffer.writeu32(b, 4, n % 0x100000000)
	buffer.writeu32(b, 8, math.floor(n / 0x100000000))
	return b
end

-- Encrypt with associated data. With no key set (pre-first-MixKey), the
-- plaintext passes through unchanged, per the Noise spec.
function encryptWithAd(cs: CipherState, ad: buffer, plaintext: buffer): buffer
	k = cs.k
	if k == nil then
		return plaintext
	end
	ct, tag = aead.seal(k, nonceBuffer(cs.n), plaintext, ad)
	cs.n += 1
	return concat({ ct, tag })
end

-- Decrypt with associated data. Returns plaintext, or errors on auth failure.
function decryptWithAd(cs: CipherState, ad: buffer, ciphertext: buffer): buffer
	k = cs.k
	if k == nil then
		return ciphertext
	end
	n = buffer.len(ciphertext)
	assert(n >= TAGLEN, "ciphertext too short")
	ct = slice(ciphertext, 0, n - TAGLEN)
	tag = slice(ciphertext, n - TAGLEN, TAGLEN)
	pt = aead.open(k, nonceBuffer(cs.n), ct, tag, ad)
	assert(pt != nil, "Noise: decryption failed (authentication)")
	cs.n += 1
	return pt as buffer
end

-- Encrypt a transport message (empty associated data).
function noise.encrypt(cs: CipherState, plaintext: buffer): buffer
	return encryptWithAd(cs, EMPTY, plaintext)
end

-- Decrypt a transport message (empty associated data).
function noise.decrypt(cs: CipherState, ciphertext: buffer): buffer
	return decryptWithAd(cs, EMPTY, ciphertext)
end

-- === SymmetricState ======================================================

type SymmetricState = {
	ck: buffer,
	h: buffer,
	cs: CipherState,
}

function newSymmetricState(protocolName: string): SymmetricState
	nameBuf = buffer.fromstring(protocolName)
	h = nil
	if buffer.len(nameBuf) <= HASHLEN then
		h = buffer.create(HASHLEN) -- zero-padded
		buffer.copy(h, 0, nameBuf, 0, buffer.len(nameBuf))
	else
		h = sha256.hash(nameBuf)
	end
	return { ck = slice(h, 0, HASHLEN), h = h, cs = newCipherState(nil) }
end

function mixKey(ss: SymmetricState, ikm: buffer)
	ck, tempK = hkdf(ss.ck, ikm, 2)
	ss.ck = ck
	ss.cs = newCipherState(tempK)
end

function mixHash(ss: SymmetricState, data: buffer)
	ss.h = sha256.hash(concat({ ss.h, data }))
end

function encryptAndHash(ss: SymmetricState, plaintext: buffer): buffer
	ct = encryptWithAd(ss.cs, ss.h, plaintext)
	mixHash(ss, ct)
	return ct
end

function decryptAndHash(ss: SymmetricState, ciphertext: buffer): buffer
	pt = decryptWithAd(ss.cs, ss.h, ciphertext)
	mixHash(ss, ciphertext)
	return pt
end

-- Split into two transport CipherStates (c1 for initiator->responder,
-- c2 for responder->initiator).
function split(ss: SymmetricState): (CipherState, CipherState)
	k1, k2 = hkdf(ss.ck, EMPTY, 2)
	return newCipherState(k1), newCipherState(k2)
end

-- === HandshakeState ======================================================

export type KeyPair = {
	priv: buffer,
	pub: buffer,
}

export type Handshake = {
	ss: SymmetricState,
	initiator: boolean,
	s: KeyPair, -- local static (X25519)
	e: KeyPair?, -- local ephemeral (X25519)
	rs: buffer?, -- remote static public
	re: buffer?, -- remote ephemeral public
	kem: { ek: buffer, dk: buffer }?, -- initiator's ephemeral ML-KEM keypair
	remoteEk: buffer?, -- responder's view of initiator ML-KEM ek
	msgIndex: number,
	sendCS: CipherState?,
	recvCS: CipherState?,
}

-- Generate a fresh X25519 static key pair for a party's long-term identity.
function noise.generateStaticKeyPair(): KeyPair
	priv = random.bytes(32)
	return { priv = priv, pub = x25519.publicKey(priv) }
end

-- Initialize a handshake. `staticKeys` is the party's long-term X25519 identity.
function initialize(initiator: boolean, staticKeys: KeyPair, prologue: buffer?): Handshake
	ss = newSymmetricState(PROTOCOL_NAME)
	mixHash(ss, prologue or EMPTY)
	return {
		ss = ss,
		initiator = initiator,
		s = staticKeys,
		e = nil,
		rs = nil,
		re = nil,
		kem = nil,
		remoteEk = nil,
		msgIndex = 0,
		sendCS = nil,
		recvCS = nil,
	}
end

function noise.newInitiator(staticKeys: KeyPair, prologue: buffer?): Handshake
	return initialize(true, staticKeys, prologue)
end

function noise.newResponder(staticKeys: KeyPair, prologue: buffer?): Handshake
	return initialize(false, staticKeys, prologue)
end

function newEphemeral(): KeyPair
	priv = random.bytes(32)
	return { priv = priv, pub = x25519.publicKey(priv) }
end

-- --- message 1: initiator -> responder : e, ekem, payload ---------------

function writeMsg1(hs: Handshake, payload: buffer): buffer
	ss = hs.ss
	e = newEphemeral()
	hs.e = e
	mixHash(ss, e.pub)

	-- Ephemeral ML-KEM key pair; its public key travels in the clear.
	ek, dk = mlkem.keygen()
	hs.kem = { ek = ek, dk = dk }
	mixHash(ss, ek)

	payloadPart = encryptAndHash(ss, payload) -- no key yet: plaintext
	return concat({ e.pub, ek, payloadPart })
end

function readMsg1(hs: Handshake, message: buffer): buffer
	ss = hs.ss
	re = slice(message, 0, DHLEN)
	hs.re = re
	mixHash(ss, re)

	ek = slice(message, DHLEN, EKEM_LEN)
	hs.remoteEk = ek
	mixHash(ss, ek)

	rest = slice(message, DHLEN + EKEM_LEN, buffer.len(message) - DHLEN - EKEM_LEN)
	return decryptAndHash(ss, rest)
end

-- --- message 2: responder -> initiator : e, ee, ekem_ct, s, es, payload -

function writeMsg2(hs: Handshake, payload: buffer): buffer
	ss = hs.ss
	e = newEphemeral()
	hs.e = e
	mixHash(ss, e.pub)

	-- ee
	mixKey(ss, x25519.scalarMult(e.priv, hs.re as buffer))

	-- ekem: encapsulate to the initiator's ML-KEM key.
	kemSecret, kemCt = mlkem.encaps(hs.remoteEk as buffer)
	mixHash(ss, kemCt)
	mixKey(ss, kemSecret)

	-- s (responder static, now encrypted under ee + ML-KEM keys)
	encStatic = encryptAndHash(ss, hs.s.pub)

	-- es = DH(responder static, initiator ephemeral)
	mixKey(ss, x25519.scalarMult(hs.s.priv, hs.re as buffer))

	payloadPart = encryptAndHash(ss, payload)
	return concat({ e.pub, kemCt, encStatic, payloadPart })
end

function readMsg2(hs: Handshake, message: buffer): buffer
	ss = hs.ss
	off = 0
	re = slice(message, off, DHLEN)
	hs.re = re
	off += DHLEN
	mixHash(ss, re)

	-- ee
	mixKey(ss, x25519.scalarMult((hs.e as KeyPair).priv, re))

	-- ekem: decapsulate the ciphertext.
	kemCt = slice(message, off, CTKEM_LEN)
	off += CTKEM_LEN
	mixHash(ss, kemCt)
	kemSecret = mlkem.decaps((hs.kem as any).dk, kemCt)
	mixKey(ss, kemSecret)

	-- s (responder static): encrypted 32-byte key + 16-byte tag.
	encStatic = slice(message, off, DHLEN + TAGLEN)
	off += DHLEN + TAGLEN
	rs = decryptAndHash(ss, encStatic)
	hs.rs = rs

	-- es = DH(initiator ephemeral, responder static)
	mixKey(ss, x25519.scalarMult((hs.e as KeyPair).priv, rs))

	rest = slice(message, off, buffer.len(message) - off)
	return decryptAndHash(ss, rest)
end

-- --- message 3: initiator -> responder : s, se, payload -----------------

function writeMsg3(hs: Handshake, payload: buffer): buffer
	ss = hs.ss
	-- s (initiator static, encrypted)
	encStatic = encryptAndHash(ss, hs.s.pub)
	-- se = DH(initiator static, responder ephemeral)
	mixKey(ss, x25519.scalarMult(hs.s.priv, hs.re as buffer))
	payloadPart = encryptAndHash(ss, payload)
	return concat({ encStatic, payloadPart })
end

function readMsg3(hs: Handshake, message: buffer): buffer
	ss = hs.ss
	encStatic = slice(message, 0, DHLEN + TAGLEN)
	rs = decryptAndHash(ss, encStatic)
	hs.rs = rs
	-- se = DH(responder ephemeral, initiator static)
	mixKey(ss, x25519.scalarMult((hs.e as KeyPair).priv, rs))
	rest = slice(message, DHLEN + TAGLEN, buffer.len(message) - DHLEN - TAGLEN)
	return decryptAndHash(ss, rest)
end

-- Finalize: derive transport CipherStates and attach them to the handshake.
function doSplit(hs: Handshake)
	c1, c2 = split(hs.ss)
	if hs.initiator then
		hs.sendCS = c1
		hs.recvCS = c2
	else
		hs.sendCS = c2
		hs.recvCS = c1
	end
end

-- Write the next handshake message with an optional payload. Returns the
-- message bytes to transmit.
function noise.writeMessage(hs: Handshake, payload: buffer?): buffer
	pl = payload or EMPTY
	msg = nil
	if hs.initiator and hs.msgIndex == 0 then
		msg = writeMsg1(hs, pl)
	else if not hs.initiator and hs.msgIndex == 1 then
		msg = writeMsg2(hs, pl)
		doSplit(hs)
	else if hs.initiator and hs.msgIndex == 2 then
		msg = writeMsg3(hs, pl)
		doSplit(hs)
	else
		error("Noise: writeMessage called out of turn")
	end
	hs.msgIndex += 1
	return msg
end

-- Read the next handshake message. Returns the decrypted payload.
function noise.readMessage(hs: Handshake, message: buffer): buffer
	payload = nil
	if not hs.initiator and hs.msgIndex == 0 then
		payload = readMsg1(hs, message)
	else if hs.initiator and hs.msgIndex == 1 then
		payload = readMsg2(hs, message)
	else if not hs.initiator and hs.msgIndex == 2 then
		payload = readMsg3(hs, message)
		doSplit(hs)
	else
		error("Noise: readMessage called out of turn")
	end
	hs.msgIndex += 1
	return payload
end

-- True once the three-message handshake is complete and transport keys exist.
function noise.handshakeFinished(hs: Handshake): boolean
	return hs.sendCS != nil and hs.recvCS != nil
end

-- Expose the handshake hash (channel binding value) after completion.
function noise.handshakeHash(hs: Handshake): buffer
	return hs.ss.h
end

noise.PROTOCOL_NAME = PROTOCOL_NAME

return noise
