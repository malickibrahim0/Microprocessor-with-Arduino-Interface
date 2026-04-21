"""
ISA definition for the 32-bit pipelined RISC SoC
(Microprocessor-with-Arduino-Interface).

Instruction format (32 bits), LSB-contiguous:

    [31:24] rb_instant  (8-bit immediate)
    [23:17] ra_instant  (7-bit immediate)
    [16:13] read_rb     (source B register, 4-bit)
    [12:9]  read_ra     (source A register, 4-bit)
    [8:5]   write_rd    (destination register, 4-bit)
    [4]     prefix      (0 = Page 1, 1 = Page 2)
    [3:0]   opcode      (4-bit opcode within page)

Key design notes:
- Prefix is a per-instruction bit, not a separate opcode.
  No pipeline hazard between PREFIX and extended instruction.
- For JMP/CMPJ/JAL/JALR targets, the target is packed into
  {rb_instant, ra_instant} -> 15-bit target. Encoder picks
  7-bit or 15-bit depending on target value.
- Register writeback is disabled for control/output ops:
    Page 1: CMPJ (0xD), JMP (0xE), HLT (0xF)
    Page 2: JALR (0x3), CORDIC_TRIG (0x5), MMIO_WR (0xB), RETI (0xF)
"""

# Mnemonic -> { op, pfx, operands }
# operands: list of tokens describing positional args:
#   rd   = destination register
#   ra   = source A register
#   rb   = source B register
#   imm7 = 7-bit immediate (fits in ra_instant)
#   imm8 = 8-bit immediate (fits in rb_instant)
#   imm5 = shift amount (0..31), goes in rb_instant[4:0]
#   tgt  = branch/jump target label or literal (0..32767)
#
# Design choice per instruction:
#   LDI   rd, imm16       -> imm high 8 bits in rb_instant, low 7 bits in
#                            ra_instant. But ALU uses RA_Instant[15:0] and
#                            RB_Instant[15:0] concatenated. Since both are
#                            zero-extended from narrower fields, effective
#                            immediate is limited. See encode_mnemonic below.
#   ADI   rd, ra, imm8    -> imm8 in rb_instant
#   SUI   rd, ra, imm8    -> imm8 in rb_instant (Page 2)
#   SHL/SHR/ROL/ROR rd, ra, imm5 -> shift count in rb_instant[4:0]
#   CMPJ  ra, rb, tgt     -> tgt packed into ra_instant (7b) + rb_instant (8b)
#   JMP   tgt             -> tgt packed into ra_instant (7b) + rb_instant (8b)
#   JAL   rd, tgt         -> target + link register
#   JALR  ra, rd          -> jump to register value + link

