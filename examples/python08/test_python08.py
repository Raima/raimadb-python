"""pytest test for python08Example. Mirrors core08Test.ps1.

Each of the three underlying databases is read once (1 Hello + 1 World
each = 3 + 3) and then the union database is read (3 Hello + 3 World)
for a total of 6 each.
"""
import python08Example


def test_run_main(tmp_path, monkeypatch, capsys):
    monkeypatch.chdir(tmp_path)
    assert python08Example.main([]) == 0
    out = capsys.readouterr().out
    lines = out.splitlines()
    assert len([l for l in lines if "Hello World" in l]) == 0
    assert len([l for l in lines if "Hello" in l]) == 6
    assert len([l for l in lines if "World" in l]) == 6
