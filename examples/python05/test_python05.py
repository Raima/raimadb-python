"""pytest test for python05Example. Mirrors core05Test.ps1."""
import python05Example


def test_run_main(tmp_path, monkeypatch, capsys):
    monkeypatch.chdir(tmp_path)
    assert python05Example.main([]) == 0
    out = capsys.readouterr().out
    hw = [l for l in out.splitlines() if "Hello World" in l]
    assert len(hw) == 1, f"expected 1 'Hello World' line, got {len(hw)}:\n{out}"
