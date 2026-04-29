"""pytest test for python20Example.

The C example loops forever by default; we run a small fixed number of
iterations with a tiny sleep so the test completes quickly.
"""
import python20Example


def test_run_main(tmp_path, monkeypatch, capsys):
    monkeypatch.chdir(tmp_path)
    assert python20Example.main(["-i", "5", "-m", "10"]) == 0
    out = capsys.readouterr().out
    inserted = [l for l in out.splitlines() if l.startswith("Inserted:")]
    read = [l for l in out.splitlines() if l.startswith("Read:")]
    assert len(inserted) == 5, f"expected 5 'Inserted:' lines, got {len(inserted)}:\n{out}"
    assert len(read) == 5, f"expected 5 'Read:' lines, got {len(read)}:\n{out}"
