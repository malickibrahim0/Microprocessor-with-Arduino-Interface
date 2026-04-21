"""
Parser for the SoC assembler.

Grammar:
    program     := line*
    line        := (label)? (instruction)? (comment)? NEWLINE
    label       := IDENTIFIER ':'
    instruction := MNEMONIC (operand (',' operand)*)?
    comment     := ';' .* | '//' .*
"""

import re


class ParseError(Exception):
    """Raised for assembly-time syntax errors."""
    def __init__(self, message, line_num=None, line_text=None):
        self.line_num = line_num
        self.line_text = line_text
        if line_num is not None:
            message = f"Line {line_num}: {message}"
            if line_text:
                message += f"\n  >>> {line_text.strip()}"
        super().__init__(message)


LABEL_RE = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(.*)$')


def strip_comment(line):
    """Remove ';' and '//' comments and trailing whitespace."""
    for marker in (';', '//'):
        idx = line.find(marker)
        if idx >= 0:
            line = line[:idx]
    return line.rstrip()


def parse_line(raw_line, line_num):
    """Parse one source line."""
    line = strip_comment(raw_line).strip()
    if not line:
        return None

    label = None
    m = LABEL_RE.match(line)
    if m:
        label = m.group(1)
        line = m.group(2).strip()

    if not line:
        return {'label': label, 'mnemonic': None, 'operands': []}

    parts = line.split(None, 1)
    mnemonic = parts[0]
    operands = []
    if len(parts) > 1:
        operands = [o.strip() for o in parts[1].split(',')]
        operands = [o for o in operands if o]

    return {'label': label, 'mnemonic': mnemonic, 'operands': operands}


def parse_source(text):
    """Parse full source text. Returns list of parsed lines with line numbers."""
    results = []
    for i, raw in enumerate(text.splitlines(), start=1):
        try:
            parsed = parse_line(raw, i)
            if parsed is None:
                continue
            parsed['line_num'] = i
            parsed['source'] = raw
            results.append(parsed)
        except Exception as e:
            raise ParseError(str(e), line_num=i, line_text=raw) from e
    return results
