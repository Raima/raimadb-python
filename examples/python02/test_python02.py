"""pytest test for python02Example.

Mirrors core02Test.ps1: the example must print exactly one "Hello" line,
exactly one "World" line, and zero "Hello World" lines.
"""
import python02Example


def test_run_main(tmp_path, monkeypatch, capsys):
    monkeypatch.chdir(tmp_path)
    rc = python02Example.main([])
    assert rc == 0
    out = capsys.readouterr().out
    lines = out.splitlines()
    hello_world = [l for l in lines if "Hello World" in l]
    hello = [l for l in lines if "Hello" in l]
    world = [l for l in lines if "World" in l]
    assert len(hello_world) == 0, f"unexpected 'Hello World' line:\n{out}"
    assert len(hello) == 1, f"expected 1 'Hello' line, got {len(hello)}:\n{out}"
    assert len(world) == 1, f"expected 1 'World' line, got {len(world)}:\n{out}"
