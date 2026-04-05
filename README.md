# flattr: Flattened Attributes

_flattr_ is a simple CLI tool that converts structured data into a flat mapping
of attribute paths and values. Conversely, _unflattr_ performs the opposite
conversion from attribute paths and values into structured data. Both _flattr_
and _unflattr_ support multiple serialization formats.

## Features

The tool supports reading and writing JSON and YAML. This means reading/writing
both structured data and flattened attributes.

Does not convert between formats; structured data in JSON converts to/from flat
attributes in JSON, structured data in YAML converts to/from flat attributes in
YAML.

Attribute paths are encoded within the format and consider escape sequences.

Conversion is _lossless_. In other words, converting structures into attributes
and back again will produce the original document.

### CLI

Both `flattr` and `unflattr` are CLI tools. They read from
_stdin_, write to _stdout_, and require a single `--format` flag.

**Examples:**

```sh
flattr --format json < data.json > flat.json
```

```sh
unflattr --format yaml < flat.yaml > data.yaml
```

### JSON Support

`flattr` and `unflattr` fully support JSON.

**Path construction:** (very) loosely based on
[RFC6901](https://www.rfc-editor.org/rfc/rfc6901) JSON Pointers, using a dollar
sign (`$`) delimiter to distinguish array indexes, and replacing the numeric
escapes (i.e. `~0` for `~` and `~1` for `/`) with literal escapes when special
characters appear in the reference token:

- `~~` escapes `~`
- `~/` escapes `/`
- `~$` escapes `$`

JSON string backslash (`\`) escape sequences remain untouched.

**Empty structures:** because the existence of an empty structure (i.e. `{}` and
`[]`) carries information, yet has no attributes, pass it into the flattened
structure as is.

**Scalar documents:** if a document contains no structures, then _flattr_ and
_unflattr_ do nothing.

**Example 1:**

Structured data:

```json
{
  "a": {
    "b": "foo",
    "c": 42,
    "d": [true, false]
  },
  "e": null,
  "f": {},
  "g": {},
  "~/$": "~ escapes",
  "\\": "backslash",
}
```

Flat attributes:

```json
{
  "/a/b": "foo",
  "/a/c": 42,
  "/a/d$0": true,
  "/a/d$1": false,
  "/e": null,
  "/f": {},
  "/g": [],
  "/~~~/~$": "~ escapes",
  "/\\": "backslash"
}
```

**Example 2:**

Structured data:

```json
["one", "two", "three"]
```

Flat attributes:

```json
{
  "$0": "one",
  "$1": "two",
  "$2": "three"
}
```

**Example 3:**

Structured data:

```json
"just a scalar"
```

Flat attributes:

```json
"just a scalar"
```

### YAML Support

`flattr` and `unflattr` fully support YAML.

**Path construction:** (very) loosely based on
[YAMLPath](https://github.com/wwkimball/yamlpath/wiki/Segments-of-a-YAML-Path),
specifically using _slash notation_, using a dollar sign (`$`) delimiter to
distinguish array indexes.

Although it is possible to escape `$` with a backslash (`\`), the standards in
YAML are substantially less firm, and maintaining a natural isomorphism with
JSON is beneficial to form commutative squares on _flattr_, _unflattr_,
_json2yaml_, and _yaml2json_:

$$
\begin{align*}
\tt{flattr}_{\text{JSON}} \circ \tt{json2yaml} \
  &= \tt{json2yaml} \circ \tt{flattr}_{\text{YAML}} \\
\tt{flattr}_{\text{YAML}} \circ \tt{yaml2json} \
  &= \tt{yaml2json} \circ \tt{flattr}_{\text{JSON}} \\
\tt{unflattr}_{\text{JSON}} \circ \tt{json2yaml} \
  &= \tt{json2yaml} \circ \tt{uflattr}_{\text{YAML}} \\
\tt{unflattr}_{\text{YAML}} \circ \tt{yaml2json} \
  &= \tt{yaml2json} \circ \tt{uflattr}_{\text{JSON}} \\
\end{align*}
$$

Therefore, follow the same escaping rules as JSON by adopting tilde (`~`) as a
special character:

- `~~` escapes `~`
- `~/` escapes `/`
- `~$` escapes `$`

**Empty structures:** because the existence of an empty structure (i.e. `{}` and
`[]`) carries information, yet has no attributes, pass it into the flattened
structure as is.

**Scalar documents:** if a document contains no structures, then _flattr_ and
_unflattr_ do nothing.

**Example 1:**

Structured data:

```yaml
hash_nest:
  scalar_value: 1234
  array_values:
    - a
    - b
    - c
  array_of_hashes:
    - id: 42
      name: something
    - id: 1337
      name: something else
dotted.key.123: [On, Off]
slashed/key:
  - stuff
  - things
$42: not an array
~/$: escapes!
empty-list: []
empty-hash: {}
```

Flat attributes:

```yaml
/hash_nest/scalar_value: 1234
/hash_nest/array_values$0: a
/hash_nest/array_values$1: b
/hash_nest/array_values$2: c
/hash_nest/array_of_hashes$0/id: 42
/hash_nest/array_of_hashes$0/name: something
/hash_nest/array_of_hashes$1/id: 1337
/hash_nest/array_of_hashes$1/name: something else
/dotted.key.123$0: On
/dotted.key.123$1: Off
/slashed~/key$0: stuff
/slashed~/key$1: things
/~$42: not an array
/~~~/~$: escapes!
/empty-list: []
/empty-hash: {}
```

**Example 2:**

Structured data:

```yaml
- one
- two
- three
```

Flat attributes:

```yaml
$0: one
$1: two
$2: three
```

**Example 3:**

Structured data:

```yaml
"just a scalar"
```

Flat attributes:

```yaml
"just a scalar"
```
