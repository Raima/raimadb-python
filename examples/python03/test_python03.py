"""pytest test for python03Example.

Mirrors core03Test.ps1: the example must print exactly one line containing
"Hello World".
"""
import python03Example


def test_run_main(tmp_path, monkeypatch, capsys):
    monkeypatch.chdir(tmp_path)
    rc = python03Example.main([])
    assert rc == 0
    out = capsys.readouterr().out
    hello_world = [l for l in out.splitlines() if "Hello World" in l]
    assert len(hello_world) == 1, f"expected 1 'Hello World' line, got {len(hello_world)}:\n{out}"
