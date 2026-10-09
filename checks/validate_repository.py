#!/usr/bin/env python3
"""Validate provenance and historical data; never execute a MATLAB model."""
from __future__ import annotations
import csv
import hashlib
import json
import math
from pathlib import Path
import re
import statistics
import sys
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
HIST = ROOT / "data" / "historical"
COLUMNS = [
    "model", "case_id", "run_index", "param_name", "param_value_SI",
    "param_unit", "entrance_theta", "x_half", "slope_half", "broadness",
    "x_half_status", "slope_status", "broadness_status", "valid_half",
    "valid_broad", "exclusion_reason", "source_id",
]
CASE_LENGTHS = [5, 5, 5, 5, 5, 6, 5, 5]
STATUSES = {"recorded", "not_recorded", "no_crossing"}
VALIDITY = {"true", "false", "unknown"}
A_SOURCE = "week3:ca4f0d64-7a61-42d1-a5fe-f89b28fb75aa"
B_SOURCE = "compare_modelAB:B_arrays"

def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)

def close(a: float, b: float, message: str, *, tolerance: float = 1e-12) -> None:
    require(math.isclose(a, b, rel_tol=tolerance, abs_tol=0.0), message)

def read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))

def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def numeric_literals(body: str) -> list[str]:
    tokens = body.strip().split()
    require(bool(tokens), "Empty MATLAB numeric array")
    require(all(re.fullmatch(r"(?:NaN|[+-]?(?:\d+\.?\d*|\.\d+)(?:e[+-]?\d+)?)", t, re.I)
                for t in tokens), "Unexpected MATLAB numeric array expression")
    return tokens

def matlab_array(code: str, variable: str) -> list[str]:
    escaped = re.escape(variable)
    array = re.search(escaped + r"\s*=\s*\.\.\.\s*\[([^\]]+)\](\s*\*\s*[0-9.eE+-]+)?\s*;", code)
    if array:
        values = numeric_literals(array.group(1))
        if array.group(2):
            factor = float(array.group(2).split("*", 1)[1])
            require("NaN" not in values, "NaN in a scaled parameter array")
            return [repr(float(v) * factor) for v in values]
        return values
    repeated = re.search(escaped + r"\s*=\s*\.\.\.\s*([0-9.eE+-]+)\s*\*\s*ones\(1,(\d+)\)\s*;", code)
    require(repeated is not None, "Could not parse preserved array: " + variable)
    return [repeated.group(1)] * int(repeated.group(2))

def parse_a_log(text: str) -> dict[tuple[int, int], dict[str, str]]:
    case_id = 0
    parsed = {}
    for line in text.splitlines():
        header = re.fullmatch(r"Case (\d+)", line)
        if header:
            case_id = int(header.group(1))
        run = re.fullmatch(
            r"Run (\d+): entrance = (\S+), xhalf = (\S+), slope = (\S+), broadness = (\S+)", line)
        if run:
            parsed[(case_id, int(run.group(1)))] = dict(zip(
                ("entrance_theta", "x_half", "slope_half", "broadness"), run.groups()[1:]))
        exposure = re.fullmatch(r"pA0 = (\S+) Pa, tend = (\S+) s, xhalf = (\S+)", line)
        if exposure:
            index = 1 + sum(key[0] == 8 for key in parsed)
            parsed[(8, index)] = {
                "param_value_SI": exposure.group(1), "tend": exposure.group(2), "x_half": exposure.group(3)}
    require(len(parsed) == 41, "Console excerpt must contain all 41 A case/run keys")
    return parsed

def check_sources() -> str:
    manifest = read_json(ROOT / "data" / "source_manifest.json")
    require(manifest["file_count"] == 21 and len(manifest["files"]) == 21,
            "Source manifest must describe exactly 21 preserved .m files")
    paths = []
    for entry in manifest["files"]:
        path = ROOT / entry["path"]
        require(path.is_file(), "Missing preserved source: " + entry["path"])
        require(sha256(path) == entry["sha256"], "Source hash changed: " + entry["path"])
        paths.append(entry["path"])
    actual = {p.relative_to(ROOT).as_posix() for p in (ROOT / "src").rglob("*.m")}
    require(actual == set(paths) and len(paths) == len(set(paths)), "Manifest/source inventory mismatch")
    require(not list(ROOT.rglob("*.asv")), "Autosave .asv file must not be published")
    return (ROOT / "src" / "ModelA_Reproduction" / "compare_modelAB.m").read_text(encoding="utf-8")

