"""pytest test for python01Example.

Mirrors the assertion in core01Test.ps1: the example must print exactly
one line containing "Hello World".

The test runs in a temporary working directory so the database files
(`python01.rdm/`, `tfserver.lock`) created by the example don't pollute
the repo and don't interfere with other tests.
"""
import python01Example


def test_run_main(tmp_path, monkeypatch, capsys):
    monkeypatch.chdir(tmp_path)
    rc = python01Example.main([])
    assert rc == 0
    out = capsys.readouterr().out
    hello_lines = [line for line in out.splitlines() if "Hello World" in line]
    assert len(hello_lines) == 1, (
        f"Expected exactly one 'Hello World' line, got {len(hello_lines)}:\n{out}"
    )
