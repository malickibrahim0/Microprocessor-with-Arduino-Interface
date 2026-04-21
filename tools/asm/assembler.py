"""
Two-pass assembler for the 32-bit pipelined RISC SoC.

Usage:
    python assembler.py input.asm [options]

Examples:
    python assembler.py programs/fib.asm
    python assembler.py fib.asm --hex memory.hex --sv rom_init.svh
    python assembler.py fib.asm --verify reference.hex
    python assembler.py fib.asm --debug
"""

import argparse
import datetime
import sys
from pathlib import Path

from isa import ISA, encode_mnemonic, resolve_target, decode_instruction
from parser import parse_source, ParseError


def assemble(source_text, source_name='<string>'):
    """
    Two-pass assembly.

    Pass 1: walk source, assign addresses to labels.
    Pass 2: encode each instruction, patching label targets.

    Returns: (list_of_emitted_dicts, labels_dict)
    """
    parsed = parse_source(source_text)

    # ---- Pass 1: assign addresses, build label table ----
    labels = {}
    instructions = []
    addr = 0
    for p in parsed:
        if p['label']:
            if p['label'] in labels:
                raise ParseError(
                    f"Duplicate label '{p['label']}' (previously at "
                    f"address {labels[p['label']]})",
                    line_num=p['line_num'], line_text=p['source']
                )
            labels[p['label']] = addr
        if p['mnemonic'] is not None:
            p['addr'] = addr
            instructions.append(p)
            addr += 1

    # ---- Pass 2: encode ----
    emitted = []
    for p in instructions:
        mnemonic = p['mnemonic']
        operands = p['operands']
        try:
            word, info = encode_mnemonic(mnemonic, operands)
        except Exception as e:
            raise ParseError(str(e), line_num=p['line_num'],
                              line_text=p['source']) from e

        if info['needs_label']:
            label_name = info['needs_label']
            if label_name not in labels:
                raise ParseError(
                    f"Undefined label: '{label_name}'",
                    line_num=p['line_num'], line_text=p['source']
                )
            target_addr = labels[label_name]
            try:
                word = resolve_target(word, target_addr)
            except ValueError as e:
                raise ParseError(
                    str(e), line_num=p['line_num'], line_text=p['source']
                ) from e

        emitted.append({
            'addr': p['addr'],
            'word': word,
            'source': p['source'].strip(),
            'line_num': p['line_num'],
            'mnemonic': mnemonic,
            'operands': operands,
        })

    return emitted, labels


def emit_hex(emitted, source_name='program'):
    """Emit $readmemh-compatible hex file."""
    lines = []
    lines.append(f'// Auto-generated from {source_name}')
    lines.append(f'// Assembled on {datetime.datetime.now().isoformat(timespec="seconds")}')
    lines.append(f'// Total instructions: {len(emitted)}')
    lines.append('// Do not edit by hand - regenerate with tools/asm/assembler.py')
    lines.append('')
    for e in emitted:
        lines.append(f'{e["word"]:08x} // {e["addr"]:02x}: {e["source"]}')
    return '\n'.join(lines) + '\n'


def emit_sv(emitted, source_name='program', param_name='PROGRAM_ROM'):
    """Emit SystemVerilog localparam array include."""
    lines = []
    lines.append(f'// Auto-generated from {source_name}')
    lines.append(f'// Assembled on {datetime.datetime.now().isoformat(timespec="seconds")}')
    lines.append('// Do not edit by hand. Regenerate with assembler.py')
    lines.append('')
    lines.append(f'localparam int {param_name}_SIZE = {len(emitted)};')
    lines.append(f'logic [31:0] {param_name} [0:{param_name}_SIZE-1] = \'{{')
    for i, e in enumerate(emitted):
        sep = ',' if i < len(emitted) - 1 else ' '
        lines.append(f"    32'h{e['word']:08x}{sep} // {e['addr']:02x}: {e['source']}")
    lines.append('};')
    return '\n'.join(lines) + '\n'


