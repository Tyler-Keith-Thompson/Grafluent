#!/usr/bin/env python3
"""Reference model for GraphFormats (Tests/Catalogs/GraphFormats).

Run: uv run --quiet --no-project --with networkx==3.7 --with scipy==1.18.1 --with pydot==4.0.1 \
         python3 Tests/Catalogs/GraphFormats/ref.py [--write] [--stress] [--bench]

The model is an independent Python implementation of api.md: one reader and one writer per
format (DOT, GraphML, node-link JSON, Matrix Market, edge list, adjacency list, Mermaid, GML,
Pajek, graph6, sparse6, digraph6, DIMACS, METIS, Cytoscape JSON), with its own UTF-8, XML and JSON
scanners, so that every rule api.md states (what is accepted, what is an error and where, what a
writer prints byte for byte) is code here.

  * A reader fills a target: `D` (DirectedPseudograph), `DS` (AdjacencyList: a parallel edge
    returns the existing position), `U` (Pseudograph), `US` (UndirectedAdjacencyList). Attribute
    callbacks are setters; the model keeps, per vertex and per edge position, the keys in
    first-set order with the last value set.
  * Errors are (kind, line, column): 1-based, column counted in Unicode scalars.

Cross-checks, per row where the library reads the input the same way (the rest are listed in
KNOWN with the reason, and in api.md under disagreements):

  * GraphML: NetworkX `read_graphml` on read rows; every writer row read back by NetworkX.
  * node-link JSON: NetworkX `node_link_graph` on read rows; writer rows byte-equal to
    `json.dumps(nx.node_link_data(G, edges="edges"))`.
  * Matrix Market: SciPy `mmread` on read rows; writer rows byte-equal to SciPy `mmwrite`.
  * edge list, adjacency list: NetworkX `read_edgelist` / `read_adjlist` on read rows; writer rows
    byte-equal to `write_edgelist(data=columns)` / `write_adjlist` (its three header comment lines
    removed), on simple graphs.
  * GML, Pajek, graph6, sparse6, Cytoscape JSON: NetworkX's parse_gml, parse_pajek,
    from_graph6_bytes, from_sparse6_bytes and cytoscape_graph on read rows; writer rows byte-equal to
    generate_gml, generate_pajek, to_graph6_bytes, to_sparse6_bytes and
    json.dumps(cytoscape_data(G)), edges compared as sets where NetworkX lists them by adjacency.
    digraph6, DIMACS and METIS have no Python implementation: the model follows nauty's
    formats.txt, the DIMACS challenge pages and the METIS manual.
  * DOT: pydot 4.0.1 parses every writer row back to the same edges and explicit attributes;
    read rows are compared on edges and explicit attributes where pydot's grammar agrees (pydot
    applies no defaults and has no strict merge). Graphviz itself is not installable without a
    system package, so the Graphviz rules (escaping, defaults, strict) cite its grammar page and
    scan.l and are not executed.
  * Mermaid: no Python implementation exists; the model follows the flowchart syntax page and
    flow.jison of mermaid-js 11.

--write regenerates cases.md; without it the run fails if cases.md differs. --stress writes random
graphs in every format and reads them back (model, and the libraries where they read the format),
and feeds 3,000 mutated inputs to every model reader, which must return a graph or a ParseError.
--bench times the same libraries on the benchmark graph (a random directed graph, 10⁵ vertices,
10⁶ weighted edges).
"""
import decimal
import io
import json
import math
import os
import random
import re
import sys
import time
import warnings

warnings.simplefilter("ignore")
# Integers of any length parse (Python otherwise refuses more than 4,300 digits), so that a huge
# integer is numberOutOfRange, as api.md says, and not a crash of the model.
sys.set_int_max_str_digits(0)

import networkx as nx  # noqa: E402
import numpy as np  # noqa: E402
import pydot  # noqa: E402
import scipy.io  # noqa: E402
import scipy.sparse  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
MAX_DEPTH = 64
INT_MIN, INT_MAX = -(1 << 63), (1 << 63) - 1


# ============================================================================ errors, targets

class ParseError(Exception):
    def __init__(self, kind, offset):
        super().__init__(kind)
        self.kind = kind
        self.offset = offset  # character offset into the decoded text, or ('byte', n)
        self.line = self.column = None

    def locate(self, text, raw):
        if isinstance(self.offset, tuple):  # invalid UTF-8 at byte n
            n = self.offset[1]
            line_start = raw.rfind(b"\n", 0, n) + 1
            self.line = raw.count(b"\n", 0, n) + 1
            self.column = len(raw[line_start:n].decode("utf-8")) + 1
        else:
            n = self.offset
            self.line = text.count("\n", 0, n) + 1
            self.column = n - (text.rfind("\n", 0, n) + 1) + 1
        return self

    def __str__(self):
        return f"error {self.kind} at {self.line}:{self.column}"


class Target:
    """A representation filled by a reader. `simple` targets return an existing edge's position
    for a repeated pair (AdjacencyList, UndirectedAdjacencyList)."""

    def __init__(self, directed, simple=False, vtype=str):
        self.directed, self.simple, self.vtype = directed, simple, vtype
        self.vertices, self.index, self.vattrs = [], {}, []
        self.edges, self.eattrs, self.pairs = [], [], {}
        self.gattrs = {}

    def key(self, u, v):
        return (u, v) if self.directed else (min(u, v), max(u, v))

    def vertex(self, name):
        i = self.index.get(name)
        if i is None:
            i = self.index[name] = len(self.vertices)
            self.vertices.append(name)
            self.vattrs.append({})
        return i

    def edge(self, u, v):
        k = self.key(u, v)
        if self.simple and k in self.pairs:
            return self.pairs[k]
        self.edges.append((u, v))
        self.eattrs.append({})
        self.pairs.setdefault(k, len(self.edges) - 1)
        return len(self.edges) - 1

    def __eq__(self, o):
        return (self.directed, self.vertices, self.vattrs, self.edges, self.eattrs, self.gattrs) == (
            o.directed, o.vertices, o.vattrs, o.edges, o.eattrs, o.gattrs)


def graph(directed, vertices, edges, vattrs=None, eattrs=None, gattrs=None):
    g = Target(directed, vtype=int if vertices and isinstance(vertices[0], int) else str)
    for v in vertices:
        g.vertex(v)
    for u, v in edges:
        g.edges.append((g.vertex(u), g.vertex(v)))
        g.eattrs.append({})
    for v, a in (vattrs or {}).items():
        g.vattrs[g.index[v]] = dict(a)
    for p, a in (eattrs or {}).items():
        g.eattrs[p] = dict(a)
    g.gattrs = dict(gattrs or {})
    return g


# ---------------------------------------------------------------- notation

PLAIN = re.compile(r"^[A-Za-z0-9_]+$")


def fmt_value(v):
    if type(v) is bool:
        return "true" if v else "false"
    if type(v) is int:
        return str(v)
    if type(v) is float:
        return repr(v)
    return json.dumps(v, ensure_ascii=False)


def fmt_name(v):
    if isinstance(v, int):
        return str(v)
    return v if PLAIN.match(v) else json.dumps(v, ensure_ascii=False)


def fmt_attrs(a):
    return "{" + ", ".join(f"{fmt_name(k)}={fmt_value(x)}" for k, x in a.items()) + "}" if a else ""


def fmt_graph(g):
    if isinstance(g, ParseError):
        return f"**{g.kind}** at {g.line}:{g.column}"
    arrow = ">" if g.directed else "-"
    vs = ", ".join(fmt_name(v) + fmt_attrs(a) for v, a in zip(g.vertices, g.vattrs))
    es = ", ".join(f"{fmt_name(g.vertices[u])}{arrow}{fmt_name(g.vertices[v])}" + fmt_attrs(a)
                   for (u, v), a in zip(g.edges, g.eattrs))
    s = ("D:" if g.directed else "U:") + (" " + vs if vs else "") + ("; " + es if es else "")
    if g.gattrs:
        s += "; graph" + fmt_attrs(g.gattrs)
    return s


# ---------------------------------------------------------------- text

def decode(raw):
    """UTF-8, strict, with one leading byte-order mark removed."""
    if raw.startswith(b"\xef\xbb\xbf"):
        raw = raw[3:]
    try:
        return raw.decode("utf-8"), raw
    except UnicodeDecodeError as e:
        raise ParseError("invalidUTF8", ("byte", e.start)).locate(None, raw)


def run_reader(reader, raw, target):
    if isinstance(raw, str):
        raw = raw.encode()
    try:
        text, body = decode(raw)
    except ParseError as e:
        return e
    try:
        reader(text, target)
        return target
    except ParseError as e:
        return e.locate(text, body)


FLOAT_DEC = re.compile(r"[+-]?(?:[0-9]+\.[0-9]*|\.[0-9]+|[0-9]+)(?:[eE][+-]?[0-9]+)?$")
INT_DEC = re.compile(r"[+-]?[0-9]+$")


def ascii_lower(s):
    """Lowercase ASCII letters only: the readers compare keywords by ASCII case, so no non-ASCII
    letter lowercases into a keyword (as KELVIN SIGN does into k under str.lower)."""
    return "".join(c.lower() if c.isascii() else c for c in s)


def py_double(x):
    """Python repr: the shortest round-trip digits, positional for decimal exponents -4 ..< 16."""
    return repr(x)


# ============================================================================ DOT

DOT_KEYWORDS = {"strict", "graph", "digraph", "node", "edge", "subgraph"}
DOT_NUMERAL = re.compile(r"-?(?:\.[0-9]+|[0-9]+(?:\.[0-9]*)?)")
DOT_IDENT = re.compile(r"[A-Za-z_\u0080-\U0010ffff][A-Za-z0-9_\u0080-\U0010ffff]*")


def dot_is_idchar(c):
    return c.isascii() and (c.isalnum() or c == "_") or not c.isascii()


def dot_lex(t):
    toks, p, n = [], 0, len(t)
    while True:
        while p < n:
            c = t[p]
            if c in " \t\r\n\v\f":
                p += 1
            elif c == "#" and (p == 0 or t[p - 1] == "\n"):
                q = t.find("\n", p)
                p = n if q < 0 else q
            elif t.startswith("//", p):
                q = t.find("\n", p)
                p = n if q < 0 else q
            elif t.startswith("/*", p):
                q = t.find("*/", p + 2)
                if q < 0:
                    raise ParseError("unexpectedEndOfInput", p)
                p = q + 2
            else:
                break
        if p >= n:
            toks.append(("eof", None, n))
            return toks
        c = t[p]
        if t.startswith("->", p) or t.startswith("--", p):
            toks.append((t[p:p + 2], None, p))
            p += 2
        elif c in "{}[];,=:+":
            toks.append((c, None, p))
            p += 1
        elif c == '"':
            q, out = p + 1, []
            while True:
                if q >= n:
                    raise ParseError("unexpectedEndOfInput", p)
                d = t[q]
                if d == '"':
                    break
                if d == "\\" and q + 1 < n and t[q + 1] == '"':
                    out.append('"')
                    q += 2
                elif d == "\\" and q + 1 < n and t[q + 1] == "\n":
                    q += 2
                else:
                    out.append(d)
                    q += 1
            toks.append(("id", ("quoted", "".join(out)), p))
            p = q + 1
        elif c == "<":
            q, depth = p, 0
            while True:
                if q >= n:
                    raise ParseError("unexpectedEndOfInput", p)
                if t[q] == "<":
                    depth += 1
                elif t[q] == ">":
                    depth -= 1
                    if depth == 0:
                        break
                q += 1
            toks.append(("id", ("html", t[p + 1:q]), p))
            p = q + 1
        elif c in "0123456789" or c == "." or c == "-":
            m = DOT_NUMERAL.match(t, p)
            if not m:
                raise ParseError("syntax", p)
            q = m.end()
            if q < n and (dot_is_idchar(t[q]) or t[q] == "."):
                raise ParseError("syntax", q)
            toks.append(("id", ("numeral", t[p:q]), p))
            p = q
        elif dot_is_idchar(c):
            m = DOT_IDENT.match(t, p)
            word = m.group()
            if ascii_lower(word) in DOT_KEYWORDS:
                toks.append(("kw", ascii_lower(word), p))
            else:
                toks.append(("id", ("ident", word), p))
            p = m.end()
        else:
            raise ParseError("syntax", p)


def dot_read(t, g):
    toks = dot_lex(t)
    i = 0

    def peek():
        return toks[i]

    def take():
        nonlocal i
        i += 1
        return toks[i - 1]

    def fail(tok, kind="syntax"):
        raise ParseError("unexpectedEndOfInput" if tok[0] == "eof" else kind, tok[2])

    def ident():
        tok = take()
        if tok[0] != "id":
            fail(tok)
        kind, value = tok[1]
        if kind == "quoted":
            while peek()[0] == "+":
                take()
                nxt = take()
                if nxt[0] != "id" or nxt[1][0] != "quoted":
                    fail(nxt)
                value += nxt[1][1]
        return value

    def attr_list():
        pairs = []
        while peek()[0] == "[":
            take()
            while peek()[0] != "]":
                if peek()[0] == "eof":
                    fail(peek())
                k = ident()
                if take()[0] != "=":
                    fail(toks[i - 1])
                pairs.append((k, ident()))
                if peek()[0] in (";", ","):
                    take()
            take()
        return pairs

    tok = take()
    strict = False
    if tok[0] == "kw" and tok[1] == "strict":
        strict = True
        tok = take()
    if not (tok[0] == "kw" and tok[1] in ("graph", "digraph")):
        fail(tok)
    directed = tok[1] == "digraph"
    if directed != g.directed:
        raise ParseError("kindMismatch", tok[2])
    op = "->" if directed else "--"
    if peek()[0] == "id":
        ident()
    if take()[0] != "{":
        fail(toks[i - 1])
    merged = {}
    # The open subgraphs' vertex lists (each an insertion-ordered dict), innermost last.
    open_lists = []

    def mention(v):
        for members in open_lists:
            members.setdefault(v, None)

    def node(name, node_defaults):
        if name in g.index:
            v = g.index[name]
        else:
            v = g.vertex(name)
            for k, x in node_defaults.items():
                g.vattrs[v][k] = x
        mention(v)
        return v

    def is_subgraph(tok):
        return tok[0] == "{" or (tok[0] == "kw" and tok[1] == "subgraph")

    def subgraph(depth, node_defaults, edge_defaults):
        """A subgraph at the current token: its vertices in order of first mention."""
        tok = take()
        if tok[0] == "kw":
            if peek()[0] == "id":
                ident()
            if peek()[0] != "{":
                raise ParseError("unsupported", tok[2])
            tok = take()
        if depth > MAX_DEPTH:
            raise ParseError("nestingTooDeep", tok[2])
        members = {}
        open_lists.append(members)
        statements(depth, dict(node_defaults), dict(edge_defaults), root=False)
        open_lists.pop()
        for v in members:
            mention(v)
        return list(members)

    def operand(depth, node_defaults, edge_defaults):
        """An edge operand: (vertices, port)."""
        if is_subgraph(peek()):
            vs = subgraph(depth + 1, node_defaults, edge_defaults)
            if peek()[0] == ":":
                fail(peek())
            return vs, None
        name = ident()
        port = None
        if peek()[0] == ":":
            take()
            port = ident()
            if peek()[0] == ":":
                take()
                port += ":" + ident()
        return [node(name, node_defaults)], port

    def chain(first, depth, node_defaults, edge_defaults):
        operands = [first]
        while peek()[0] in ("->", "--"):
            e = take()
            if e[0] != op:
                fail(e)
            operands.append(operand(depth, node_defaults, edge_defaults))
        pairs = attr_list()
        for (tails, tport), (heads, hport) in zip(operands, operands[1:]):
            for u in tails:
                for v in heads:
                    k = g.key(u, v)
                    if strict and k in merged:
                        p = merged[k]
                    else:
                        p = g.edge(u, v)
                        merged.setdefault(k, p)
                        for kk, x in edge_defaults.items():
                            g.eattrs[p][kk] = x
                    if tport is not None:
                        g.eattrs[p]["tailport"] = tport
                    if hport is not None:
                        g.eattrs[p]["headport"] = hport
                    for kk, x in pairs:
                        g.eattrs[p][kk] = x

    def statements(depth, node_defaults, edge_defaults, root):
        while True:
            tok = peek()
            if tok[0] == "}":
                take()
                return
            if tok[0] == "eof":
                fail(tok)
            if tok[0] == ";":
                take()
                continue
            if is_subgraph(tok):
                vs = subgraph(depth + 1, node_defaults, edge_defaults)
                if peek()[0] == ":":
                    fail(peek())
                if peek()[0] in ("->", "--"):
                    chain((vs, None), depth, node_defaults, edge_defaults)
            elif tok[0] == "kw" and tok[1] in ("graph", "node", "edge"):
                take()
                if peek()[0] != "[":
                    fail(peek())
                pairs = attr_list()
                target = {"graph": g.gattrs if root else {}, "node": node_defaults, "edge": edge_defaults}[tok[1]]
                for k, x in pairs:
                    target[k] = x
            elif tok[0] == "id":
                name = ident()
                if peek()[0] == "=":
                    take()
                    value = ident()
                    if root:
                        g.gattrs[name] = value
                else:
                    port = None
                    if peek()[0] == ":":
                        take()
                        port = ident()
                        if peek()[0] == ":":
                            take()
                            port += ":" + ident()
                    if peek()[0] in ("->", "--"):
                        chain(([node(name, node_defaults)], port), depth, node_defaults, edge_defaults)
                    else:
                        pairs = attr_list()
                        v = node(name, node_defaults)
                        for k, x in pairs:
                            g.vattrs[v][k] = x
            else:
                fail(tok)
            if peek()[0] == ";":
                take()

    statements(0, {}, {}, root=True)
    tok = peek()
    if tok[0] != "eof":
        fail(tok, "unsupported" if tok[0] == "kw" and tok[1] in ("strict", "graph", "digraph") else "syntax")


def dot_quote(s):
    out = ['"']
    for k, c in enumerate(s):
        if c == '"':
            out.append('\\"')
        elif c == "\\" and (k + 1 == len(s) or s[k + 1] == "\n"):
            out.append("\\\\\n")
        else:
            out.append(c)
    out.append('"')
    return "".join(out)


def dot_id(s):
    if s.isascii() and re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", s) and ascii_lower(s) not in DOT_KEYWORDS:
        return s
    if DOT_NUMERAL.fullmatch(s):
        return s
    return dot_quote(s)


def dot_value(x):
    if type(x) is bool:
        return "true" if x else "false"
    if type(x) is int:
        return str(x)
    if type(x) is float:
        r = py_double(x)
        return r if DOT_NUMERAL.fullmatch(r) else dot_quote(r)
    return dot_id(x)


def dot_attrs(a):
    return " [" + ", ".join(f"{dot_id(k)}={dot_value(x)}" for k, x in a.items()) + "]" if a else ""


def dot_write(g):
    out = ["digraph {\n" if g.directed else "graph {\n"]
    if g.gattrs:
        out.append("\tgraph" + dot_attrs(g.gattrs) + ";\n")
    for v, a in zip(g.vertices, g.vattrs):
        out.append("\t" + dot_id(str(v)) + dot_attrs(a) + ";\n")
    op = " -> " if g.directed else " -- "
    for (u, v), a in zip(g.edges, g.eattrs):
        out.append("\t" + dot_id(str(g.vertices[u])) + op + dot_id(str(g.vertices[v])) + dot_attrs(a) + ";\n")
    out.append("}\n")
    return "".join(out)


# ============================================================================ XML subset

XML_NAME = re.compile(r"[A-Za-z_:À-\U0010ffff][A-Za-z0-9_.:\-·À-\U0010ffff]*")
XML_PREDEFINED = {"lt": "<", "gt": ">", "amp": "&", "quot": '"', "apos": "'"}


def xml_char_ok(c):
    o = ord(c)
    return o in (9, 10, 13) or 0x20 <= o <= 0xD7FF or 0xE000 <= o <= 0xFFFD or 0x10000 <= o <= 0x10FFFF


class Element:
    def __init__(self, name, attrs, offset):
        self.name, self.attrs, self.offset = name, attrs, offset
        self.children, self.text, self.has_elements = [], [], False

    @property
    def local(self):
        return self.name.split(":")[-1]


def xml_parse(t):
    """Elements with attributes (dict, with each attribute's offset) and character data. No DTD,
    no entities but the five predefined and character references."""
    n, p = len(t), 0
    for k, c in enumerate(t):
        if not xml_char_ok(c):
            raise ParseError("syntax", k)

    def ref(q):  # t[q] == '&'
        e = t.find(";", q)
        if e < 0:
            raise ParseError("syntax", q)
        name = t[q + 1:e]
        if name.startswith("#x") and re.fullmatch(r"#x[0-9A-Fa-f]+", name):
            code = int(name[2:], 16)
        elif name.startswith("#") and re.fullmatch(r"#[0-9]+", name):
            code = int(name[1:])
        elif name in XML_PREDEFINED:
            return XML_PREDEFINED[name], e + 1
        elif XML_NAME.fullmatch(name):
            raise ParseError("entityNotAllowed", q)
        else:
            raise ParseError("syntax", q)
        if code > 0x10FFFF or not xml_char_ok(chr(code)):
            raise ParseError("invalidValue", q)
        return chr(code), e + 1

    def skip_ws(q):
        while q < n and t[q] in " \t\r\n":
            q += 1
        return q

    def misc(q, allow_decl):
        while True:
            q = skip_ws(q)
            if t.startswith("<!--", q):
                e = t.find("-->", q + 4)
                if e < 0:
                    raise ParseError("unexpectedEndOfInput", q)
                if "--" in t[q + 4:e]:
                    raise ParseError("syntax", q)
                q = e + 3
            elif t.startswith("<?", q):
                e = t.find("?>", q)
                if e < 0:
                    raise ParseError("unexpectedEndOfInput", q)
                m = XML_NAME.match(t, q + 2)
                if not m:
                    raise ParseError("syntax", q)
                if ascii_lower(m.group()) == "xml":
                    raise ParseError("syntax", q)
                q = e + 2
            elif t.startswith("<!DOCTYPE", q):
                raise ParseError("doctypeNotAllowed", q)
            else:
                return q

    # XML declaration: only at offset 0.
    if t.startswith("<?xml") and n > 5 and t[5] in " \t\r\n?":
        e = t.find("?>")
        if e < 0:
            raise ParseError("unexpectedEndOfInput", 0)
        decl = t[5:e]
        # XML's S is space, tab, CR and LF (not every Unicode space, as \s would be).
        m = re.fullmatch(r"[ \t\r\n]+version[ \t\r\n]*=[ \t\r\n]*(['\"])1\.[0-9]+\1"
                         r"([ \t\r\n]+encoding[ \t\r\n]*=[ \t\r\n]*(['\"])([A-Za-z][A-Za-z0-9._\-]*)\3)?"
                         r"([ \t\r\n]+standalone[ \t\r\n]*=[ \t\r\n]*(['\"])(yes|no)\6)?[ \t\r\n]*", decl)
        if not m:
            raise ParseError("syntax", 0)
        if m.group(4) and ascii_lower(m.group(4)) not in ("utf-8", "utf8"):
            raise ParseError("unsupported", 5 + m.start(4))
        p = e + 2
    p = misc(p, True)
    if p >= n:
        raise ParseError("unexpectedEndOfInput", p)
    if t[p] != "<":
        raise ParseError("syntax", p)
    stack, root = [], None
    while True:
        if p >= n:
            raise ParseError("unexpectedEndOfInput", stack[-1].offset if stack else p)
        if t.startswith("<!--", p) or (t.startswith("<?", p) and stack):
            p = misc(p, False) if not stack else _skip_one_misc(t, p)
            continue
        if t.startswith("<![CDATA[", p):
            if not stack:
                raise ParseError("syntax", p)
            e = t.find("]]>", p)
            if e < 0:
                raise ParseError("unexpectedEndOfInput", p)
            stack[-1].text.append(t[p + 9:e])
            p = e + 3
            continue
        if t.startswith("<!DOCTYPE", p):
            raise ParseError("doctypeNotAllowed", p)
        if t.startswith("<!", p):
            raise ParseError("syntax", p)
        if t.startswith("</", p):
            m = XML_NAME.match(t, p + 2)
            if not m:
                raise ParseError("syntax", p + 2)
            q = skip_ws(m.end())
            if q >= n:
                raise ParseError("unexpectedEndOfInput", p)
            if t[q] != ">":
                raise ParseError("syntax", q)
            if not stack or m.group() != stack[-1].name:  # an end tag with no open element too
                raise ParseError("mismatchedTag", p)
            el = stack.pop()
            p = q + 1
            if not stack:
                root = el
                break
            continue
        if t[p] == "<":
            start = p
            m = XML_NAME.match(t, p + 1)
            if not m:
                raise ParseError("syntax", p + 1)
            name, q, attrs = m.group(), m.end(), {}
            while True:
                q2 = skip_ws(q)
                if q2 >= n:
                    raise ParseError("unexpectedEndOfInput", start)
                if t.startswith("/>", q2) or t[q2] == ">":
                    q = q2
                    break
                if q2 == q:
                    raise ParseError("syntax", q2)
                am = XML_NAME.match(t, q2)
                if not am:
                    raise ParseError("syntax", q2)
                aname = am.group()
                q3 = skip_ws(am.end())
                if q3 >= n:
                    raise ParseError("unexpectedEndOfInput", start)
                if t[q3] != "=":
                    raise ParseError("syntax", q3)
                q3 = skip_ws(q3 + 1)
                if q3 >= n:
                    raise ParseError("unexpectedEndOfInput", start)
                quote = t[q3]
                if quote not in "'\"":
                    raise ParseError("syntax", q3)
                q4, val = q3 + 1, []
                while True:
                    if q4 >= n:
                        raise ParseError("unexpectedEndOfInput", start)
                    c = t[q4]
                    if c == quote:
                        break
                    if c == "<":
                        raise ParseError("syntax", q4)
                    if c == "&":
                        s, q4 = ref(q4)
                        val.append(s)
                        continue
                    if c == "\r":
                        val.append(" ")
                        q4 += 2 if t.startswith("\r\n", q4) else 1
                        continue
                    val.append(" " if c in "\t\n" else c)
                    q4 += 1
                if aname in attrs:
                    raise ParseError("duplicateKey", q2)
                attrs[aname] = ("".join(val), q2)
                q = q4 + 1
            el = Element(name, attrs, start)
            if stack:
                stack[-1].children.append(el)
                stack[-1].has_elements = True
            if len(stack) + 1 > MAX_DEPTH:
                raise ParseError("nestingTooDeep", start)
            if t.startswith("/>", q):
                p = q + 2
                if not stack:
                    root = el
                    break
            else:
                stack.append(el)
                p = q + 1
            continue
        # character data
        if not stack:
            raise ParseError("syntax", p)
        e = t.find("<", p)
        e = n if e < 0 else e
        chunk, q = [], p
        while q < e:
            c = t[q]
            if c == "&":
                s, q = ref(q)
                chunk.append(s)
                continue
            if c == "\r":
                chunk.append("\n")
                q += 2 if t.startswith("\r\n", q) else 1
                continue
            if c == ">" and t.startswith("]]>", q - 2):
                raise ParseError("syntax", q - 2)
            chunk.append(c)
            q += 1
        stack[-1].text.append("".join(chunk))
        p = e
    p = misc(p, False)
    if p < n:
        raise ParseError("syntax", p)
    return root


def _skip_one_misc(t, p):
    if t.startswith("<!--", p):
        e = t.find("-->", p + 4)
        if e < 0:
            raise ParseError("unexpectedEndOfInput", p)
        if "--" in t[p + 4:e]:
            raise ParseError("syntax", p)
        return e + 3
    e = t.find("?>", p)
    if e < 0:
        raise ParseError("unexpectedEndOfInput", p)
    m = XML_NAME.match(t, p + 2)
    if not m or ascii_lower(m.group()) == "xml":
        raise ParseError("syntax", p)
    return e + 2


# ============================================================================ GraphML

GML_TYPES = {"boolean", "int", "long", "float", "double", "string"}


def graphml_value(kind, s, offset):
    if kind == "string":
        return s
    v = s.strip(" \t\n\r")
    if kind == "boolean":
        if v in ("true", "1"):
            return True
        if v in ("false", "0"):
            return False
        raise ParseError("invalidValue", offset)
    if kind in ("int", "long"):
        if not INT_DEC.match(v):
            raise ParseError("invalidValue", offset)
        x = int(v)
        if not INT_MIN <= x <= INT_MAX:
            raise ParseError("numberOutOfRange", offset)
        return x
    if v in ("INF", "+INF"):
        return math.inf
    if v == "-INF":
        return -math.inf
    if v == "NaN":
        return math.nan
    if not FLOAT_DEC.match(v):
        raise ParseError("invalidValue", offset)
    x = float(v)
    if math.isinf(x):
        raise ParseError("numberOutOfRange", offset)
    return x


def graphml_read(t, g):
    root = xml_parse(t)
    if root.local != "graphml":
        raise ParseError("syntax", root.offset)
    keys, graphs = {}, []
    for el in root.children:
        if el.local == "key":
            if "id" not in el.attrs:
                raise ParseError("syntax", el.offset)
            kid, off = el.attrs["id"]
            if kid in keys:
                raise ParseError("duplicateKey", off)
            dom = el.attrs.get("for", ("all", 0))[0]
            if dom not in ("graph", "node", "edge", "all", "graphml", "hyperedge", "port", "endpoint"):
                raise ParseError("invalidValue", el.attrs["for"][1])
            name = el.attrs.get("attr.name", (kid, 0))[0]
            kind = el.attrs.get("attr.type", ("string", 0))[0]
            if kind not in GML_TYPES:
                raise ParseError("invalidValue", el.attrs["attr.type"][1])
            default = None
            for c in el.children:
                if c.local == "default":
                    default = graphml_value(kind, "".join(c.text), c.offset)
            keys[kid] = (dom, name, kind, default)
        elif el.local == "graph":
            graphs.append(el)
    if not graphs:
        raise ParseError("syntax", root.offset)
    if len(graphs) > 1:
        raise ParseError("unsupported", graphs[1].offset)
    gr = graphs[0]
    if "edgedefault" not in gr.attrs:
        raise ParseError("syntax", gr.offset)
    ed, off = gr.attrs["edgedefault"]
    ed = ed.strip(" \t\n\r")  # an NMTOKEN enumeration: whitespace collapsed
    if ed not in ("directed", "undirected"):
        raise ParseError("invalidValue", off)
    if (ed == "directed") != g.directed:
        raise ParseError("kindMismatch", gr.offset)

    def data_of(el, dom, children=None):
        out = {}
        for c in (el.children if children is None else children):
            if c.local != "data":
                continue
            if "key" not in c.attrs:
                raise ParseError("syntax", c.offset)
            kid, off = c.attrs["key"]
            if kid not in keys or keys[kid][0] not in (dom, "all"):
                raise ParseError("undeclaredKey", off)
            if c.has_elements:
                continue
            _, name, kind, _ = keys[kid]
            out[name] = graphml_value(kind, "".join(c.text), c.offset)
        for kid, (kdom, name, kind, default) in keys.items():
            if kdom in (dom, "all") and default is not None and name not in out:
                out[name] = default
        return out

    g.gattrs.update(data_of(gr, "graph"))
    edges = []

    def walk(graph_el):
        for el in graph_el.children:
            if el.local == "node":
                if "id" not in el.attrs:
                    raise ParseError("syntax", el.offset)
                nid, off = el.attrs["id"]
                if nid in g.index:
                    raise ParseError("duplicateVertex", off)
                # A node's data and ports come before its nested graph (graphml.xsd); after it they
                # are unsupported.
                before = []
                for c in el.children:
                    if c.local == "graph":
                        break
                    before.append(c)
                for c in before:
                    if c.local == "port":
                        raise ParseError("unsupported", c.offset)
                v = g.vertex(nid)
                g.vattrs[v].update(data_of(el, "node", before))
                # A nested graph (a yEd group's content): its nodes and edges are the graph's.
                nested = False
                for c in el.children:
                    if nested and c.local in ("data", "port"):
                        raise ParseError("unsupported", c.offset)
                    if c.local == "graph":
                        nested = True
                        if "edgedefault" not in c.attrs:
                            raise ParseError("syntax", c.offset)
                        ned, noff = c.attrs["edgedefault"]
                        ned = ned.strip(" \t\n\r")
                        if ned not in ("directed", "undirected"):
                            raise ParseError("invalidValue", noff)
                        if (ned == "directed") != g.directed:
                            raise ParseError("unsupported", c.offset)
                        walk(c)
            elif el.local == "edge":
                for a in ("source", "target"):
                    if a not in el.attrs:
                        raise ParseError("syntax", el.offset)
                for a in ("sourceport", "targetport"):
                    if a in el.attrs:
                        raise ParseError("unsupported", el.attrs[a][1])
                if "directed" in el.attrs:
                    d, off = el.attrs["directed"]
                    d = d.strip(" \t\n\r")  # xs:boolean: true, false, 1, 0, whitespace collapsed
                    if d not in ("true", "false", "1", "0"):
                        raise ParseError("invalidValue", off)
                    if (d in ("true", "1")) != g.directed:
                        raise ParseError("unsupported", off)
                for c in el.children:
                    if c.local == "graph":
                        raise ParseError("unsupported", c.offset)
                edges.append(el)
            elif el.local == "hyperedge":
                raise ParseError("unsupported", el.offset)

    walk(gr)
    for el in edges:
        ends = []
        for a in ("source", "target"):
            name, off = el.attrs[a]
            if name not in g.index:
                raise ParseError("undeclaredVertex", off)
            ends.append(g.index[name])
        p = g.edge(*ends)
        g.eattrs[p].update(data_of(el, "edge"))


