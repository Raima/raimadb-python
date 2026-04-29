"""pytest test for python17Example.

Only the embed path is exercised automatically — the server/client/hybrid
paths require a separate TFS process. If the linked RaimaDB build does
not include the SSL transport, the test is skipped.
"""
import pytest
import python17Example


def test_run_embed(tmp_path, monkeypatch, capsys):
    monkeypatch.chdir(tmp_path)
    try:
        rc = python17Example.main(["--embed"])
    except python17Example.SSLNotSupported as e:
        pytest.skip(f"RaimaDB build has no SSL transport: {e}")
    assert rc == 0
    out = capsys.readouterr().out
    hw = [l for l in out.splitlines() if "Hello World" in l]
    assert len(hw) == 1, f"expected 1 'Hello World' line, got {len(hw)}:\n{out}"
