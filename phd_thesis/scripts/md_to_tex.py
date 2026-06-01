"""Minimal markdown-to-LaTeX converter for erratum and Q&A documents.
Handles: headers, bold, italic, inline code, pipe tables, blockquotes, lists.
Math expressions ($...$) are passed through unchanged.
"""
import re
import sys
from pathlib import Path


def escape_tex(text: str) -> str:
    """Escape LaTeX special characters, but leave $...$ math and `code` untouched."""
    # Split on math and code regions to avoid escaping inside them
    # Pattern: $...$ math OR `...` code
    parts = re.split(r'(\$[^$\n]+\$|`[^`\n]+`)', text)
    result = []
    for i, part in enumerate(parts):
        if i % 2 == 1:  # math or code region — leave untouched
            result.append(part)
        else:
            # Escape non-math, non-code regions
            part = part.replace('\\', r'\textbackslash{}')
            part = part.replace('&', r'\&')
            part = part.replace('%', r'\%')
            part = part.replace('#', r'\#')
            part = part.replace('^', r'\^{}')
            part = part.replace('_', r'\_')
            part = part.replace('{', r'\{')
            part = part.replace('}', r'\}')
            part = part.replace('~', r'\textasciitilde{}')
            part = part.replace('<', r'\textless{}')
            part = part.replace('>', r'\textgreater{}')
            result.append(part)
    return ''.join(result)


def inline_format(text: str, in_table: bool = False) -> str:
    """Apply inline formatting: bold, italic, inline code.
    Math regions ($...$) are protected from * interpretation.
    When in_table=True, never uses \\verb (incompatible with tabular)."""

    # Step 1: tokenise into math, code, and plain segments so * in math
    # is never treated as italic.
    tokens = re.split(r'(\$[^$\n]+\$|`[^`\n]+`)', text)
    result = []

    for i, tok in enumerate(tokens):
        if i % 2 == 1:
            # Math or code span
            if tok.startswith('`'):
                inner = tok[1:-1]
                # Always use \texttt with manual escaping (works in tables too)
                inner_esc = (inner
                             .replace('\\', r'\textbackslash{}')
                             .replace('{', r'\{')
                             .replace('}', r'\}')
                             .replace('_', r'\_')
                             .replace('$', r'\$')
                             .replace('#', r'\#')
                             .replace('%', r'\%')
                             .replace('&', r'\&')
                             .replace('^', r'\^{}')
                             .replace('~', r'\textasciitilde{}'))
                result.append(r'\texttt{' + inner_esc + '}')
            else:
                # Math: pass through unchanged
                result.append(tok)
        else:
            # Plain text: apply bold then italic (not inside math/code)
            tok = re.sub(r'\*\*(.+?)\*\*', lambda m: r'\textbf{' + m.group(1) + '}', tok)
            tok = re.sub(r'\*(.+?)\*', lambda m: r'\textit{' + m.group(1) + '}', tok)
            result.append(tok)

    return ''.join(result)


def process_table(lines: list) -> str:
    """Convert a markdown pipe table to a LaTeX longtable."""
    if len(lines) < 2:
        return ''

    # Parse header row
    header_cells = [c.strip() for c in lines[0].strip().strip('|').split('|')]
    ncols = len(header_cells)
    # lines[1] is the separator row — skip it
    # Remaining are data rows
    data_rows = lines[2:]

    col_spec = 'l' + ' p{3cm}' * (ncols - 1) if ncols > 2 else 'l' * ncols
    # Use a fixed column spec for the common 4-5 column case in erratum
    if ncols == 5:
        col_spec = r'c p{3.2cm} l p{3.8cm} p{3.5cm}'
    elif ncols == 4:
        col_spec = r'l p{3.5cm} p{3.5cm} p{4cm}'
    elif ncols == 3:
        col_spec = r'l p{4.5cm} p{4.5cm}'
    elif ncols == 2:
        col_spec = r'p{5cm} p{8cm}'

    out = [r'\begin{longtable}{' + col_spec + r'}',
           r'\toprule']
    header_formatted = ' & '.join(
        r'\textbf{' + inline_format(escape_tex(c)) + '}' for c in header_cells
    )
    out.append(header_formatted + r' \\')
    out.append(r'\midrule')
    out.append(r'\endhead')

    for row_line in data_rows:
        row_line = row_line.strip()
        if not row_line or row_line.startswith('|---') or row_line == '|':
            continue
        cells = [c.strip() for c in row_line.strip().strip('|').split('|')]
        # Pad to ncols if needed
        while len(cells) < ncols:
            cells.append('')
        cell_tex = ' & '.join(inline_format(escape_tex(c)) for c in cells[:ncols])
        out.append(cell_tex + r' \\')

    out.append(r'\bottomrule')
    out.append(r'\end{longtable}')
    return '\n'.join(out)