def xml_escape_text(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\r", "&#13;")


def xml_escape_attr(s):
    return (s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace('"', "&quot;")
            .replace("\t", "&#9;").replace("\n", "&#10;").replace("\r", "&#13;"))


def graphml_type(x):
    return {bool: "boolean", int: "long", float: "double", str: "string"}[type(x)]


def graphml_text(x):
    if type(x) is bool:
        return "true" if x else "false"
    if type(x) is float:
        if math.isnan(x):
            return "NaN"
        if math.isinf(x):
            return "INF" if x > 0 else "-INF"
        return py_double(x)
    return str(x)


def graphml_write(g):
    keys = {}  # (domain, name) -> [id, type]
    for dom, rows in (("graph", [g.gattrs]), ("node", g.vattrs), ("edge", g.eattrs)):
        for a in rows:
            for k, x in a.items():
                ty = graphml_type(x)
                if (dom, k) not in keys:
                    keys[(dom, k)] = [None, ty]
                elif keys[(dom, k)][1] != ty:
                    pair = {keys[(dom, k)][1], ty}
                    assert pair == {"long", "double"}, "precondition: one type per key"
                    keys[(dom, k)][1] = "double"
    for n, k in enumerate(keys):
        keys[k][0] = f"d{n}"
    out = ['<?xml version="1.0" encoding="UTF-8"?>\n',
           '<graphml xmlns="http://graphml.graphdrawing.org/xmlns" '
           'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
           'xsi:schemaLocation="http://graphml.graphdrawing.org/xmlns '
           'http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd">\n']
    for (dom, name), (kid, ty) in keys.items():
        out.append(f'  <key id="{kid}" for="{dom}" attr.name="{xml_escape_attr(name)}" attr.type="{ty}"/>\n')
    out.append(f'  <graph edgedefault="{"directed" if g.directed else "undirected"}">\n')

    def data(dom, a, indent):
        return [f'{indent}<data key="{keys[(dom, k)][0]}">{xml_escape_text(graphml_text(x))}</data>\n'
                for k, x in a.items()]

    out += data("graph", g.gattrs, "    ")
    for v, a in zip(g.vertices, g.vattrs):
        head = f'    <node id="{xml_escape_attr(str(v))}"'
        if a:
            out += [head + ">\n"] + data("node", a, "      ") + ["    </node>\n"]
        else:
            out.append(head + "/>\n")
    for (u, v), a in zip(g.edges, g.eattrs):
        head = (f'    <edge source="{xml_escape_attr(str(g.vertices[u]))}" '
                f'target="{xml_escape_attr(str(g.vertices[v]))}"')
        if a:
            out += [head + ">\n"] + data("edge", a, "      ") + ["    </edge>\n"]
        else:
            out.append(head + "/>\n")
    out.append("  </graph>\n</graphml>\n")
    return "".join(out)


# ============================================================================ JSON

class JNull:
    pass


class JObj:
    """A JSON object with its key and value offsets."""

    def __init__(self, offset):
        self.offset, self.items = offset, {}


def json_parse(t):
    n = len(t)

    def ws(p):
        while p < n and t[p] in " \t\r\n":
            p += 1
        return p

    def value(p, depth):
        p = ws(p)
        if p >= n:
            raise ParseError("unexpectedEndOfInput", p)
        c = t[p]
        if c in "{[":
            if depth + 1 > MAX_DEPTH:
                raise ParseError("nestingTooDeep", p)
        if c == "{":
            obj, q = JObj(p), ws(p + 1)
            if q < n and t[q] == "}":
                return (obj, p), q + 1
            while True:
                q = ws(q)
                if q >= n:
                    raise ParseError("unexpectedEndOfInput", q)
                if t[q] != '"':
                    raise ParseError("syntax", q)
                (k, koff), q = string(q)
                q = ws(q)
                if q >= n:
                    raise ParseError("unexpectedEndOfInput", q)
                if t[q] != ":":
                    raise ParseError("syntax", q)
                v, q = value(q + 1, depth + 1)
                if k in obj.items:
                    raise ParseError("duplicateKey", koff)
                obj.items[k] = (v, koff)
                q = ws(q)
                if q >= n:
                    raise ParseError("unexpectedEndOfInput", q)
                if t[q] == ",":
                    q += 1
                    continue
                if t[q] == "}":
                    return (obj, p), q + 1
                raise ParseError("syntax", q)
        if c == "[":
            arr, q = [], ws(p + 1)
            if q < n and t[q] == "]":
                return (arr, p), q + 1
            while True:
                v, q = value(q, depth + 1)
                arr.append(v)
                q = ws(q)
                if q >= n:
                    raise ParseError("unexpectedEndOfInput", q)
                if t[q] == ",":
                    q += 1
                    continue
                if t[q] == "]":
                    return (arr, p), q + 1
                raise ParseError("syntax", q)
        if c == '"':
            return string(p)
        for word, v in (("true", True), ("false", False), ("null", JNull)):
            if t.startswith(word, p):
                return (v, p), p + len(word)
        m = re.compile(r"-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?").match(t, p)
        if m and m.end() > p and t[p:m.end()] != "-":
            s = m.group()
            if m.group(2) is None and m.group(3) is None:
                x = int(s)
                if not INT_MIN <= x <= INT_MAX:
                    raise ParseError("numberOutOfRange", p)
                return (x, p), m.end()
            x = float(s)
            if math.isinf(x):
                raise ParseError("numberOutOfRange", p)
            return (x, p), m.end()
        raise ParseError("syntax", p)

    def string(p):
        q, out = p + 1, []
        while True:
            if q >= n:
                raise ParseError("unexpectedEndOfInput", p)
            c = t[q]
            if c == '"':
                return ("".join(out), p), q + 1
            if ord(c) < 0x20:
                raise ParseError("syntax", q)
            if c != "\\":
                out.append(c)
                q += 1
                continue
            if q + 1 >= n:
                raise ParseError("unexpectedEndOfInput", p)
            e = t[q + 1]
            simple = {'"': '"', "\\": "\\", "/": "/", "b": "\b", "f": "\f", "n": "\n", "r": "\r", "t": "\t"}
            if e in simple:
                out.append(simple[e])
                q += 2
                continue
            if e != "u":
                raise ParseError("syntax", q)
            h = t[q + 2:q + 6]
            if not re.fullmatch(r"[0-9A-Fa-f]{4}", h):
                raise ParseError("syntax", q)
            code = int(h, 16)
            if 0xD800 <= code < 0xDC00:
                h2 = t[q + 6:q + 12]
                if re.fullmatch(r"\\u[dD][c-fC-F][0-9A-Fa-f]{2}", h2):
                    code = 0x10000 + ((code - 0xD800) << 10) + (int(h2[2:], 16) - 0xDC00)
                    out.append(chr(code))
                    q += 12
                    continue
                raise ParseError("invalidValue", q)
            if 0xDC00 <= code < 0xE000:
                raise ParseError("invalidValue", q)
            out.append(chr(code))
            q += 6

    v, p = value(0, 0)
    p = ws(p)
    if p < n:
        raise ParseError("syntax", p)
    return v


def node_link_read(t, g):
    (top, off) = json_parse(t)
    if not isinstance(top, JObj):
        raise ParseError("syntax", off)
    items = top.items

    def get(key, default):
        return items[key][0] if key in items else (default, None)

    (directed, doff) = get("directed", False)
    if type(directed) is not bool:
        raise ParseError("invalidValue", doff)
    if directed != g.directed:
        raise ParseError("kindMismatch", doff if doff is not None else off)
    (multigraph, moff) = get("multigraph", True)
    if type(multigraph) is not bool:
        raise ParseError("invalidValue", moff)

    def scalar(v):
        x, xoff = v
        if x is JNull or isinstance(x, (JObj, list)):
            raise ParseError("unsupported", xoff)
        return x

    (gattrs, goff) = get("graph", None)
    if gattrs is not None:
        if not isinstance(gattrs, JObj):
            raise ParseError("invalidValue", goff)
        for k, (v, _) in gattrs.items.items():
            g.gattrs[k] = scalar(v)
    if "nodes" not in items:
        raise ParseError("syntax", off)
    (nodes, noff) = items["nodes"][0]
    if not isinstance(nodes, list):
        raise ParseError("invalidValue", noff)
    if "edges" in items:
        (edges, eoff) = items["edges"][0]
    elif "links" in items:
        (edges, eoff) = items["links"][0]
    else:
        raise ParseError("syntax", off)
    if not isinstance(edges, list):
        raise ParseError("invalidValue", eoff)

    def vid(v):
        x, xoff = v
        if isinstance(x, list):
            # An array id (NetworkX's tuple node): its canonical JSON text, as a string id.
            text = json_id_text(x, xoff)
            if g.vtype is int:
                raise ParseError("invalidVertex", xoff)
            return text, xoff
        if type(x) is int:
            name = x if g.vtype is int else str(x)
        elif type(x) is str and g.vtype is str:
            name = x
        else:
            raise ParseError("invalidVertex" if type(x) in (int, str) else "invalidValue", xoff)
        return name, xoff

    for (node, nodeoff) in nodes:
        if not isinstance(node, JObj):
            raise ParseError("invalidValue", nodeoff)
        if "id" not in node.items:
            raise ParseError("syntax", nodeoff)
        name, xoff = vid(node.items["id"][0])
        if name in g.index:
            raise ParseError("duplicateVertex", xoff)
        v = g.vertex(name)
        for k, (x, _) in node.items.items():
            if k != "id":
                g.vattrs[v][k] = scalar(x)
    merged = {}
    keyed, key_counts = {}, {}  # multigraph: (pair, key) -> position; pair -> number of keys
    for (edge, edgeoff) in edges:
        if not isinstance(edge, JObj):
            raise ParseError("invalidValue", edgeoff)
        ends = []
        for a in ("source", "target"):
            if a not in edge.items:
                raise ParseError("syntax", edgeoff)
            name, xoff = vid(edge.items[a][0])
            if name not in g.index:
                raise ParseError("undeclaredVertex", xoff)
            ends.append(g.index[name])
        k = g.key(*ends)
        if multigraph:
            # NetworkX's node_link_graph: add_edge(u, v, key=d.get("key")); a key already between
            # the pair is that edge (attributes updated), None gets new_edge_key. Python's dict
            # equality: True == 1 == 1.0.
            ky = edge.items["key"][0] if "key" in edge.items else (JNull, None)
            if ky[0] is not JNull:
                ky = scalar(ky)
                if isinstance(ky, float) and ky.is_integer() and INT_MIN <= ky <= INT_MAX:
                    ky = int(ky)
                elif type(ky) is bool:
                    ky = int(ky)
                if isinstance(ky, str):
                    ky = ("s", ky)
            else:
                ky = key_counts.get(k, 0)
                while (k, ky) in keyed:
                    ky += 1
            if (k, ky) in keyed:
                p = keyed[(k, ky)]
            else:
                p = g.edge(*ends)
                keyed[(k, ky)] = p
                key_counts[k] = key_counts.get(k, 0) + 1
        elif k in merged:
            p = merged[k]
        else:
            p = g.edge(*ends)
            merged.setdefault(k, p)
        for kk, (x, _) in edge.items.items():
            if kk not in ("source", "target", "key"):
                g.eattrs[p][kk] = scalar(x)


def json_id_text(items, offset):
    """An array id's canonical JSON text: elements as the writer writes values, ", " between."""
    parts = []
    for x, _ in items:
        if isinstance(x, JObj):
            raise ParseError("invalidValue", offset)
        if isinstance(x, list):
            parts.append(json_id_text(x, offset))
        elif x is JNull:
            parts.append("null")
        else:
            parts.append(json_value(x))
    return "[" + ", ".join(parts) + "]"


def json_str(s):
    out = ['"']
    for c in s:
        o = ord(c)
        if c == '"':
            out.append('\\"')
        elif c == "\\":
            out.append("\\\\")
        elif c in "\n\r\t\b\f":
            out.append({"\n": "\\n", "\r": "\\r", "\t": "\\t", "\b": "\\b", "\f": "\\f"}[c])
        elif o < 0x20 or o > 0x7E:
            if o > 0xFFFF:
                o -= 0x10000
                out.append("\\u%04x\\u%04x" % (0xD800 + (o >> 10), 0xDC00 + (o & 0x3FF)))
            else:
                out.append("\\u%04x" % o)
        else:
            out.append(c)
    out.append('"')
    return "".join(out)


def json_value(x):
    if type(x) is bool:
        return "true" if x else "false"
    if type(x) is int:
        return str(x)
    if type(x) is float:
        assert math.isfinite(x), "precondition: finite"
        return py_double(x)
    return json_str(x)


def has_parallel(g):
    seen = set()
    for u, v in g.edges:
        k = g.key(u, v)
        if k in seen:
            return True
        seen.add(k)
    return False


def node_link_write(g):
    multi = has_parallel(g)
    obj = lambda pairs: "{" + ", ".join(f"{json_str(k)}: {v}" for k, v in pairs) + "}"
    nodes = []
    for v, a in zip(g.vertices, g.vattrs):
        assert "id" not in a
        nodes.append(obj([(k, json_value(x)) for k, x in a.items()] + [("id", json_value(v))]))
    edges, count = [], {}
    for (u, v), a in zip(g.edges, g.eattrs):
        assert not {"source", "target", "key"} & set(a)
        pairs = [(k, json_value(x)) for k, x in a.items()]
        pairs += [("source", json_value(g.vertices[u])), ("target", json_value(g.vertices[v]))]
        if multi:
            k = g.key(u, v)
            pairs.append(("key", str(count.get(k, 0))))
            count[k] = count.get(k, 0) + 1
        edges.append(obj(pairs))
    return obj([("directed", json_value(g.directed)), ("multigraph", json_value(multi)),
                ("graph", obj([(k, json_value(x)) for k, x in g.gattrs.items()])),
                ("nodes", "[" + ", ".join(nodes) + "]"), ("edges", "[" + ", ".join(edges) + "]")])


# ============================================================================ Matrix Market

def lines_of(t):
    """(offset, content) per line; a CR before LF is not content."""
    out, p = [], 0
    while p <= len(t):
        q = t.find("\n", p)
        end = len(t) if q < 0 else q
        content = t[p:end]
        if content.endswith("\r"):
            content = content[:-1]
        if q >= 0 or content:
            out.append((p, content))
        if q < 0:
            break
        p = q + 1
    return out


def tokens_of(off, s):
    return [(off + m.start(), m.group()) for m in re.finditer(r"[^ \t]+", s)]


def mm_real(tok, off):
    low = ascii_lower(tok)
    if re.fullmatch(r"[+-]?(inf|infinity)", low):
        return -math.inf if low.startswith("-") else math.inf
    if re.fullmatch(r"[+-]?nan", low):
        return math.nan
    if not FLOAT_DEC.match(tok):
        raise ParseError("invalidValue", off)
    x = float(tok)
    if math.isinf(x):
        raise ParseError("numberOutOfRange", off)
    return x


def mm_int(tok, off, sign=True):
    if not (INT_DEC.match(tok) if sign else re.fullmatch(r"[0-9]+", tok)):
        raise ParseError("invalidValue" if sign else "syntax", off)
    x = int(tok)
    if not INT_MIN <= x <= INT_MAX:
        raise ParseError("numberOutOfRange", off)
    return x


def mm_max_vertices(t):
    """maximumVertexCount's default: 16 vertices per input byte (after a byte-order mark) plus 4,096."""
    return 16 * len(t.encode()) + 4096


def mm_read(t, g):
    ls = lines_of(t)
    if not ls or not ls[0][1].startswith("%%MatrixMarket"):
        raise ParseError("syntax", 0)
    off, head = ls[0]
    toks = tokens_of(off, head)
    if toks[0][1] != "%%MatrixMarket" or len(toks) != 5:
        raise ParseError("syntax", toks[min(len(toks) - 1, 5)][0] if len(toks) > 5 else off)
    (o1, obj), (o2, fmt), (o3, field), (o4, sym) = [(o, ascii_lower(s)) for o, s in toks[1:]]
    if obj == "vector":
        raise ParseError("unsupported", o1)
    if obj != "matrix":
        raise ParseError("syntax", o1)
    if fmt == "array":
        raise ParseError("unsupported", o2)
    if fmt != "coordinate":
        raise ParseError("syntax", o2)
    if field == "complex":
        raise ParseError("unsupported", o3)
    if field not in ("pattern", "integer", "real"):
        raise ParseError("syntax", o3)
    if sym == "hermitian":
        raise ParseError("unsupported", o4)
    if sym not in ("general", "symmetric", "skew-symmetric"):
        raise ParseError("syntax", o4)
    if sym == "skew-symmetric" and field == "pattern":
        raise ParseError("invalidValue", o4)
    if sym == "general" and not g.directed or sym == "skew-symmetric" and not g.directed:
        raise ParseError("kindMismatch", o4)
    k = 1
    while k < len(ls) and (ls[k][1].startswith("%") or not ls[k][1].strip(" \t")):
        k += 1
    if k >= len(ls):
        raise ParseError("unexpectedEndOfInput", len(t))
    size = tokens_of(*ls[k])
    if len(size) < 3:
        raise ParseError("syntax", ls[k][0] + len(ls[k][1]))
    if len(size) > 3:
        raise ParseError("syntax", size[3][0])
    rows, cols, nnz = [mm_int(s, o, sign=False) for o, s in size]
    if rows != cols:
        raise ParseError("notSquare", size[1][0])
    if rows > mm_max_vertices(t):  # maximumVertexCount's default
        raise ParseError("limitExceeded", size[0][0])
    for i in range(rows):
        g.vertex(i if g.vtype is int else str(i))
    width = 2 if field == "pattern" else 3
    seen = 0
    for off, line in ls[k + 1:]:
        if not line.strip(" \t"):
            continue
        if line.startswith("%"):
            raise ParseError("syntax", off)
        toks = tokens_of(off, line)
        if seen == nnz:
            raise ParseError("entryCountMismatch", off)
        if len(toks) < width:
            raise ParseError("syntax", off + len(line))
        if len(toks) > width:
            raise ParseError("syntax", toks[width][0])
        r, c = [mm_int(s, o, sign=False) for o, s in toks[:2]]
        for (o, _), x in zip(toks, (r, c)):
            if not 1 <= x <= rows:
                raise ParseError("indexOutOfRange", o)
        r, c = r - 1, c - 1
        w = None
        if field == "integer":
            w = mm_int(toks[2][1], toks[2][0])
        elif field == "real":
            w = mm_real(toks[2][1], toks[2][0])
        if sym == "skew-symmetric" and r == c:
            raise ParseError("invalidValue", toks[0][0])
        if sym == "skew-symmetric" and w == INT_MIN:  # its mirror, -w, is not an Int
            raise ParseError("numberOutOfRange", toks[2][0])
        seen += 1
        if sym == "general" or not g.directed:
            arcs = [(r, c, w)]
        elif r == c:
            arcs = [(r, c, w)]
        else:
            arcs = [(r, c, w), (c, r, (-w if sym == "skew-symmetric" else w))]
        for u, v, x in arcs:
            p = g.edge(u, v)
            if x is not None:
                g.eattrs[p]["weight"] = x
    if seen < nnz:
        raise ParseError("entryCountMismatch", len(t))


def mm_real_text(x):
    """SciPy 1.18 (fast_matrix_market): shortest round-trip digits as d[.ddd]E<e>, E<e> omitted
    when e == 0; Infinity, -Infinity, NaN; 0 and -0."""
    if math.isnan(x):
        return "NaN"
    if math.isinf(x):
        return "Infinity" if x > 0 else "-Infinity"
    if x == 0:
        return "-0" if math.copysign(1, x) < 0 else "0"
    sign, digits, exp = decimal.Decimal(repr(x)).as_tuple()
    digits = list(digits)
    while len(digits) > 1 and digits[-1] == 0:
        digits.pop()
        exp += 1
    e = len(digits) - 1 + exp
    mant = str(digits[0]) + ("." + "".join(map(str, digits[1:])) if len(digits) > 1 else "")
    return ("-" if sign else "") + mant + ("" if e == 0 else f"E{e}")


def mm_write(g, weight=None):
    """weight: None (pattern), or a list by edge position of ints (integer) or floats (real)."""
    field = "pattern" if weight is None else ("integer" if all(type(w) is int for w in weight) else "real")
    out = [f"%%MatrixMarket matrix coordinate {field} {'general' if g.directed else 'symmetric'}\n", "%\n",
           f"{len(g.vertices)} {len(g.vertices)} {len(g.edges)}\n"]
    for p, (u, v) in enumerate(g.edges):
        r, c = (u, v) if g.directed else (max(u, v), min(u, v))
        s = f"{r + 1} {c + 1}"
        if field == "integer":
            s += f" {weight[p]}"
        elif field == "real":
            s += " " + mm_real_text(float(weight[p]))
        out.append(s + "\n")
    return "".join(out)


# ============================================================================ edge list, adjacency list

def text_lines(t):
    """(offset, content) with comments (from '#') removed."""
    out = []
    for off, line in lines_of(t):
        h = line.find("#")
        out.append((off, line if h < 0 else line[:h]))
    return out


def lexical(tok):
    """An integer in Int, else a decimal (infinite beyond Double) or inf/infinity/nan as Python's
    float reads them, else the text."""
    if INT_DEC.match(tok):
        x = int(tok)
        if INT_MIN <= x <= INT_MAX:
            return x
    if FLOAT_DEC.match(tok):
        return float(tok)
    if re.fullmatch(r"[+-]?(inf|infinity|nan)", ascii_lower(tok)):
        return float(tok)
    return tok


def list_tokens_of(off, s):
    """Fields of an edge- or adjacency-list line: runs of non-whitespace as str.split() reads it."""
    return [(off + m.start(), m.group()) for m in re.finditer(r"[^\s]+", s)]


def check_delimiter(d):
    """A delimiter is one ASCII scalar that cannot start or continue a field's number or name: not a
    letter, a digit, '.', '+', '-', '#', LF or CR (a precondition)."""
    assert d is None or (len(d) == 1 and d.isascii() and not d.isalnum() and d not in ".+-#\n\r"), \
        "precondition: delimiter"


PY_DECIMAL = re.compile(r"[+-]?(?:[0-9]+\.[0-9]*|\.[0-9]+|[0-9]+)(?:[eE][+-]?[0-9]+)?")
PY_INT = re.compile(r"[+-]?[0-9]+\Z")
PY_WORD = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")


def py_string(t, q):
    """The Python string literal at t[q] (a quote) on one line: (value, end)."""
    quote, out, p, n = t[q], [], q + 1, len(t)
    while True:
        if p >= n or t[p] == "\n":
            raise ParseError("syntax", q)
        c = t[p]
        if c == quote:
            return "".join(out), p + 1
        if c != "\\":
            out.append(c)
            p += 1
            continue
        if p + 1 >= n or t[p + 1] == "\n":
            raise ParseError("syntax", q)
        e = t[p + 1]
        simple = {"\\": "\\", "'": "'", '"': '"', "a": "\a", "b": "\b", "f": "\f", "n": "\n", "r": "\r",
                  "t": "\t", "v": "\v"}
        if e in simple:
            out.append(simple[e])
            p += 2
        elif e in "xuU":
            width = {"x": 2, "u": 4, "U": 8}[e]
            h = t[p + 2:p + 2 + width]
            if not re.fullmatch(r"[0-9A-Fa-f]{%d}" % width, h):
                raise ParseError("syntax", p)
            code = int(h, 16)
            if code > 0x10FFFF or 0xD800 <= code < 0xE000:
                raise ParseError("invalidValue", p)
            out.append(chr(code))
            p += 2 + width
        elif e in "01234567":
            m = re.compile(r"[0-7]{1,3}").match(t, p + 1)
            out.append(chr(int(m.group(), 8)))
            p = m.end()
        else:
            out.append("\\" + e)
            p += 2


def py_dict(t, q, end, eattrs):
    """The Python dict literal at t[q] ('{'), within the line t[:end]; the items go into eattrs in
    order. Returns the offset past its '}'."""
    def blanks(p):
        while p < end and t[p] in " \t":
            p += 1
        return p

    def value(p):
        if p >= end:
            raise ParseError("syntax", p)
        c = t[p]
        if c in "'\"":
            return py_string(t, p)
        if c in "[({":
            raise ParseError("unsupported", p)
        for word, x in (("-inf", -math.inf), ("inf", math.inf), ("nan", math.nan)):
            if t.startswith(word, p) and not (p + len(word) < end and (t[p + len(word)].isalnum() or t[p + len(word)] == "_")):
                return x, p + len(word)
        m = PY_WORD.match(t, p)
        if m and m.end() <= end:
            w = m.group()
            if w == "True":
                return True, m.end()
            if w == "False":
                return False, m.end()
            if w == "None":
                raise ParseError("unsupported", p)
            raise ParseError("syntax", p)
        m = PY_DECIMAL.match(t, p)
        if not m or m.end() > end:
            raise ParseError("syntax", p)
        s = m.group()
        if m.end() < end and t[m.end()] not in " \t,}":
            raise ParseError("syntax", m.end())
        if PY_INT.match(s):
            x = int(s)
            if not INT_MIN <= x <= INT_MAX:
                raise ParseError("numberOutOfRange", p)
            return x, m.end()
        return float(s), m.end()

    p = blanks(q + 1)
    first = True
    while True:
        if p >= end:
            raise ParseError("syntax", p)
        c = t[p]
        if c == "}":
            return p + 1
        if not first:
            raise ParseError("syntax", p)
        if c not in "'\"":
            if c.isalnum() or c in "+-.([{_":
                raise ParseError("unsupported", p)
            raise ParseError("syntax", p)
        key, p = py_string(t, p)
        p = blanks(p)
        if p >= end or t[p] != ":":
            raise ParseError("syntax", p)
        p = blanks(p + 1)
        x, p = value(p)
        eattrs[key] = x
        p = blanks(p)
        if p < end and t[p] == ",":
            p = blanks(p + 1)
            first = True
        else:
            first = False


def edge_list_read(t, g, columns=(), delimiter=None):
    check_delimiter(delimiter)
    width = 2 + len(columns)

    def vertex(tok):
        """An ID's vertex: the text, or for an Int target the decimal Int it spells."""
        off, s = tok
        if g.vtype is int:
            if not INT_DEC.match(s) or not INT_MIN <= int(s) <= INT_MAX:
                raise ParseError("invalidVertex", off)
            return g.vertex(int(s))
        return g.vertex(s)
    for off, raw in lines_of(t):
        h = raw.find("#")
        content = raw if h < 0 else raw[:h]
        if delimiter is None:
            toks = list_tokens_of(off, content)
            if not toks:
                continue
        else:
            if content == "" or (delimiter not in content and content.isspace()):
                continue
            toks, start = [], 0
            for piece in content.split(delimiter):
                toks.append((off + start, piece))
                start += len(piece) + 1
        if not columns and len(toks) >= 3 and toks[2][1].startswith("{"):
            u = vertex(toks[0])
            v = vertex(toks[1])
            attrs = {}
            end = off + len(raw)
            p = py_dict(t, toks[2][0], end, attrs)
            while p < end and t[p] in " \t":
                p += 1
            if p < end and t[p] != "#":
                raise ParseError("syntax", p)
            e = g.edge(u, v)
            for k, x in attrs.items():
                g.eattrs[e][k] = x
            continue
        if len(toks) < width:
            raise ParseError("syntax", off + len(content))
        if len(toks) > width:
            raise ParseError("syntax", toks[width][0])
        u = vertex(toks[0])
        p = g.edge(u, vertex(toks[1]))
        for name, (_, s) in zip(columns, toks[2:]):
            g.eattrs[p][name] = lexical(s)


def adjacency_list_read(t, g):
    for off, line in text_lines(t):
        toks = list_tokens_of(off, line)
        if not toks:
            continue
        u = g.vertex(toks[0][1])
        for _, s in toks[1:]:
            g.edge(u, g.vertex(s))


TOKEN_SAFE = re.compile(r"[^\s#]+\Z")


def token(s):
    assert TOKEN_SAFE.match(s), "precondition: token-safe"
    return s


def delimited_token(s, delimiter):
    assert not ({delimiter, "#", "\n", "\r"} & set(s)), "precondition: token-safe"
    return s


def edge_list_write(g, columns=(), delimiter=None):
    check_delimiter(delimiter)
    tok = token if delimiter is None else (lambda s: delimited_token(s, delimiter))
    out = []
    for (u, v), a in zip(g.edges, g.eattrs):
        parts = [tok(str(g.vertices[u])), tok(str(g.vertices[v]))]
        for c in columns:
            x = a[c]
            assert type(x) is not bool
            parts.append(tok(py_double(x) if type(x) is float else str(x)))
        out.append((delimiter or " ").join(parts) + "\n")
    return "".join(out)


def adjacency_list_write(g):
    rows = [[] for _ in g.vertices]
    for u, v in g.edges:
        rows[u if g.directed else min(u, v)].append(v if g.directed or u <= v else u)
    return "".join(" ".join(token(str(g.vertices[x])) for x in [i] + row) + "\n" for i, row in enumerate(rows))


# ============================================================================ Mermaid

MM_SKIP = {"classDef", "class", "style", "linkStyle", "click"}
MM_UNSUPPORTED = {"subgraph", "end", "direction"}
MM_DIAGRAMS = {"sequenceDiagram", "classDiagram", "stateDiagram", "erDiagram", "gantt", "pie", "journey",
               "gitGraph", "mindmap", "timeline", "quadrantChart", "requirementDiagram", "kanban"}
MM_ID = re.compile(r"[A-Za-z0-9_]+")
MM_SHAPES = [("(((", ")))"), ("((", "))"), ("([", "])"), ("[[", "]]"), ("[(", ")]"), ("{{", "}}"),
             ("[/", "/]"), ("[\\", "\\]"), ("[/", "\\]"), ("[\\", "/]"), ("(", ")"), ("[", "]"),
             ("{", "}"), (">", "]")]
MM_ENTITIES = {"quot": '"', "amp": "&", "lt": "<", "gt": ">"}
MM_LINKS = [  # (regex, directed)
    (re.compile(r"-{2,}[>ox]"), True), (re.compile(r"-{3,}"), False),
    (re.compile(r"-\.+-[>ox]"), True), (re.compile(r"-\.+-"), False),
    (re.compile(r"={2,}[>ox]"), True), (re.compile(r"={3,}"), False)]
MM_TEXT_LINKS = [("--", re.compile(r"-{2,}[>ox]|-{3,}"), "--"), ("-.", re.compile(r"\.+-[>ox]?"), ".-"),
                 ("==", re.compile(r"={2,}[>ox]|={3,}"), "==")]


def mermaid_decode(s):
    def sub(m):
        name = m.group(1)
        if name.isdigit():
            code = int(name)
            if code <= 0x10FFFF and not 0xD800 <= code < 0xE000:
                return chr(code)
            return m.group()
        return MM_ENTITIES.get(name, m.group())
    return re.sub(r"#([A-Za-z]+|[0-9]+);", sub, s)


def mermaid_read(t, g):
    statement = mermaid_reader(t, g)
    n, p = len(t), 0
    if t.startswith("---") and (n == 3 or t[3] in "\r\n"):
        ls = lines_of(t)
        for off, line in ls[1:]:
            if line.rstrip(" \t") == "---":
                p = off + len(line)
                break
        else:
            raise ParseError("unexpectedEndOfInput", 0)

    def sp(q):
        while q < n and t[q] in " \t":
            q += 1
        return q

    def at_end(q):
        return q >= n or t[q] in "\n;" or t.startswith("\r\n", q)

    def end_stmt(q):
        q = sp(q)
        if not at_end(q):
            raise ParseError("syntax", q)
        return q

    def next_stmt(q):  # past one separator: LF, ;, a lone CR, or CR LF as one
        if t.startswith("\r\n", q):
            return q + 2
        return q + 1 if q < n else q

    header = False
    while True:
        p = sp(p)
        while p < n and t[p] in "\r\n;":
            p = sp(p + 1)
        if p >= n:
            break
        if t.startswith("%%", p):
            q = t.find("\n", p)
            p = n if q < 0 else q
            continue
        m = re.compile(r"[A-Za-z]+").match(t, p)
        word = m.group() if m else None
        if not header:
            if word in ("graph", "flowchart"):
                q = sp(m.end())
                d = re.compile(r"(TB|TD|BT|RL|LR)(?![A-Za-z0-9_])").match(t, q)
                if d:
                    q = d.end()
                p = next_stmt(end_stmt(q))
                header = True
                continue
            raise ParseError("unsupported" if word in MM_DIAGRAMS else "syntax", p)
        if word in MM_SKIP and m.end() < n and t[m.end()] in " \t" and MM_ID.match(t[sp(m.end()):sp(m.end()) + 1]):
            # A styling statement names something after its keyword; `style --> B` is a vertex.
            q = t.find("\n", p)
            p = n if q < 0 else q
            continue
        if word in MM_UNSUPPORTED and (m.end() >= n or not MM_ID.match(t[m.end()])):
            raise ParseError("unsupported", p)
        p = next_stmt(statement(p))
    if not header:
        raise ParseError("syntax", p)


def _mermaid_text(t, q, close):
    """Text inside a shape or pipe, from q to `close`: quoted or not."""
    n = len(t)
    if q < n and t[q] == '"':
        e = t.find('"', q + 1)
        if e < 0:
            raise ParseError("unexpectedEndOfInput", q)
        text = t[q + 1:e]
        r = e + 1
        while r < n and t[r] in " \t":
            r += 1
        if not t.startswith(close, r):
            raise ParseError("syntax", r)
        return mermaid_decode(text), r + len(close)
    e = q
    while e < n and not t.startswith(close, e):
        if t[e] in '"\n':
            raise ParseError("syntax", e)
        e += 1
    if e >= n:
        raise ParseError("unexpectedEndOfInput", q)
    return mermaid_decode(t[q:e].strip(" \t")), e + len(close)


def mermaid_reader(t, g):
    """mermaid_read with statements bound to the target."""
    n = len(t)

    def sp(q):
        while q < n and t[q] in " \t":
            q += 1
        return q

    def node(q):
        m = MM_ID.match(t, q)
        if not m:
            raise ParseError("unexpectedEndOfInput" if q >= n else "syntax", q)
        name = m.group()
        if name == "end":
            raise ParseError("unsupported", q)
        v = g.vertex(name if g.vtype is str else int(name))
        q = m.end()
        if t.startswith("@{", q):
            raise ParseError("unsupported", q)
        for open_, close in MM_SHAPES:
            if t.startswith(open_, q):
                label, r = _mermaid_shape(t, q + len(open_), open_)
                g.vattrs[v]["label"] = label
                q = r
                break
        if t.startswith(":::", q):
            c = re.compile(r"[A-Za-z0-9_\-]+").match(t, q + 3)
            if not c:
                raise ParseError("syntax", q + 3)
            q = c.end()
        return v, q

    def group(q):
        vs = []
        while True:
            v, q = node(sp(q))
            vs.append(v)
            r = sp(q)
            if r < n and t[r] == "&":
                q = r + 1
                continue
            return vs, q

    def link(q):
        q = sp(q)
        if q >= n or t[q] in "\r\n;":
            return None, q
        if t[q] == "<" or (t[q] in "ox" and t.startswith(("--", "==", "-."), q + 1)):
            raise ParseError("unsupported", q)
        if t.startswith("~~~", q):
            raise ParseError("unsupported", q)
        for start, closer, search in MM_TEXT_LINKS:
            if t.startswith(start, q) and q + 2 < n and t[q + 2] in " \t":
                r = q + 2
                eol = t.find("\n", r)
                eol = n if eol < 0 else eol
                e = t.find(search, r, eol)
                m = closer.match(t, e) if e >= 0 else None
                if not m:
                    raise ParseError("syntax", q)
                label = mermaid_decode(t[r:e].strip(" \t"))
                return (m.group()[-1] in ">ox", label, q), m.end()
        for rx_, directed in MM_LINKS:
            m = rx_.match(t, q)
            if m:
                r = m.end()
                label = None
                s = sp(r)
                if s < n and t[s] == "|":
                    label, r = _mermaid_text(t, s + 1, "|")
                return (directed, label, q), r
        raise ParseError("syntax", q)

    def statement(q):
        sources, q = group(q)
        while True:
            lk, q = link(q)
            if lk is None:
                return q
            directed, label, off = lk
            if directed != g.directed:
                raise ParseError("kindMismatch", off)
            targets, q = group(q)
            for u in sources:
                for v in targets:
                    p = g.edge(u, v)
                    if label is not None:
                        g.eattrs[p]["label"] = label
            sources = targets

    return statement


def _mermaid_shape(t, q, open_):
    candidates = [c for o, c in MM_SHAPES if o == open_]
    n = len(t)
    if q < n and t[q] == '"':
        e = t.find('"', q + 1)
        if e < 0:
            raise ParseError("unexpectedEndOfInput", q)
        r = e + 1
        while r < n and t[r] in " \t":
            r += 1
        for c in candidates:
            if t.startswith(c, r):
                return mermaid_decode(t[q + 1:e]), r + len(c)
        raise ParseError("syntax", r)
    e = q
    while e < n:
        for c in candidates:
            if t.startswith(c, e):
                return mermaid_decode(t[q:e].strip(" \t")), e + len(c)
        if t[e] in '"\n':
            raise ParseError("syntax", e)
        e += 1
    raise ParseError("unexpectedEndOfInput", q)


MM_KEYWORDS = {"end", "graph", "flowchart", "subgraph", "style", "classDef", "class", "click", "linkStyle", "direction"}


def mermaid_label(s):
    out = []
    for c in s:
        out.append({"#": "#35;", '"': "#quot;", "&": "#amp;", "<": "#lt;", ">": "#gt;",
                    "\n": "#10;", "\r": "#13;"}.get(c, c))
    return '"' + "".join(out) + '"'


def mermaid_write(g):
    def vid(v):
        s = str(v)
        assert re.fullmatch(r"[A-Za-z0-9_]+", s) and s not in MM_KEYWORDS, "precondition: Mermaid id"
        return s
    out = ["flowchart TD\n"]
    for v, a in zip(g.vertices, g.vattrs):
        out.append("    " + vid(v) + (f"[{mermaid_label(a['label'])}]" if "label" in a else "") + "\n")
    op = "-->" if g.directed else "---"
    for (u, v), a in zip(g.edges, g.eattrs):
        lab = f"|{mermaid_label(a['label'])}|" if "label" in a else ""
        out.append(f"    {vid(g.vertices[u])} {op}{lab} {vid(g.vertices[v])}\n")
    return "".join(out)


# ============================================================================ GML

GML_KEY = re.compile(r"[A-Za-z][A-Za-z0-9_]*")
GML_NUMBER = re.compile(r"[+-]?(?:[0-9]+\.[0-9]*|\.[0-9]+|[0-9]+)(?:[eE][+-]?[0-9]+)?")
GML_KEYCHAR = re.compile(r"[A-Za-z0-9_]")


def gml_unescape(s):
    def sub(m):
        text = m.group(0)
        if text[1] == "#":
            code = int(text[3:-1], 16) if text[2] == "x" else int(text[2:-1])
            if code > 0x10FFFF or 0xD800 <= code < 0xE000:
                return text
            return chr(code)
        return {"amp": "&", "lt": "<", "gt": ">", "quot": '"'}[text[1:-1]]
    return re.sub(r"&(?:#[0-9]+|#x[0-9A-Fa-f]+|amp|lt|gt|quot);", sub, s)


class GMLLexer:
    """Tokens on demand: (kind, value, offset, text); kinds key, int, real, string, [, ], eof."""

    def __init__(self, t):
        self.t, self.p = t, 0

    def next(self):
        t, n = self.t, len(self.t)
        p = self.p
        while p < n:
            c = t[p]
            if c in " \t\r\n":
                p += 1
            elif c == "#":
                q = t.find("\n", p)
                p = n if q < 0 else q
            else:
                break
        if p >= n:
            self.p = p
            return ("eof", None, n, "")
        c = t[p]
        if c in "[]":
            self.p = p + 1
            return (c, None, p, c)
        if c == '"':
            q = t.find('"', p + 1)
            if q < 0:
                raise ParseError("unexpectedEndOfInput", p)
            self.boundary(q + 1)
            self.p = q + 1
            return ("string", gml_unescape(t[p + 1:q]), p, t[p:q + 1])
        if c.isascii() and c.isalpha():
            m = GML_KEY.match(t, p)
            self.p = m.end()
            return ("key", m.group(), p, m.group())
        if c in "+-" and t.startswith("INF", p + 1):
            q = p + 4
            self.boundary(q)
            self.p = q
            return ("real", -math.inf if c == "-" else math.inf, p, t[p:q])
        m = GML_NUMBER.match(t, p)
        if not m:
            raise ParseError("syntax", p)
        s = m.group()
        self.boundary(m.end())
        self.p = m.end()
        if re.fullmatch(r"[+-]?[0-9]+", s):
            x = int(s)
            if not INT_MIN <= x <= INT_MAX:
                raise ParseError("numberOutOfRange", p)
            return ("int", x, p, s)
        x = float(s)
        if math.isinf(x):
            raise ParseError("numberOutOfRange", p)
        return ("real", x, p, s)

    def boundary(self, q):
        if q < len(self.t) and GML_KEYCHAR.match(self.t[q]):
            raise ParseError("syntax", q)


def gml_read(t, g):
    lex = GMLLexer(t)

    def value():
        """A value token: scalars as is; INF and NAN keys as doubles."""
        tok = lex.next()
        if tok[0] == "key" and tok[1] in ("INF", "NAN"):
            return ("real", math.inf if tok[1] == "INF" else math.nan, tok[2], tok[1])
        if tok[0] in ("int", "real", "string", "["):
            return tok
        if tok[0] == "eof":
            raise ParseError("unexpectedEndOfInput", tok[2])
        raise ParseError("syntax", tok[2])

    def skip_list(depth, open_offset):
        """The rest of a list whose '[' was read (at depth `depth`)."""
        if depth > MAX_DEPTH:
            raise ParseError("nestingTooDeep", open_offset)
        while True:
            tok = lex.next()
            if tok[0] == "]":
                return
            if tok[0] == "eof":
                raise ParseError("unexpectedEndOfInput", tok[2])
            if tok[0] != "key":
                raise ParseError("syntax", tok[2])
            v = value()
            if v[0] == "[":
                skip_list(depth + 1, v[2])

    def pairs(depth, open_offset):
        """The (key token, value token) pairs of a list whose '[' was read, lists skipped (value '[')
        or handed to `on_list`."""
        if depth > MAX_DEPTH:
            raise ParseError("nestingTooDeep", open_offset)
        while True:
            tok = lex.next()
            if tok[0] == "]":
                return
            if tok[0] == "eof":
                raise ParseError("unexpectedEndOfInput", tok[2])
            if tok[0] != "key":
                raise ParseError("syntax", tok[2])
            yield tok, value()

    def scalar(v):
        return v[1]

    ids, edges = {}, []  # node id -> vertex; edges: (source token, target token, attrs)
    graph_seen = None

    def read_node(node_key, depth, open_offset):
        id_tok = label_tok = None
        attrs = {}
        for k, v in pairs(depth, open_offset):
            if k[1] == "id":
                if id_tok is not None:
                    raise ParseError("duplicateKey", k[2])
                if v[0] != "int":
                    raise ParseError("invalidValue", v[2])
                id_tok = v
            elif k[1] == "label":
                if label_tok is not None:
                    raise ParseError("duplicateKey", k[2])
                if v[0] == "[":
                    raise ParseError("invalidValue", v[2])
                label_tok = v
            elif v[0] == "[":
                skip_list(depth + 1, v[2])
            else:
                attrs[k[1]] = scalar(v)
        if id_tok is None:
            raise ParseError("syntax", node_key[2])
        if id_tok[1] in ids:
            raise ParseError("duplicateVertex", id_tok[2])
        if label_tok is not None:
            name = label_tok[1] if label_tok[0] == "string" else label_tok[3]
            at = label_tok[2]
        else:
            name = str(id_tok[1])
            at = id_tok[2]
        if g.vtype is int:
            raise ParseError("invalidVertex", at)
        if name in g.index:
            raise ParseError("duplicateVertex", at)
        v = g.vertex(name)
        ids[id_tok[1]] = v
        g.vattrs[v].update(attrs)

    def read_edge(edge_key, depth, open_offset):
        ends = {"source": None, "target": None}
        attrs = {}
        for k, v in pairs(depth, open_offset):
            if k[1] in ends:
                if ends[k[1]] is not None:
                    raise ParseError("duplicateKey", k[2])
                if v[0] != "int":
                    raise ParseError("invalidValue", v[2])
                ends[k[1]] = v
            elif v[0] == "[":
                skip_list(depth + 1, v[2])
            else:
                attrs[k[1]] = scalar(v)
        if ends["source"] is None or ends["target"] is None:
            raise ParseError("syntax", edge_key[2])
        edges.append((ends["source"], ends["target"], attrs))

    def read_graph(graph_key, open_offset):
        seen = {}
        for k, v in pairs(1, open_offset):
            name = k[1]
            if name in ("directed", "multigraph"):
                if name in seen:
                    raise ParseError("duplicateKey", k[2])
                if v[0] != "int" or v[1] not in (0, 1):
                    raise ParseError("invalidValue", v[2])
                seen[name] = v
                if name == "directed" and (v[1] == 1) != g.directed:
                    raise ParseError("kindMismatch", v[2])
            elif name in ("node", "edge"):
                if v[0] != "[":
                    raise ParseError("invalidValue", v[2])
                (read_node if name == "node" else read_edge)(k, 2, v[2])
            elif v[0] == "[":
                skip_list(2, v[2])
            else:
                g.gattrs[name] = scalar(v)
        if g.directed and "directed" not in seen:
            raise ParseError("kindMismatch", graph_key[2])
        resolved = []
        for s, d, attrs in edges:
            for tok in (s, d):
                if tok[1] not in ids:
                    raise ParseError("undeclaredVertex", tok[2])
            resolved.append((ids[s[1]], ids[d[1]], attrs))
        for u, v, attrs in resolved:
            p = g.edge(u, v)
            g.eattrs[p].update(attrs)

    while True:
        tok = lex.next()
        if tok[0] == "eof":
            break
        if tok[0] != "key":
            raise ParseError("syntax", tok[2])
        if tok[1] == "graph":
            if graph_seen is not None:
                raise ParseError("unsupported", tok[2])
            graph_seen = tok
            v = value()
            if v[0] != "[":
                raise ParseError("invalidValue", v[2])
            read_graph(tok, v[2])
        else:
            v = value()
            if v[0] == "[":
                skip_list(1, v[2])
    if graph_seen is None:
        raise ParseError("unexpectedEndOfInput", len(t))


def gml_escape(s):
    return re.sub('[^ -~]|[&"]', lambda m: "&#" + str(ord(m.group(0))) + ";", s)


GML_VALID_KEY = re.compile(r"[A-Za-z][0-9A-Za-z_]*\Z")


def gml_value(x):
    if type(x) is bool:
        return "1" if x else "0"
    if type(x) is int:
        return str(x) if -(2 ** 31) <= x < 2 ** 31 else '"' + str(x) + '"'
    if type(x) is float:
        text = repr(x).upper()
        if text == "INF":
            return "+INF"
        e = text.rfind("E")
        if e != -1 and text.find(".", 0, e) == -1:
            text = text[:e] + "." + text[e:]
        return text
    return '"' + gml_escape(x) + '"'


def gml_write(g):
    def attrs(a, indent, reserved):
        out = []
        for k, x in a.items():
            assert GML_VALID_KEY.match(k) and k not in reserved, "WriteError"
            out.append(f"{indent}{k} {gml_value(x)}\n")
        return out
    out = ["graph [\n"]
    if g.directed:
        out.append("  directed 1\n")
    if has_parallel(g):
        out.append("  multigraph 1\n")
    out += attrs(g.gattrs, "  ", {"directed", "multigraph", "node", "edge"})
    for i, (v, a) in enumerate(zip(g.vertices, g.vattrs)):
        out += ["  node [\n", f"    id {i}\n", f'    label "{gml_escape(str(v))}"\n']
        out += attrs(a, "    ", {"id", "label"})
        out.append("  ]\n")
    for (u, v), a in zip(g.edges, g.eattrs):
        out += ["  edge [\n", f"    source {u}\n", f"    target {v}\n"]
        out += attrs(a, "    ", {"source", "target"})
        out.append("  ]\n")
    out.append("]\n")
    return "".join(out)


# ============================================================================ Pajek

def pajek_fields(t, off, line):
    """POSIX shlex fields of a line: [(offset of the field's first character, text)]."""
    out, p, n = [], 0, len(line)
    while True:
        while p < n and line[p] in " \t\r":
            p += 1
        if p >= n:
            return out
        start, buf = p, []
        while p < n and line[p] not in " \t\r":
            c = line[p]
            if c == '"':
                q = p + 1
                while True:
                    if q >= n:
                        raise ParseError("syntax", off + p)
                    d = line[q]
                    if d == '"':
                        break
                    if d == "\\" and q + 1 < n and line[q + 1] in '"\\':
                        buf.append(line[q + 1])
                        q += 2
                        continue
                    buf.append(d)
                    q += 1
                p = q + 1
            elif c == "'":
                q = line.find("'", p + 1)
                if q < 0:
                    raise ParseError("syntax", off + p)
                buf.append(line[p + 1:q])
                p = q + 1
            elif c == "\\":
                if p + 1 >= n:
                    raise ParseError("syntax", off + p)
                buf.append(line[p + 1])
                p += 2
            else:
                buf.append(c)
                p += 1
        out.append((off + start, "".join(buf)))


def pajek_number(tok, off):
    low = ascii_lower(tok)
    if FLOAT_DEC.match(tok) or re.fullmatch(r"[+-]?(inf|infinity|nan)", low):
        return float(tok)
    raise ParseError("invalidValue", off)


def pajek_read(t, g, maximumVertexCount=None):
    bound = mm_max_vertices(t) if maximumVertexCount is None else maximumVertexCount
    section = None  # None, "vertices", "arcs", "edges", "arcslist", "edgeslist"
    n = None
    vertex_lines = {}  # number -> (label, label offset, attrs list)
    num2v = None
    count_offset = None

    def finish_vertices():
        nonlocal num2v
        num2v = [None] * (n + 1)
        for k in range(1, n + 1):
            label = vertex_lines[k][0] if k in vertex_lines else str(k)
            num2v[k] = g.vertex(label)
        order = sorted(vertex_lines.items(), key=lambda kv: kv[1][3])
        for k, (_, _, attrs, _) in order:
            for key, x in attrs:
                g.vattrs[num2v[k]][key] = x

    def index(tok, off):
        if not INT_DEC.match(tok):
            raise ParseError("syntax", off)
        x = int(tok)
        if not 1 <= x <= n:
            raise ParseError("indexOutOfRange", off)
        return x

    def pairs_of(fields):
        out = []
        for j in range(0, len(fields), 2):
            if j + 1 >= len(fields):
                raise ParseError("syntax", fields[j][0])
            out.append((fields[j][1], fields[j + 1][1]))
        return out

    for off, line in lines_of(t):
        stripped = line.lstrip(" \t\r")
        lead = off + len(line) - len(stripped)
        if not stripped or stripped.startswith("%"):
            continue
        if stripped.startswith("*"):
            m = re.match(r"[^ \t\r]*", stripped)
            word = ascii_lower(m.group())
            kw_end = lead + m.end()
            if word == "*network":
                rest = line[kw_end - off:].lstrip(" \t\r").rstrip(" \t\r")
                g.gattrs["name"] = rest
                continue
            if word == "*vertices":
                if n is not None:
                    raise ParseError("unsupported", lead)
                toks = tokens_of(kw_end, line[kw_end - off:])
                if not toks:
                    raise ParseError("syntax", off + len(line))
                if len(toks) > 2:
                    raise ParseError("syntax", toks[2][0])
                for o, s in toks:
                    if not re.fullmatch(r"[0-9]+", s):
                        raise ParseError("syntax", o)
                    if int(s) > INT_MAX:
                        raise ParseError("numberOutOfRange", o)
                n = int(toks[0][1])
                count_offset = toks[0][0]
                if n > bound:
                    raise ParseError("limitExceeded", count_offset)
                section = "vertices"
                continue
            kinds = {"*arcs": True, "*edges": False, "*arcslist": True, "*edgeslist": False}
            if word in kinds:
                if n is None:
                    raise ParseError("syntax", lead)
                if section == "vertices":
                    finish_vertices()
                if kinds[word] != g.directed:
                    raise ParseError("kindMismatch", lead)
                section = word[1:]
                continue
            raise ParseError("unsupported", lead)
        fields = pajek_fields(t, off, line)
        if section is None:
            raise ParseError("syntax", lead)
        if section == "vertices":
            k = index(fields[0][1], fields[0][0])
            if k in vertex_lines:
                raise ParseError("duplicateVertex", fields[0][0])
            label, loff = (fields[1][1], fields[1][0]) if len(fields) > 1 else (str(k), fields[0][0])
            attrs = []
            if len(fields) > 2:
                attrs.append(("x", pajek_number(fields[2][1], fields[2][0])))
            if len(fields) > 3:
                attrs.append(("y", pajek_number(fields[3][1], fields[3][0])))
            if len(fields) > 4:
                attrs.append(("shape", fields[4][1]))
            attrs += pairs_of(fields[5:])
            vertex_lines[k] = (label, loff, attrs, off)
        elif section in ("arcs", "edges"):
            if len(fields) < 2:
                raise ParseError("syntax", off + len(line))
            u = index(fields[0][1], fields[0][0])
            v = index(fields[1][1], fields[1][0])
            attrs = []
            if len(fields) > 2:
                attrs.append(("weight", pajek_number(fields[2][1], fields[2][0])))
            attrs += pairs_of(fields[3:])
            p = g.edge(num2v[u], num2v[v])
            for key, x in attrs:
                g.eattrs[p][key] = x
        else:
            u = index(fields[0][1], fields[0][0])
            for o, s in fields[1:]:
                v = index(s, o)
                g.edge(num2v[u], num2v[v])
    if section == "vertices":
        finish_vertices()


def pajek_quote(s):
    if s == "" or any(c.isspace() or c in "\"\\'" for c in s):
        return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'
    return s


def pajek_text(x):
    if type(x) is bool:
        return "true" if x else "false"
    if type(x) is float:
        return py_double(x)
    return str(x)


def pajek_write(g):
    out = [f"*vertices {len(g.vertices)}\n"]
    for i, (v, a) in enumerate(zip(g.vertices, g.vattrs), 1):
        assert "\n" not in str(v)
        for k in ("x", "y", "weight"):
            assert k not in a or type(a[k]) in (int, float), "WriteError invalidValue"
        x = pajek_text(a.get("x", 0.0))
        y = pajek_text(a.get("y", 0.0))
        shape = pajek_quote(pajek_text(a.get("shape", "ellipse")))
        s = f"{i} {pajek_quote(str(v))} {x} {y} {shape}"
        for k, val in a.items():
            if k not in ("x", "y", "shape"):
                s += f" {pajek_quote(k)} {pajek_quote(pajek_text(val))}"
        out.append(s + "\n")
    out.append("*arcs\n" if g.directed else "*edges\n")
    for (u, v), a in zip(g.edges, g.eattrs):
        s = f"{u + 1} {v + 1} {pajek_text(a.get('weight', 1.0))}"
        for k, val in a.items():
            if k != "weight":
                s += f" {pajek_quote(k)} {pajek_quote(pajek_text(val))}"
        out.append(s + "\n")
    return "".join(out)


# ============================================================================ graph6, sparse6, digraph6

def nauty_data(t, p, header):
    """After an optional header at p: (start of N, end of data, offset of the line feed or None)."""
    if t.startswith(header, p):
        p += len(header)
    lf = t.find("\n", p)
    end = len(t) if lf < 0 else lf
    if lf >= 0 and end > p and t[end - 1] == "\r":
        end -= 1
    return p, end, lf


def nauty_byte(t, q):
    o = ord(t[q])
    if not 63 <= o <= 126:
        raise ParseError("syntax", q)
    return o - 63


def nauty_size(t, p, end):
    """N(n) at p: (n, offset past it)."""
    def need(q):
        if q >= end:
            raise ParseError("unexpectedEndOfInput", end)
        return nauty_byte(t, q)
    b = need(p)
    if b < 63:
        return b, p + 1
    b1 = need(p + 1)
    if b1 < 63:
        n = 0
        for q in range(p + 1, p + 4):
            n = n << 6 | need(q)
        return n, p + 4
    n = 0
    for q in range(p + 2, p + 8):
        n = n << 6 | need(q)
    return n, p + 8


def nauty_trailing(t, lf):
    if lf is not None and lf >= 0 and lf + 1 < len(t):
        raise ParseError("syntax", lf + 1)


def nauty_bits(t, start, count):
    bits = []
    for q in range(start, start + count):
        b = ord(t[q]) - 63
        bits += [(b >> s) & 1 for s in range(5, -1, -1)]
    return bits


def nauty_dense(t, g, header, lead, bit_count, pair):
    p, end, lf = nauty_data(t, 0, header)
    if lead is not None:
        if p >= end:
            raise ParseError("unexpectedEndOfInput", end)
        if t[p] != lead:
            raise ParseError("syntax", p)
        p += 1
    size_at = p
    n, p = nauty_size(t, p, end)
    m = bit_count(n)
    needed = (m + 5) // 6
    for q in range(p, min(end, p + needed)):
        nauty_byte(t, q)
    if end - p < needed:
        raise ParseError("unexpectedEndOfInput", end)
    if end - p > needed:
        raise ParseError("syntax", p + needed)
    bits = nauty_bits(t, p, needed)
    if any(bits[m:]):
        raise ParseError("invalidValue", p + needed - 1)
    nauty_trailing(t, lf)
    for i in range(n):
        g.vertex(i if g.vtype is int else str(i))
    for k in range(m):
        if bits[k]:
            g.edge(*pair(n, k))


def graph6_pairs(n):
    return [(i, j) for j in range(1, n) for i in range(j)]


def graph6_read(t, g):
    cache = {}

    def pair(n, k):
        if n not in cache:
            cache[n] = graph6_pairs(n)
        return cache[n][k]
    nauty_dense(t, g, ">>graph6<<", None, lambda n: n * (n - 1) // 2, pair)


def digraph6_read(t, g):
    nauty_dense(t, g, ">>digraph6<<", "&", lambda n: n * n, lambda n, k: divmod(k, n))


def sparse6_k(n):
    return max(n - 1, 0).bit_length()


def sparse6_read(t, g, maximumVertexCount=None):
    bound = mm_max_vertices(t) if maximumVertexCount is None else maximumVertexCount
    p, end, lf = nauty_data(t, 0, ">>sparse6<<")
    if p >= end:
        raise ParseError("unexpectedEndOfInput", end)
    if t[p] == ";":
        raise ParseError("unsupported", p)
    if t[p] != ":":
        raise ParseError("syntax", p)
    p += 1
    size_at = p
    n, p = nauty_size(t, p, end)
    if n > bound:
        raise ParseError("limitExceeded", size_at)
    for q in range(p, end):
        nauty_byte(t, q)
    nauty_trailing(t, lf)
    for i in range(n):
        g.vertex(i if g.vtype is int else str(i))
    k = sparse6_k(n)
    bits = nauty_bits(t, p, end - p)
    i, v = 0, 0
    while i + 1 + k <= len(bits):
        b = bits[i]
        x = 0
        for s in bits[i + 1:i + 1 + k]:
            x = x << 1 | s
        i += 1 + k
        if b:
            v += 1
        if x >= n or v >= n:
            break
        if x > v:
            v = x
        else:
            g.edge(x, v)


def nauty_n(n):
    if n <= 62:
        return chr(63 + n)
    if n <= 258047:
        return "~" + "".join(chr(63 + (n >> s & 63)) for s in (12, 6, 0))
    return "~~" + "".join(chr(63 + (n >> s & 63)) for s in (30, 24, 18, 12, 6, 0))


def nauty_pack(bits):
    bits = bits + [0] * (-len(bits) % 6)
    return "".join(chr(63 + sum(b << (5 - s) for s, b in enumerate(bits[q:q + 6]))) for q in range(0, len(bits), 6))


def graph6_write(g, header=False):
    n = len(g.vertices)
    adj = set()
    for u, v in g.edges:
        assert u != v, "WriteError selfLoop"
        k = (min(u, v), max(u, v))
        assert k not in adj, "WriteError parallelEdge"
        adj.add(k)
    bits = [1 if p in adj else 0 for p in graph6_pairs(n)]
    return (">>graph6<<" if header else "") + nauty_n(n) + nauty_pack(bits) + "\n"


def digraph6_write(g, header=False):
    n = len(g.vertices)
    adj = set()
    for u, v in g.edges:
        assert (u, v) not in adj, "WriteError parallelEdge"
        adj.add((u, v))
    bits = [1 if (i, j) in adj else 0 for i in range(n) for j in range(n)]
    return (">>digraph6<<" if header else "") + "&" + nauty_n(n) + nauty_pack(bits) + "\n"


def sparse6_write(g, header=False):
    n = len(g.vertices)
    k = sparse6_k(n)

    def enc(x):
        return [(x >> (k - 1 - s)) & 1 for s in range(k)]
    edges = sorted((max(u, v), min(u, v)) for u, v in g.edges)
    bits, cur = [], 0
    for j, i in edges:
        if j == cur:
            bits += [0] + enc(i)
        elif j == cur + 1:
            cur = j
            bits += [1] + enc(i)
        else:
            cur = j
            bits += [1] + enc(j) + [0] + enc(i)
    pad = -len(bits) % 6
    last = edges[-1][0] if edges else None
    if pad and k < 6 and n == (1 << k) and last == n - 2 and pad >= k + 1:
        bits += [0] + [1] * (pad - 1)
    else:
        bits += [1] * pad
    return (">>sparse6<<" if header else "") + ":" + nauty_n(n) + nauty_pack(bits) + "\n"


# ============================================================================ DIMACS

def dimacs_read(t, g, maximumVertexCount=None):
    bound = mm_max_vertices(t) if maximumVertexCount is None else maximumVertexCount
    fmt = None
    n = m = 0
    seen = 0
    for off, line in lines_of(t):
        toks = tokens_of(off, line)
        if not toks or toks[0][1] == "c":
            continue
        first, foff = toks[0][1], toks[0][0]
        if first == "p":
            if fmt is not None:
                raise ParseError("syntax", foff)
            if len(toks) < 4:
                raise ParseError("syntax", off + len(line))
            if len(toks) > 4:
                raise ParseError("syntax", toks[4][0])
            word, woff = toks[1][1], toks[1][0]
            if word in ("max", "min", "asn", "cut"):
                raise ParseError("unsupported", woff)
            if word not in ("sp", "edge", "col"):
                raise ParseError("syntax", woff)
            if (word == "sp") != g.directed:
                raise ParseError("kindMismatch", woff)
            n = mm_int(toks[2][1], toks[2][0], sign=False)
            m = mm_int(toks[3][1], toks[3][0], sign=False)
            if n > bound:
                raise ParseError("limitExceeded", toks[2][0])
            fmt = word
            for i in range(n):
                g.vertex(i if g.vtype is int else str(i))
            continue
        if first == "n":
            raise ParseError("unsupported", foff)
        letter = "a" if g.directed else "e"
        if fmt is None or first != letter:
            raise ParseError("syntax", foff)
        if seen == m:
            raise ParseError("entryCountMismatch", foff)
        width = 4 if g.directed else 3
        if len(toks) < width:
            raise ParseError("syntax", off + len(line))
        if len(toks) > width:
            raise ParseError("syntax", toks[width][0])
        ends = []
        for o, s in toks[1:3]:
            x = mm_int(s, o, sign=False)
            if not 1 <= x <= n:
                raise ParseError("indexOutOfRange", o)
            ends.append(x - 1)
        w = mm_int(toks[3][1], toks[3][0]) if g.directed else None
        seen += 1
        p = g.edge(*ends)
        if w is not None:
            g.eattrs[p]["weight"] = w
    if fmt is None:
        raise ParseError("unexpectedEndOfInput", len(t))
    if seen < m:
        raise ParseError("entryCountMismatch", len(t))


def dimacs_write(g, weight=None):
    n = len(g.vertices)
    if g.directed:
        out = [f"p sp {n} {len(g.edges)}\n"]
        out += [f"a {u + 1} {v + 1} {weight[p]}\n" for p, (u, v) in enumerate(g.edges)]
    else:
        out = [f"p edge {n} {len(g.edges)}\n"]
        out += [f"e {u + 1} {v + 1}\n" for u, v in g.edges]
    return "".join(out)


# ============================================================================ METIS

def metis_read(t, g, maximumVertexCount=None):
    bound = mm_max_vertices(t) if maximumVertexCount is None else maximumVertexCount
    ls = [(o, s) for o, s in lines_of(t) if not s.startswith("%")]
    k = 0
    while k < len(ls) and not ls[k][1].strip(" \t"):
        k += 1
    if k >= len(ls):
        raise ParseError("unexpectedEndOfInput", len(t))
    off, line = ls[k]
    head = tokens_of(off, line)
    if len(head) < 2:
        raise ParseError("syntax", off + len(line))
    if len(head) > 4:
        raise ParseError("syntax", head[4][0])
    n = mm_int(head[0][1], head[0][0], sign=False)
    m = mm_int(head[1][1], head[1][0], sign=False)
    sizes = vweights = eweights = False
    if len(head) > 2:
        o, s = head[2]
        if not re.fullmatch(r"[01]{1,3}", s):
            raise ParseError("invalidValue", o)
        s = s.rjust(3, "0")
        sizes, vweights, eweights = s[0] == "1", s[1] == "1", s[2] == "1"
    if len(head) > 3:
        o, s = head[3]
        if not re.fullmatch(r"[0-9]+", s):
            raise ParseError("syntax", o)
        if not vweights or int(s) == 0:
            raise ParseError("invalidValue", o)
        if int(s) > 1:
            raise ParseError("unsupported", o)
    if n > bound:
        raise ParseError("limitExceeded", head[0][0])
    for i in range(n):
        g.vertex(i if g.vtype is int else str(i))
    entries = []  # (u, v, w, offset) in document order
    lines = ls[k + 1:]
    for u in range(n):
        if u >= len(lines):
            raise ParseError("unexpectedEndOfInput", len(t))
        off, line = lines[u]
        toks = tokens_of(off, line)
        q = 0

        def field_value(name):
            nonlocal q
            if q >= len(toks):
                raise ParseError("syntax", off + len(line))
            o, s = toks[q]
            q += 1
            if not INT_DEC.match(s):
                raise ParseError("invalidValue", o)
            x = int(s)
            if not INT_MIN <= x <= INT_MAX:
                raise ParseError("numberOutOfRange", o)
            g.vattrs[u][name] = x
        if sizes:
            field_value("size")
        if vweights:
            field_value("weight")
        while q < len(toks):
            o, s = toks[q]
            q += 1
            v = mm_int(s, o, sign=False)
            if not 1 <= v <= n:
                raise ParseError("indexOutOfRange", o)
            v -= 1
            if v == u:
                raise ParseError("invalidValue", o)
            w = None
            if eweights:
                if q >= len(toks):
                    raise ParseError("syntax", off + len(line))
                wo, ws = toks[q]
                q += 1
                w = mm_int(ws, wo)
            entries.append((u, v, w, o))
    for off, line in lines[n:]:
        if line.strip(" \t"):
            raise ParseError("syntax", off + len(line) - len(line.lstrip(" \t")))
    # Mirrors: after every line is read.
    pending = {}
    consumed = set()
    for idx, (u, v, w, o) in enumerate(entries):
        if v > u:
            pending.setdefault((u, v, w), []).append(idx)
        else:
            q = pending.get((v, u, w))
            if not q:
                raise ParseError("invalidValue", o)
            consumed.add(q.pop(0))
    for idx, (u, v, w, o) in enumerate(entries):
        if v > u and idx not in consumed:
            raise ParseError("invalidValue", o)
    count = 0
    for u, v, w, o in entries:
        if v > u:
            p = g.edge(u, v)
            count += 1
            if w is not None:
                g.eattrs[p]["weight"] = w
    if count != m:
        raise ParseError("entryCountMismatch", head[1][0])


def metis_write(g, weight=None):
    n = len(g.vertices)
    rows = [[] for _ in range(n)]
    seen = set()
    for p, (u, v) in enumerate(g.edges):
        assert u != v, "WriteError selfLoop"
        k = (min(u, v), max(u, v))
        assert k not in seen, "WriteError parallelEdge"
        seen.add(k)
        rows[u].append((v, p))
        rows[v].append((u, p))
    out = [f"{n} {len(g.edges)}" + (" 1" if weight is not None else "") + "\n"]
    for row in rows:
        parts = []
        for x, p in row:
            parts.append(str(x + 1))
            if weight is not None:
                parts.append(str(weight[p]))
        out.append(" ".join(parts) + "\n")
    return "".join(out)


# ============================================================================ Cytoscape JSON

def cytoscape_read(t, g):
    (top, off) = json_parse(t)
    if not isinstance(top, JObj):
        raise ParseError("syntax", off)
    items = top.items

    def get(key, default):
        return items[key][0] if key in items else (default, None)

    def scalar(v):
        x, xoff = v
        if x is JNull or isinstance(x, (JObj, list)):
            raise ParseError("unsupported", xoff)
        return x

    (directed, doff) = get("directed", False)
    if type(directed) is not bool:
        raise ParseError("invalidValue", doff)
    if directed != g.directed:
        raise ParseError("kindMismatch", doff if doff is not None else off)
    (multigraph, moff) = get("multigraph", False)
    if type(multigraph) is not bool:
        raise ParseError("invalidValue", moff)
    if "data" in items:
        (data, daoff) = items["data"][0]
        if isinstance(data, JObj):
            for k, (v, _) in data.items.items():
                g.gattrs[k] = scalar(v)
        elif isinstance(data, list):
            for pair, poff in data:
                if not (isinstance(pair, list) and len(pair) == 2 and type(pair[0][0]) is str):
                    raise ParseError("invalidValue", poff)
                g.gattrs[pair[0][0]] = scalar(pair[1])
        else:
            raise ParseError("invalidValue", daoff)
    if "elements" not in items:
        raise ParseError("syntax", off)
    (elements, eloff) = items["elements"][0]
    nodes, edges = [], []
    if isinstance(elements, JObj):
        for key, out in (("nodes", nodes), ("edges", edges)):
            if key in elements.items:
                (arr, aoff) = elements.items[key][0]
                if not isinstance(arr, list):
                    raise ParseError("invalidValue", aoff)
                out += arr
    elif isinstance(elements, list):
        for el, eoff in elements:
            if not isinstance(el, JObj):
                raise ParseError("invalidValue", eoff)
            if "group" in el.items:
                (grp, goff) = el.items["group"][0]
                if grp not in ("nodes", "edges"):
                    raise ParseError("invalidValue", goff)
                (edges if grp == "edges" else nodes).append((el, eoff))
            else:
                d = el.items.get("data")
                is_edge = d is not None and isinstance(d[0][0], JObj) and "source" in d[0][0].items
                (edges if is_edge else nodes).append((el, eoff))
    else:
        raise ParseError("invalidValue", eloff)

    def data_of(el, eoff):
        if not isinstance(el, JObj):
            raise ParseError("invalidValue", eoff)
        if "data" not in el.items:
            raise ParseError("syntax", eoff)
        (d, doff2) = el.items["data"][0]
        if not isinstance(d, JObj):
            raise ParseError("invalidValue", doff2)
        return d, doff2

    def ident(v):
        x, xoff = v
        if type(x) is int:
            return str(x), xoff
        if type(x) is str:
            return x, xoff
        raise ParseError("invalidValue", xoff)

    for el, eoff in nodes:
        d, doff2 = data_of(el, eoff)
        if "id" not in d.items:
            raise ParseError("syntax", doff2)
        name, xoff = ident(d.items["id"][0])
        if name in g.index:
            raise ParseError("duplicateVertex", xoff)
        v = g.vertex(name)
        for k, (x, _) in d.items.items():
            if k != "id":
                g.vattrs[v][k] = scalar(x)
    pending = []
    for el, eoff in edges:
        d, doff2 = data_of(el, eoff)
        ends = []
        for a in ("source", "target"):
            if a not in d.items:
                raise ParseError("syntax", doff2)
            name, xoff = ident(d.items[a][0])
            if name not in g.index:
                raise ParseError("undeclaredVertex", xoff)
            ends.append(g.index[name])
        attrs = {}
        for k, (x, _) in d.items.items():
            if k in ("source", "target") or (k == "key" and multigraph):
                continue
            attrs[k] = scalar(x)
        pending.append((ends, attrs))
    for ends, attrs in pending:
        p = g.edge(*ends)
        g.eattrs[p].update(attrs)


def cytoscape_write(g):
    multi = has_parallel(g)
    obj = lambda pairs: "{" + ", ".join(f"{json_str(k)}: {v}" for k, v in pairs) + "}"
    nodes = []
    for v, a in zip(g.vertices, g.vattrs):
        assert "id" not in a, "WriteError reservedKey"
        pairs = [(k, json_value(x)) for k, x in a.items()] + [("id", json_str(str(v)))]
        for extra in ("value", "name"):
            if extra not in a:
                pairs.append((extra, json_str(str(v))))
        nodes.append(obj([("data", obj(pairs))]))
    edges, count = [], {}
    for (u, v), a in zip(g.edges, g.eattrs):
        assert not {"source", "target", "key"} & set(a), "WriteError reservedKey"
        pairs = [(k, json_value(x)) for k, x in a.items()]
        pairs += [("source", json_str(str(g.vertices[u]))), ("target", json_str(str(g.vertices[v])))]
        if multi:
            k = g.key(u, v)
            pairs.append(("key", str(count.get(k, 0))))
            count[k] = count.get(k, 0) + 1
        edges.append(obj([("data", obj(pairs))]))
    data = "[" + ", ".join(f"[{json_str(k)}, {json_value(x)}]" for k, x in g.gattrs.items()) + "]"
    return obj([("data", data), ("directed", json_value(g.directed)), ("multigraph", json_value(multi)),
                ("elements", obj([("nodes", "[" + ", ".join(nodes) + "]"), ("edges", "[" + ", ".join(edges) + "]")]))])


# ============================================================================ readers table

def reader_for(fmt, **kw):
    if fmt == "edgeList":
        return lambda t, g: edge_list_read(t, g, kw.get("columns", ()), kw.get("delimiter"))
    bounded = {"pajek": pajek_read, "sparse6": sparse6_read, "dimacs": dimacs_read, "metis": metis_read}
    if fmt in bounded:
        return lambda t, g: bounded[fmt](t, g, kw.get("maximumVertexCount"))
    return {"dot": dot_read, "graphML": graphml_read, "nodeLinkJSON": node_link_read,
            "matrixMarket": mm_read, "adjacencyList": adjacency_list_read,
            "mermaid": mermaid_read, "gml": gml_read, "graph6": graph6_read, "digraph6": digraph6_read,
            "cytoscapeJSON": cytoscape_read}[fmt]


TARGETS = {
    "D": ("DirectedPseudograph<String>", True, False, str),
    "DS": ("AdjacencyList<String>", True, True, str),
    "U": ("Pseudograph<String>", False, False, str),
    "US": ("UndirectedAdjacencyList<String>", False, True, str),
    "DI": ("DirectedPseudograph<Int>", True, False, int),
    "UI": ("Pseudograph<Int>", False, False, int),
    "DSI": ("AdjacencyList<Int>", True, True, int),
    "USI": ("UndirectedAdjacencyList<Int>", False, True, int),
}

LABEL = {"dot": "dot", "graphML": "graphML", "nodeLinkJSON": "nodeLinkJSON", "matrixMarket": "matrixMarket",
         "edgeList": "edgeList", "adjacencyList": "adjacencyList", "mermaid": "mermaid", "gml": "gml",
         "pajek": "pajek", "graph6": "graph6", "sparse6": "sparse6", "digraph6": "digraph6", "dimacs": "dimacs",
         "metis": "metis", "cytoscapeJSON": "cytoscapeJSON"}
WRITER = {"dot": "writeDOT(to:)", "graphML": "writeGraphML(to:)", "nodeLinkJSON": "writeNodeLinkJSON(to:)",
          "matrixMarket": "writeMatrixMarket(to:)", "edgeList": "writeEdgeList(to:)",
          "adjacencyList": "writeAdjacencyList(to:)", "mermaid": "writeMermaid(to:)", "gml": "writeGML(to:)",
          "pajek": "writePajek(to:)", "graph6": "writeGraph6(to:)", "sparse6": "writeSparse6(to:)",
          "digraph6": "writeDigraph6(to:)", "dimacs": "writeDIMACS(to:)", "metis": "writeMETIS(to:)",
          "cytoscapeJSON": "writeCytoscapeJSON(to:)"}
PREFIX = {"dot": "DT", "graphML": "GM", "nodeLinkJSON": "NL", "matrixMarket": "MM", "edgeList": "EL",
          "adjacencyList": "AL", "mermaid": "MD"}
GROUP = {"dot": "DOT", "graphML": "GraphML", "nodeLinkJSON": "Node-link JSON", "matrixMarket": "Matrix Market",
         "edgeList": "Edge list", "adjacencyList": "Adjacency list", "mermaid": "Mermaid", "gml": "GML",
         "pajek": "Pajek", "graph6": "graph6", "sparse6": "sparse6", "digraph6": "digraph6", "dimacs": "DIMACS",
         "metis": "METIS", "cytoscapeJSON": "Cytoscape JSON"}


def make_target(code):
    _, directed, simple, vtype = TARGETS[code]
    return Target(directed, simple, vtype)


CASES = []


def R(fmt, target, case, text, **kw):
    CASES.append(dict(kind="read", fmt=fmt, target=target, case=case, text=text, kw=kw))


def W(fmt, case, g, **kw):
    CASES.append(dict(kind="write", fmt=fmt, case=case, graph=g, kw=kw))


def E(*a, **kw):  # error rows read the same way
    R(*a, **kw)


H = '<graphml xmlns="http://graphml.graphdrawing.org/xmlns">'

# ---------------------------------------------------------------- DOT read
R("dot", "D", "empty digraph", "digraph {}")
R("dot", "D", "one edge creates both vertices", "digraph { a -> b }")
R("dot", "D", "edge chain: one edge per hop, attributes on each", "digraph { a -> b -> c [w=1] }")
R("dot", "D", "node statements merge, later value wins", "digraph { a [x=1]; a [y=2, x=3] }")
R("dot", "D", "node defaults apply to vertices created later, also by edges",
  "digraph {\n  a\n  node [shape=box]\n  b\n  a -> c\n}\n")
R("dot", "D", "edge defaults apply to later edges; explicit overrides",
  "digraph { edge [w=1]; a -> b; edge [w=2]; b -> c; c -> d [w=3] }")
R("dot", "D", "graph attributes: ID = ID and graph [ ]", 'digraph { rankdir=LR; graph [label="t"] }')
R("dot", "D", "graph name is not reported", "digraph G { a }")
R("dot", "D", "quoted IDs; \\\" is the only escape", 'digraph { "a b" -> "c\\"d" }')
R("dot", "D", "other backslashes are kept", 'digraph { "a\\nb" }')
R("dot", "D", "backslash-newline continues a quoted string", 'digraph { "ab\\\nc" }')
R("dot", "D", "+ concatenates quoted strings", 'digraph { "x" + "y" -> b }')
R("dot", "D", "HTML string: the text between the outer brackets", "digraph { a [label=<<b>x</b>>] }")
R("dot", "D", "numerals are IDs", "digraph { 1.5 -> -2 -> .5 -> 3. }")
R("dot", "D", "keywords are case-insensitive", "DiGraph { NODE [k=v]; x }")
R("dot", "D", "comments: //, /* */, and # lines", "# preprocessor\ndigraph { // one\n a /* two */ -> b\n}\n")
R("dot", "D", "non-ASCII identifiers", "digraph { é -> 日本 }")
R("dot", "D", "parallel edges and a loop kept", "digraph { a -> b; a -> b [k=2]; a -> a }")
R("dot", "DS", "simple target: a parallel edge is the same edge, attributes merge",
  "digraph { a -> b [x=1]; a -> b [y=2] }")
R("dot", "D", "strict: parallel edges merge", "strict digraph { a -> b [x=1]; a -> b [y=2, x=3] }")
R("dot", "U", "strict graph: b -- a is a -- b; loops allowed", "strict graph { a -- b; b -- a; a -- a }")
R("dot", "U", "undirected", "graph { a -- b -- c; c -- a }")
R("dot", "U", "undirected parallel edges kept", "graph { a -- b; b -- a }")
R("dot", "D", "attribute lists: ; and , separators, several lists", "digraph { a [p=1; q=2, r=3][s=4] }")
R("dot", "D", "a byte-order mark is skipped", "﻿digraph { a }")
R("dot", "D", "statements need no separator", "digraph { a b -> c d }")
E("dot", "D", "graph into a directed target", "graph { a -- b }")
E("dot", "U", "digraph into an undirected target", "digraph { a -> b }")
E("dot", "D", "-- in a digraph", "digraph { a -- b }")
R("dot", "D", "subgraph: its vertices join the graph", "digraph { subgraph s { a } }")
R("dot", "D", "anonymous subgraph as an endpoint: an edge to each of its vertices", "digraph { a -> { b c } }")
R("dot", "D", "port: the tail's port is the edge's tailport", "digraph { a:p -> b }")
E("dot", "D", "a second graph (unsupported)", "digraph { a }\ndigraph { b }")
E("dot", "D", "unterminated quoted string", 'digraph { "a }')
E("dot", "D", "unterminated comment", "digraph { /* a }")
E("dot", "D", "missing closing brace", "digraph { a -> b")
E("dot", "D", "numeral followed by a letter", "digraph { 1a }")
E("dot", "D", "attribute without a value", "digraph { a [k] }")
E("dot", "D", "edge operator with no tail", "digraph { -> b }")
E("dot", "D", "missing graph keyword", "strict { a }")
E("dot", "D", "invalid UTF-8", b"digraph {\n  \xc3\x28 }")
E("dot", "D", "+ before a non-quoted ID", 'digraph { "a" + b }')

# ---------------------------------------------------------------- GraphML read
R("graphML", "D", "nodes and edges in document order",
  H + '<graph edgedefault="directed"><node id="a"/><node id="b"/><edge source="a" target="b"/>'
  '<edge source="b" target="a"/></graph></graphml>')
R("graphML", "U", "undirected", H + '<graph edgedefault="undirected"><node id="a"/><node id="b"/>'
  '<edge source="b" target="a"/></graph></graphml>')
R("graphML", "D", "typed keys",
  H + '<key id="k0" for="node" attr.name="b" attr.type="boolean"/>'
  '<key id="k1" for="node" attr.name="i" attr.type="int"/>'
  '<key id="k2" for="node" attr.name="l" attr.type="long"/>'
  '<key id="k3" for="node" attr.name="f" attr.type="float"/>'
  '<key id="k4" for="node" attr.name="d" attr.type="double"/>'
  '<key id="k5" for="node" attr.name="s" attr.type="string"/>'
  '<graph edgedefault="directed"><node id="a"><data key="k0">true</data><data key="k1">-7</data>'
  '<data key="k2">9223372036854775807</data><data key="k3">0.5</data><data key="k4">1e-3</data>'
  '<data key="k5"> x </data></node><node id="b"><data key="k0">0</data><data key="k4">INF</data>'
  '<data key="k1"> 3 </data></node></graph></graphml>')
R("graphML", "D", "a key's default applies where no data element gives it",
  H + '<key id="c" for="node" attr.name="color" attr.type="string"><default>red</default></key>'
  '<key id="w" for="edge" attr.name="weight" attr.type="double"><default>1.0</default></key>'
  '<graph edgedefault="directed"><node id="a"/><node id="b"><data key="c">blue</data></node>'
  '<edge source="a" target="b"/></graph></graphml>')
R("graphML", "D", "missing attr.type is string; missing attr.name is the key id; for=\"all\"",
  H + '<key id="k"/><graph edgedefault="directed"><node id="a"><data key="k">1</data></node>'
  '<edge source="a" target="a"><data key="k">2</data></edge></graph></graphml>')
R("graphML", "D", "graph data", H + '<key id="n" for="graph" attr.name="name"/><graph edgedefault="directed">'
  '<data key="n">G</data></graph></graphml>')
R("graphML", "D", "edges may come before the nodes they name",
  H + '<graph edgedefault="directed"><edge source="b" target="a"/><node id="a"/><node id="b"/></graph></graphml>')
R("graphML", "D", "parallel edges kept", H + '<graph edgedefault="directed"><node id="a"/><node id="b"/>'
  '<edge source="a" target="b"/><edge source="a" target="b"/></graph></graphml>')
R("graphML", "DS", "simple target: parallel edges merge, last value wins",
  H + '<key id="w" for="edge" attr.name="w" attr.type="int"/><graph edgedefault="directed"><node id="a"/><node id="b"/>'
  '<edge source="a" target="b"><data key="w">1</data></edge><edge source="a" target="b"><data key="w">2</data></edge>'
  '</graph></graphml>')
R("graphML", "D", "declaration, comments, processing instructions, CDATA",
  '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<!-- c -->\n<?app x?>\n' + H +
  '<key id="s" for="node" attr.name="s"/><graph edgedefault="directed"><!-- n --><node id="a">'
  '<data key="s"><![CDATA[<x> & y]]></data></node></graph></graphml>\n<!-- end -->\n')
R("graphML", "D", "predefined entities and character references",
  H + '<key id="s" for="node" attr.name="s"/><graph edgedefault="directed"><node id="&lt;&amp;&#x41;&#66;">'
  '<data key="s">&quot;&apos;&gt;&#233;</data></node></graph></graphml>')
R("graphML", "D", "attribute values: tab and newline become spaces; text: CR LF becomes LF",
  H + '<key id="s" for="node" attr.name="s"/><graph edgedefault="directed"><node id="a\tb\nc&#10;d">'
  '<data key="s">x\r\ny</data></node></graph></graphml>')
R("graphML", "D", "data with element content (yEd) is skipped",
  H + '<key id="g" for="node" yfiles.type="nodegraphics"/><graph edgedefault="directed"><node id="a">'
  '<data key="g"><y:ShapeNode xmlns:y="http://www.yworks.com/xml/graphml"/></data></node></graph></graphml>')
R("graphML", "D", "unknown elements are skipped", H + '<desc>d</desc><graph edgedefault="directed"><desc>x</desc>'
  '<node id="a"><desc>y</desc></node><foo:bar xmlns:foo="urn:x"><node id="z"/></foo:bar></graph></graphml>')
R("graphML", "D", "single-quoted attributes, whitespace in tags",
  "<graphml xmlns='http://graphml.graphdrawing.org/xmlns' ><graph  edgedefault = 'directed' ><node id='a' />"
  "</graph ></graphml>")
R("graphML", "D", "a matching edge directed attribute is accepted",
  H + '<graph edgedefault="directed"><node id="a"/><edge source="a" target="a" directed="true"/></graph></graphml>')
E("graphML", "D", "DOCTYPE (no DTD, so no entity expansion)",
  '<!DOCTYPE g [<!ENTITY e "zz">]>' + H + '<graph edgedefault="directed"/></graphml>')
E("graphML", "D", "an undeclared entity", H + '<graph edgedefault="directed"><node id="&e;"/></graph></graphml>')
E("graphML", "D", "invalid character reference", H + '<graph edgedefault="directed"><node id="&#0;"/></graph></graphml>')
E("graphML", "D", "mismatched end tag", H + '<graph edgedefault="directed"><node id="a"></edge></graph></graphml>')
E("graphML", "D", "unclosed element", H + '<graph edgedefault="directed">')
E("graphML", "D", "edgedefault is required (graphml.xsd)", H + '<graph><node id="a"/></graph></graphml>')
E("graphML", "D", "undirected into a directed target", H + '<graph edgedefault="undirected"/></graphml>')
E("graphML", "D", "edge to an undeclared node", H + '<graph edgedefault="directed"><node id="a"/>'
  '<edge source="a" target="z"/></graph></graphml>')
E("graphML", "D", "duplicate node id", H + '<graph edgedefault="directed"><node id="a"/><node id="a"/></graph></graphml>')
E("graphML", "D", "data with an undeclared key", H + '<graph edgedefault="directed"><node id="a"><data key="k">1</data>'
  '</node></graph></graphml>')
E("graphML", "D", "an edge key used on a node", H + '<key id="k" for="edge"/><graph edgedefault="directed"><node id="a">'
  '<data key="k">1</data></node></graph></graphml>')
E("graphML", "D", "int value that is not an integer", H + '<key id="k" for="node" attr.type="int"/>'
  '<graph edgedefault="directed"><node id="a"><data key="k">1.5</data></node></graph></graphml>')
E("graphML", "D", "long beyond Int64", H + '<key id="k" for="node" attr.type="long"/>'
  '<graph edgedefault="directed"><node id="a"><data key="k">9223372036854775808</data></node></graph></graphml>')
E("graphML", "D", "boolean is true, false, 1 or 0", H + '<key id="k" for="node" attr.type="boolean"/>'
  '<graph edgedefault="directed"><node id="a"><data key="k">True</data></node></graph></graphml>')
R("graphML", "D", "an empty nested graph", H + '<graph edgedefault="directed"><node id="a"><graph edgedefault="directed"/>'
  '</node></graph></graphml>')
E("graphML", "D", "a second graph (unsupported)", H + '<graph edgedefault="directed"/><graph edgedefault="directed"/></graphml>')
E("graphML", "D", "hyperedge (unsupported)", H + '<graph edgedefault="directed"><node id="a"/><hyperedge/></graph></graphml>')
E("graphML", "D", "an edge whose directed differs from edgedefault (unsupported)", H + '<graph edgedefault="directed">'
  '<node id="a"/><edge source="a" target="a" directed="false"/></graph></graphml>')
E("graphML", "D", "encoding other than UTF-8", '<?xml version="1.0" encoding="ISO-8859-1"?>' + H +
  '<graph edgedefault="directed"/></graphml>')
E("graphML", "D", "duplicate attribute", H + '<graph edgedefault="directed" edgedefault="directed"/></graphml>')
E("graphML", "D", "nesting deeper than 64 elements", H + '<graph edgedefault="directed"><node id="a"><desc>' +
  "<x>" * 61 + "</x>" * 61 + "</desc></node></graph></graphml>")
E("graphML", "D", "text after the root element", H + '<graph edgedefault="directed"/></graphml>x')
E("graphML", "D", "root is not graphml", '<graph edgedefault="directed"/>')
E("graphML", "D", "a control character", H + '<graph edgedefault="directed"><node id="a\x01"/></graph></graphml>')

# ---------------------------------------------------------------- node-link JSON read
R("nodeLinkJSON", "UI", "NetworkX's node_link_data(path_graph(3))",
  '{"directed": false, "multigraph": false, "graph": {}, "nodes": [{"id": 0}, {"id": 1}, {"id": 2}], '
  '"edges": [{"source": 0, "target": 1}, {"source": 1, "target": 2}]}')
R("nodeLinkJSON", "D", "string ids, typed attributes",
  '{"directed": true, "multigraph": false, "graph": {"name": "g"}, "nodes": [{"color": "red", "id": "a"}, '
  '{"id": "b", "n": -3, "x": 0.5, "ok": true}], "edges": [{"w": 2.0, "source": "a", "target": "b"}]}')
R("nodeLinkJSON", "D", "integer ids into a String target are their decimal text",
  '{"directed": true, "nodes": [{"id": 10}, {"id": "x"}], "edges": [{"source": 10, "target": "x"}]}')
R("nodeLinkJSON", "D", "multigraph true: parallel edges kept, key ignored",
  '{"directed": true, "multigraph": true, "nodes": [{"id": "a"}, {"id": "b"}], "edges": '
  '[{"source": "a", "target": "b", "key": 0}, {"source": "a", "target": "b", "key": 1, "w": 2}]}')
R("nodeLinkJSON", "D", "multigraph false: parallel edges merge, later attributes win",
  '{"directed": true, "multigraph": false, "nodes": [{"id": "a"}, {"id": "b"}], "edges": '
  '[{"source": "a", "target": "b", "w": 1}, {"source": "a", "target": "b", "w": 2, "c": "x"}]}')
R("nodeLinkJSON", "U", "defaults as NetworkX: directed false, multigraph true",
  '{"nodes": [{"id": "a"}, {"id": "b"}], "edges": [{"source": "a", "target": "b"}, {"source": "b", "target": "a"}]}')
R("nodeLinkJSON", "U", "\"links\" is read when \"edges\" is absent (NetworkX before 3.4)",
  '{"nodes": [{"id": "a"}], "links": [{"source": "a", "target": "a"}]}')
R("nodeLinkJSON", "D", "string escapes and a surrogate pair",
  '{"directed": true, "nodes": [{"id": "\\u00e9\\n\\"\\\\\\/\\ud83d\\ude00"}], "edges": []}')
R("nodeLinkJSON", "D", "unknown top-level members are ignored",
  '{"directed": true, "nodes": [], "edges": [], "extra": [1, {"x": null}]}')
E("nodeLinkJSON", "U", "directed into an undirected target", '{"directed": true, "nodes": [], "edges": []}')
E("nodeLinkJSON", "D", "duplicate object key", '{"directed": true, "directed": true, "nodes": [], "edges": []}')
E("nodeLinkJSON", "D", "duplicate vertex (1 and \"1\" in a String target)",
  '{"directed": true, "nodes": [{"id": 1}, {"id": "1"}], "edges": []}')
E("nodeLinkJSON", "DI", "string id into an Int target",
  '{"directed": true, "nodes": [{"id": "a"}], "edges": []}')
E("nodeLinkJSON", "D", "edge to an undeclared vertex", '{"directed": true, "nodes": [{"id": "a"}], '
  '"edges": [{"source": "a", "target": "b"}]}')
E("nodeLinkJSON", "D", "null attribute (unsupported)", '{"directed": true, "nodes": [{"id": "a", "x": null}], "edges": []}')
E("nodeLinkJSON", "D", "array attribute (unsupported)", '{"directed": true, "nodes": [{"id": "a", "x": [1]}], "edges": []}')
E("nodeLinkJSON", "D", "nesting deeper than 64", '{"directed": true, "nodes": [{"id": "a", "x": ' + "[" * 63 + "]" * 63 +
  "}], \"edges\": []}")
E("nodeLinkJSON", "D", "number overflows Double", '{"directed": true, "graph": {"x": 1e400}, "nodes": [], "edges": []}')
E("nodeLinkJSON", "D", "integer beyond Int64", '{"directed": true, "graph": {"x": 9223372036854775808}, "nodes": [], "edges": []}')
E("nodeLinkJSON", "D", "lone surrogate", '{"directed": true, "nodes": [{"id": "\\ud800"}], "edges": []}')
E("nodeLinkJSON", "D", "trailing comma", '{"directed": true, "nodes": [], "edges": [],}')
E("nodeLinkJSON", "D", "NaN is not JSON", '{"directed": true, "graph": {"x": NaN}, "nodes": [], "edges": []}')
E("nodeLinkJSON", "D", "leading zero", '{"directed": true, "graph": {"x": 01}, "nodes": [], "edges": []}')
E("nodeLinkJSON", "D", "raw control character in a string", '{"directed": true, "nodes": [{"id": "a\tb"}], "edges": []}')
E("nodeLinkJSON", "D", "missing nodes", '{"directed": true, "edges": []}')
E("nodeLinkJSON", "D", "top level is not an object", "[]")
E("nodeLinkJSON", "D", "unterminated string", '{"directed": true, "nodes": [{"id": "a}]}')
E("nodeLinkJSON", "D", "missing id", '{"directed": true, "nodes": [{"x": 1}], "edges": []}')

# ---------------------------------------------------------------- Matrix Market read
MMH = "%%MatrixMarket matrix coordinate "
R("matrixMarket", "DI", "general pattern: an arc per entry, row to column", MMH + "pattern general\n3 3 2\n1 2\n3 1\n")
R("matrixMarket", "DI", "integer weights", MMH + "integer general\n2 2 2\n1 2 -5\n2 2 7\n")
R("matrixMarket", "DI", "real weights; comments, blank lines, CR LF, tabs",
  MMH + "real general\r\n% comment\r\n\r\n3 3 2\r\n1\t2  0.5\r\n\r\n3 3 -1e3\r\n")
R("matrixMarket", "UI", "symmetric into an undirected target: an edge per entry", MMH + "integer symmetric\n3 3 3\n2 1 4\n3 3 1\n3 2 6\n")
R("matrixMarket", "DI", "symmetric into a directed target: both arcs, a diagonal entry once",
  MMH + "integer symmetric\n3 3 2\n2 1 4\n3 3 1\n")
R("matrixMarket", "DI", "skew-symmetric: the mirrored arc has the negated weight", MMH + "real skew-symmetric\n2 2 1\n2 1 1.5\n")
R("matrixMarket", "DI", "vertices 0..<n even without entries", MMH + "pattern general\n4 4 1\n1 2\n")
R("matrixMarket", "DI", "duplicate entries are parallel edges", MMH + "integer general\n2 2 2\n1 2 5\n1 2 7\n")
R("matrixMarket", "DSI", "simple target: duplicate entries merge, last weight wins", MMH + "integer general\n2 2 2\n1 2 5\n1 2 7\n")
R("matrixMarket", "DI", "Infinity and NaN (SciPy writes them)", MMH + "real general\n2 2 3\n1 2 Infinity\n2 1 -inf\n1 1 NaN\n")
R("matrixMarket", "DI", "qualifiers are case-insensitive", "%%MatrixMarket MATRIX Coordinate PATTERN General\n2 2 1\n1 2\n")
R("matrixMarket", "UI", "an upper-triangle entry in a symmetric file", MMH + "pattern symmetric\n3 3 1\n1 3\n")
R("matrixMarket", "DI", "empty matrix", MMH + "pattern general\n0 0 0\n")
R("matrixMarket", "DI", "no newline at the end", MMH + "pattern general\n2 2 1\n2 1")
E("matrixMarket", "DI", "missing banner", "3 3 0\n")
E("matrixMarket", "DI", "banner is case-sensitive (mmio.c)", "%%MATRIXMARKET matrix coordinate pattern general\n1 1 0\n")
E("matrixMarket", "DI", "array format (unsupported)", "%%MatrixMarket matrix array real general\n2 2\n1\n0\n0\n1\n")
E("matrixMarket", "DI", "complex (unsupported)", MMH + "complex general\n1 1 1\n1 1 1 0\n")
E("matrixMarket", "DI", "hermitian (unsupported)", MMH + "real hermitian\n1 1 0\n")
E("matrixMarket", "DI", "vector (unsupported)", "%%MatrixMarket vector coordinate real general\n3 0\n")
E("matrixMarket", "UI", "general into an undirected target", MMH + "pattern general\n2 2 0\n")
E("matrixMarket", "DI", "not square", MMH + "pattern general\n2 3 0\n")
E("matrixMarket", "DI", "index 0", MMH + "pattern general\n2 2 1\n0 1\n")
E("matrixMarket", "DI", "index beyond n", MMH + "pattern general\n2 2 1\n1 3\n")
E("matrixMarket", "DI", "fewer entries than declared", MMH + "pattern general\n2 2 2\n1 2\n")
E("matrixMarket", "DI", "more entries than declared", MMH + "pattern general\n2 2 1\n1 2\n2 1\n")
E("matrixMarket", "DI", "an extra column", MMH + "integer general\n2 2 1\n1 2 5 6\n")
E("matrixMarket", "DI", "a missing value", MMH + "integer general\n2 2 1\n1 2\n")
E("matrixMarket", "DI", "integer field with a fraction", MMH + "integer general\n2 2 1\n1 2 3.5\n")
E("matrixMarket", "DI", "hexadecimal float", MMH + "real general\n2 2 1\n1 2 0x1p3\n")
E("matrixMarket", "DI", "integer value beyond Int64", MMH + "integer general\n2 2 1\n1 2 99999999999999999999\n")
E("matrixMarket", "DI", "a comment after the size line", MMH + "pattern general\n2 2 2\n1 2\n% c\n2 1\n")
E("matrixMarket", "DI", "skew-symmetric diagonal entry", MMH + "real skew-symmetric\n2 2 1\n2 2 1\n")
E("matrixMarket", "DI", "pattern skew-symmetric", MMH + "pattern skew-symmetric\n2 2 0\n")
E("matrixMarket", "DI", "no size line", MMH + "pattern general\n% only\n")
E("matrixMarket", "DI", "signed index", MMH + "pattern general\n2 2 1\n+1 2\n")

# ---------------------------------------------------------------- edge list, adjacency list read
R("edgeList", "D", "two tokens per line; vertices by first appearance", "a b\nb c\nc a\n")
R("edgeList", "D", "comments, blank lines, runs of spaces and tabs, CR LF", "# head\r\na  b # tail\r\n\r\n\tb\tc\r\n")
R("edgeList", "D", "columns: integer, double or string by their text", "a b 1 0.5 x\nb c -2 1e3 3.0x\n",
  columns=["n", "w", "s"])
R("edgeList", "U", "undirected; parallel edges and loops kept", "a b\nb a\na a\n")
R("edgeList", "US", "simple undirected target: b a is a b", "a b\nb a\n")
R("edgeList", "D", "an integer beyond Int64 is a double", "a b 99999999999999999999\n", columns=["w"])
E("edgeList", "D", "one token", "a b\nc\n")
E("edgeList", "D", "an extra token", "a b c\n")
E("edgeList", "D", "a missing column", "a b 1\nb c\n", columns=["w"])
R("adjacencyList", "D", "head, then its successors; a lone head is an isolated vertex", "a b c\nb c\nd\n")
R("adjacencyList", "U", "undirected: each pair as written", "a b c\nb c\n")
R("adjacencyList", "D", "a repeated neighbor is a parallel edge; a loop", "a b b a\n")
R("adjacencyList", "DS", "simple target: a repeated neighbor merges", "a b b\n")
R("adjacencyList", "D", "comments and blank lines", "# c\na b # d\n\nb\n")

# ---------------------------------------------------------------- Mermaid read
R("mermaid", "D", "flowchart with a direction", "flowchart LR\n    A --> B\n")
R("mermaid", "D", "graph keyword, no direction", "graph\nA-->B\n")
R("mermaid", "D", "chain", "flowchart TD\n  A --> B --> C\n")
R("mermaid", "D", "& fans out: every source to every target", "flowchart TD\n  A & B --> C & D\n")
R("mermaid", "D", "shapes give labels; the shape itself is not graph data",
  "flowchart TD\n  A[box] --> B(round)\n  C{decision} --> D((circle))\n  E>flag] --> F[(db)]\n"
  "  G[[sub]] --> H{{hex}}\n  I[/para/] --> J[\\alt\\]\n  K[/trap\\] --> L([stadium])\n  M(((double))) --> A\n")
R("mermaid", "D", "quoted labels and entity codes", 'flowchart TD\n  A["a [b] #quot;c#quot; #35; #9829;"]\n')
R("mermaid", "D", "a later label replaces the earlier one", "flowchart TD\n  A[one]\n  A --> B\n  A[two]\n")
R("mermaid", "D", "edge labels: |text| and text in the link",
  'flowchart TD\n  A -->|yes| B\n  B -- no --> C\n  C -->|"q|r"| A\n')
R("mermaid", "D", "dotted, thick, circle and cross links are directed",
  "flowchart TD\n  A -.-> B\n  B ==> C\n  C --o D\n  D --x A\n  A -. t .-> C\n  B == t ==> D\n  A ---> D\n")
R("mermaid", "U", "open links into an undirected target", "flowchart TD\n  A --- B\n  B -.- C\n  C === A\n  A -- t --- C\n")
R("mermaid", "D", "styling statements, ::: classes and %% comments are skipped",
  "%%{init: {}}%%\nflowchart TD\n  %% note\n  A:::hot --> B\n  classDef hot fill:#f00\n  class A hot\n"
  "  style B stroke:#333\n  click A callback\n  linkStyle 0 stroke:#0f0\n")
R("mermaid", "D", "; separates statements", "flowchart TD; A --> B; B --> C;")
R("mermaid", "D", "front matter is skipped", "---\ntitle: T\n---\nflowchart TD\n  A --> B\n")
R("mermaid", "D", "o right after the dashes is a circle head", "flowchart TD\n  A---oB\n")
E("mermaid", "D", "open link into a directed target", "flowchart TD\n  A --- B\n")
E("mermaid", "U", "arrow into an undirected target", "flowchart TD\n  A --> B\n")
E("mermaid", "D", "subgraph ... end (unsupported)", "flowchart TD\n  subgraph one\n    A --> B\n  end\n")
E("mermaid", "D", "bidirectional link (unsupported)", "flowchart TD\n  A <--> B\n")
E("mermaid", "D", "invisible link (unsupported)", "flowchart TD\n  A ~~~ B\n")
E("mermaid", "D", "@{ } shape syntax (unsupported)", "flowchart TD\n  A@{ shape: rect }\n")
E("mermaid", "D", "another diagram type", "sequenceDiagram\n  A->>B: hi\n")
E("mermaid", "D", "missing header", "A --> B\n")
E("mermaid", "D", "a label cannot span lines", "flowchart TD\n  A[box\n")
E("mermaid", "D", "end is not a vertex id", "flowchart TD\n  A --> end\n")
E("mermaid", "D", "link without a target", "flowchart TD\n  A -->\n")

# ---------------------------------------------------------------- writers
EMPTY_D = graph(True, [], [])
P = graph(True, ["a", "b", "c"], [("a", "b"), ("b", "c")])
ISO = graph(True, ["a", "b", "z"], [("a", "b")])
TYPED = graph(True, ["a", "b"], [("a", "b"), ("b", "b")],
              {"a": {"label": "x y", "n": 3, "x": 2.0, "ok": True}},
              {0: {"weight": 2, "w2": -0.5}, 1: {"weight": 1.5}}, {"title": "G"})
UNDIRECTED = graph(False, ["a", "b", "c"], [("b", "a"), ("a", "a"), ("a", "b"), ("c", "b")])
INTS = graph(False, [0, 1, 2], [(0, 1), (1, 2)])
QUOTING = graph(True, ["node", "1.5", "-x", "é", "a b", 'q"r', "tail\\", "bs\\\nnl", "_ok9"], [("node", "1.5")],
                {"-x": {"k": 1e-05}, "é": {"inf": math.inf}})
ESCAPES = graph(True, ['a&<>"', "t\tn\nr\r"], [('a&<>"', "t\tn\nr\r")],
                {'a&<>"': {"s": "x & <y> \"z\" \r\n"}}, {0: {"s": "\t"}})
MIXED = graph(True, ["a", "b"], [("a", "b"), ("b", "a")], {"a": {"w": 1}}, {0: {"w": 1}, 1: {"w": 2.5}})
SPECIAL = graph(True, ["a"], [], {"a": {"x": math.inf, "y": -math.inf, "z": math.nan, "b": False}})
UNICODE = graph(True, ["é", "😀", "c\u0001"], [("é", "😀")], {"é": {"s": "\b\f/'"}})
MULTI = graph(True, ["a", "b"], [("a", "b"), ("b", "a"), ("a", "b"), ("a", "b")], {}, {1: {"w": 1}})
MULTI_U = graph(False, ["a", "b"], [("a", "b"), ("b", "a")])
MM_D = graph(True, [0, 1, 2], [(1, 0), (0, 1), (2, 0), (2, 1), (2, 2), (2, 0), (0, 2)])
MM_U = graph(False, [0, 1, 2, 3], [(0, 1), (2, 1), (2, 2), (1, 0)])
LABELS = graph(True, ["A", "B", "C"], [("A", "B"), ("B", "C"), ("C", "A")],
               {"A": {"label": 'say "hi" #1 <b> & more'}, "B": {"label": "two\nlines"}}, {0: {"label": "yes|no"}})
LABELS_U = graph(False, ["A", "B"], [("A", "B"), ("B", "B")], {}, {1: {"label": "loop"}})

W("dot", "empty digraph", EMPTY_D)
W("dot", "every vertex, then every edge, in order", ISO)
W("dot", "typed attributes; graph attributes first", TYPED)
W("dot", "undirected, a loop, parallel edges", UNDIRECTED)
W("dot", "Int vertices are numerals", INTS)
W("dot", "quoting: keywords, numerals, non-ASCII, quotes, trailing backslash, backslash before newline", QUOTING)
W("dot", "non-finite doubles and booleans", SPECIAL)
W("graphML", "empty digraph", EMPTY_D)
W("graphML", "nodes without data are empty elements", ISO)
W("graphML", "typed keys: graph, then node, then edge keys, by first appearance", TYPED)
W("graphML", "undirected", UNDIRECTED)
W("graphML", "escaping in ids and data", ESCAPES)
W("graphML", "integer and double values under one key: double", MIXED)
W("graphML", "INF, -INF, NaN, booleans", SPECIAL)
W("nodeLinkJSON", "empty digraph", EMPTY_D)
W("nodeLinkJSON", "path, string ids", P)
W("nodeLinkJSON", "typed attributes", TYPED)
W("nodeLinkJSON", "Int vertices are numbers", INTS)
W("nodeLinkJSON", "parallel edges: multigraph true and NetworkX's keys", MULTI)
W("nodeLinkJSON", "undirected parallel edges: b-a is the second a-b", MULTI_U)
W("nodeLinkJSON", "non-ASCII and control characters are escaped", UNICODE)
W("matrixMarket", "pattern, general, entries in edge order", MM_D)
W("matrixMarket", "integer weights", MM_D, weight=[1, -2, 3, 4, 5, 6, 9223372036854775807])
W("matrixMarket", "real weights: SciPy's number format", MM_D, weight=[1.0, 0.1, 1234.5, -2.0, 1e-7, 1e20, 2.0 ** 60])
W("matrixMarket", "non-finite and signed zero", graph(True, [0, 1], [(0, 1), (1, 0), (0, 0), (1, 1)]),
  weight=[math.inf, math.nan, -0.0, -math.inf])
W("matrixMarket", "undirected: symmetric, lower triangle", MM_U)
W("matrixMarket", "undirected with weights", MM_U, weight=[0.5, 2.0, 3.0, 4.0])
W("matrixMarket", "empty graph", graph(True, [], []))
W("matrixMarket", "isolated vertices count in the size line", graph(True, [0, 1, 2, 3], [(3, 0)]))
W("edgeList", "edges in order; isolated vertices are lost", ISO)
W("edgeList", "columns", TYPED, columns=["weight"])
W("edgeList", "undirected", UNDIRECTED)
W("edgeList", "Int vertices", INTS)
W("adjacencyList", "directed: successors in edge order; isolated vertex alone", graph(
    True, ["a", "b", "c", "d"], [("a", "c"), ("b", "a"), ("a", "b"), ("a", "a")]))
W("adjacencyList", "undirected: each edge on its earlier endpoint's line", UNDIRECTED)
W("adjacencyList", "undirected path", graph(False, ["a", "b", "c", "d"], [("c", "b"), ("a", "b"), ("d", "c")]))
W("mermaid", "directed, vertex and edge labels with escapes", LABELS)
W("mermaid", "undirected", LABELS_U)
W("mermaid", "empty", EMPTY_D)
W("mermaid", "vertices without labels", ISO)

# ---------------------------------------------------------------- GF-226 – GF-231
R("dot", "D", "a non-ASCII digit starts an identifier, not a numeral", "digraph { \u0663 -> x }")
E("graphML", "D", "an end tag with no open element", "</graphml>")
E("nodeLinkJSON", "D", "an id that is neither a string nor an integer", '{"directed": true, "nodes": [{"id": 1.5}], "edges": []}')
E("nodeLinkJSON", "D", "neither edges nor links", '{"directed": true, "nodes": []}')
E("matrixMarket", "DI", "skew-symmetric: a mirrored weight outside Int", MMH + "integer skew-symmetric\n2 2 1\n2 1 -9223372036854775808\n")
R("mermaid", "D", "a lone CR ends a statement", "flowchart TD\n  A\rB --> C\n")

# ---------------------------------------------------------------- GF-232 – GF-256
E("matrixMarket", "DI", "a vertex count above the default maximumVertexCount (16 a byte plus 4,096)", MMH + "pattern general\n16777217 16777217 0\n")
R("nodeLinkJSON", "D", "multigraph: an edge whose key is taken is that edge; no key gets new_edge_key",
  '{"directed": true, "multigraph": true, "nodes": [{"id": "a"}, {"id": "b"}], "edges": ['
  '{"source": "a", "target": "b", "w": 1}, {"source": "a", "target": "b", "key": 1, "w": 2}, '
  '{"source": "a", "target": "b", "key": 0, "w": 3}, {"source": "a", "target": "b", "w": 4}, '
  '{"source": "a", "target": "b", "key": "1", "w": 5}, {"source": "a", "target": "b", "key": true, "w": 6}]}')
R("nodeLinkJSON", "U", "undirected multigraph: b-a under a-b's key is that edge",
  '{"multigraph": true, "nodes": [{"id": "a"}, {"id": "b"}], "edges": ['
  '{"source": "a", "target": "b", "key": 0, "w": 1}, {"source": "b", "target": "a", "key": 0, "w": 2}]}')
R("nodeLinkJSON", "D", "multigraph: a null key is no key",
  '{"directed": true, "multigraph": true, "nodes": [{"id": "a"}], "edges": ['
  '{"source": "a", "target": "a", "key": null, "w": 1}, {"source": "a", "target": "a", "key": 0, "w": 2}]}')
E("nodeLinkJSON", "D", "an array as an edge key",
  '{"directed": true, "multigraph": true, "nodes": [{"id": "a"}], "edges": [{"source": "a", "target": "a", "key": [1]}]}')
R("edgeList", "D", "inf, Infinity, nan and a decimal beyond Double are doubles", "a b inf\nb c -Infinity\nc d nan\nd e 1e999\n",
  columns=["w"])
R("edgeList", "D", "VT, FF, NBSP and other Unicode whitespace separate fields",
  "a\x0bb\nc\x0cd\u00a0\nx\u3000y\u2003\r\n")
E("edgeList", "D", "NBSP between three fields makes three fields", "a\u00a0b\u00a0c\n")
R("adjacencyList", "D", "Unicode whitespace separates neighbours", "a\u00a0b\u2003c\x1fd\n")
R("graphML", "D", "xs:boolean: directed=\"1\" on a directed edge",
  H + '<graph edgedefault="directed"><node id="a"/><edge source="a" target="a" directed="1"/></graph></graphml>')
R("graphML", "U", "xs:boolean: directed=\" 0 \" on an undirected edge",
  H + '<graph edgedefault="undirected"><node id="a"/><edge source="a" target="a" directed=" 0 "/></graph></graphml>')
R("graphML", "D", "edgedefault with whitespace around it",
  H + '<graph edgedefault=" directed\n"><node id="a"/><edge source="a" target="a"/></graph></graphml>')
R("mermaid", "D", "a styling keyword followed by a link or & is a vertex",
  "flowchart TD\n  style --> B\n  class & A --> C\n  style A fill:#f9f\n  class A foo\n")
R("mermaid", "DS", "into a simple target a repeated link merges, its last label winning", "flowchart LR\n  A -->|x| B\n  A -->|y| B\n")
R("mermaid", "US", "into a simple undirected target B --- A is A --- B", "graph TD\n  A --- B\n  B ---|t| A\n")
E("matrixMarket", "DI", "pattern: a third field on an entry", MMH + "pattern general\n2 2 1\n1 2 3\n")
R("nodeLinkJSON", "D", "multigraph: a key-less edge skips keys taken; later keys find it",
  '{"directed": true, "multigraph": true, "nodes": [{"id": "a"}, {"id": "b"}], "edges": ['
  '{"source": "a", "target": "b", "key": 1, "w": 1}, {"source": "a", "target": "b", "w": 2}, '
  '{"source": "a", "target": "b", "key": 0, "w": 3}, {"source": "a", "target": "b", "key": 2, "w": 4}]}')
E("matrixMarket", "DI", "a lone CR inside a field", MMH + "pattern general\n2 2 1\n1\r2 2\n")
E("matrixMarket", "DI", "a comment of several words after the size line", MMH + "pattern general\n2 2 1\n% a b\n1 2\n")
E("matrixMarket", "DI", "an entry cut short before CR LF", MMH + "pattern general\n2 2 1\n1\r\n")
R("edgeList", "D", "# ends a field it touches", "a b#c d\n")
E("edgeList", "D", "one token before CR LF", "a b\r\nc\r\n")
E("graphML", "D", "a vertical tab in text (XML forbids C0 controls)", H + '<graph edgedefault="directed"><node id="a\x0b"/></graph></graphml>')
E("edgeList", "D", "an overlong three-byte sequence", b"a \xe0\x80\xaf\n")
R("nodeLinkJSON", "U", "multigraph: a repeated string key is that edge, in either orientation",
  '{"multigraph": true, "nodes": [{"id": "a"}, {"id": "b"}], "edges": ['
  '{"source": "a", "target": "b", "key": "x", "w": 1}, {"source": "b", "target": "a", "key": "x", "w": 2}, '
  '{"source": "a", "target": "b", "key": 1.5, "w": 3}, {"source": "a", "target": "b", "key": 1.5, "w": 4}]}')

# ---------------------------------------------------------------- GF-257 – GF-259
E("matrixMarket", "DI", "a 69-byte file claiming 2^24 vertices is over the default maximumVertexCount",
  MMH + "pattern general\n16777216 16777216 0\n")
R("nodeLinkJSON", "D", "multigraph: key-less edges after key 2 get new_edge_key 3 and 4; key 3 is the first",
  '{"directed": true, "multigraph": true, "nodes": [{"id": "a"}, {"id": "b"}], "edges": ['
  '{"source": "a", "target": "b", "w": 1}, {"source": "a", "target": "b", "key": 2, "w": 2}, '
  '{"source": "a", "target": "b", "w": 3}, {"source": "a", "target": "b", "w": 4}, '
  '{"source": "a", "target": "b", "key": 3, "w": 5}]}')
R("nodeLinkJSON", "D", "multigraph: key 1 after two key-less edges is the second",
  '{"directed": true, "multigraph": true, "nodes": [{"id": "a"}, {"id": "b"}], "edges": ['
  '{"source": "a", "target": "b", "w": 1}, {"source": "a", "target": "b", "w": 2}, '
  '{"source": "a", "target": "b", "key": 1, "w": 3}]}')


# ---------------------------------------------------------------- GF-260 on: DOT subgraphs and ports
R("dot", "D", "subgraph scope: node and edge defaults set inside stay inside",
  "digraph { node [c=1]; subgraph { node [c=2]; edge [w=x]; a -> b } c; d -> e }")
R("dot", "D", "{ a b } -> { c d }: every tail to every head, tails outer, attributes on each",
  "digraph { { a b } -> { c d } [w=1] }")
R("dot", "D", "a subgraph operand's own edges come before the chain's", "digraph { x -> { a -> b } }")
R("dot", "D", "nested named subgraphs as an operand: every vertex mentioned inside",
  "digraph { subgraph s1 { a subgraph s2 { b } a } -> c }")
R("dot", "D", "graph attributes inside a subgraph are not reported", "digraph { k=1; subgraph { k=2; graph [m=3]; a } }")
R("dot", "D", "a subgraph's edge defaults apply to edges from it, not to a later chain",
  "digraph { subgraph { edge [w=1]; a -> b } -> c }")
R("dot", "D", "ports in a chain: each hop's tail and head port", "digraph { a:p -> b:q:n -> c }")
R("dot", "D", "a port on a node statement is ignored; an explicit tailport wins",
  "digraph { a:p [x=1]; a:p -> b [tailport=s] }")
R("dot", "U", "undirected: a quoted port and a compass point", 'graph { a:"p q" -- b:sw }')
R("dot", "D", "edge defaults come before the ports", "digraph { edge [headport=z, w=1]; a -> b:q }")
R("dot", "D", "strict: an edge from a subgraph merges with an earlier one",
  "strict digraph { a -> b [x=1]; { a } -> b [y=2] }")
R("dot", "D", "64 nested subgraphs", "digraph { " + "{ " * 64 + "a " + "} " * 64 + "}")
E("dot", "D", "65 nested subgraphs", "digraph { " + "{ " * 65 + "a " + "} " * 65 + "}")
E("dot", "D", "a port on a subgraph operand", "digraph { { a }:p -> b }")
E("dot", "D", "subgraph without a body (unsupported)", "digraph { subgraph s; a }")
E("dot", "D", "an unterminated subgraph", "digraph { { a }")
E("dot", "D", "a port without an ID", "digraph { a: -> b }")

# ---------------------------------------------------------------- GraphML nested graphs
YED = ' xmlns:y="http://www.yworks.com/xml/graphml"'
R("graphML", "D", "yEd group: the group node, then its content; edges at any depth",
  '<graphml xmlns="http://graphml.graphdrawing.org/xmlns">'
  '<graph edgedefault="directed"><node id="g" yfiles.foldertype="group"><graph id="g:" edgedefault="directed">'
  '<node id="g::a"/><node id="g::b"/><edge source="g::a" target="g::b"/></graph></node><node id="c"/>'
  '<edge source="c" target="g::a"/></graph></graphml>')
R("graphML", "D", "a group inside a group",
  H + '<graph edgedefault="directed"><node id="g" yfiles.foldertype="group"><graph edgedefault="directed">'
  '<node id="h" yfiles.foldertype="group"><graph edgedefault="directed"><node id="x"/></graph></node>'
  '<node id="y"/></graph></node><edge source="x" target="y"/></graph></graphml>')
R("graphML", "D", "data of a group node and its content; the nested graph's own data is skipped",
  H + '<key id="n" for="node" attr.name="n"/><key id="t" for="graph" attr.name="t"/>'
  '<graph edgedefault="directed"><data key="t">root</data><node id="g" yfiles.foldertype="group">'
  '<data key="n">0</data><graph edgedefault="directed"><data key="t">inner</data><node id="a"><data key="n">1</data>'
  '</node></graph></node></graph></graphml>')
R("graphML", "U", "undirected nested graph; an edge before the nodes it names",
  H + '<graph edgedefault="undirected"><edge source="a" target="b"/><node id="g" yfiles.foldertype="group">'
  '<graph edgedefault="undirected"><node id="a"/></graph></node><node id="b"/></graph></graphml>')
R("graphML", "D", "a nested graph in a node that is not a yEd group",
  H + '<graph edgedefault="directed"><node id="g"><graph edgedefault="directed"><node id="a"/></graph></node>'
  '</graph></graphml>')
E("graphML", "D", "a nested graph without edgedefault",
  H + '<graph edgedefault="directed"><node id="g"><graph><node id="a"/></graph></node></graph></graphml>')
E("graphML", "D", "a nested graph of the other kind (unsupported)",
  H + '<graph edgedefault="directed"><node id="g"><graph edgedefault="undirected"/></node></graph></graphml>')
E("graphML", "D", "data after a node's nested graph (unsupported)",
  H + '<key id="n" for="node" attr.name="n"/><graph edgedefault="directed"><node id="g"><graph edgedefault="directed">'
  '<node id="a"/></graph><data key="n">0</data></node></graph></graphml>')
E("graphML", "D", "a node inside a nested graph declared twice",
  H + '<graph edgedefault="directed"><node id="a"/><node id="g"><graph edgedefault="directed"><node id="a"/>'
  '</graph></node></graph></graphml>')
E("graphML", "D", "a graph inside an edge stays unsupported",
  H + '<graph edgedefault="directed"><node id="a"/><edge source="a" target="a"><graph edgedefault="directed"/>'
  '</edge></graph></graphml>')

# ---------------------------------------------------------------- node-link tuple ids
R("nodeLinkJSON", "D", "array ids (NetworkX tuples) are their canonical JSON text",
  '{"directed": true, "multigraph": false, "graph": {}, "nodes": [{"id": [0, 1]}, {"id": ["a", [1, 2.5]]}], '
  '"edges": [{"source": [0, 1], "target": ["a", [1, 2.5]]}]}')
R("nodeLinkJSON", "U", "an array id written with other spacing is the same id",
  '{"nodes": [{"id": [0,1]}, {"id": [ 1 , 0 ]}], "edges": [{"source": [ 0,1 ], "target": [1,0]}]}')
R("nodeLinkJSON", "D", "empty array, null, booleans, a double and escapes in array ids",
  '{"directed": true, "nodes": [{"id": []}, {"id": [null, true, false, 1e2, "\\u00e9\\""]}], "edges": []}')
E("nodeLinkJSON", "D", "an object inside an array id",
  '{"directed": true, "nodes": [{"id": [1, {"a": 2}]}], "edges": []}')
E("nodeLinkJSON", "DI", "an array id into an Int target", '{"directed": true, "nodes": [{"id": [1, 2]}], "edges": []}')
E("nodeLinkJSON", "D", "an array id and the string of its text are one id",
  '{"directed": true, "nodes": [{"id": [1, 2]}, {"id": "[1, 2]"}], "edges": []}')
E("nodeLinkJSON", "D", "an edge to an array id no node declares",
  '{"directed": true, "nodes": [{"id": [1]}], "edges": [{"source": [1], "target": [2]}]}')

# ---------------------------------------------------------------- edge list: dict data, delimiters
R("edgeList", "D", "NetworkX data=True: a Python dict after u v; {} is no data",
  "a b {'weight': 3, 'color': 'red'}\nb c {}\n")
R("edgeList", "D", "dict values: floats, booleans, inf, nan, signs, a trailing comma",
  "a b {'x': 1.5, \"y\": -2, 'ok': True, 'no': False, 'i': inf, 'm': -inf, 'n': nan, 'e': 1e-05, 'p': +7,}\n")
R("edgeList", "D", "dict string escapes", "a b {'s': 'q\\'\\\"\\\\\\n\\t\\x41\\u00e9\\U0001F600\\101\\0\\q'}\n")
R("edgeList", "D", "a dict string may hold # and the delimiter; a comment may follow the dict",
  "a b {'s': 'x#y z'}  # comment\n")
R("edgeList", "D", "a repeated dict key is reported again, the last value winning", "a b {'w': 1, 'v': 2, 'w': 3}\n")
R("edgeList", "U", "dicts on an undirected list; blanks inside the dict", "a b {  'w' :1 ,'v':  2  }\nb a\n")
E("edgeList", "D", "None in a dict (unsupported)", "a b {'w': None}\n")
E("edgeList", "D", "a list in a dict (unsupported)", "a b {'w': [1, 2]}\n")
E("edgeList", "D", "a non-string dict key (unsupported)", "a b {1: 2}\n")
E("edgeList", "D", "an unterminated dict", "a b {'w': 1\n")
E("edgeList", "D", "text after the dict", "a b {'w': 1} x\n")
E("edgeList", "D", "a dict string not closed on its line", "a b {'w': 'x}\n")
E("edgeList", "D", "a dict integer beyond Int64", "a b {'w': 9223372036854775808}\n")
E("edgeList", "D", "a malformed \\x escape", "a b {'w': '\\x4'}\n")
E("edgeList", "D", "a surrogate escape", "a b {'w': '\\ud800'}\n")
E("edgeList", "D", "a dict with a missing colon", "a b {'w' 1}\n")
E("edgeList", "D", "a bare name in a dict", "a b {'w': x}\n")
E("edgeList", "D", "with columns, a dict is a field like any other", "a b {'w':1}\n", columns=["w"])
R("edgeList", "D", "comma delimiter: fields kept exactly, spaces included", "a,b\n c,d \n", delimiter=",")
E("edgeList", "D", "a delimiter ending the line adds an empty field at the end", "a\tb\t", delimiter="\t")
R("edgeList", "D", "semicolon delimiter with columns", "a;b;1;x y\nb;c;2.5;\n", delimiter=";", columns=["w", "s"])
R("edgeList", "D", "tab delimiter: spaces stay in fields; blank, whitespace and comment lines skipped",
  "a b\tc d\n\n   \n# x\nc d\ta # tail\n", delimiter="\t")
R("edgeList", "D", "empty fields are IDs", ",b\nb,\n", delimiter=",")
R("edgeList", "D", "a dict after delimited endpoints may hold the delimiter", "a,b,{'w': 1, 'x': 2}\n", delimiter=",")
R("edgeList", "DI", "comma-delimited integers into an Int target", "1,2\n2,3\r\n", delimiter=",")
R("edgeList", "US", "a simple target merges b,a into a,b", "a,b,1\nb,a,2\n", delimiter=",", columns=["w"])
E("edgeList", "D", "delimited: too few fields", "a,b\nc\n", delimiter=",")
E("edgeList", "D", "delimited: an extra field", "a,b,c\n", delimiter=",")
E("edgeList", "D", "delimited: a missing column", "a,b,1\nb,c\n", delimiter=",", columns=["w"])

# ---------------------------------------------------------------- GML read
R("gml", "D", "NetworkX's write_gml output",
  'graph [\n  directed 1\n  name "g"\n  node [\n    id 0\n    label "a"\n    color "red"\n  ]\n  node [\n    id 1\n'
  '    label "b"\n  ]\n  edge [\n    source 0\n    target 1\n    weight 2.5\n  ]\n]\n')
R("gml", "U", "undirected by default; nodes named by their labels", 'graph [ node [ id 7 label "x" ] node [ id 3 label "y" ]'
  ' edge [ source 3 target 7 ] ]')
R("gml", "U", "a node without a label is named by its id", "graph [ node [ id 5 ] node [ id 6 label \"six\" ] edge [ source 5 target 6 ] ]")
R("gml", "D", "values: integers, reals, strings, INF, -INF, NAN, 1.E-05",
  'graph [ directed 1 node [ id 0 label "a" i -3 r 2.0 e 1.E-05 s "t" p +INF m -INF q INF n NAN f .5 ] ]')
R("gml", "D", "character references and the four named entities are decoded; others are kept",
  'graph [ directed 1 node [ id 0 label "&#233;&#x41;&amp;&lt;&gt;&quot;&apos;&nbsp;&#xD800;&#1114112;&" ] ]')
R("gml", "D", "lists such as graphics are skipped; top-level keys are ignored; # comments",
  '# made by hand\nCreator "yFiles"\nVersion 2.2\ngraph [\n  directed 1 # a comment\n  node [ id 0 label "a"\n'
  '    graphics [ x 1.0 y 2.0 fill "#FF0000" inner [ deep 1 ] ] w 1 ]\n  edge [ source 0 target 0 graphics [ width 2 ] ]\n]\n')
R("gml", "D", "edges may come before the nodes they name; key is an ordinary attribute",
  'graph [ directed 1 edge [ source 1 target 0 key 4 ] node [ id 0 label "a" ] node [ id 1 label "b" ] ]')
R("gml", "D", "multigraph 1: parallel edges kept", 'graph [ directed 1 multigraph 1 node [ id 0 label "a" ]'
  ' edge [ source 0 target 0 key 0 ] edge [ source 0 target 0 key 1 ] ]')
R("gml", "DS", "simple target: parallel edges merge, last value wins", 'graph [ directed 1 node [ id 0 label "a" ]'
  ' node [ id 1 label "b" ] edge [ source 0 target 1 w 1 ] edge [ source 0 target 1 w 2 ] ]')
R("gml", "US", "simple undirected target: 1-0 is 0-1", 'graph [ node [ id 0 ] node [ id 1 ] edge [ source 0 target 1 ]'
  ' edge [ source 1 target 0 ] ]')
R("gml", "D", "a string may span lines", 'graph [ directed 1 node [ id 0 label "two\nlines" ] ]')
R("gml", "U", "a number as a label is its text", "graph [ node [ id 0 label 1.50 ] node [ id 1 label -7 ] ]")
R("gml", "U", "graph attributes where they are read; a repeated key is reported again",
  'graph [ a 1 node [ id 0 ] b "x" a 2 node [ id 1 c 1 c 2 ] ]')
R("gml", "U", "a byte-order mark, CR LF and tabs", "\ufeffgraph [\r\n\tnode [\r\n\t\tid 0\r\n\t]\r\n]\r\n")
R("gml", "U", "empty graph", "graph [ ]")
R("gml", "U", "directed 0", "graph [ directed 0 node [ id 0 ] ]")
E("gml", "U", "no graph", 'Creator "x"\n')
E("gml", "U", "empty input", "")
E("gml", "U", "a second graph (unsupported)", "graph [ ] graph [ ]")
E("gml", "U", "graph whose value is not a list", "graph 1")
E("gml", "U", "directed that is not 0 or 1", "graph [ directed 2 ]")
E("gml", "U", "directed 1 into an undirected target", "graph [ directed 1 ]")
E("gml", "D", "no directed into a directed target", "graph [ node [ id 0 ] ]")
E("gml", "D", "directed 0 into a directed target", "graph [ directed 0 ]")
E("gml", "U", "directed twice", "graph [ directed 0 directed 0 ]")
E("gml", "U", "multigraph that is not 0 or 1", 'graph [ multigraph "yes" ]')
E("gml", "U", "a node without an id", 'graph [ node [ label "a" ] ]')
E("gml", "U", "an id that is not an integer", 'graph [ node [ id "a" ] ]')
E("gml", "U", "two ids in one node", "graph [ node [ id 0 id 1 ] ]")
E("gml", "U", "two labels in one node", 'graph [ node [ id 0 label "a" label "b" ] ]')
E("gml", "U", "a label that is a list", "graph [ node [ id 0 label [ x 1 ] ] ]")
E("gml", "U", "an id declared twice", "graph [ node [ id 0 ] node [ id 0 ] ]")
E("gml", "U", "two nodes with one label", 'graph [ node [ id 0 label "a" ] node [ id 1 label "a" ] ]')
E("gml", "U", "a label equal to another node's id text", 'graph [ node [ id 0 ] node [ id 1 label "0" ] ]')
E("gml", "U", "node whose value is not a list", "graph [ node 1 ]")
E("gml", "U", "an edge without a target", "graph [ node [ id 0 ] edge [ source 0 ] ]")
E("gml", "U", "a source that is not an integer", "graph [ node [ id 0 ] edge [ source 0.0 target 0 ] ]")
E("gml", "U", "two sources in one edge", "graph [ node [ id 0 ] edge [ source 0 source 0 target 0 ] ]")
E("gml", "U", "an edge to an undeclared node", "graph [ node [ id 0 ] edge [ source 0 target 9 ] ]")
E("gml", "U", "an unterminated string", 'graph [ node [ id 0 label "a ] ]')
E("gml", "U", "an unclosed list", "graph [ node [ id 0 ]")
E("gml", "U", "] at the top level", "graph [ ] ]")
E("gml", "U", "a number followed by a letter", "graph [ node [ id 0x ] ]")
E("gml", "U", "a string followed by a letter", 'graph [ node [ id 0 label "a"b ] ]')
E("gml", "U", "a value where a key should be", "graph [ 1 2 ]")
E("gml", "U", "a key where a value should be", "graph [ node [ id label ] ]")
E("gml", "U", "an integer beyond Int64", "graph [ x 9223372036854775808 ]")
E("gml", "U", "a real that overflows", "graph [ x 1e999 ]")
E("gml", "U", "65 nested lists", "graph [ " + "a [ " * 64 + "] " * 64 + "]")
R("gml", "U", "64 nested lists", "graph [ " + "a [ " * 63 + "] " * 63 + "]")
E("gml", "U", "a key starting with an underscore", "graph [ _x 1 ]")
E("gml", "U", "invalid UTF-8", b'graph [ x "\xff" ]')

# ---------------------------------------------------------------- Pajek read
R("pajek", "U", "NetworkX's write_pajek output",
  "*vertices 4\n1 0 0.0 0.0 ellipse\n2 1 0.0 0.0 ellipse\n3 2 0.0 0.0 ellipse\n4 3 0.0 0.0 ellipse\n*edges\n"
  "1 2 1.0\n2 3 1.0\n3 4 1.0\n")
R("pajek", "D", "arcs with weights and key-value pairs; vertices with coordinates, shape and pairs",
  '*Vertices 3\n1 "a" 0.1 0.2 box ic Red\n2 "b"\n3 "c" 1 2\n*Arcs\n1 2 2.5 c Blue l "x y"\n2 3\n3 3 -1\n')
R("pajek", "U", "quoting as shlex: double and single quotes, escapes, joined pieces",
  "*vertices 4\n1 \"a b\"\n2 'c \"d'\n3 x\\ y\n4 p\"q r\"s\\\"t\n*edges\n1 2\n3 4\n")
R("pajek", "U", "a vertex without a line is named by its number; lines in any order",
  '*vertices 4\n3 "c"\n1 "a"\n*edges\n2 4\n1 3\n')
R("pajek", "U", "a vertex line with only its number is labelled by it", "*vertices 2\n2\n1 a\n*edges\n1 2\n")
R("pajek", "D", "*network, % comments, blank lines, keywords in any case, a 2-mode count",
  "% made by hand\n*Network my net  \n\n*VERTICES 3 2\n% between\n1 a\n2 b\n3 c\n\n*arcs :1 \"rel\"\n1 3\n")
R("pajek", "D", "*arcslist: a vertex then its successors", "*vertices 3\n*arcslist\n1 2 3\n2\n3 1 1\n")
R("pajek", "U", "*edgeslist", "*vertices 3\n*edgeslist\n1 2 3\n")
R("pajek", "U", "labels that map to one vertex are that vertex", '*vertices 3\n1 "x"\n2 "x"\n*edges\n1 2\n2 3\n')
R("pajek", "DS", "simple target: parallel arcs merge, last weight wins", "*vertices 2\n1 a\n2 b\n*arcs\n1 2 1\n1 2 2\n")
R("pajek", "D", "weights inf, -inf, nan and integers read as doubles", "*vertices 2\n1 a\n2 b\n*arcs\n1 2 inf\n2 1 -Infinity\n1 1 NaN\n2 2 3\n")
R("pajek", "U", "CR LF", "*vertices 2\r\n1 a\r\n2 b\r\n*edges\r\n1 2\r\n")
R("pajek", "U", "a byte-order mark", "\ufeff*vertices 1\n1 a\n*edges\n")
R("pajek", "U", "no vertices", "*vertices 0\n*edges\n")
R("pajek", "D", "an empty file is an empty graph", "")
R("pajek", "D", "two *arcs sections", "*vertices 2\n1 a\n2 b\n*arcs\n1 2\n*arcs\n2 1\n")
R("pajek", "D", "an empty quoted label", '*vertices 1\n1 ""\n')
R("pajek", "D", "*network after the vertices does not end their section", "*vertices 2\n1 a\n*network n\n2 b\n")
E("pajek", "U", "a data line before *vertices", "1 a\n")
E("pajek", "U", "*edges before *vertices", "*edges\n1 2\n")
E("pajek", "U", "*vertices without a count", "*vertices\n")
E("pajek", "U", "a count that is not a number", "*vertices x\n")
E("pajek", "U", "a third field on *vertices", "*vertices 2 1 0\n")
E("pajek", "U", "a count past Int64", "*vertices 9223372036854775808\n")
E("pajek", "U", "a count above the default maximumVertexCount", "*vertices 16777216\n")
E("pajek", "U", "a count above maximumVertexCount", "*vertices 3\n", maximumVertexCount=2)
R("pajek", "D", "a count at maximumVertexCount", "*vertices 2\n1 a\n2 b\n", maximumVertexCount=2)
E("pajek", "U", "a vertex number 0", "*vertices 2\n0 a\n")
E("pajek", "U", "a vertex number beyond n", "*vertices 2\n3 a\n")
E("pajek", "U", "a vertex number that is not an integer", "*vertices 2\nx a\n")
E("pajek", "U", "a vertex number given twice", "*vertices 2\n1 a\n1 b\n")
E("pajek", "U", "an x that is not a number", "*vertices 1\n1 a x 0.0\n")
E("pajek", "U", "a key without a value", "*vertices 1\n1 a 0 0 box ic\n")
E("pajek", "U", "*arcs into an undirected target", "*vertices 1\n*arcs\n")
E("pajek", "D", "*edges into a directed target", "*vertices 1\n*edges\n")
E("pajek", "U", "an edge line of one field", "*vertices 1\n*edges\n1\n")
E("pajek", "U", "an endpoint beyond n", "*vertices 1\n*edges\n1 2\n")
E("pajek", "U", "an endpoint that is not an integer", "*vertices 1\n*edges\n1 a\n")
E("pajek", "U", "a weight that is not a number", "*vertices 1\n*edges\n1 1 w\n")
E("pajek", "U", "an unclosed quote", '*vertices 1\n1 "a\n')
E("pajek", "U", "a backslash at the end of a line", "*vertices 1\n1 a\\\n")
E("pajek", "U", "*matrix (unsupported)", "*vertices 2\n*matrix\n0 1\n1 0\n")
E("pajek", "U", "a second *vertices (unsupported)", "*vertices 1\n*vertices 1\n")
E("pajek", "U", "an unknown section (unsupported)", "*vertices 1\n*partition p\n1\n")

# ---------------------------------------------------------------- graph6, sparse6, digraph6 read
R("graph6", "UI", "graph6: five vertices, edges 0-1, 1-2, 3-4", "DgC\n")
R("graph6", "UI", "graph6: no vertices", "?\n")
R("graph6", "UI", "graph6: one vertex, no data", "@\n")
R("graph6", "UI", "graph6: the header, no final newline", ">>graph6<<Bw")
R("graph6", "UI", "graph6: CR LF", "C~\r\n")
R("graph6", "USI", "graph6 into a simple target", "Ch\n")
R("graph6", "UI", "graph6: 63 vertices take the four-byte size", "~??~" + "?" * 326 + "@\n")
E("graph6", "UI", "graph6: empty input", "")
E("graph6", "UI", "graph6: a size byte below 63", "!\n")
E("graph6", "UI", "graph6: a data byte above 126", "C\x7f\n")
E("graph6", "UI", "graph6: too few data bytes", "D?\n")
E("graph6", "UI", "graph6: too many data bytes", "Bw?\n")
E("graph6", "UI", "graph6: padding bits that are not 0", "Bx\n")
E("graph6", "UI", "graph6: text after the line feed", "Bw\nBw\n")
E("graph6", "UI", "graph6: a four-byte size cut short", "~?\n")
E("graph6", "UI", "graph6: a sparse6 line", ":Bw\n")
E("graph6", "UI", "graph6: invalid UTF-8", b"B\xc3\n")
R("digraph6", "DI", "digraph6: arcs and a loop, row by row", "&BQ_\n")
R("digraph6", "DI", "digraph6: the header", ">>digraph6<<&CC__\n")
R("digraph6", "DI", "digraph6: no vertices", "&?\n")
R("digraph6", "DSI", "digraph6 into a simple target", "&AW\n")
E("digraph6", "DI", "digraph6: no &", "BQ_\n")
E("digraph6", "DI", "digraph6: empty input", "")
E("digraph6", "DI", "digraph6: too few data bytes", "&C\n")
E("digraph6", "DI", "digraph6: padding bits that are not 0", "&AX\n")
R("sparse6", "UI", "sparse6: nauty's example, seven vertices", ":Fa@x^\n")
R("sparse6", "UI", "sparse6: loops and parallel edges", ":B_M\n")
R("sparse6", "USI", "sparse6 into a simple target: parallel edges merge", ":B_M\n")
R("sparse6", "UI", "sparse6: the header, a jump over vertices", ">>sparse6<<:GwYJ\n")
R("sparse6", "UI", "sparse6: one vertex with a loop (k = 0)", ":@^\n")
R("sparse6", "UI", "sparse6: no vertices", ":?\n")
R("sparse6", "UI", "sparse6: the padding special case (n = 4, last edge at vertex 2)", ":C`b\n")
E("sparse6", "UI", "sparse6: incremental sparse6 (unsupported)", ";Bc\n")
E("sparse6", "UI", "sparse6: no colon", "Bc\n")
E("sparse6", "UI", "sparse6: empty input", "")
E("sparse6", "UI", "sparse6: a data byte below 63", ":Bc \n")
E("sparse6", "UI", "sparse6: a size above the default maximumVertexCount", ":~~??F???\n")
E("sparse6", "UI", "sparse6: a size above maximumVertexCount", ":C\n", maximumVertexCount=3)
E("sparse6", "UI", "sparse6: a size cut short", ":~~??\n")
E("sparse6", "UI", "sparse6: text after the line feed", ":?\nx")

# ---------------------------------------------------------------- DIMACS read
R("dimacs", "DI", "shortest path (.gr): comments, the problem line, weighted arcs",
  "c 9th DIMACS challenge\np sp 3 3\nc arcs\na 1 2 7\na 2 3 -1\na 3 1 0\n")
R("dimacs", "UI", "clique (p edge): edges, isolated vertices", "c\np edge 4 2\ne 1 2\ne 4 2\n")
R("dimacs", "UI", "colouring (p col), tabs, CR LF, blank lines", "p col 2 1\r\n\r\ne\t1\t2\r\n")
R("dimacs", "DSI", "simple target: a repeated arc merges, last weight wins", "p sp 2 2\na 1 2 1\na 1 2 5\n")
R("dimacs", "DI", "parallel arcs and loops kept", "p sp 2 3\na 1 2 1\na 1 2 2\na 2 2 3\n")
R("dimacs", "UI", "no edges", "p edge 3 0\n")
E("dimacs", "DI", "no problem line", "c only\n")
E("dimacs", "DI", "an arc before the problem line", "a 1 2 3\np sp 2 1\n")
E("dimacs", "DI", "a second problem line", "p sp 1 0\np sp 1 0\n")
E("dimacs", "DI", "a flow problem (unsupported)", "p max 2 1\n")
E("dimacs", "DI", "an unknown problem", "p foo 2 1\n")
E("dimacs", "UI", "p sp into an undirected target", "p sp 2 0\n")
E("dimacs", "DI", "p edge into a directed target", "p edge 2 0\n")
E("dimacs", "DI", "a problem line of three fields", "p sp 2\n")
E("dimacs", "DI", "a problem line of five fields", "p sp 2 0 x\n")
E("dimacs", "DI", "a vertex count that is not a number", "p sp x 0\n")
E("dimacs", "DI", "a vertex count above the default maximumVertexCount", "p sp 16777216 0\n")
E("dimacs", "DI", "a vertex count above maximumVertexCount", "p sp 3 0\n", maximumVertexCount=2)
E("dimacs", "DI", "an index 0", "p sp 2 1\na 0 1 1\n")
E("dimacs", "DI", "an index beyond n", "p sp 2 1\na 1 3 1\n")
E("dimacs", "DI", "a signed index", "p sp 2 1\na +1 2 1\n")
E("dimacs", "DI", "a weight that is not an integer", "p sp 2 1\na 1 2 1.5\n")
E("dimacs", "DI", "a weight beyond Int64", "p sp 2 1\na 1 2 9223372036854775808\n")
E("dimacs", "DI", "a missing weight", "p sp 2 1\na 1 2\n")
E("dimacs", "UI", "an extra field on an edge", "p edge 2 1\ne 1 2 3\n")
E("dimacs", "DI", "more arcs than declared", "p sp 2 1\na 1 2 1\na 2 1 1\n")
E("dimacs", "DI", "fewer arcs than declared", "p sp 2 2\na 1 2 1\n")
E("dimacs", "DI", "an e line in a shortest-path file", "p sp 2 1\ne 1 2\n")
E("dimacs", "UI", "a node descriptor line (unsupported)", "p edge 2 0\nn 1 5\n")
E("dimacs", "DI", "an unknown line", "p sp 2 0\nx 1\n")

# ---------------------------------------------------------------- METIS read
R("metis", "UI", "the METIS manual's graph: unweighted",
  "7 11\n5 3 2\n1 3 4\n5 4 2 1\n2 3 6 7\n1 3 6\n5 4 7\n6 4\n")
R("metis", "UI", "fmt 1: edge weights", "3 2 1\n2 5 3 1\n1 5\n1 1\n")
R("metis", "UI", "fmt 011: a vertex weight, then neighbours with edge weights", "3 2 011\n4 2 1\n2 1 1 3 2\n0 2 2\n")
R("metis", "UI", "fmt 110 with ncon 1: a size and a weight per vertex", "2 1 110 1\n3 4 2\n5 6 1\n")
R("metis", "UI", "comments anywhere; a blank line is a vertex without neighbours; trailing blank lines",
  "% header next\n\n3 1\n% vertex 1\n2\n1\n\n\n% done\n\n")
R("metis", "USI", "parallel entries on both sides into a simple target", "2 2\n2 2\n1 1\n")
R("metis", "UI", "no vertices", "0 0\n")
R("metis", "UI", "CR LF and tabs", "2 1\r\n2\r\n1\t\r\n")
E("metis", "UI", "an empty file", "")
E("metis", "UI", "a header of one field", "3\n")
E("metis", "UI", "a header of five fields", "1 0 010 1 9\n")
E("metis", "UI", "a fmt that is not 0s and 1s", "1 0 2\n\n")
E("metis", "UI", "ncon 2 (unsupported)", "1 0 010 2\n5 6\n")
E("metis", "UI", "ncon 0", "1 0 010 0\n\n")
E("metis", "UI", "ncon without vertex weights", "1 0 1 1\n\n")
E("metis", "UI", "a vertex count above the default maximumVertexCount", "16777216 0\n")
E("metis", "UI", "a vertex count above maximumVertexCount", "3 0\n\n\n\n", maximumVertexCount=2)
E("metis", "UI", "a neighbour 0", "2 1\n0\n1\n")
E("metis", "UI", "a neighbour beyond n", "2 1\n3\n1\n")
E("metis", "UI", "a neighbour that is not a number", "2 1\nx\n1\n")
E("metis", "UI", "a loop", "2 1\n1\n1\n")
E("metis", "UI", "a missing edge weight", "2 1 1\n2\n1 1\n")
E("metis", "UI", "an edge weight that is not an integer", "2 1 1\n2 x\n1 1\n")
E("metis", "UI", "a missing vertex weight", "2 1 010\n\n1\n")
E("metis", "UI", "fewer vertex lines than n", "3 1\n2\n1\n")
E("metis", "UI", "a line after the last vertex", "1 0\n\n5\n")
E("metis", "UI", "an edge listed on one side only", "3 1\n2\n\n\n")
E("metis", "UI", "a lower entry with no mirror", "3 1\n2\n1 3\n\n")
E("metis", "UI", "weights that differ on the two sides", "2 1 1\n2 1\n1 2\n")
E("metis", "UI", "an edge count that is not m", "2 2\n2\n1\n")

# ---------------------------------------------------------------- Cytoscape JSON read
R("cytoscapeJSON", "U", "NetworkX's cytoscape_data(path_graph(3))",
  '{"data": [], "directed": false, "multigraph": false, "elements": {"nodes": [{"data": {"id": "0", "value": 0, '
  '"name": "0"}}, {"data": {"id": "1", "value": 1, "name": "1"}}, {"data": {"id": "2", "value": 2, "name": "2"}}], '
  '"edges": [{"data": {"source": 0, "target": 1}}, {"data": {"source": 1, "target": 2}}]}}')
R("cytoscapeJSON", "D", "directed, attributes, NetworkX's graph data pairs",
  '{"data": [["name", "g"], ["n", 2]], "directed": true, "multigraph": false, "elements": {"nodes": '
  '[{"data": {"color": "red", "id": "a", "value": "a", "name": "a"}}, {"data": {"id": "b"}}], '
  '"edges": [{"data": {"w": 1.5, "id": "e1", "source": "a", "target": "b"}}]}}')
R("cytoscapeJSON", "U", "Cytoscape.js: an array of elements with group; position and classes ignored; data object",
  '{"data": {"title": "t"}, "elements": [{"group": "nodes", "data": {"id": "a"}, "position": {"x": 1, "y": 2}, '
  '"classes": "c", "selected": false}, {"group": "edges", "data": {"id": "e", "source": "a", "target": "b"}}, '
  '{"group": "nodes", "data": {"id": "b"}}]}')
R("cytoscapeJSON", "U", "without group, an element is an edge when its data has source",
  '{"elements": [{"data": {"source": "x", "target": "y"}}, {"data": {"id": "x"}}, {"data": {"id": "y"}}]}')
R("cytoscapeJSON", "D", "multigraph true: every edge kept, key not reported",
  '{"directed": true, "multigraph": true, "elements": {"nodes": [{"data": {"id": "a"}}], "edges": ['
  '{"data": {"source": "a", "target": "a", "key": 0}}, {"data": {"source": "a", "target": "a", "key": 0, "w": 2}}]}}')
R("cytoscapeJSON", "D", "multigraph false: parallel edges kept, key reported",
  '{"directed": true, "elements": {"nodes": [{"data": {"id": "a"}}], "edges": ['
  '{"data": {"source": "a", "target": "a", "key": 7}}, {"data": {"source": "a", "target": "a"}}]}}')
R("cytoscapeJSON", "DS", "simple target: parallel edges merge, last value wins",
  '{"directed": true, "elements": {"nodes": [{"data": {"id": "a"}}, {"data": {"id": "b"}}], "edges": ['
  '{"data": {"source": "a", "target": "b", "w": 1}}, {"data": {"source": "a", "target": "b", "w": 2}}]}}')
R("cytoscapeJSON", "U", "integer ids and endpoints are their decimal text",
  '{"elements": {"nodes": [{"data": {"id": 1}}, {"data": {"id": "2"}}], "edges": [{"data": {"source": "1", "target": 2}}]}}')
R("cytoscapeJSON", "U", "no nodes or edges members", '{"elements": {}}')
E("cytoscapeJSON", "U", "no elements", '{"directed": false}')
E("cytoscapeJSON", "U", "top level not an object", "[]")
E("cytoscapeJSON", "U", "directed into an undirected target", '{"directed": true, "elements": {}}')
E("cytoscapeJSON", "D", "no directed into a directed target", '{"elements": {}}')
E("cytoscapeJSON", "U", "directed that is not a boolean", '{"directed": 0, "elements": {}}')
E("cytoscapeJSON", "U", "multigraph that is not a boolean", '{"multigraph": "no", "elements": {}}')
E("cytoscapeJSON", "U", "data that is neither an object nor an array", '{"data": 1, "elements": {}}')
E("cytoscapeJSON", "U", "a data pair that is not [string, value]", '{"data": [[1, 2]], "elements": {}}')
E("cytoscapeJSON", "U", "a data value that is a list (unsupported)", '{"data": {"x": [1]}, "elements": {}}')
E("cytoscapeJSON", "U", "elements that are neither an object nor an array", '{"elements": 3}')
E("cytoscapeJSON", "U", "nodes that are not an array", '{"elements": {"nodes": {}}}')
E("cytoscapeJSON", "U", "an element that is not an object", '{"elements": [1]}')
E("cytoscapeJSON", "U", "a group other than nodes or edges", '{"elements": [{"group": "x", "data": {"id": "a"}}]}')
E("cytoscapeJSON", "U", "a node without data", '{"elements": {"nodes": [{"id": "a"}]}}')
E("cytoscapeJSON", "U", "a node's data that is not an object", '{"elements": {"nodes": [{"data": 1}]}}')
E("cytoscapeJSON", "U", "a node without an id", '{"elements": {"nodes": [{"data": {"name": "a"}}]}}')
E("cytoscapeJSON", "U", "an id that is a boolean", '{"elements": {"nodes": [{"data": {"id": true}}]}}')
E("cytoscapeJSON", "U", "a node declared twice (1 and \"1\")", '{"elements": {"nodes": [{"data": {"id": 1}}, {"data": {"id": "1"}}]}}')
E("cytoscapeJSON", "U", "a null attribute (unsupported)", '{"elements": {"nodes": [{"data": {"id": "a", "x": null}}]}}')
E("cytoscapeJSON", "U", "an edge without a source", '{"elements": {"nodes": [{"data": {"id": "a"}}], "edges": [{"data": {"target": "a"}}]}}')
E("cytoscapeJSON", "U", "an edge to an undeclared node",
  '{"elements": {"nodes": [{"data": {"id": "a"}}], "edges": [{"data": {"source": "a", "target": "b"}}]}}')
E("cytoscapeJSON", "U", "an edge attribute that is an object (unsupported)",
  '{"elements": {"nodes": [{"data": {"id": "a"}}], "edges": [{"data": {"source": "a", "target": "a", "x": {}}}]}}')
E("cytoscapeJSON", "U", "a duplicate key", '{"elements": {}, "elements": {}}')

# ---------------------------------------------------------------- writers of the new formats
GML_TYPED = graph(True, ["a", "b"], [("a", "b"), ("b", "b")],
                  {"a": {"color": "x y", "n": 3, "x": 2.0, "ok": True, "no": False}},
                  {0: {"weight": 2, "w2": -0.5}, 1: {"weight": 1.5}}, {"title": "G", "n": 1})
GML_NUMBERS = graph(False, ["a"], [], {"a": {"big": 2 ** 31, "low": -(2 ** 31), "top": 2 ** 31 - 1, "e": 1e-05,
                                             "f": 1e16, "p": math.inf, "m": -math.inf, "q": math.nan, "z": -0.0}})
GML_ESCAPES = graph(True, ['a"&<b>', "é\n😀", "~ "], [('a"&<b>', "é\n😀")], {"~ ": {"s": "tab\tquote\"amp&"}})
W("gml", "empty digraph", EMPTY_D)
W("gml", "empty undirected graph: no directed line", graph(False, [], []))
W("gml", "every vertex, then every edge, in order", ISO)
W("gml", "typed attributes; graph attributes first; booleans as 1 and 0", GML_TYPED)
W("gml", "undirected, a loop, parallel edges: multigraph 1", UNDIRECTED)
W("gml", "integers outside 32 bits as strings; reals as NetworkX writes them", GML_NUMBERS)
W("gml", "character references for quotes, ampersands and everything outside ASCII", GML_ESCAPES)
W("gml", "Int vertices: labels are their text", INTS)
PAJEK_TYPED = graph(True, ["a", "b", "c"], [("a", "b"), ("b", "c"), ("c", "c")],
                    {"a": {"x": 0.5, "y": 2, "shape": "box", "ic": "Red"}, "b": {"ic": "Blue", "x": -1.0}},
                    {0: {"weight": 2.5, "c": "Green"}, 1: {"weight": 3}, 2: {"l": 1}})
PAJEK_QUOTES = graph(False, ["a b", 'q"r', "back\\slash", "it's", "", "plain", "nb\u00a0sp"],
                     [("a b", 'q"r'), ("it's", "")], {"plain": {"k y": "v w", "e": ""}})
W("pajek", "empty digraph", EMPTY_D)
W("pajek", "undirected path: NetworkX's defaults for x, y, shape and weight", graph(False, ["0", "1", "2"], [("0", "1"), ("1", "2")]))
W("pajek", "coordinates, shape, weights and key-value pairs", PAJEK_TYPED)
W("pajek", "quoting: whitespace, quotes, backslashes, apostrophes, empty strings", PAJEK_QUOTES)
W("pajek", "parallel edges and a loop", UNDIRECTED)
NAUTY_PATH = graph(False, [0, 1, 2, 3, 4], [(0, 1), (1, 2), (3, 4)])
W("graph6", "graph6: a path and an edge", NAUTY_PATH)
W("graph6", "graph6: with the header", NAUTY_PATH, header=True)
W("graph6", "graph6: no vertices", graph(False, [], []))
W("graph6", "graph6: K4, edges in any orientation", graph(False, [0, 1, 2, 3], [(1, 0), (0, 2), (3, 0), (1, 2), (3, 1), (2, 3)]))
W("graph6", "graph6: 63 vertices take the four-byte size", graph(False, list(range(63)), [(61, 62)]))
W("digraph6", "digraph6: arcs and a loop", graph(True, [0, 1, 2], [(0, 1), (1, 1), (2, 0)]))
W("digraph6", "digraph6: with the header", graph(True, [0, 1, 2, 3], [(0, 3), (3, 0)]), header=True)
W("digraph6", "digraph6: no vertices", graph(True, [], []))
W("sparse6", "sparse6: nauty's example", graph(False, list(range(7)), [(0, 1), (0, 2), (1, 2), (5, 6)]))
W("sparse6", "sparse6: loops and parallel edges", graph(False, [0, 1, 2], [(0, 1), (1, 0), (1, 1), (2, 2)]))
W("sparse6", "sparse6: with the header, a jump over vertices", graph(False, list(range(8)), [(6, 1), (7, 2), (7, 2)]), header=True)
W("sparse6", "sparse6: the padding special case", graph(False, [0, 1, 2, 3], [(0, 1), (1, 1), (0, 2)]))
W("sparse6", "sparse6: a loop at vertex 0 of four (nauty's padding)", graph(False, [0, 1, 2, 3], [(0, 0)]))
W("sparse6", "sparse6: one vertex with a loop (k = 0)", graph(False, [0], [(0, 0)]))
W("sparse6", "sparse6: no vertices", graph(False, [], []))
W("dimacs", "shortest path: p sp and weighted arcs in position order",
  graph(True, [0, 1, 2], [(0, 1), (2, 0), (1, 1)]), weight=[7, -2, 0])
W("dimacs", "clique: p edge and edges as stored", graph(False, [0, 1, 2, 3], [(1, 0), (2, 3)]))
W("dimacs", "empty digraph", graph(True, [], []), weight=[])
W("metis", "unweighted: neighbours in the order of the incident edges",
  graph(False, [0, 1, 2, 3], [(0, 1), (2, 0), (1, 2)]))
W("metis", "edge weights: fmt 1", graph(False, [0, 1, 2], [(0, 1), (2, 1)]), weight=[5, -3])
W("metis", "isolated vertices are empty lines", graph(False, [0, 1, 2], [(2, 0)]))
W("metis", "no vertices", graph(False, [], []))
CY_TYPED = graph(True, ["a", "b"], [("a", "b"), ("b", "b")],
                 {"a": {"label": "x y", "n": 3, "x": 2.0, "ok": True}, "b": {"name": "B", "value": 7}},
                 {0: {"weight": 2, "w2": -0.5}, 1: {"id": "e1"}}, {"title": "G", "k": 1})
W("cytoscapeJSON", "empty digraph", EMPTY_D)
W("cytoscapeJSON", "undirected path", graph(False, ["0", "1", "2"], [("0", "1"), ("1", "2")]))
W("cytoscapeJSON", "typed attributes; a vertex's own name and value stay in place", CY_TYPED)
W("cytoscapeJSON", "parallel edges: multigraph true and NetworkX's keys", MULTI)
W("cytoscapeJSON", "non-ASCII and control characters are escaped", UNICODE)
W("edgeList", "a comma delimiter: IDs may hold spaces", graph(True, ["a b", "c"], [("a b", "c"), ("c", "c")]), delimiter=",")
W("edgeList", "a tab delimiter with columns; an empty string value", graph(
    True, ["x", "y"], [("x", "y")], {}, {0: {"w": 1.5, "s": ""}}), delimiter="\t", columns=["w", "s"])


def write_output(c):
    g, kw = c["graph"], c["kw"]
    f = c["fmt"]
    if f == "dot":
        return dot_write(g)
    if f == "graphML":
        return graphml_write(g)
    if f == "nodeLinkJSON":
        return node_link_write(g)
    if f == "matrixMarket":
        return mm_write(g, kw.get("weight"))
    if f == "edgeList":
        return edge_list_write(g, kw.get("columns", ()), kw.get("delimiter"))
    if f == "adjacencyList":
        return adjacency_list_write(g)
    if f == "gml":
        return gml_write(g)
    if f == "pajek":
        return pajek_write(g)
    if f == "graph6":
        return graph6_write(g, kw.get("header", False))
    if f == "sparse6":
        return sparse6_write(g, kw.get("header", False))
    if f == "digraph6":
        return digraph6_write(g, kw.get("header", False))
    if f == "dimacs":
        return dimacs_write(g, kw.get("weight"))
    if f == "metis":
        return metis_write(g, kw.get("weight"))
    if f == "cytoscapeJSON":
        return cytoscape_write(g)
    return mermaid_write(g)


def evaluate(c):
    if c["kind"] == "read":
        return run_reader(reader_for(c["fmt"], **c["kw"]), c["text"], make_target(c["target"]))
    return write_output(c)


# ============================================================================ cross-checks

def same(a, b):
    if type(a) is float and type(b) is float and math.isnan(a) and math.isnan(b):
        return True
    return type(a) is type(b) and a == b


def same_attrs(a, b):
    return a.keys() == b.keys() and all(same(a[k], b[k]) for k in a)


def edge_key(u, v, a, directed):
    ends = (u, v) if directed else tuple(sorted((u, v), key=str))
    return repr((ends, sorted((k, repr(x)) for k, x in a.items())))


def edge_multiset(pairs, directed):
    return sorted(edge_key(u, v, a, directed) for u, v, a in pairs)


def our_edges(g):
    return [(g.vertices[u], g.vertices[v], a) for (u, v), a in zip(g.edges, g.eattrs)]


def nx_edges(G):
    if G.is_multigraph():
        return [(u, v, d) for u, v, k, d in G.edges(keys=True, data=True)]
    return list(G.edges(data=True))


def nx_matches(g, G, attrs=True):
    if [str(v) for v in G.nodes] != [str(v) for v in g.vertices]:
        return "vertex order"
    if attrs and any(not same_attrs(G.nodes[v], a) for v, a in zip(G.nodes, g.vattrs)):
        return "vertex attributes"
    strip = (lambda a: a) if attrs else (lambda a: {})
    if edge_multiset([(str(u), str(v), strip(d)) for u, v, d in nx_edges(G)], g.directed) != edge_multiset(
            [(str(u), str(v), strip(a)) for u, v, a in our_edges(g)], g.directed):
        return "edges"
    return None


def nx_create(g):
    multi = not TARGETS_SIMPLE.get(id(g), False)
    return (nx.MultiDiGraph if multi else nx.DiGraph)() if g.directed else (nx.MultiGraph if multi else nx.Graph)()


TARGETS_SIMPLE = {}


NEW_FORMATS = {"gml", "pajek", "graph6", "sparse6", "digraph6", "dimacs", "metis", "cytoscapeJSON"}


def known(c):
    """The KNOWN reason for a row: by (format, case) for the formats added after the first seven,
    whose case texts repeat the first ones'; by case otherwise."""
    if (c["fmt"], c["case"]) in KNOWN:
        return KNOWN[(c["fmt"], c["case"])]
    if c["fmt"] in NEW_FORMATS:
        return None
    return KNOWN.get(c["case"])


def py_id_text(x):
    """A NetworkX tuple node as the reader names an array id."""
    if isinstance(x, tuple):
        return "[" + ", ".join(py_id_text(e) for e in x) + "]"
    if x is None:
        return "null"
    return json_value(x)


def strip_attrs(G, node_keys=(), edge_keys=()):
    for _, d in G.nodes(data=True):
        for k in node_keys:
            d.pop(k, None)
    for e in (G.edges(keys=True, data=True) if G.is_multigraph() else G.edges(data=True)):
        for k in edge_keys:
            e[-1].pop(k, None)
    return G


def library_read_new(c, raw, ours, directed, simple):
    """library_read for the formats added after the first seven: a graph from the library, or a
    string verdict, or None for no library."""
    f = c["fmt"]
    text = raw.decode("utf-8")
    if f == "gml":
        try:
            G = nx.parse_gml(text, label="label")
        except nx.NetworkXError as e:
            if "has no 'label'" not in str(e):
                raise
            G = nx.parse_gml(text, label="id")
    elif f == "pajek":
        G = nx.parse_pajek(text)
        strip_attrs(G, node_keys=("id",))
    elif f == "graph6":
        G = nx.from_graph6_bytes(raw.rstrip(b"\n"))
    elif f == "sparse6":
        G = nx.from_sparse6_bytes(raw.rstrip(b"\n"))
    elif f == "cytoscapeJSON":
        data = json.loads(text)
        G = nx.cytoscape_graph(data)
        strip_attrs(G, node_keys=("id",), edge_keys=("source", "target") + (("key",) if data.get("multigraph") else ()))
    else:
        return "no library"
    if G.is_directed() != directed:
        return "library reads the other kind"
    if simple:
        G = (nx.DiGraph if directed else nx.Graph)(G)
    return G


def library_write_new(c, out):
    g, kw, f = c["graph"], c["kw"], c["fmt"]

    def nx_graph(multi):
        G = ((nx.MultiDiGraph if multi else nx.DiGraph) if g.directed else (nx.MultiGraph if multi else nx.Graph))()
        for v, a in zip(g.vertices, g.vattrs):
            G.add_node(v, **a)
        for (u, v), a in zip(g.edges, g.eattrs):
            G.add_edge(g.vertices[u], g.vertices[v], **a)
        G.graph.update(g.gattrs)
        return G

    if f == "gml":
        G = nx_graph(has_parallel(g))
        ref = "".join(line + "\n" for line in nx.generate_gml(G) if not re.fullmatch(r"    key [0-9]+", line))
        if ref == out:
            return None
        def split(s):
            head, _, rest = s[:-2].partition("  edge [\n")  # without the graph's closing ]
            blocks = []
            for b in ("  edge [\n" + rest).split("  edge [\n")[1:]:
                lines = b.split("\n")
                if not g.directed:  # NetworkX orients an undirected edge by adjacency
                    ends = sorted(int(x.split()[1]) for x in lines[:2])
                    lines[:2] = [f"    source {ends[0]}", f"    target {ends[1]}"]
                blocks.append("\n".join(lines))
            return head, sorted(blocks)
        return None if split(ref) == split(out) else f"NetworkX writes {ref!r}"
    if f == "pajek":
        G = nx_graph(True)
        ref = "".join(line + "\n" for line in nx.generate_pajek(G))
        if ref == out:
            return None
        def edge_lines(s):
            out = []
            for line in s.splitlines():
                parts = line.split(" ")
                if not g.directed and len(parts) >= 2 and parts[0].isdigit():
                    parts[:2] = sorted(parts[:2], key=int)
                out.append(" ".join(parts))
            return sorted(out)
        a, b = ref.split("*", 2), out.split("*", 2)
        if a[:2] == b[:2] and edge_lines(a[2]) == edge_lines(b[2]):
            return None
        return f"NetworkX writes {ref!r}"
    if f == "graph6":
        G = nx.Graph()
        G.add_nodes_from(g.vertices)
        G.add_edges_from((g.vertices[u], g.vertices[v]) for u, v in g.edges)
        ref = nx.to_graph6_bytes(G, header=kw.get("header", False)).decode()
        return None if ref == out else f"NetworkX writes {ref!r}"
    if f == "sparse6":
        G = nx.MultiGraph()
        G.add_nodes_from(g.vertices)
        G.add_edges_from((g.vertices[u], g.vertices[v]) for u, v in g.edges)
        ref = nx.to_sparse6_bytes(G, header=kw.get("header", False)).decode()
        return None if ref == out else f"NetworkX writes {ref!r}"
    if f == "cytoscapeJSON":
        G = nx_graph(has_parallel(g))
        ref = json.dumps(nx.cytoscape_data(G))
        if ref == out:
            return None
        a, b = json.loads(ref), json.loads(out)
        ea, eb = a["elements"].pop("edges"), b["elements"].pop("edges")
        def norm(e):
            d = dict(e["data"])
            if not g.directed:
                d["source"], d["target"] = sorted((d["source"], d["target"]))
            return json.dumps(d, sort_keys=True)
        if a == b and sorted(map(norm, ea)) == sorted(map(norm, eb)):
            return None
        return f"NetworkX writes {ref!r}"
    return None


def round_trip_new(c, out):
    """round_trip for the formats added after the first seven."""
    g, kw, f = c["graph"], c["kw"], c["fmt"]
    integral = f in ("graph6", "sparse6", "digraph6", "dimacs", "metis")
    vtype = int if integral else str
    back = run_reader(reader_for(f, **kw), out, Target(g.directed, False, vtype))
    if isinstance(back, ParseError):
        return f"reads back as {back}"
    expect = Target(g.directed, False, vtype)
    for v in g.vertices:
        expect.vertex(v if integral else str(v))

    def gml_back(x):
        if type(x) is bool:
            return int(x)
        if type(x) is int and not -(2 ** 31) <= x < 2 ** 31:
            return str(x)
        return x

    for i, a in enumerate(g.vattrs):
        if f == "gml":
            expect.vattrs[i] = {k: gml_back(x) for k, x in a.items()}
        elif f == "pajek":
            e = {"x": float(a.get("x", 0.0)), "y": float(a.get("y", 0.0)), "shape": pajek_text(a.get("shape", "ellipse"))}
            e.update({k: pajek_text(x) for k, x in a.items() if k not in ("x", "y", "shape")})
            expect.vattrs[i] = e
        elif f == "cytoscapeJSON":
            e = dict(a)
            for extra in ("value", "name"):
                e.setdefault(extra, str(g.vertices[i]))
            expect.vattrs[i] = e
    if f == "gml":
        expect.gattrs = {k: gml_back(x) for k, x in g.gattrs.items()}
    elif f == "cytoscapeJSON":
        expect.gattrs = dict(g.gattrs)
    for p, (u, v) in enumerate(g.edges):
        a = g.eattrs[p]
        if f in ("graph6", "sparse6", "metis"):
            u, v = min(u, v), max(u, v)
        q = expect.edge(u, v)
        if f == "gml":
            expect.eattrs[q] = {k: gml_back(x) for k, x in a.items()}
        elif f == "pajek":
            e = {"weight": float(a.get("weight", 1.0))}
            e.update({k: pajek_text(x) for k, x in a.items() if k != "weight"})
            expect.eattrs[q] = e
        elif f == "cytoscapeJSON":
            expect.eattrs[q] = dict(a)
        elif f in ("dimacs", "metis") and kw.get("weight") is not None:
            expect.eattrs[q] = {"weight": kw["weight"][p]}
    if f in ("graph6", "sparse6", "digraph6", "metis"):
        same_edges = edge_multiset(our_edges(expect), g.directed) == edge_multiset(our_edges(back), g.directed)
        ok = expect.vertices == back.vertices and same_edges
    else:
        ok = (expect.vertices == back.vertices and expect.edges == back.edges and expect.gattrs == back.gattrs and
              all(same_attrs(x, y) for x, y in zip(expect.vattrs, back.vattrs)) and
              all(same_attrs(x, y) for x, y in zip(expect.eattrs, back.eattrs)))
    return None if ok else f"reads back as {fmt_graph(back)}, expected {fmt_graph(expect)}"


def library_read(c):
    """What the reference library makes of a read row: a graph comparison or None when it agrees."""
    raw = c["text"].encode() if isinstance(c["text"], str) else c["text"]
    ours = evaluate(c)
    _, directed, simple, vtype = TARGETS[c["target"]]
    f = c["fmt"]
    try:
        if f in NEW_FORMATS:
            G = library_read_new(c, raw, ours, directed, simple)
            if G == "no library":
                return None
            if isinstance(G, str):
                return G
        elif f == "graphML":
            G = nx.read_graphml(io.BytesIO(raw))
            if not G.is_directed() == directed:
                return "library reads the other kind"
            if simple:
                G = (nx.DiGraph if directed else nx.Graph)(G)
        elif f == "nodeLinkJSON":
            G = nx.node_link_graph(json.loads(raw.decode("utf-8")))
            G = nx.relabel_nodes(G, {v: py_id_text(v) for v in G if isinstance(v, tuple)})
            if simple:
                G = (nx.DiGraph if directed else nx.Graph)(G)
        elif f == "matrixMarket":
            A = scipy.sparse.coo_array(scipy.io.mmread(io.BytesIO(raw)))
            if A.shape[0] != A.shape[1]:
                return "library accepts a non-square matrix"
            G = (nx.DiGraph if simple else nx.MultiDiGraph)() if directed else nx.MultiGraph()
            G.add_nodes_from(range(A.shape[0]))
            field = raw.split(b"\n", 1)[0].split()[3].lower()
            for r, col, x in zip(A.row.tolist(), A.col.tolist(), A.data.tolist()):
                if not directed and r < col:
                    continue  # SciPy's mirrored copy
                d = {} if field == b"pattern" else {"weight": x}
                if not directed and r >= col and (r, col) in [(cc, rr) for rr, cc in [(r, col)]] and False:
                    pass
                G.add_edge(r, col, **d)
        elif f == "edgeList":
            cols = c["kw"].get("columns", [])
            create = (nx.DiGraph if simple else nx.MultiDiGraph)() if directed else (nx.Graph if simple else nx.MultiGraph)()
            data = [(k, lexical) for k in cols] if cols else (b"{" in raw)
            G = nx.read_edgelist(io.BytesIO(raw), create_using=create, data=data, delimiter=c["kw"].get("delimiter"))
        elif f == "adjacencyList":
            create = (nx.DiGraph if simple else nx.MultiDiGraph)() if directed else (nx.Graph if simple else nx.MultiGraph)()
            G = nx.read_adjlist(io.BytesIO(raw), create_using=create)
        elif f == "dot":
            gs = quiet_pydot(raw.decode("utf-8"))
            if not gs:
                raise ValueError("pydot: no graph")
            pg = gs[0]
            edges = pydot_edges(pg)
            if isinstance(ours, ParseError):
                return "library accepts it"
            if pg.get_strict() or c["target"].endswith("S"):
                return None  # pydot does not merge
            mine = [(str(g1), str(g2)) for g1, g2, _ in our_edges(ours)]
            if pg.get_subgraph_list():  # pydot keeps a subgraph's edges apart from the root's
                return None if sorted(edges) == sorted(mine) else f"edges {edges}"
            return None if edges == mine else f"edges {edges}"
        else:
            return None
    except Exception as e:  # noqa: BLE001
        return None if isinstance(ours, ParseError) else f"library raises {type(e).__name__}: {str(e)[:60]}"
    if isinstance(ours, ParseError):
        return "library accepts it"
    if not directed and f == "matrixMarket":
        # compare as unordered entries
        a = sorted(repr((tuple(sorted((u, v))), sorted(d.items()))) for u, v, d in nx_edges(G))
        b = sorted(repr((tuple(sorted((u, v))), sorted(d.items()))) for u, v, d in our_edges(ours))
        return None if a == b else "entries"
    return nx_matches(ours, G)


def pydot_edges(pg):
    """Every edge pydot read, a subgraph endpoint expanded to its vertices (tails outer)."""
    def ends(x):
        if isinstance(x, str):
            return [dot_unquote(x)]
        return [dot_unquote(k) for k in x["nodes"]]
    out = []
    for e in pg.get_edges():
        for u in ends(e.get_source()):
            for v in ends(e.get_destination()):
                out.append((u, v))
    for s in pg.get_subgraph_list():
        out += pydot_edges(s)
    return out


def quiet_pydot(text):
    import contextlib
    with contextlib.redirect_stdout(io.StringIO()):
        return pydot.graph_from_dot_data(text)


def dot_unquote(s):
    try:
        toks = dot_lex(s)
    except ParseError:
        return s
    kind, value = toks[0][1] if toks[0][0] == "id" else ("ident", s)
    return value


def library_write(c, out):
    """Byte comparison with the library's writer, or a read-back by the library."""
    g, kw, f = c["graph"], c["kw"], c["fmt"]
    if f in NEW_FORMATS:
        return library_write_new(c, out)
    if f == "nodeLinkJSON":
        G = (nx.MultiDiGraph if has_parallel(g) else nx.DiGraph)() if g.directed else (
            nx.MultiGraph if has_parallel(g) else nx.Graph)()
        for v, a in zip(g.vertices, g.vattrs):
            G.add_node(v, **a)
        for (u, v), a in zip(g.edges, g.eattrs):
            G.add_edge(g.vertices[u], g.vertices[v], **a)
        G.graph.update(g.gattrs)
        ref = json.dumps(nx.node_link_data(G, edges="edges"))
        if ref == out:
            return None
        if G.is_multigraph():
            # NetworkX lists edges by adjacency; ours are in position order. Same edges and keys?
            def norm(e):
                ends = (e["source"], e["target"])
                if not g.directed:
                    ends = tuple(sorted(ends, key=str))
                rest = sorted((k, v) for k, v in e.items() if k not in ("source", "target", "key"))
                return repr((ends, e["key"], rest))
            a, b = json.loads(ref), json.loads(out)
            if sorted(map(norm, a.pop("edges"))) == sorted(map(norm, b.pop("edges"))) and a == b:
                return None
        return f"NetworkX writes {ref!r}"
    if f == "matrixMarket":
        w = kw.get("weight")
        if not g.edges:
            return None  # SciPy writes field real for every empty matrix
        rows, cols = [], []
        for u, v in g.edges:
            r, cc = (u, v) if g.directed else (max(u, v), min(u, v))
            rows.append(r)
            cols.append(cc)
        field = "pattern" if w is None else ("integer" if all(type(x) is int for x in w) else "real")
        data = np.ones(len(rows)) if w is None else np.array(w, dtype=np.int64 if field == "integer" else float)
        A = scipy.sparse.coo_array((data, (rows, cols)), shape=(len(g.vertices),) * 2)
        b = io.BytesIO()
        scipy.io.mmwrite(b, A, field=field, symmetry="general" if g.directed else "symmetric")
        ref = b.getvalue().decode()
        return None if ref == out else f"SciPy writes {ref!r}"
    if f == "graphML":
        G = nx.read_graphml(io.BytesIO(out.encode()), node_type=str)
        expect = Target(g.directed)
        for v, a in zip(g.vertices, g.vattrs):
            expect.vattrs[expect.vertex(str(v))] = dict(a)
        for (u, v), a in zip(g.edges, g.eattrs):
            expect.eattrs[expect.edge(u, v)] = dict(a)
        promote(expect)
        r = nx_matches(expect, G)
        if r is None and G.graph != {**g.gattrs, "node_default": {}, "edge_default": {}} and G.graph != g.gattrs:
            r = f"graph attributes {G.graph}"
        return r
    if f == "dot":
        try:
            pg = quiet_pydot(out)[0]
        except Exception as e:  # noqa: BLE001
            return f"pydot raises {type(e).__name__}: {str(e)[:60]}"
        names = [dot_unquote(n.get_name()) for n in pg.get_nodes() if n.get_name() not in ("graph", "node", "edge")]
        edges = [(dot_unquote(e.get_source()), dot_unquote(e.get_destination())) for e in pg.get_edges()]
        if any("\\" in str(v) for v in g.vertices):
            return None  # pydot keeps backslashes before a quote and drops line continuations
        if names != [str(v) for v in g.vertices]:
            return f"pydot vertices {names}"
        mine = [(str(g.vertices[u]), str(g.vertices[v])) for u, v in g.edges]
        if sorted(edges) != sorted(mine):  # pydot groups the edges of one pair together
            return f"pydot edges {edges}"
        return None
    if f in ("edgeList", "adjacencyList"):
        if has_parallel(g):
            return None
        G = (nx.DiGraph if g.directed else nx.Graph)()
        G.add_nodes_from(g.vertices)
        for (u, v), a in zip(g.edges, g.eattrs):
            G.add_edge(g.vertices[u], g.vertices[v], **a)
        b = io.BytesIO()
        if f == "edgeList":
            if [(str(u), str(v)) for u, v in G.edges] != [(str(g.vertices[u]), str(g.vertices[v])) for u, v in g.edges]:
                return None  # NetworkX lists edges by adjacency, not by position
            nx.write_edgelist(G, b, data=list(kw.get("columns", [])) or False, delimiter=kw.get("delimiter") or " ")
            ref = b.getvalue().decode()
        else:
            nx.write_adjlist(G, b)
            ref = "".join(line + "\n" for line in b.getvalue().decode().splitlines() if not line.startswith("#"))
        return None if ref == out else f"NetworkX writes {ref!r}"
    return None


def promote(g):
    """GraphML: an integer and a double under one key are written as double."""
    for rows in (g.vattrs, g.eattrs):
        types = {}
        for a in rows:
            for k, x in a.items():
                types.setdefault(k, set()).add(type(x))
        for a in rows:
            for k, x in a.items():
                if types[k] == {int, float}:
                    a[k] = float(x)


def round_trip(c, out):
    """The model reads the writer's output back; returns None when it gives the graph back, up to what
    the format does not carry (api.md, Round trips)."""
    g, kw, f = c["graph"], c["kw"], c["fmt"]
    if f in NEW_FORMATS:
        return round_trip_new(c, out)
    vtype = int if g.vertices and isinstance(g.vertices[0], int) and f in ("matrixMarket", "nodeLinkJSON") else str
    back = run_reader(reader_for(f, **kw), out, Target(g.directed, False, vtype))
    if isinstance(back, ParseError):
        return f"reads back as {back}"
    expect = Target(g.directed, False, vtype)
    if f in ("matrixMarket",):
        for i in range(len(g.vertices)):
            expect.vertex(i)
    elif f not in ("edgeList",):
        for v in g.vertices:
            expect.vertex(v if vtype is int else str(v))
    if f == "graphML":
        for i, a in enumerate(g.vattrs):
            expect.vattrs[i] = dict(a)
        expect.gattrs = dict(g.gattrs)
    elif f == "nodeLinkJSON":
        for i, a in enumerate(g.vattrs):
            expect.vattrs[i] = dict(a)
        expect.gattrs = dict(g.gattrs)
    elif f == "dot":
        for i, a in enumerate(g.vattrs):
            expect.vattrs[i] = {k: dot_text(x) for k, x in a.items()}
        expect.gattrs = {k: dot_text(x) for k, x in g.gattrs.items()}
    elif f == "mermaid":
        for i, a in enumerate(g.vattrs):
            expect.vattrs[i] = {k: x for k, x in a.items() if k == "label"}
    for p, (u, v) in enumerate(g.edges):
        name = (lambda x: x) if f == "matrixMarket" else (lambda x: g.vertices[x] if vtype is int else str(g.vertices[x]))
        if f == "matrixMarket" and not g.directed:
            u, v = max(u, v), min(u, v)
        q = expect.edge(expect.vertex(name(u)), expect.vertex(name(v)))
        a = g.eattrs[p]
        if f in ("graphML", "nodeLinkJSON"):
            expect.eattrs[q] = dict(a)
        elif f == "dot":
            expect.eattrs[q] = {k: dot_text(x) for k, x in a.items()}
        elif f == "mermaid":
            expect.eattrs[q] = {k: x for k, x in a.items() if k == "label"}
        elif f == "edgeList":
            expect.eattrs[q] = {k: lexical(py_double(a[k]) if type(a[k]) is float else str(a[k]))
                                for k in kw.get("columns", [])}
        elif f == "matrixMarket" and kw.get("weight") is not None:
            expect.eattrs[q] = {"weight": kw["weight"][p]}
    if f == "graphML":
        promote(expect)
    if f == "adjacencyList":
        return None if (sorted(expect.vertices) == sorted(back.vertices) and
                        edge_multiset(our_edges(expect), g.directed) == edge_multiset(our_edges(back), g.directed)) \
            else f"reads back as {fmt_graph(back)}"
    ok = (expect.vertices == back.vertices and expect.edges == back.edges and expect.gattrs == back.gattrs and
          all(same_attrs(x, y) for x, y in zip(expect.vattrs, back.vattrs)) and
          all(same_attrs(x, y) for x, y in zip(expect.eattrs, back.eattrs)))
    return None if ok else f"reads back as {fmt_graph(back)}, expected {fmt_graph(expect)}"


def dot_text(x):
    if type(x) is bool:
        return "true" if x else "false"
    if type(x) is float:
        return py_double(x)
    return str(x)


# Library behaviour that differs from ours on purpose (api.md, Library disagreements).
KNOWN = {
    "a delimiter ending the line adds an empty field at the end": "NetworkX ignores fields past the declared data",
    # GF-232 – GF-256
    "a vertex count above the default maximumVertexCount (16 a byte plus 4,096)": "SciPy makes the empty 2^24 + 1 square matrix lazily",
    # GF-257 – GF-259
    "a 69-byte file claiming 2^24 vertices is over the default maximumVertexCount": "SciPy makes the empty 2^24 square matrix lazily",
    "edgedefault with whitespace around it": "NetworkX compares edgedefault without collapsing whitespace, so reads it undirected",
    "pattern: a third field on an entry": "SciPy ignores extra columns",
    "a lone CR inside a field": "SciPy reads 1\\r2 as two fields",
    "one token before CR LF": "NetworkX skips lines with fewer than two tokens",
    "an entry cut short before CR LF": "",
    "NBSP between three fields makes three fields": "NetworkX ignores tokens past the declared data (it splits at NBSP too)",
    # GF-226 – GF-231
    "an id that is neither a string nor an integer": "NetworkX takes any hashable JSON value as a node id (1.5 here)",
    "skew-symmetric: a mirrored weight outside Int": "SciPy negates in int64 and wraps -2^63 to itself",
    # DOT: pydot 4.0.1's grammar, not Graphviz's
    "numerals are IDs": "pydot rejects a negative numeral after an edge operator",
    "attribute lists: ; and , separators, several lists": "pydot rejects ; inside [ ] and a second [ ] list",
    "a byte-order mark is skipped": "pydot does not skip a byte-order mark",
    "graph into a directed target": "pydot has no target: it reads either kind",
    "digraph into an undirected target": "pydot has no target: it reads either kind",
    "-- in a digraph": "pydot accepts either edge operator in either kind (Graphviz: syntax error)",
    "a second graph (unsupported)": "pydot returns a list of graphs",
    "numeral followed by a letter": "pydot splits 1a into two IDs (Graphviz warns and splits)",
    "attribute without a value": "pydot accepts [k] (Graphviz: syntax error)",
    # GraphML: NetworkX 3.7 read_graphml
    "a key's default applies where no data element gives it":
        "NetworkX stores defaults in G.graph['node_default'] and does not apply them (graphml spec: applies)",
    "missing attr.type is string; missing attr.name is the key id; for=\"all\"": "NetworkX requires attr.name",
    "DOCTYPE (no DTD, so no entity expansion)": "NetworkX (expat) expands internal entities",
    "edgedefault is required (graphml.xsd)": "NetworkX reads a missing edgedefault as undirected",
    "undirected into a directed target": "NetworkX has no target: it reads either kind",
    "edge to an undeclared node": "NetworkX adds the node",
    "duplicate node id": "NetworkX merges the two nodes",
    "a second graph (unsupported)": "NetworkX reads the first graph only",
    "encoding other than UTF-8": "NetworkX (expat) decodes ISO-8859-1",
    "nesting deeper than 64 elements": "NetworkX has no depth limit",
    # node-link JSON: json.loads + node_link_graph
    "\"links\" is read when \"edges\" is absent (NetworkX before 3.4)": "NetworkX 3.7 requires edges=\"links\" for it",
    "directed into an undirected target": "NetworkX has no target: it reads either kind",
    "duplicate object key": "json.loads keeps the last value",
    "duplicate vertex (1 and \"1\" in a String target)": "NetworkX node ids keep their JSON type",
    "string id into an Int target": "NetworkX node ids keep their JSON type",
    "edge to an undeclared vertex": "NetworkX adds the node",
    "null attribute (unsupported)": "NetworkX stores None",
    "array attribute (unsupported)": "NetworkX stores the list",
    "nesting deeper than 64": "json.loads nests to Python's recursion limit",
    "number overflows Double": "json.loads gives inf",
    "integer beyond Int64": "json.loads gives a Python int of any size",
    "lone surrogate": "json.loads keeps a lone surrogate in the str",
    "NaN is not JSON": "json.loads accepts NaN, Infinity",
    "missing id": "NetworkX makes a node named None",
    # Matrix Market: SciPy 1.18.1 mmread (fast_matrix_market)
    "array format (unsupported)": "SciPy reads array format",
    "complex (unsupported)": "SciPy reads complex",
    "hermitian (unsupported)": "SciPy reads hermitian",
    "general into an undirected target": "SciPy has no target",
    "not square": "SciPy reads rectangular matrices (NetworkX from_scipy_sparse_array raises)",
    "an extra column": "SciPy ignores extra columns",
    "integer field with a fraction": "SciPy truncates 3.5 to 3",
    "hexadecimal float": "SciPy reads 0x1p3 as 0.0",
    "skew-symmetric diagonal entry": "SciPy keeps a diagonal entry in a skew-symmetric file",
    "pattern skew-symmetric": "SciPy accepts the combination the spec forbids",
    "signed index": "SciPy accepts +1 as an index",
    # DOT subgraphs (pydot 4.0.1)
    "a subgraph operand's own edges come before the chain's": "pydot drops the chain's edges from a subgraph that holds an edge",
    "nested named subgraphs as an operand: every vertex mentioned inside": "pydot gives a subgraph operand only its direct node statements",
    "a subgraph's edge defaults apply to edges from it, not to a later chain": "pydot reads the keyword edge in a subgraph operand as a node",
    "64 nested subgraphs": "pydot's parser exceeds Python's recursion limit",
    "subgraph without a body (unsupported)": "pydot accepts a subgraph reference",
    # GraphML nested graphs (NetworkX 3.7)
    "a nested graph in a node that is not a yEd group": "NetworkX reads a nested graph's nodes only under yfiles.foldertype=\"group\"",
    "a nested graph without edgedefault": "NetworkX does not check a nested graph",
    "a nested graph of the other kind (unsupported)": "NetworkX does not check a nested graph",
    "a node inside a nested graph declared twice": "NetworkX merges the two nodes",
    "data after a node's nested graph (unsupported)": "NetworkX reads a node's data wherever it is among its children",
    "a graph inside an edge stays unsupported": "NetworkX ignores it",
    # node-link tuple ids (NetworkX 3.7)
    "array ids (NetworkX tuples) are their canonical JSON text": "NetworkX makes an edge endpoint's array a tuple without converting the arrays inside it (unhashable)",
    "an array id into an Int target": "NetworkX has no target: the id is a tuple",
    "an array id and the string of its text are one id": "NetworkX keeps the tuple (1, 2) and the string \"[1, 2]\" apart",
    "an edge to an array id no node declares": "NetworkX adds the node",
    # edge list dict data and delimiters (NetworkX 3.7 parse_edgelist)
    "dict values: floats, booleans, inf, nan, signs, a trailing comma": "literal_eval reads no inf or nan",
    "a dict string may hold # and the delimiter; a comment may follow the dict": "NetworkX cuts the line at the first #, inside the dict too",
    "None in a dict (unsupported)": "NetworkX stores None",
    "a list in a dict (unsupported)": "NetworkX stores the list",
    "a dict integer beyond Int64": "literal_eval reads an int of any size",
    "a surrogate escape": "Python keeps a lone surrogate in the str",
    "comma-delimited integers into an Int target": "NetworkX splits only the LF, so the CR stays in the last field",
    "delimited: too few fields": "NetworkX skips lines with fewer than two fields",
    "delimited: an extra field": "NetworkX with data=False ignores fields past the endpoints",
    "delimited: a missing column": "NetworkX accepts a line without its data",
    # GML (NetworkX 3.7 parse_gml)
    ("gml", "a node without a label is named by its id"): "NetworkX names every node by label (label=\"label\") or every one by id (label=\"id\")",
    ("gml", "character references and the four named entities are decoded; others are kept"):
        "NetworkX decodes every HTML 4 entity (&nbsp;) and makes &#xD800; a lone surrogate",
    ("gml", "lists such as graphics are skipped; top-level keys are ignored; # comments"): "NetworkX keeps a list value as a dict attribute",
    ("gml", "multigraph 1: parallel edges kept"): "NetworkX takes key as the edge's key, not an attribute",
    ("gml", "simple target: parallel edges merge, last value wins"): "NetworkX rejects a parallel edge without multigraph 1",
    ("gml", "simple undirected target: 1-0 is 0-1"): "NetworkX rejects a parallel edge without multigraph 1",
    ("gml", "a string may span lines"): "NetworkX joins the lines of a string with a space and fails on this one",
    ("gml", "a number as a label is its text"): "NetworkX keeps a numeric label as a number (1.5, not 1.50)",
    ("gml", "graph attributes where they are read; a repeated key is reported again"): "NetworkX makes a repeated key a list",
    ("gml", "a byte-order mark, CR LF and tabs"): "NetworkX does not skip a byte-order mark",
    ("gml", "directed that is not 0 or 1"): "NetworkX reads any true value as directed",
    ("gml", "directed 1 into an undirected target"): "NetworkX has no target: it reads either kind",
    ("gml", "no directed into a directed target"): "NetworkX has no target: it reads either kind",
    ("gml", "directed 0 into a directed target"): "NetworkX has no target: it reads either kind",
    ("gml", "directed twice"): "NetworkX makes a repeated key a list",
    ("gml", "multigraph that is not 0 or 1"): "NetworkX reads any true value as a multigraph",
    ("gml", "an id that is not an integer"): "NetworkX takes any value as an id",
    ("gml", "a label equal to another node's id text"): "NetworkX compares a label with labels only",
    ("gml", "a source that is not an integer"): "NetworkX takes any value as an endpoint (0.0 == 0)",
    ("gml", "a key where a value should be"): "NetworkX takes an unquoted word as the value of id, label, source and target",
    ("gml", "an integer beyond Int64"): "NetworkX reads an int of any size",
    ("gml", "65 nested lists"): "NetworkX has no depth limit",
    # Pajek (NetworkX 3.7 parse_pajek)
    ("pajek", "arcs with weights and key-value pairs; vertices with coordinates, shape and pairs"):
        "NetworkX reads x, y and shape only from lines of five fields or more",
    ("pajek", "a vertex without a line is named by its number; lines in any order"): "NetworkX reads exactly n lines after *vertices",
    ("pajek", "a vertex line with only its number is labelled by it"): "NetworkX requires a label on every vertex line (ValueError)",
    ("pajek", "*network, % comments, blank lines, keywords in any case, a 2-mode count"):
        "NetworkX fails on a second number after *vertices and does not skip % comments",
    ("pajek", "*arcslist: a vertex then its successors"): "NetworkX reads exactly n lines after *vertices and has no *arcslist",
    ("pajek", "*edgeslist"): "NetworkX reads exactly n lines after *vertices and has no *edgeslist",
    ("pajek", "labels that map to one vertex are that vertex"): "NetworkX reads exactly n lines after *vertices",
    ("pajek", "a byte-order mark"): "NetworkX does not skip a byte-order mark",
    ("pajek", "*network after the vertices does not end their section"): "NetworkX reads exactly n lines after *vertices",
    ("pajek", "a data line before *vertices"): "NetworkX ignores lines outside a section",
    ("pajek", "a vertex number given twice"): "NetworkX reads both lines",
    ("pajek", "an x that is not a number"): "NetworkX drops x, y and shape it cannot read",
    ("pajek", "a key without a value"): "NetworkX drops an unpaired field",
    ("pajek", "a second *vertices (unsupported)"): "NetworkX reads every *vertices section",
    ("pajek", "an unknown section (unsupported)"): "NetworkX ignores lines outside a section",
    ("pajek", "coordinates, shape, weights and key-value pairs"): "NetworkX skips non-string attributes (with a warning)",
    ("pajek", "quoting: whitespace, quotes, backslashes, apostrophes, empty strings"):
        "NetworkX leaves an apostrophe and an empty string unquoted (unreadable by shlex) and skips empty values",
    # graph6, sparse6 (NetworkX 3.7)
    ("graph6", "graph6: CR LF"): "NetworkX strips only the LF",
    ("graph6", "graph6: padding bits that are not 0"): "NetworkX does not check the padding",
    ("sparse6", "sparse6: one vertex with a loop (k = 0)"): "NetworkX uses k = 1 for n <= 1 (nauty: the bits of n - 1, so 0)",
    ("sparse6", "sparse6: a size above the default maximumVertexCount"): "NetworkX makes every vertex",
    ("sparse6", "sparse6: a size above maximumVertexCount"): "NetworkX has no bound",
    ("sparse6", "sparse6: a loop at vertex 0 of four (nauty's padding)"):
        "NetworkX pads with a 0 bit whenever the last vertex is below n - 1 (:CB); nauty only when it is n - 2 (:CF)",
    # Cytoscape JSON (NetworkX 3.7 cytoscape_graph)
    ("cytoscapeJSON", "directed, attributes, NetworkX's graph data pairs"): "NetworkX requires every node's value",
    ("cytoscapeJSON", "Cytoscape.js: an array of elements with group; position and classes ignored; data object"):
        "NetworkX requires data as pairs and elements as an object",
    ("cytoscapeJSON", "without group, an element is an edge when its data has source"): "NetworkX requires data and elements as an object",
    ("cytoscapeJSON", "multigraph true: every edge kept, key not reported"): "NetworkX requires data and each node's value",
    ("cytoscapeJSON", "multigraph false: parallel edges kept, key reported"): "NetworkX requires data and each node's value",
    ("cytoscapeJSON", "simple target: parallel edges merge, last value wins"): "NetworkX requires data and each node's value",
    ("cytoscapeJSON", "integer ids and endpoints are their decimal text"): "NetworkX requires data and each node's value",
    ("cytoscapeJSON", "no nodes or edges members"): "NetworkX requires data, nodes and edges",
    ("cytoscapeJSON", "typed attributes; a vertex's own name and value stay in place"):
        "NetworkX overwrites a node's value attribute with the node",
    # edge list, adjacency list: NetworkX 3.7
    "one token": "NetworkX skips lines with fewer than two tokens",
    "an extra token": "NetworkX ignores tokens past the declared data",
    "a missing column": "NetworkX accepts a line without its data",
    "comments and blank lines": "NetworkX read_adjlist raises IndexError on a line that is only a comment",
}


# ============================================================================ catalog

def number_cases():
    for k, c in enumerate(CASES, 1):
        c["id"] = f"GF-{k:03d}"


def md(s):
    return s.replace("|", "\\|")


def code(s):
    return "`" + md(s) + "`" if "`" not in s else "``" + md(s) + "``"


def literal(x):
    if isinstance(x, bytes):
        try:
            x = x.decode("utf-8")
        except UnicodeDecodeError:
            return "bytes " + " ".join(f"{b:02x}" for b in x)
    # Whitespace other than the space is escaped, so that a cell shows it (JSON's \uXXXX).
    return "".join(f"\\u{ord(ch):04x}" if ch.isspace() and ord(ch) > 0x7F else ch
                   for ch in json.dumps(x, ensure_ascii=False))


def op_of(c):
    f = c["fmt"]
    if c["kind"] == "read":
        extra = ", columns: " + json.dumps(c["kw"]["columns"]) if "columns" in c["kw"] else ""
        if "delimiter" in c["kw"]:
            extra += ", delimiter: " + json.dumps(c["kw"]["delimiter"])
        if "maximumVertexCount" in c["kw"]:
            extra += f", maximumVertexCount: {c['kw']['maximumVertexCount']}"
        return f"{TARGETS[c['target']][0]}({LABEL[f]}:{extra})"
    kw = c["kw"]
    extra = ""
    if "columns" in kw:
        extra = ", columns: " + json.dumps(kw["columns"])
    if "delimiter" in kw:
        extra += ", delimiter: " + json.dumps(kw["delimiter"])
    if kw.get("header"):
        extra += ", header: true"
    if "weight" in kw:
        extra = ", weight: " + "[" + ", ".join(fmt_value(w) for w in kw["weight"]) + "]"
    return WRITER[f].replace("(to:)", f"(to:{extra})")


def render():
    number_cases()
    rows = []
    for c in CASES:
        r = evaluate(c)
        if c["kind"] == "read":
            inp, exp = code(literal(c["text"])), md(fmt_graph(r)) if isinstance(r, ParseError) else code(fmt_graph(r))
        else:
            inp, exp = code(fmt_graph(c["graph"])), code(literal(r))
        rows.append(f"| {c['id']} | {GROUP[c['fmt']]} {'read' if c['kind'] == 'read' else 'write'} | "
                    f"{md(c['case'])} | `{md(op_of(c))}` | {inp} | {exp} |")
    reads = sum(c["kind"] == "read" for c in CASES)
    errors = sum(c["kind"] == "read" and isinstance(evaluate(c), ParseError) for c in CASES)
    head = HEADER.format(n=len(CASES), reads=reads, errors=errors, writes=len(CASES) - reads)
    return head + "\n".join(rows) + "\n"


HEADER = """# GraphFormats: case catalog (GF-001 – GF-{n:03d}, {n} rows)

Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 --with
scipy==1.18.1 --with pydot==4.0.1 python3 Tests/Catalogs/GraphFormats/ref.py`; `--write`
regenerates this file, `--stress` adds random round trips and mutated inputs). {reads} read rows
({errors} of them errors) and {writes} write rows. The model implements api.md independently of the
libraries; each row is then compared with NetworkX 3.7 (GraphML, node-link JSON, edge list,
adjacency list, GML, Pajek, graph6, sparse6, Cytoscape JSON), SciPy 1.18.1 (Matrix Market) or pydot
4.0.1 (DOT), where the library reads or writes the format (no Python library reads digraph6, DIMACS
or METIS), and every write row is read back by the model. Rows where a library differs are listed,
with the reason, under "Library disagreements" in api.md.

## Notation

**Op.** A read row calls the reader initializer on the target type, with the default vertex
mapping (`String` IDs as they are; `Int` targets take Matrix Market's, DIMACS's and METIS's
1-based indices minus one, node-link integer ids, and the nauty formats' vertices `0..<n`), with the
options shown (`columns:`, `delimiter:`, `maximumVertexCount:`). A write row calls the writer on the
graph in **Input** with the default `vertexID` (`String(describing:)`) and the graph's attributes as
the attribute closures (`label` only, for Mermaid; `weight:` for Matrix Market, DIMACS and METIS,
`columns:` and `delimiter:` for the edge list, `header:` for the nauty formats).

**Input** of a read row and **Expected** of a write row are the exact text, as a JSON string
literal (so `\\n` is a line feed, `\\t` a tab). `bytes …` is input that is not UTF-8.

**Graphs.** `D:` directed, `U:` undirected; then the vertices in `vertices` order, and after `;` the
edges (when there are any) in position order (`a>b` an arc, `a-b` an undirected edge, written in its stored orientation),
and `; graph{{…}}` for graph attributes when there are any. `{{k=v, …}}` after a vertex or an edge
is its attributes: keys in the order they were first set, each with the last value set. Values:
`"…"` a string, `3` an integer, `2.0` / `1e-05` / `inf` / `nan` a double (Python's `repr`),
`true` / `false` a boolean. A vertex name is written bare when it is letters, digits and `_`,
otherwise as a JSON string.

**Errors.** `**kind** at line:column`: the `ParseError.Kind` and the 1-based position of the first
offending character, the column counted in Unicode scalars (api.md, Errors).

| ID | Group | Case | Op | Input | Expected |
|---|---|---|---|---|---|
"""


def check_rows():
    number_cases()
    bad = []
    for c in CASES:
        r = evaluate(c)
        key = c["id"]
        if c["kind"] == "read":
            why = library_read(c)
        else:
            why = library_write(c, r) or round_trip(c, r)
        reason = known(c)
        if why and reason is None:
            bad.append(f"{key} {c['fmt']} {c['case']}: {why}")
        if not why and reason:
            bad.append(f"{key} listed in KNOWN but agrees")
    return bad


# ============================================================================ stress

def random_graph(rng, directed, vtype=str, attrs=True):
    n = rng.randint(0, 7)
    alphabet = ["a", "b", "x y", 'q"', "\\", "é", "日", "\n", "#", "<&>", "1", "-2", "_"]
    names = []
    while len(names) < n:
        v = rng.randint(0, 50) if vtype is int else "".join(rng.choice(alphabet) for _ in range(rng.randint(1, 3)))
        if v not in names:
            names.append(v)
    edges = [(rng.choice(names), rng.choice(names)) for _ in range(rng.randint(0, 9))] if names else []
    g = graph(directed, names, edges)
    g.vtype = vtype
    if attrs:
        pick = lambda: rng.choice([rng.randint(-5, 5), rng.choice([0.5, -2.0, 1e-07, 1e22, 3.25]),
                                   rng.choice(alphabet) * rng.randint(1, 2), rng.random() < 0.5])
        for a in g.vattrs:
            for k in rng.sample(["label", "c", "w"], rng.randint(0, 2)):
                a[k] = pick()
        for a in g.eattrs:
            for k in rng.sample(["label", "w"], rng.randint(0, 2)):
                a[k] = pick()
    return g


def stress():
    rng = random.Random(7)
    failures, count = [], 0
    for k in range(400):
        directed = rng.random() < 0.6
        g = random_graph(rng, directed)
        # GraphML needs one type per key: keep the first type of each.
        for rows in (g.vattrs, g.eattrs):
            seen = {}
            for a in rows:
                for kk in list(a):
                    t = type(a[kk])
                    if seen.setdefault(kk, t) is not t:
                        del a[kk]
        for f in ("dot", "graphML", "nodeLinkJSON"):
            c = dict(kind="write", fmt=f, case="stress", graph=g, kw={})
            out = write_output(c)
            why = round_trip(c, out)
            if f == "graphML" and not why:
                why = library_write(c, out)
            if f == "dot" and not why:
                why = library_write(c, out)
                if why and why.startswith("pydot raises"):
                    why = None  # pydot 4.0.1 fails on some quoted IDs (a leading '-', for one)
            count += 1
            if why:
                failures.append(f"{f} {fmt_graph(g)}: {why}")
        gi = random_graph(rng, directed, int, attrs=False)
        w = [rng.choice([rng.randint(-9, 9), 0.1 * rng.randint(-99, 99)]) for _ in gi.edges]
        w = [float(x) for x in w] if any(type(x) is float for x in w) else w
        for kw in ({}, {"weight": w}):
            c = dict(kind="write", fmt="matrixMarket", case="stress", graph=gi, kw=kw)
            out = write_output(c)
            count += 1
            why = round_trip(c, out) or library_write(c, out)
            if why:
                failures.append(f"matrixMarket {fmt_graph(gi)} {kw}: {why}")
        plain = graph(directed, [f"v{i}" for i in range(rng.randint(1, 6))], [])
        for _ in range(rng.randint(0, 8)):
            plain.edges.append((rng.randrange(len(plain.vertices)), rng.randrange(len(plain.vertices))))
            plain.eattrs.append({"label": rng.choice(["a", 'b "c"', "#x;", "<p>&", "x|y", "two\nlines"])})
        for i, a in enumerate(plain.vattrs):
            if rng.random() < 0.5:
                a["label"] = rng.choice(["A", "[b]", "(c)", '"q"', "#35;"])
        for f in ("mermaid", "adjacencyList", "edgeList"):
            c = dict(kind="write", fmt=f, case="stress", graph=plain, kw={})
            out = write_output(c)
            count += 1
            why = round_trip(c, out) or library_write(c, out)
            if why:
                failures.append(f"{f} {fmt_graph(plain)}: {why}")
        # The formats added after the first seven.
        gs = random_graph(rng, directed)
        # NetworkX's GML writer quotes every value under a key named label (label 5 is "5"); the
        # vertex label is the ID here, so neither carries one.
        for a in gs.vattrs + gs.eattrs:
            a.pop("label", None)
        for f in ("gml", "cytoscapeJSON", "pajek"):
            gp = gs
            if f == "pajek":
                if any("\n" in v for v in gs.vertices):
                    continue
                gp = graph(directed, gs.vertices, [(gs.vertices[u], gs.vertices[v]) for u, v in gs.edges])
                for i, a in enumerate(gs.vattrs):
                    gp.vattrs[i] = {k: x for k, x in a.items() if not (type(x) is str and "\n" in x) and k not in ("x", "y")}
                for i, a in enumerate(gs.eattrs):
                    gp.eattrs[i] = {k: x for k, x in a.items() if not (type(x) is str and "\n" in x) and k != "weight"}
            c = dict(kind="write", fmt=f, case="stress", graph=gp, kw={})
            out = write_output(c)
            count += 1
            why = round_trip(c, out)
            if not why and f in ("gml", "cytoscapeJSON"):
                why = library_write(c, out)
            if why:
                failures.append(f"{f} {fmt_graph(gp)}: {why}")
        gu = random_graph(rng, False, int, attrs=False)
        gu = graph(False, list(range(len(gu.vertices))), [])
        n = len(gu.vertices)
        for _ in range(rng.randint(0, 12) if n else 0):
            gu.edges.append((rng.randrange(n), rng.randrange(n)))
            gu.eattrs.append({})
        simple = graph(False, list(range(n)), [])
        seen = set()
        for u, v in gu.edges:
            if u != v and (min(u, v), max(u, v)) not in seen:
                seen.add((min(u, v), max(u, v)))
                simple.edges.append((u, v))
                simple.eattrs.append({})
        gd = graph(True, list(range(n)), [])
        for u, v in set(gu.edges):
            gd.edges.append((u, v))
            gd.eattrs.append({})
        cases = [("graph6", simple, {}), ("graph6", simple, {"header": True}), ("sparse6", gu, {}),
                 ("digraph6", gd, {}), ("dimacs", gd, {"weight": [rng.randint(-9, 9) for _ in gd.edges]}),
                 ("dimacs", gu, {}), ("metis", simple, {}), ("metis", simple, {"weight": [rng.randint(-9, 9) for _ in simple.edges]})]
        for f, gg, kw in cases:
            c = dict(kind="write", fmt=f, case="stress", graph=gg, kw=kw)
            out = write_output(c)
            count += 1
            why = round_trip(c, out)
            if not why and f == "graph6":
                why = library_write(c, out)
            if not why and f == "sparse6" and n > 1:
                G = nx.from_sparse6_bytes(out.rstrip("\n").encode())
                if edge_multiset([(u, v, {}) for u, v in G.edges()], False) != edge_multiset(
                        [(gg.vertices[u], gg.vertices[v], {}) for u, v in gg.edges], False):
                    why = f"NetworkX reads {sorted(G.edges())}"
            if why:
                failures.append(f"{f} {fmt_graph(gg)} {kw}: {why}")
        gl = graph(directed, ["a b", "c", "", "d#"[:1]], [])
        for _ in range(rng.randint(0, 5)):
            gl.edges.append((rng.randrange(4), rng.randrange(4)))
            gl.eattrs.append({"w": rng.choice([1, -2.5, "x y", ""])})
        c = dict(kind="write", fmt="edgeList", case="stress", graph=gl, kw={"delimiter": ",", "columns": ["w"]})
        out = write_output(c)
        count += 1
        why = round_trip(c, out)
        if why:
            failures.append(f"edgeList , {fmt_graph(gl)}: {why}")
    # mutated inputs: every model reader returns a graph or a ParseError
    seeds = [c for c in CASES if c["kind"] == "read"]
    crashes = 0
    for k in range(3000):
        c = rng.choice(seeds)
        raw = bytearray(c["text"].encode() if isinstance(c["text"], str) else c["text"])
        for _ in range(rng.randint(1, 4)):
            op = rng.randrange(3)
            pos = rng.randrange(len(raw) + 1)
            if op == 0 and raw:
                del raw[min(pos, len(raw) - 1)]
            elif op == 1:
                raw[pos:pos] = bytes([rng.choice(b'<>{}[]"&;#-=|\\\n\r\t 0aZ%.:\xc3\xff')])
            elif raw:
                raw[min(pos, len(raw) - 1)] = rng.randrange(256)
        try:
            run_reader(reader_for(c["fmt"], **c["kw"]), bytes(raw), make_target(c["target"]))
        except Exception as e:  # noqa: BLE001
            crashes += 1
            failures.append(f"{c['fmt']} mutated {bytes(raw)!r}: {type(e).__name__} {e}")
    print(f"stress: {count} round trips, 3000 mutated inputs, {len(failures)} failures")
    for f in sorted(failures, key=lambda s: s.split()[0])[:20]:
        print("  ", f)
    return not failures


# ============================================================================ bench

def bench():
    import tempfile
    rng = random.Random(1)
    n, m = 100_000, 1_000_000
    G = nx.gnm_random_graph(n, m, seed=1, directed=True)
    for u, v, d in G.edges(data=True):
        d["weight"] = rng.random()
    tmp = tempfile.mkdtemp()

    def t(label, fn, repeat=1):
        best = math.inf
        for _ in range(repeat):
            s = time.perf_counter()
            fn()
            best = min(best, time.perf_counter() - s)
        print(f"| {label} | {best * 1000:.0f} ms |")

    p = os.path.join(tmp, "g")
    print(f"random directed graph, {n:,} vertices, {m:,} edges, a double weight per edge")
    print("| Operation | Time |\n|---|---|")
    t("NetworkX write_edgelist(data=['weight'])", lambda: nx.write_edgelist(G, p + ".el", data=["weight"]))
    print(f"| (edge list size) | {os.path.getsize(p + '.el') / 1e6:.1f} MB |")
    t("NetworkX read_edgelist(data=[('weight', float)])",
      lambda: nx.read_edgelist(p + ".el", create_using=nx.DiGraph, nodetype=int, data=[("weight", float)]))
    t("NetworkX write_adjlist", lambda: nx.write_adjlist(G, p + ".al"))
    t("NetworkX read_adjlist", lambda: nx.read_adjlist(p + ".al", create_using=nx.DiGraph))
    t("NetworkX write_graphml", lambda: nx.write_graphml(G, p + ".graphml"))
    print(f"| (GraphML size) | {os.path.getsize(p + '.graphml') / 1e6:.1f} MB |")
    t("NetworkX read_graphml", lambda: nx.read_graphml(p + ".graphml"))
    t("json.dumps(node_link_data)", lambda: open(p + ".json", "w").write(json.dumps(nx.node_link_data(G, edges="edges"))))
    t("node_link_graph(json.loads)", lambda: nx.node_link_graph(json.loads(open(p + ".json").read())))
    A = nx.to_scipy_sparse_array(G, format="coo")
    t("SciPy mmwrite (real general)", lambda: scipy.io.mmwrite(p + ".mtx", A, symmetry="general"), repeat=3)
    print(f"| (Matrix Market size) | {os.path.getsize(p + '.mtx') / 1e6:.1f} MB |")
    t("SciPy mmread", lambda: scipy.io.mmread(p + ".mtx"), repeat=3)
    import scipy.io._fast_matrix_market as fmm
    threads, fmm.PARALLELISM = fmm.PARALLELISM, 1
    t("SciPy mmwrite, one thread", lambda: scipy.io.mmwrite(p + ".mtx", A, symmetry="general"), repeat=3)
    t("SciPy mmread, one thread", lambda: scipy.io.mmread(p + ".mtx"), repeat=3)
    fmm.PARALLELISM = threads
    t("SciPy mmread → NetworkX from_scipy_sparse_array",
      lambda: nx.from_scipy_sparse_array(scipy.io.mmread(p + ".mtx"), create_using=nx.DiGraph))
    small = nx.gnm_random_graph(10_000, 100_000, seed=1, directed=True)
    t("pydot: to_pydot(...).to_string(), 10^5 edges", lambda: open(p + ".dot", "w").write(nx.nx_pydot.to_pydot(small).to_string()))
    t("pydot graph_from_dot_data, 10^5 edges", lambda: pydot.graph_from_dot_data(open(p + ".dot").read()))


# ============================================================================ main

def main():
    if "--bench" in sys.argv:
        bench()
        return
    text = render()
    path = os.path.join(HERE, "cases.md")
    if "--write" in sys.argv:
        with open(path, "w") as fh:
            fh.write(text)
        print(f"wrote {path}")
    else:
        old = open(path).read() if os.path.exists(path) else ""
        if old != text:
            print("cases.md differs from the model (run with --write)")
            sys.exit(1)
    bad = check_rows()
    for b in bad:
        print("MISMATCH", b)
    ok = not bad
    if "--stress" in sys.argv:
        ok = stress() and ok
    print(f"{len(CASES)} rows; {'ok' if ok else 'FAILED'}")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