ISA = {
    # ============================================================
    # Page 1 (prefix = 0) - base arithmetic / logic / control
    # ============================================================
    'NOP':  {'op': 0x0, 'pfx': 0, 'operands': []},
    'LDI':  {'op': 0x1, 'pfx': 0, 'operands': ['rd', 'imm']},
    'ADD':  {'op': 0x2, 'pfx': 0, 'operands': ['rd', 'ra', 'rb']},
    'SUB':  {'op': 0x3, 'pfx': 0, 'operands': ['rd', 'ra', 'rb']},
    'ADI':  {'op': 0x4, 'pfx': 0, 'operands': ['rd', 'ra', 'imm8']},
    'MUL':  {'op': 0x5, 'pfx': 0, 'operands': ['rd', 'ra', 'rb']},
    'DIV':  {'op': 0x6, 'pfx': 0, 'operands': ['rd', 'ra', 'rb']},  # stubbed in ALU
    'DEC':  {'op': 0x7, 'pfx': 0, 'operands': ['rd', 'rb']},
    'INC':  {'op': 0x8, 'pfx': 0, 'operands': ['rd', 'rb']},
    'NOR':  {'op': 0x9, 'pfx': 0, 'operands': ['rd', 'ra', 'rb']},
    'NAND': {'op': 0xA, 'pfx': 0, 'operands': ['rd', 'ra', 'rb']},
    'XOR':  {'op': 0xB, 'pfx': 0, 'operands': ['rd', 'ra', 'rb']},
    'COMP': {'op': 0xC, 'pfx': 0, 'operands': ['rd', 'rb']},
    'CMPJ': {'op': 0xD, 'pfx': 0, 'operands': ['ra', 'rb', 'tgt']},
    'JMP':  {'op': 0xE, 'pfx': 0, 'operands': ['tgt']},
    'HLT':  {'op': 0xF, 'pfx': 0, 'operands': []},

    # ============================================================
    # Page 2 (prefix = 1) - extended ops
    # ============================================================
    'MOV':          {'op': 0x0, 'pfx': 1, 'operands': ['rd', 'rb']},
    'LOAD':         {'op': 0x1, 'pfx': 1, 'operands': ['rd', 'ra']},
    'JAL':          {'op': 0x2, 'pfx': 1, 'operands': ['rd', 'tgt']},
    'JALR':         {'op': 0x3, 'pfx': 1, 'operands': ['rd', 'ra']},
    'LOAD_ALT':     {'op': 0x4, 'pfx': 1, 'operands': ['rd', 'ra']},
    'CORDIC_TRIG':  {'op': 0x5, 'pfx': 1, 'operands': ['ra', 'rb']},
    'SHL':          {'op': 0x6, 'pfx': 1, 'operands': ['rd', 'ra', 'imm5']},
    'SHR':          {'op': 0x7, 'pfx': 1, 'operands': ['rd', 'ra', 'imm5']},
    'AND':          {'op': 0x8, 'pfx': 1, 'operands': ['rd', 'ra', 'rb']},
    'OR':           {'op': 0x9, 'pfx': 1, 'operands': ['rd', 'ra', 'rb']},
    'MMIO_RD':      {'op': 0xA, 'pfx': 1, 'operands': ['rd', 'ra']},
    'MMIO_WR':      {'op': 0xB, 'pfx': 1, 'operands': ['ra', 'rb']},
    'ROL':          {'op': 0xC, 'pfx': 1, 'operands': ['rd', 'ra', 'imm5']},
    'ROR':          {'op': 0xD, 'pfx': 1, 'operands': ['rd', 'ra', 'imm5']},
    'SUI':          {'op': 0xE, 'pfx': 1, 'operands': ['rd', 'ra', 'imm8']},
    'RETI':         {'op': 0xF, 'pfx': 1, 'operands': []},
}


# Mnemonics that disable register writeback (hardware matches decoder)
NO_WRITEBACK_PAGE1 = {0xD, 0xE, 0xF}              # CMPJ, JMP, HLT
NO_WRITEBACK_PAGE2 = {0x3, 0x5, 0xB, 0xF}         # JALR, CORDIC_TRIG, MMIO_WR, RETI


def parse_register(token):
    """Parse a register token. Accepts R0..R15, r0..r15, R10 or RA etc."""
    t = token.upper().strip()
    if not t.startswith('R'):
        raise ValueError(f"Not a register: {token}")
    suffix = t[1:]
    # Hex single-char form: RA, RB, ..., RF
    if len(suffix) == 1 and suffix in '0123456789ABCDEF':
        return int(suffix, 16)
    # Decimal form: R0..R15
    if suffix.isdigit():
        n = int(suffix)
        if 0 <= n <= 15:
            return n
    raise ValueError(f"Invalid register: {token}")


def parse_immediate(token):
    """Parse an immediate: #5, 0x1A, 0b1010, 42, -1."""
    t = token.strip()
    if t.startswith('#'):
        t = t[1:]
    if t.startswith('-'):
        return -parse_immediate(t[1:])
    if t.startswith('0x') or t.startswith('0X'):
        return int(t, 16)
    if t.startswith('0b') or t.startswith('0B'):
        return int(t, 2)
    return int(t, 10)


