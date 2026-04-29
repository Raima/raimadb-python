"""pytest test for python07Example. Mirrors core07Test.ps1."""
import python07Example


def test_run_main(tmp_path, monkeypatch, capsys):
    monkeypatch.chdir(tmp_path)
    assert python07Example.main([]) == 0
    out = capsys.readouterr().out
    lines = out.splitlines()
    assert len([l for l in lines if "Hello World" in l]) == 0
    assert len([l for l in lines if "Hello" in l]) == 1
    assert len([l for l in lines if "World" in l]) == 1
