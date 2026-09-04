# tablefmt

> Make Linux CLI tables easy to **hear**. Every value goes together with its
> column name — `k1: v1, k2: v2` — so a screen reader reads it correctly, with
> no hand-written `awk` or `column` pipelines.

[![License: Unlicense](https://img.shields.io/badge/license-Unlicense-blue.svg)](LICENSE)

`tablefmt` is a single [Bash](https://www.gnu.org/software/bash/) script that
formats the tabular output of common Linux commands into a linear, speakable
form. It is built for blind and visually-impaired users who read the terminal
through a screen reader — but it is equally handy for anyone who wants clean,
machine-friendly text.

## Why tablefmt?

Raw table output is hard to listen to:

- **Column names are lost.** By the time you hear a value, you have already
  forgotten which column it belongs to.
- **Numbers run together.** `20` in one column and `000` in the next become
  “twenty, zero zero zero” instead of “twenty” and “zero zero zero”.
- **Walls of numbers.** A bare `ps aux` is nearly impossible to follow by ear.

`tablefmt` turns

```
PID USER      %CPU COMMAND
123 root       0.0 bash
456 john      12.5 vim -u NONE
```

into

```
PID: 123, USER: root, %CPU: 0.0, COMMAND: bash
PID: 456, USER: john, %CPU: 12.5, COMMAND: vim -u NONE
```

Every value is announced together with its name. Simple, predictable, speakable.

## Features

- 🗣️ **Screen-reader first** — `key: value` output, one record per line
- 🧩 **Three output modes** — inline (default), vertical, and JSON Lines
- 🎯 **Column selection & sorting** — `--columns`, `--sort`, `--first`, `--last`
- 🔢 **Numbered records** — `--number` prefixes each record
- 🧼 **Handles real output** — `ps`, `top`, `df`, `free`, separator tables, and more
- 🎨 **ANSI-aware** — color codes are stripped before parsing
- 🔁 **Passthrough** — non-tabular input passes through untouched
- 🪶 **Zero dependencies** — just `bash` and `awk`

## Install

One line, no cloning required:

```bash
curl -LsSf https://raw.githubusercontent.com/alekssamos/tablefmt/main/install.sh | bash
```

This downloads `tablefmt` into `~/.local/bin` and adds that directory to your
`PATH` (via `~/.bashrc` / `~/.profile`). Open a new shell afterwards, or run:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Alternatively, clone and install:

```bash
git clone https://github.com/alekssamos/tablefmt.git
cd tablefmt
bash install.sh
```

## Usage

Pipe any tabular command into `tablefmt`:

```bash
ps aux   | tablefmt
ps -ef   | tablefmt
top -b -n 1 | tablefmt
df -h    | tablefmt
free -h  | tablefmt
```

### Output modes

| Mode       | Flag          | Output                                              |
|------------|---------------|-----------------------------------------------------|
| Inline     | *(default)*   | `PID: 123, USER: root, COMMAND: bash`               |
| Vertical   | `--vertical`  | one field per line, blank line between records      |
| JSON Lines | `--jsonl`     | `{"PID":"123","USER":"root","COMMAND":"bash"}`      |

### Options

| Option             | Description                                            |
|--------------------|--------------------------------------------------------|
| `--inline`         | one record per line (default)                          |
| `--vertical`       | each field on its own line                             |
| `--jsonl`          | each record as a JSON object per line                  |
| `--columns LIST`   | only the selected columns, e.g. `PID,%CPU,COMMAND`     |
| `--sort KEY`       | sort by column `KEY` (numeric when possible)           |
| `--first N`        | only the first `N` records                             |
| `--last N`         | only the last `N` records                              |
| `--number`         | number the records                                     |
| `--header REGEX`   | explicitly match the header line                       |
| `--separator CHAR` | explicit delimiter: `\|`, `,`, `;`, …                  |
| `--quiet`, `-q`    | stay silent when no table is found                     |
| `--strict`         | fail when no table is found                            |
| `--version`        | print the version                                      |
| `-h`, `--help`     | show help                                              |

### Examples

```bash
# Top processes by memory, numbered:
top -b -n 1 | tablefmt --columns PID,%CPU,%MEM,COMMAND --number

# The five most CPU-hungry processes:
ps aux | tablefmt --sort "%CPU" --last 5

# Filesystems, one field per line:
df -h | tablefmt --vertical

# Machine-readable records for further processing:
command | tablefmt --jsonl

# Tables with an explicit separator:
printf 'NAME|AGE|CITY\n----|----|----\nIvan|30|Moscow\n' | tablefmt --separator '|'
```

## How it works

`tablefmt` detects the header row of the incoming table — with built-in rules
for `ps`, `top`, `df`, `free` and a general heuristic — then parses rows in two
ways: **fixed-width** columns for aligned output, and **whitespace** columns
with a greedy last column for everything else. ANSI escapes are stripped first,
and anything that is not a table is passed through unchanged. The whole
formatter is a single `awk` program driven by a thin Bash wrapper — see
[`tablefmt`](tablefmt).

## Requirements

- **bash** — the shell wrapper
- **awk** — POSIX, `gawk`, `mawk`, or BSD `awk`
- **curl** — only for the one-line install

## Tests

```bash
bash tests/run.sh
```

## License

Public domain — [Unlicense](LICENSE). Do whatever you want with it.
