#!/usr/bin/env python3
"""Reference model for GraphFormats (Tests/Catalogs/GraphFormats).

Run: uv run --quiet --no-project --with networkx==3.7 --with scipy==1.18.1 --with pydot==4.0.1 \
         python3 Tests/Catalogs/GraphFormats/ref.py [--write] [--stress] [--bench]

The model is an independent Python implementation of api.md: one reader and one writer per
format (DOT, GraphML, node-link JSON, Matrix Market, edge list, adjacency list, Mermaid), with
its own UTF-8, XML and JSON scanners, so that every rule api.md states (what is accepted, what
is an error and where, what a writer prints byte for byte) is code here.

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
--bench prints the baselines api.md quotes.
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
        elif c.isdigit() or c == "." or c == "-":
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
            if word.lower() in DOT_KEYWORDS:
                toks.append(("kw", word.lower(), p))
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
    node_defaults, edge_defaults, merged = {}, {}, {}

    def node(name):
        if name in g.index:
            return g.index[name]
        v = g.vertex(name)
        for k, x in node_defaults.items():
            g.vattrs[v][k] = x
        return v

    while True:
        tok = peek()
        if tok[0] == "}":
            take()
            break
        if tok[0] == "eof":
            fail(tok)
        if tok[0] == ";":
            take()
            continue
        if tok[0] == "{" or (tok[0] == "kw" and tok[1] == "subgraph"):
            fail(tok, "unsupported")
        if tok[0] == "kw" and tok[1] in ("graph", "node", "edge"):
            take()
            if peek()[0] != "[":
                fail(peek())
            pairs = attr_list()
            target = {"graph": g.gattrs, "node": node_defaults, "edge": edge_defaults}[tok[1]]
            for k, x in pairs:
                target[k] = x
        elif tok[0] == "id":
            a = ident()
            if peek()[0] == "=":
                take()
                g.gattrs[a] = ident()
            elif peek()[0] == ":":
                fail(peek(), "unsupported")
            elif peek()[0] in ("->", "--"):
                names = [a]
                while peek()[0] in ("->", "--"):
                    e = take()
                    if e[0] != op:
                        fail(e)
                    nxt = peek()
                    if nxt[0] == "{" or (nxt[0] == "kw" and nxt[1] == "subgraph"):
                        fail(nxt, "unsupported")
                    names.append(ident())
                    if peek()[0] == ":":
                        fail(peek(), "unsupported")
                pairs = attr_list()
                vs = [node(x) for x in names]
                for u, v in zip(vs, vs[1:]):
                    k = g.key(u, v)
                    if strict and k in merged:
                        p = merged[k]
                    else:
                        p = g.edge(u, v)
                        merged.setdefault(k, p)
                        for kk, x in edge_defaults.items():
                            g.eattrs[p][kk] = x
                    for kk, x in pairs:
                        g.eattrs[p][kk] = x
            else:
                pairs = attr_list()
                v = node(a)
                for k, x in pairs:
                    g.vattrs[v][k] = x
        else:
            fail(tok)
        if peek()[0] == ";":
            take()
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
    if s.isascii() and re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", s) and s.lower() not in DOT_KEYWORDS:
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
                if m.group().lower() == "xml":
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
        m = re.fullmatch(r"\s+version\s*=\s*(['\"])1\.[0-9]+\1"
                         r"(\s+encoding\s*=\s*(['\"])([A-Za-z][A-Za-z0-9._\-]*)\3)?"
                         r"(\s+standalone\s*=\s*(['\"])(yes|no)\6)?\s*", decl)
        if not m:
            raise ParseError("syntax", 0)
        if m.group(4) and m.group(4).lower() not in ("utf-8", "utf8"):
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
            if m.group() != stack[-1].name:
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
    if not m or m.group().lower() == "xml":
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
    if ed not in ("directed", "undirected"):
        raise ParseError("invalidValue", off)
    if (ed == "directed") != g.directed:
        raise ParseError("kindMismatch", gr.offset)

    def data_of(el, dom):
        out = {}
        for c in el.children:
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
    for el in gr.children:
        if el.local == "node":
            if "id" not in el.attrs:
                raise ParseError("syntax", el.offset)
            nid, off = el.attrs["id"]
            if nid in g.index:
                raise ParseError("duplicateVertex", off)
            for c in el.children:
                if c.local in ("graph", "port"):
                    raise ParseError("unsupported", c.offset)
            v = g.vertex(nid)
            g.vattrs[v].update(data_of(el, "node"))
        elif el.local == "edge":
            for a in ("source", "target"):
                if a not in el.attrs:
                    raise ParseError("syntax", el.offset)
            for a in ("sourceport", "targetport"):
                if a in el.attrs:
                    raise ParseError("unsupported", el.attrs[a][1])
            if "directed" in el.attrs:
                d, off = el.attrs["directed"]
                if d not in ("true", "false"):
                    raise ParseError("invalidValue", off)
                if (d == "true") != g.directed:
                    raise ParseError("unsupported", off)
            for c in el.children:
                if c.local == "graph":
                    raise ParseError("unsupported", c.offset)
            edges.append(el)
        elif el.local == "hyperedge":
            raise ParseError("unsupported", el.offset)
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
        if not multigraph and k in merged:
            p = merged[k]
        else:
            p = g.edge(*ends)
            merged.setdefault(k, p)
        for kk, (x, _) in edge.items.items():
            if kk not in ("source", "target", "key"):
                g.eattrs[p][kk] = scalar(x)


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
    low = tok.lower()
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


def mm_read(t, g):
    ls = lines_of(t)
    if not ls or not ls[0][1].startswith("%%MatrixMarket"):
        raise ParseError("syntax", 0)
    off, head = ls[0]
    toks = tokens_of(off, head)
    if toks[0][1] != "%%MatrixMarket" or len(toks) != 5:
        raise ParseError("syntax", toks[min(len(toks) - 1, 5)][0] if len(toks) > 5 else off)
    (o1, obj), (o2, fmt), (o3, field), (o4, sym) = [(o, s.lower()) for o, s in toks[1:]]
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
    if INT_DEC.match(tok):
        x = int(tok)
        if INT_MIN <= x <= INT_MAX:
            return x
    if FLOAT_DEC.match(tok):
        x = float(tok)
        if math.isfinite(x):
            return x
    return tok


def edge_list_read(t, g, columns=()):
    width = 2 + len(columns)
    for off, line in text_lines(t):
        toks = tokens_of(off, line)
        if not toks:
            continue
        if len(toks) < width:
            raise ParseError("syntax", off + len(line))
        if len(toks) > width:
            raise ParseError("syntax", toks[width][0])
        p = g.edge(g.vertex(toks[0][1]), g.vertex(toks[1][1]))
        for name, (_, s) in zip(columns, toks[2:]):
            g.eattrs[p][name] = lexical(s)


def adjacency_list_read(t, g):
    for off, line in text_lines(t):
        toks = tokens_of(off, line)
        if not toks:
            continue
        u = g.vertex(toks[0][1])
        for _, s in toks[1:]:
            g.edge(u, g.vertex(s))


TOKEN_SAFE = re.compile(r"[^ \t\n\r\v\f#]+$")


def token(s):
    assert TOKEN_SAFE.match(s), "precondition: token-safe"
    return s


def edge_list_write(g, columns=()):
    out = []
    for (u, v), a in zip(g.edges, g.eattrs):
        parts = [token(str(g.vertices[u])), token(str(g.vertices[v]))]
        for c in columns:
            x = a[c]
            assert type(x) is not bool
            parts.append(token(py_double(x) if type(x) is float else str(x)))
        out.append(" ".join(parts) + "\n")
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

    def next_stmt(q):  # past one separator
        if q < n and t[q] == "\r":
            q += 1
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
        if word in MM_SKIP and m.end() < n and t[m.end()] in " \t":
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


# ============================================================================ readers table

def reader_for(fmt, **kw):
    if fmt == "edgeList":
        return lambda t, g: edge_list_read(t, g, kw.get("columns", ()))
    return {"dot": dot_read, "graphML": graphml_read, "nodeLinkJSON": node_link_read,
            "matrixMarket": mm_read, "adjacencyList": adjacency_list_read,
            "mermaid": mermaid_read}[fmt]


TARGETS = {
    "D": ("DirectedPseudograph<String>", True, False, str),
    "DS": ("AdjacencyList<String>", True, True, str),
    "U": ("Pseudograph<String>", False, False, str),
    "US": ("UndirectedAdjacencyList<String>", False, True, str),
    "DI": ("DirectedPseudograph<Int>", True, False, int),
    "UI": ("Pseudograph<Int>", False, False, int),
    "DSI": ("AdjacencyList<Int>", True, True, int),
}

LABEL = {"dot": "dot", "graphML": "graphML", "nodeLinkJSON": "nodeLinkJSON", "matrixMarket": "matrixMarket",
         "edgeList": "edgeList", "adjacencyList": "adjacencyList", "mermaid": "mermaid"}
WRITER = {"dot": "writeDOT(to:)", "graphML": "writeGraphML(to:)", "nodeLinkJSON": "writeNodeLinkJSON(to:)",
          "matrixMarket": "writeMatrixMarket(to:)", "edgeList": "writeEdgeList(to:)",
          "adjacencyList": "writeAdjacencyList(to:)", "mermaid": "writeMermaid(to:)"}
PREFIX = {"dot": "DT", "graphML": "GM", "nodeLinkJSON": "NL", "matrixMarket": "MM", "edgeList": "EL",
          "adjacencyList": "AL", "mermaid": "MD"}
GROUP = {"dot": "DOT", "graphML": "GraphML", "nodeLinkJSON": "Node-link JSON", "matrixMarket": "Matrix Market",
         "edgeList": "Edge list", "adjacencyList": "Adjacency list", "mermaid": "Mermaid"}


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
E("dot", "D", "subgraph (phase 2)", "digraph { subgraph s { a } }")
E("dot", "D", "anonymous subgraph as an endpoint (phase 2)", "digraph { a -> { b c } }")
E("dot", "D", "port (phase 2)", "digraph { a:p -> b }")
E("dot", "D", "a second graph (phase 2)", "digraph { a }\ndigraph { b }")
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
E("graphML", "D", "nested graph (phase 2)", H + '<graph edgedefault="directed"><node id="a"><graph edgedefault="directed"/>'
  '</node></graph></graphml>')
E("graphML", "D", "a second graph (phase 2)", H + '<graph edgedefault="directed"/><graph edgedefault="directed"/></graphml>')
E("graphML", "D", "hyperedge (phase 2)", H + '<graph edgedefault="directed"><node id="a"/><hyperedge/></graph></graphml>')
E("graphML", "D", "an edge whose directed differs from edgedefault (phase 2)", H + '<graph edgedefault="directed">'
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
E("matrixMarket", "DI", "array format (phase 2)", "%%MatrixMarket matrix array real general\n2 2\n1\n0\n0\n1\n")
E("matrixMarket", "DI", "complex (phase 2)", MMH + "complex general\n1 1 1\n1 1 1 0\n")
E("matrixMarket", "DI", "hermitian (phase 2)", MMH + "real hermitian\n1 1 0\n")
E("matrixMarket", "DI", "vector (phase 2)", "%%MatrixMarket vector coordinate real general\n3 0\n")
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
E("mermaid", "D", "subgraph ... end (phase 2)", "flowchart TD\n  subgraph one\n    A --> B\n  end\n")
E("mermaid", "D", "bidirectional link (phase 2)", "flowchart TD\n  A <--> B\n")
E("mermaid", "D", "invisible link (phase 2)", "flowchart TD\n  A ~~~ B\n")
E("mermaid", "D", "@{ } shape syntax (phase 2)", "flowchart TD\n  A@{ shape: rect }\n")
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
        return edge_list_write(g, kw.get("columns", ()))
    if f == "adjacencyList":
        return adjacency_list_write(g)
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


def library_read(c):
    """What the reference library makes of a read row: a graph comparison or None when it agrees."""
    raw = c["text"].encode() if isinstance(c["text"], str) else c["text"]
    ours = evaluate(c)
    _, directed, simple, vtype = TARGETS[c["target"]]
    f = c["fmt"]
    try:
        if f == "graphML":
            G = nx.read_graphml(io.BytesIO(raw))
            if not G.is_directed() == directed:
                return "library reads the other kind"
            if simple:
                G = (nx.DiGraph if directed else nx.Graph)(G)
        elif f == "nodeLinkJSON":
            G = nx.node_link_graph(json.loads(raw.decode("utf-8")))
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
            G = nx.read_edgelist(io.BytesIO(raw), create_using=create, data=[(k, lexical) for k in cols] if cols else False)
        elif f == "adjacencyList":
            create = (nx.DiGraph if simple else nx.MultiDiGraph)() if directed else (nx.Graph if simple else nx.MultiGraph)()
            G = nx.read_adjlist(io.BytesIO(raw), create_using=create)
        elif f == "dot":
            gs = quiet_pydot(raw.decode("utf-8"))
            if not gs:
                raise ValueError("pydot: no graph")
            pg = gs[0]
            edges = [(dot_unquote(e.get_source()), dot_unquote(e.get_destination())) for e in pg.get_edges()]
            if isinstance(ours, ParseError):
                return "library accepts it"
            if pg.get_strict() or c["target"].endswith("S"):
                return None  # pydot does not merge
            mine = [(g1, g2) for g1, g2, _ in our_edges(ours)]
            return None if edges == [(str(u), str(v)) for u, v in mine] else f"edges {edges}"
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
            nx.write_edgelist(G, b, data=list(kw.get("columns", [])) or False)
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
    # DOT: pydot 4.0.1's grammar, not Graphviz's
    "numerals are IDs": "pydot rejects a negative numeral after an edge operator",
    "attribute lists: ; and , separators, several lists": "pydot rejects ; inside [ ] and a second [ ] list",
    "a byte-order mark is skipped": "pydot does not skip a byte-order mark",
    "graph into a directed target": "pydot has no target: it reads either kind",
    "digraph into an undirected target": "pydot has no target: it reads either kind",
    "-- in a digraph": "pydot accepts either edge operator in either kind (Graphviz: syntax error)",
    "subgraph (phase 2)": "pydot reads subgraphs; phase 2 here",
    "port (phase 2)": "pydot keeps the port in the vertex name (a:p)",
    "a second graph (phase 2)": "pydot returns a list of graphs",
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
    "nested graph (phase 2)": "NetworkX flattens nested graphs",
    "a second graph (phase 2)": "NetworkX reads the first graph only",
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
    "array format (phase 2)": "SciPy reads array format; phase 2 here",
    "complex (phase 2)": "SciPy reads complex; phase 2 here",
    "hermitian (phase 2)": "SciPy reads hermitian; phase 2 here",
    "general into an undirected target": "SciPy has no target",
    "not square": "SciPy reads rectangular matrices (NetworkX from_scipy_sparse_array raises)",
    "an extra column": "SciPy ignores extra columns",
    "integer field with a fraction": "SciPy truncates 3.5 to 3",
    "hexadecimal float": "SciPy reads 0x1p3 as 0.0",
    "skew-symmetric diagonal entry": "SciPy keeps a diagonal entry in a skew-symmetric file",
    "pattern skew-symmetric": "SciPy accepts the combination the spec forbids",
    "signed index": "SciPy accepts +1 as an index",
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
    return json.dumps(x, ensure_ascii=False)


def op_of(c):
    f = c["fmt"]
    if c["kind"] == "read":
        extra = ", columns: " + json.dumps(c["kw"]["columns"]) if "columns" in c["kw"] else ""
        return f"{TARGETS[c['target']][0]}({LABEL[f]}:{extra})"
    kw = c["kw"]
    extra = ""
    if "columns" in kw:
        extra = ", columns: " + json.dumps(kw["columns"])
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
adjacency list), SciPy 1.18.1 (Matrix Market) or pydot 4.0.1 (DOT), where the library reads or writes
the format, and every write row is read back by the model. Rows where a library differs are listed,
with the reason, under "Library disagreements" in api.md.

## Notation

**Op.** A read row calls the reader initializer on the target type, with the default vertex
mapping (`String` IDs as they are; `Int` targets take Matrix Market's 1-based indices minus one,
and node-link integer ids). A write row calls the writer on the graph in **Input** with the default
`vertexID` (`String(describing:)`) and the graph's attributes as the attribute closures (`label`
only, for Mermaid; `weight:` for Matrix Market, `columns:` for the edge list).

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
        if why and c["case"] not in KNOWN:
            bad.append(f"{key} {c['fmt']} {c['case']}: {why}")
        if not why and c["case"] in KNOWN and KNOWN[c["case"]]:
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
    for f in failures[:20]:
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