def convert(md_text: str) -> str:
    lines = md_text.split('\n')
    output = []
    i = 0
    in_blockquote = False

    while i < len(lines):
        line = lines[i]

        # --- Horizontal rule ---
        if re.match(r'^---+$', line.strip()):
            if in_blockquote:
                output.append(r'\end{quote}')
                in_blockquote = False
            output.append(r'\medskip\hrule\medskip')
            i += 1
            continue

        # --- Headings ---
        m = re.match(r'^(#{1,4})\s+(.+)$', line)
        if m:
            level = len(m.group(1))
            title = inline_format(m.group(2))
            cmds = [r'\section*', r'\subsection*', r'\subsubsection*', r'\paragraph']
            output.append(f'{cmds[level-1]}{{{inline_format(escape_tex(m.group(2)))}}}')
            i += 1
            continue

        # --- Pipe tables ---
        if line.startswith('|'):
            table_lines = []
            while i < len(lines) and lines[i].startswith('|'):
                table_lines.append(lines[i])
                i += 1
            output.append(process_table(table_lines))
            output.append('')
            continue

        # --- Blockquotes ---
        if line.startswith('>'):
            if not in_blockquote:
                output.append(r'\begin{quote}')
                in_blockquote = True
            content = line.lstrip('> ')
            output.append(inline_format(escape_tex(content)))
            i += 1
            continue
        else:
            if in_blockquote:
                output.append(r'\end{quote}')
                in_blockquote = False

        # --- Unordered lists ---
        if re.match(r'^[-*]\s+', line):
            items = []
            while i < len(lines) and re.match(r'^[-*]\s+', lines[i]):
                items.append(r'\item ' + inline_format(escape_tex(re.sub(r'^[-*]\s+', '', lines[i]))))
                i += 1
            output.append(r'\begin{itemize}')
            output.extend(items)
            output.append(r'\end{itemize}')
            continue

        # --- Numbered lists ---
        if re.match(r'^\d+\.\s+', line):
            items = []
            while i < len(lines) and re.match(r'^\d+\.\s+', lines[i]):
                items.append(r'\item ' + inline_format(escape_tex(re.sub(r'^\d+\.\s+', '', lines[i]))))
                i += 1
            output.append(r'\begin{enumerate}')
            output.extend(items)
            output.append(r'\end{enumerate}')
            continue

        # --- Empty lines → paragraph break ---
        if line.strip() == '':
            output.append('')
            i += 1
            continue

        # --- Regular paragraph text ---
        output.append(inline_format(escape_tex(line)))
        i += 1

    if in_blockquote:
        output.append(r'\end{quote}')

    return '\n'.join(output)


def wrap_document(body: str, title: str = '') -> str:
    preamble = r"""\documentclass[11pt,a4paper]{article}
\usepackage{fontspec}
\setmainfont{Latin Modern Roman}
\usepackage{geometry}
\usepackage{booktabs}
\usepackage{longtable}
\usepackage{array}
\usepackage{hyperref}
\usepackage{xcolor}
\usepackage{parskip}
\usepackage{amsmath,amssymb,bm}
\geometry{margin=2.5cm, top=2cm}
\hypersetup{colorlinks=true,linkcolor=blue,urlcolor=blue,citecolor=blue}
\setlength{\LTcapwidth}{\linewidth}
"""
    return preamble + r'\begin{document}' + '\n\n' + body + '\n\n' + r'\end{document}'


if __name__ == '__main__':
    src = Path(sys.argv[1])
    out_tex = src.with_suffix('.generated.tex')
    md_text = src.read_text(encoding='utf-8')
    body = convert(md_text)
    doc = wrap_document(body, src.stem)
    out_tex.write_text(doc, encoding='utf-8')
    print(f'Written: {out_tex}')