def encode_instruction(opcode, prefix,
                        write_rd=0, read_ra=0, read_rb=0,
                        ra_instant=0, rb_instant=0):
    """
    Pack fields into a 32-bit instruction word per the new layout:
        [31:24] rb_instant  (8-bit)
        [23:17] ra_instant  (7-bit)
        [16:13] read_rb
        [12:9]  read_ra
        [8:5]   write_rd
        [4]     prefix
        [3:0]   opcode
    """
    assert 0 <= opcode <= 0xF, f"opcode out of range: {opcode}"
    assert prefix in (0, 1), f"prefix must be 0 or 1: {prefix}"
    assert 0 <= write_rd <= 0xF, f"write_rd out of range: {write_rd}"
    assert 0 <= read_ra <= 0xF, f"read_ra out of range: {read_ra}"
    assert 0 <= read_rb <= 0xF, f"read_rb out of range: {read_rb}"
    assert 0 <= ra_instant <= 0x7F, f"ra_instant out of range (7-bit): {ra_instant}"
    assert 0 <= rb_instant <= 0xFF, f"rb_instant out of range (8-bit): {rb_instant}"

    word = 0
    word |= (opcode     & 0xF)                 # [3:0]
    word |= (prefix     & 0x1) << 4             # [4]
    word |= (write_rd   & 0xF) << 5             # [8:5]
    word |= (read_ra    & 0xF) << 9             # [12:9]
    word |= (read_rb    & 0xF) << 13            # [16:13]
    word |= (ra_instant & 0x7F) << 17           # [23:17]
    word |= (rb_instant & 0xFF) << 24           # [31:24]
    return word


def pack_target_15b(target):
    """
    Pack a 15-bit target into (ra_instant[6:0], rb_instant[7:0]).
    Returns (ra_instant, rb_instant).
    ra holds upper 7 bits, rb holds lower 8 bits.
    """
    if target < 0 or target > 0x7FFF:
        raise ValueError(f"Target out of 15-bit range (0..32767): {target}")
    ra = (target >> 8) & 0x7F
    rb = target & 0xFF
    return ra, rb


