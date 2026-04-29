"""pytest test for python16Example.

The automated test only exercises ``--embed`` since orchestrating a
server subprocess is out of scope. The C core16Test.ps1 spawns a server
process and a client; here we only verify the embed path produces one
"Hello World" line.
"""
import python16Example


def test_run_embed(tmp_path, monkeypatch, capsys):
    monkeypatch.chdir(tmp_path)
    assert python16Example.main(["--embed"]) == 0
    out = capsys.readouterr().out
    hw = [l for l in out.splitlines() if "Hello World" in l]
    assert len(hw) == 1, f"expected 1 'Hello World' line, got {len(hw)}:\n{out}"