def check_data(code: str) -> tuple[list[dict[str, str]], dict]:
    with (HIST / "metrics.csv").open(encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        require(reader.fieldnames == COLUMNS, "CSV columns/order differ from the archive contract")
        rows = list(reader)
    require(len(rows) == 82, "Expected 41 A rows and 41 B rows")
    sources = read_json(HIST / "sources.json")
    require(sources["csv_contract"]["columns"] == COLUMNS, "Metadata CSV schema differs")
    require(sources["scope"] == "Existing scientific results only; no model recomputation.",
            "Archive scope declaration changed")
    require({s["source_id"] for s in sources["sources"]} == {A_SOURCE, B_SOURCE},
            "Unexpected scientific source registry")
    bsource = next(s for s in sources["sources"] if s["source_id"] == B_SOURCE)
    require(bsource["sha256"] == sha256(ROOT / "src/ModelA_Reproduction/compare_modelAB.m"),
            "B source hash metadata differs")
    log_text = (HIST / "model_a_comparison_log.txt").read_text(encoding="utf-8")
    require("[User attached" not in log_text and "李元" not in log_text,
            "Scientific excerpt must exclude conversation/attachment/private discussion text")
    a_log = parse_a_log(log_text)
    expected_keys = {(model, c, i) for model in ("A", "B")
                     for c, count in enumerate(CASE_LENGTHS, 1) for i in range(1, count + 1)}
    lookup = {}
    metadata = {(r["model"], r["case_id"], r["run_index"]): r for r in sources["runs"]}
    require(len(metadata) == 82 and set(metadata) == expected_keys, "Run metadata keys incomplete")
    parameter_arrays = {
        c: [float(v) for v in matlab_array(code, "values{" + str(c) + "}")] for c in range(1, 8)}
    pressure8 = [float(v) for v in matlab_array(code, "pA0_case8")]
    time8 = [float(v) for v in matlab_array(code, "tend_case8")]
    expected_names = {
        "A": ["T", "pA0", "MA", "H", "tend", "c", "q", "pA0"],
        "B": ["T", "pA0", "MA", "AR", "tend", "beta0", "s0", "pA0"],
    }
    expected_units = {
        "A": ["K", "Pa", "kg/mol", "m", "s", "1", "m^-2", "Pa"],
        "B": ["K", "Pa", "kg/mol", "1", "s", "1", "m^2", "Pa"],
    }
    for row in rows:
        require(None not in row and set(row) == set(COLUMNS), "Malformed CSV row")
        model, case_id, index = row["model"], int(row["case_id"]), int(row["run_index"])
        key = (model, case_id, index)
        require(key in expected_keys and key not in lookup, "Unknown or duplicate row key")
        lookup[key] = row
        require(row["source_id"] == (A_SOURCE if model == "A" else B_SOURCE), "Wrong row provenance")
        require(row["valid_half"] in VALIDITY and row["valid_broad"] in VALIDITY, "Invalid mask value")
        for value, status in (("x_half", "x_half_status"), ("slope_half", "slope_status"),
                              ("broadness", "broadness_status")):
            require(row[status] in STATUSES, "Invalid metric status")
            if row[status] == "recorded":
                require(row[value] != "" and math.isfinite(float(row[value])), "Recorded metric absent/nonfinite")
            else:
                require(row[value] == "", "Unavailable metric must have an empty numeric field")
        if row["entrance_theta"]:
            require(math.isfinite(float(row["entrance_theta"])), "Invalid entrance value")
        require(row["param_name"] == expected_names[model][case_id - 1], "Wrong parameter name")
        require(row["param_unit"] == expected_units[model][case_id - 1], "Wrong parameter unit")
        value = pressure8[index - 1] if case_id == 8 else parameter_arrays[case_id][index - 1]
        if model == "B" and case_id == 4:
            value = 500e-6 / value
        if model == "B" and case_id == 7:
            value = 1 / value
        close(float(row["param_value_SI"]), value, "Parameter mapping differs from Table-2 source")
        meta = metadata[key]
        close(meta["parameters_SI"][row["param_name"]], value, "Run metadata parameter mapping differs")
        if case_id == 8:
            close(meta["parameters_SI"]["tend"], time8[index - 1], "Missing constant-exposure paired time")
            close(value * meta["parameters_SI"]["tend"], 10.0, "Constant exposure must equal 10 Pa s")
        if model == "A":
            original = a_log[(case_id, index)]
            for valuefield, statusfield in (("x_half", "x_half_status"), ("slope_half", "slope_status"),
                                           ("broadness", "broadness_status")):
                token = original.get(valuefield)
                expected_status = "not_recorded" if token is None else "no_crossing" if token == "NaN" else "recorded"
                require(row[statusfield] == expected_status, "A metric missing-value semantic changed")
                require(row[valuefield] == (token if expected_status == "recorded" else ""), "A transcription differs")
            require(row["entrance_theta"] == original.get("entrance_theta", ""), "A entrance transcription differs")
            if case_id == 8:
                require(row["valid_half"] == row["valid_broad"] == "unknown", "A Case VIII masks cannot be inferred")
                require("not_logged" in row["exclusion_reason"], "A Case VIII missing-data reason absent")
            else:
                saturated = float(row["entrance_theta"]) >= 0.999
                valid4 = saturated and row["x_half_status"] == row["slope_status"] == "recorded"
                valid5 = saturated and row["broadness_status"] == "recorded"
                require(row["valid_half"] == str(valid4).lower(), "A half mask differs from original policy")
                require(row["valid_broad"] == str(valid5).lower(), "A width mask differs from original policy")
            close(meta["numerical_settings"]["tstart_s"], 0.001, "A historical tstart setting differs")
            close(meta["numerical_settings"]["entrance_threshold"], 0.999, "A threshold metadata differs")
        else:
            for valuefield, sourcefield, statusfield in (
                    ("x_half", "xhalf", "x_half_status"), ("slope_half", "slope", "slope_status"),
                    ("broadness", "broad", "broadness_status")):
                token = matlab_array(code, "B_" + sourcefield + "{" + str(case_id) + "}")[index - 1]
                expected_status = "not_recorded" if token == "NaN" else "recorded"
                require(row[statusfield] == expected_status, "B source NaN must be unavailable, not no_crossing")
                require(row[valuefield] == (token if expected_status == "recorded" else ""), "B literal transcription differs")
            require(row["entrance_theta"] == "", "B entrance was not retained; do not fabricate")
            for maskfield, sourcemask in (("valid_half", "valid4"), ("valid_broad", "valid5")):
                token = matlab_array(code, "B_" + sourcemask + "{" + str(case_id) + "}")[index - 1]
                require(row[maskfield] == ("true" if token == "1" else "false"), "B historical mask differs")
            ep = 2.0 if case_id == 6 and index == 1 else 0.2 if case_id == 6 and index == 2 else 0.05
            close(meta["numerical_settings"]["ep"], ep, "B high-beta step setting differs")
            close(meta["numerical_settings"]["entrance_threshold"], 0.995, "B threshold metadata differs")
    require(set(lookup) == expected_keys, "CSV case inventory incomplete")
    require([len(parameter_arrays[c]) for c in range(1, 8)] == CASE_LENGTHS[:7]
            and len(pressure8) == len(time8) == 5, "Table-2 lengths changed")
    return rows, read_json(HIST / "historical_summary.json")

def check_arithmetic(rows: list[dict[str, str]], summary: dict) -> None:
    lookup = {(r["model"], int(r["case_id"]), int(r["run_index"])): r for r in rows}
    values = {"penetration": [], "slope": [], "broadness": []}
    for (model, case_id, index), a in lookup.items():
        if model != "A" or case_id > 7:
            continue
        b = lookup[("B", case_id, index)]
        if a["valid_half"] == b["valid_half"] == "true":
            values["penetration"].append(float(b["x_half"]) / float(a["x_half"]))
            values["slope"].append(float(a["slope_half"]) / float(b["slope_half"]))
        if a["valid_broad"] == b["valid_broad"] == "true":
            values["broadness"].append(float(b["broadness"]) / float(a["broadness"]))
    require({k: len(v) for k, v in values.items()} == {"penetration": 26, "slope": 26, "broadness": 24},
            "Historical I-VII parity counts differ")
    expected = {"penetration": 1.4858283832016121, "slope": 1.9894567184796872,
                "broadness": 2.7564552931339854}
    names = {"penetration": "B_over_A_penetration", "slope": "A_over_B_slope",
             "broadness": "B_over_A_broadness"}
    reproduced = summary["recomputed_cases_I_VII"]
    require(reproduced["counts"] == {k: len(v) for k, v in values.items()}, "Summary counts differ")
    for k in values:
        mean = statistics.mean(values[k])
        close(mean, expected[k], "Historical printed arithmetic changed")
        close(mean, reproduced["means"][names[k]], "Dataset summary ratio differs")
    close(reproduced["penetration_increase_percent"], 100 * (statistics.mean(values["penetration"]) - 1),
          "Penetration percentage differs")
    require(summary["model_recomputed"] is False, "Archive cannot claim a new model run")
    reported = summary["historical_reported_all_cases"]
    require(reported["counts"] == {"penetration": 31, "slope": 31, "broadness": 29},
            "Reported all-case counts changed")
    require(reported["means"] == {"B_over_A_penetration": 1.4867, "A_over_B_slope": 1.9657,
                                  "B_over_A_broadness": 2.6226}, "Reported all-case ratios changed")
    all_penetration = values["penetration"] + [
        float(lookup[("B", 8, i)]["x_half"]) / float(lookup[("A", 8, i)]["x_half"])
        for i in range(1, 6)]
    conditional = summary["conditional_penetration_check_including_case_VIII"]
    close(conditional["ratio"], statistics.mean(all_penetration), "Conditional penetration check differs")
    require(f"{statistics.mean(all_penetration):.4f}" == "1.4867", "Rounded all-case penetration differs")
    require(f"{100 * (statistics.mean(all_penetration) - 1):.2f}" == "48.67", "Rounded penetration increment differs")
    require("reported" in conditional["mask_basis"].lower() and conditional["csv_masks_remain"].startswith("unknown"),
            "Conditional use of Case VIII must disclose reported mask basis")

def check_links() -> int:
    count = 0
    for path in ROOT.rglob("*.md"):
        text = path.read_text(encoding="utf-8")
        text = re.sub(r"\x60{3}[\s\S]*?\x60{3}", "", text)
        definitions = {}
        for match in re.finditer(r"^\s*\[([^\]]+)\]:\s*(\S+)", text, re.M):
            definitions[match.group(1).casefold()] = match.group(2)
        targets = [m.group(1) for m in re.finditer(r"!?\[[^\]]*\]\(([^)]+)\)", text)]
        for match in re.finditer(r"!?\[([^\]]*)\]\[([^\]]*)\]", text):
            name = (match.group(2) or match.group(1)).casefold()
            require(name in definitions, "Undefined Markdown reference in " + str(path.relative_to(ROOT)))
            targets.append(definitions[name])
        targets += list(definitions.values())
        targets += [m.group(1) for m in re.finditer(r'<(?:img|a)\b[^>]*(?:src|href)=["\']([^"\']+)["\']', text, re.I)]
        for target in targets:
            target = target.strip()
            target = target[1:target.find(">")] if target.startswith("<") else target.split()[0]
            require(not re.match(r"^[A-Za-z]:[\\/]", target), "Published Markdown has an absolute local path")
            require(urlsplit(target).scheme != "file", "Published Markdown must not use a local file URI")
            if target.startswith("#") or urlsplit(target).scheme or target.startswith("//"):
                continue
            local = unquote(urlsplit(target).path)
            if not local:
                continue
            require(not re.match(r"^[A-Za-z]:[\\/]", local), "Published Markdown has an absolute local path")
            resolved = ((ROOT / local.lstrip("/")) if local.startswith("/") else path.parent / local).resolve()
            require(resolved.is_relative_to(ROOT.resolve()), "Markdown link escapes repository: " + local)
            require(resolved.exists(), "Broken local Markdown link: " + str(path.relative_to(ROOT)) + " -> " + local)
            count += 1
    return count

def main() -> int:
    try:
        code = check_sources()
        print("PASS: 21 original MATLAB source hashes and autosave exclusion")
        rows, summary = check_data(code)
        print("PASS: 82 CSV rows, source-exact transcription, masks, missing values, and SI case mappings")
        check_arithmetic(rows, summary)
        print("PASS: historical I-VII arithmetic (26/26/24) and labelled conditional penetration check")
        links = check_links()
        print(f"PASS: {links} repository-local Markdown/image links")
        print("Archive checks passed. No MATLAB solver or simulation was run.")
        return 0
    except (AssertionError, ValueError, KeyError, OSError, TypeError) as exc:
        print("FAIL: " + str(exc), file=sys.stderr)
        return 1

if __name__ == "__main__":
    raise SystemExit(main())