def encode_mnemonic(mnemonic, operands):
    """
    Encode a parsed instruction into a 32-bit word.
    Returns (word, info_dict).

    info_dict['needs_label'] is set to the label string if unresolved,
    in which case the word has placeholder zeros in the target slot
    and the assembler's pass-2 resolver will patch it.
    """
    m = mnemonic.upper()
    if m not in ISA:
        raise ValueError(f"Unknown mnemonic: {mnemonic}")

    spec = ISA[m]
    if len(operands) != len(spec['operands']):
        raise ValueError(
            f"{m} expects {len(spec['operands'])} operands "
            f"({', '.join(spec['operands'])}), got {len(operands)}"
        )

    write_rd = read_ra = read_rb = 0
    ra_instant = rb_instant = 0
    target_unresolved = None

    for kind, value in zip(spec['operands'], operands):
        if kind == 'rd':
            write_rd = parse_register(value)
        elif kind == 'ra':
            read_ra = parse_register(value)
        elif kind == 'rb':
            read_rb = parse_register(value)
        elif kind == 'imm':
            # LDI specifically: pack 16-bit immediate via high/low halves
            imm = value if isinstance(value, int) else parse_immediate(value)
            if m == 'LDI':
                if imm < 0 or imm > 0xFFFF:
                    raise ValueError(f"LDI immediate out of range (0..65535): {imm}")
                # ALU does: {RA_Instant[15:0], RB_Instant[15:0]}
                # ra_instant is 7-bit, zero-extended to 32 bits, so its [15:0] = {9'h0, ra_instant[6:0]}
                # rb_instant is 8-bit, zero-extended to 32 bits, so its [15:0] = {8'h0, rb_instant[7:0]}
                # Effective value = {{9'h0, ra}, {8'h0, rb}} = (ra << 24) | (rb << 16) ??? no.
                # ALU line: mux_out = {1'b0, RA_Instant[15:0], RB_Instant[15:0]};
                # So 32-bit ALU result = {RA_Instant[15:0], RB_Instant[15:0]}
                #   high 16 bits = RA_Instant[15:0] = {9'h0, ra_instant[6:0]}
                #   low  16 bits = RB_Instant[15:0] = {8'h0, rb_instant[7:0]}
                # So to load value V into rd, we need:
                #   V[31:16] = {9'h0, ra_instant[6:0]}  -> V[31:23] must be zero
                #   V[15:0]  = {8'h0, rb_instant[7:0]}  -> V[15:8] must be zero
                # Simplest user-friendly case: V fits in low 8 bits -> ra=0, rb=V.
                if imm <= 0xFF:
                    ra_instant = 0
                    rb_instant = imm & 0xFF
                else:
                    raise ValueError(
                        f"LDI immediate 0x{imm:x} not expressible with current ALU. "
                        f"Max practical LDI value is 0xFF. For larger constants use "
                        f"LDI + SHL + OR composition, or extend the ALU LDI encoding."
                    )
            else:
                raise ValueError(f"Plain 'imm' kind not supported for {m}")
        elif kind == 'imm8':
            imm = value if isinstance(value, int) else parse_immediate(value)
            if imm < 0 or imm > 0xFF:
                raise ValueError(f"{m} imm8 out of range (0..255): {imm}")
            rb_instant = imm & 0xFF
        elif kind == 'imm7':
            imm = value if isinstance(value, int) else parse_immediate(value)
            if imm < 0 or imm > 0x7F:
                raise ValueError(f"{m} imm7 out of range (0..127): {imm}")
            ra_instant = imm & 0x7F
        elif kind == 'imm5':
            imm = value if isinstance(value, int) else parse_immediate(value)
            if imm < 0 or imm > 0x1F:
                raise ValueError(f"{m} shift amount out of range (0..31): {imm}")
            rb_instant = imm & 0x1F
        elif kind == 'tgt':
            if isinstance(value, int):
                ra_instant, rb_instant = pack_target_15b(value)
            else:
                try:
                    t = parse_immediate(value)
                    ra_instant, rb_instant = pack_target_15b(t)
                except ValueError:
                    target_unresolved = value

    word = encode_instruction(
        spec['op'], spec['pfx'],
        write_rd=write_rd,
        read_ra=read_ra,
        read_rb=read_rb,
        ra_instant=ra_instant,
        rb_instant=rb_instant,
    )

    return word, {
        'mnemonic': m,
        'operands': operands,
        'opcode': spec['op'],
        'prefix': spec['pfx'],
        'needs_label': target_unresolved,
    }


def resolve_target(word, target_addr):
    """
    Patch a 32-bit word's target fields (ra_instant + rb_instant)
    with a resolved 15-bit target address.
    Clears bits [31:17], re-inserts ra_instant and rb_instant.
    """
    ra_new, rb_new = pack_target_15b(target_addr)
    # Clear bits [31:17] = rb_instant and ra_instant fields
    word &= ~((0xFF << 24) | (0x7F << 17))
    word |= (ra_new & 0x7F) << 17
    word |= (rb_new & 0xFF) << 24
    return word


def decode_instruction(word):
    """Debug helper: decode a 32-bit word back to its fields."""
    return {
        'opcode':     (word >> 0)  & 0xF,
        'prefix':     (word >> 4)  & 0x1,
        'write_rd':   (word >> 5)  & 0xF,
        'read_ra':    (word >> 9)  & 0xF,
        'read_rb':    (word >> 13) & 0xF,
        'ra_instant': (word >> 17) & 0x7F,
        'rb_instant': (word >> 24) & 0xFF,
    }