def emit_debug_listing(emitted):
    """Decode each instruction back to fields for human verification."""
    lines = []
    lines.append(f"{'Addr':>4}  {'Word':>10}  {'Op':>4} {'Pfx':>3} "
                 f"{'Rd':>3} {'Ra':>3} {'Rb':>3} "
                 f"{'RaImm':>6} {'RbImm':>6}  Source")
    lines.append('-' * 90)
    for e in emitted:
        d = decode_instruction(e['word'])
        lines.append(
            f"  {e['addr']:02x}  0x{e['word']:08x}  "
            f"{d['opcode']:>4x} {d['prefix']:>3} "
            f"{d['write_rd']:>3x} {d['read_ra']:>3x} {d['read_rb']:>3x} "
            f"{d['ra_instant']:>6x} {d['rb_instant']:>6x}  "
            f"{e['source']}"
        )
    return '\n'.join(lines)


def verify_against(emitted, reference_path):
    """
    Compare assembled output against a reference .hex file.
    Returns (bool_match, list_of_diffs).
    """
    ref_words = []
    with open(reference_path) as f:
        for line in f:
            for c in ('//', ';'):
                idx = line.find(c)
                if idx >= 0:
                    line = line[:idx]
            line = line.strip()
            if not line:
                continue
            token = line.split()[0]
            try:
                ref_words.append(int(token, 16))
            except ValueError:
                continue

    diffs = []
    max_len = max(len(ref_words), len(emitted))
    for i in range(max_len):
        ref = ref_words[i] if i < len(ref_words) else None
        got = emitted[i]['word'] if i < len(emitted) else None
        if ref != got:
            src = emitted[i]['source'] if i < len(emitted) else ''
            diffs.append((i, ref, got, src))

    return len(diffs) == 0, diffs


def main():
    ap = argparse.ArgumentParser(
        description='32-bit RISC assembler for SoC project.'
    )
    ap.add_argument('input', help='Source .asm file')
    ap.add_argument('--hex', help='Output .hex file (readmemh format)',
                     default=None)
    ap.add_argument('--sv', help='Output .svh file (SystemVerilog include)',
                     default=None)
    ap.add_argument('--out', help='Base name for both outputs',
                     default=None)
    ap.add_argument('--verify', help='Compare against reference .hex file',
                     default=None)
    ap.add_argument('--debug', action='store_true',
                     help='Print decoded field table')
    ap.add_argument('--quiet', action='store_true',
                     help='Suppress per-instruction listing')
    args = ap.parse_args()

    src_path = Path(args.input)
    if not src_path.exists():
        print(f"ERROR: Source file not found: {args.input}", file=sys.stderr)
        return 1

    source_text = src_path.read_text()
    try:
        emitted, labels = assemble(source_text, source_name=src_path.name)
    except ParseError as e:
        print(f"ASSEMBLY ERROR:\n{e}", file=sys.stderr)
        return 1

    hex_path = args.hex
    sv_path = args.sv
    if args.out:
        base = Path(args.out)
        hex_path = str(base.with_suffix('.hex'))
        sv_path = str(base.with_suffix('.svh'))
    if not hex_path and not sv_path:
        hex_path = str(src_path.with_suffix('.hex'))
        sv_path = str(src_path.with_suffix('.svh'))

    if hex_path:
        Path(hex_path).write_text(emit_hex(emitted, source_name=src_path.name))
        print(f"Wrote {hex_path} ({len(emitted)} instructions)")
    if sv_path:
        Path(sv_path).write_text(emit_sv(emitted, source_name=src_path.name))
        print(f"Wrote {sv_path}")

    if args.debug:
        print('\n=== Debug Listing (decoded fields) ===')
        print(emit_debug_listing(emitted))

    if not args.quiet and not args.debug:
        print('\n=== Program Listing ===')
        for e in emitted:
            print(f"  {e['addr']:02x}: 0x{e['word']:08x}  {e['source']}")
        if labels:
            print('\n=== Labels ===')
            for name, addr in sorted(labels.items(), key=lambda x: x[1]):
                print(f"  {name:16s} = 0x{addr:02x}")

    if args.verify:
        match, diffs = verify_against(emitted, args.verify)
        if match:
            print(f"\nVERIFY OK: {len(emitted)} words match {args.verify}")
            return 0
        else:
            print(f"\nVERIFY FAILED: {len(diffs)} mismatches vs {args.verify}")
            for addr, ref, got, src in diffs[:20]:
                ref_s = f'{ref:08x}' if ref is not None else 'MISSING'
                got_s = f'{got:08x}' if got is not None else 'MISSING'
                print(f"  {addr:02x}: expected={ref_s} got={got_s}  ({src})")
            return 2

    return 0


if __name__ == '__main__':
    sys.exit(main())
