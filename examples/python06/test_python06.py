"""pytest test for python06Example. Mirrors core06Test.ps1."""
import python06Example


def test_run_main(tmp_path, monkeypatch, capsys):
    monkeypatch.chdir(tmp_path)
    assert python06Example.main([]) == 0
    out = capsys.readouterr().out
    micah = [l for l in out.splitlines() if "Micah" in l]
    assert len(micah) == 1, f"expected 1 'Micah' line, got {len(micah)}:\n{out}"
