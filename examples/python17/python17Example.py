#!/usr/bin/env python3
"""python17Example: Secure Socket Layer (SSL) for client/server TFS.

Builds upon python16Example. Mirrors core17Example_main.c.

The concept introduced in this example is:

- Secure Socket Layer (SSL)

Schema and program flow are identical to python16; the difference
is that SSL is configured for the connection between client and
server. The server is configured to *require* SSL (``force_ssl``),
the client is configured to *use* SSL (``use_ssl``); the server is
assigned a certificate and a secret key, and the client blindly
trusts whatever certificate the server presents.

The certificate and private key shipped with this example (in
``cert.pem`` / ``key.pem``) are the same defaults compiled into
Raima libraries. **They are not secure and must not be used in
production** — they are provided for demonstration only.

RaimaDB does not validate the server's certificate — that is the
client's responsibility. The C example places a TBD comment where
your validation code would go after retrieving the server's
certificate via ``rdm_tfsGetCertificate()``. The exact validation
logic depends on your client's requirements (SSL version, cipher
suites, etc).

With the example as-is the data sent between client and server is
encrypted, but because the certificate and key are public and the
client does not validate them, the connection is **not** secure:
anyone with the server's certificate and key can decrypt the
traffic, and the client cannot tell whether it is connected to the
genuine server. Both must be addressed in production.

Python adaptation note: not every RaimaDB build ships with the SSL
transport. On those builds ``tfs.setOption("use_ssl", "true")``
raises ``ErrorNOTIMPLEMENTED_transportSSL``. The example catches
that and re-raises it as a typed ``SSLNotSupported`` exception so
callers can decide what to do. The pytest test for this example
skips if SSL is not supported.
"""
import os
import sys
import argparse
from rdm import *
from rdm.tfsapi import *
from rdm.dbapi import *
from rdm.cursorapi import *
from rdm.rdmapi import *
from rdm.types import *
from rdm.exceptions import *
from rdm.retcodetypes import *

HERE = os.path.dirname(os.path.abspath(__file__))

with open(os.path.join(HERE, "cert.pem")) as _f:
    CERTIFICATE = _f.read()
with open(os.path.join(HERE, "key.pem")) as _f:
    PRIVATE_KEY = _f.read()

SCHEMA = """
create table info
(
    message char(50) not null
);
"""


def read_a_row(db, tfs_type):
    rc, trans = db.startRead()
    if rc != Status.Okay:
        return rc
    rc, cursor = db.getRows("INFO")
    if rc == Status.Okay:
        status = cursor.moveToFirst()
        if status == Status.Okay:
            print("The row read from the database using {} TFS is: {}".format(
                tfs_type, cursor.MESSAGE))
        elif status == Status.EndOfCursor:
            rc = Status.EndOfCursor
        cursor.free()
    trans.end()
    return rc


def write_a_row(db, tfs_type):
    rc, trans = db.startUpdate()
    if rc != Status.Okay:
        return rc
    rc, _ = db.insertRow(
        "INFO",
        MESSAGE="Hello World! inserted using {} TFS".format(tfs_type),
    )
    if rc == Status.Okay:
        return trans.end()
    trans.endRollback()
    return rc


def do_work_with_db_handle(db, tfs_type):
    rc = Status.Okay
    if tfs_type != "server":
        rc = write_a_row(db, tfs_type)
        if rc != Status.Okay:
            return rc
    while True:
        rc = read_a_row(db, tfs_type)
        if rc != Status.EndOfCursor:
            break
    return rc


def do_work_with_tfs_handle(tfs, tfs_type):
    db = tfs.allocDatabase()
    rc = db.setCatalog(SCHEMA)
    if rc == Status.Okay:
        if tfs_type == "hybrid":
            rc = db.open("tfs-shm://21553/python17", OpenMode.SHARED)
        else:
            rc = db.open("python17", OpenMode.SHARED)
        if rc == Status.Okay:
            rc = do_work_with_db_handle(db, tfs_type)
    db.free()
    return rc


class SSLNotSupported(Exception):
    """Raised when this RaimaDB build was compiled without SSL transport."""


def configure_tfs(tfs, tfs_type):
    rc = tfs.setOption("tfstype", tfs_type)
    if rc != Status.Okay:
        return rc
    if tfs_type == "server":
        rc = tfs.setOption("listen", "tcp,shm")
        if rc != Status.Okay:
            return rc
    try:
        rc = tfs.setOption("use_ssl", "true")
        if rc != Status.Okay:
            return rc
        rc = tfs.setOption("force_ssl", "true")
        if rc != Status.Okay:
            return rc
        rc = tfs.setCertificate(CERTIFICATE)
        if rc != Status.Okay:
            return rc
        rc = tfs.setKey(PRIVATE_KEY)
    except Exception as e:
        # Some RaimaDB builds ship without the SSL transport. The bindings
        # raise (rather than return) ErrorNOTIMPLEMENTED_transportSSL in
        # that case. Convert to a typed exception so callers can decide
        # how to handle it.
        msg = "{}".format(e)
        if "SSL" in type(e).__name__ or "SSL" in msg:
            raise SSLNotSupported(msg) from e
        raise
    return rc


def do_work(tfs_type):
    tfs = allocTfs()
    try:
        rc = configure_tfs(tfs, tfs_type)
    except SSLNotSupported as e:
        print("This RaimaDB build does not support SSL: {}".format(e))
        tfs.free()
        raise
    if rc != Status.Okay:
        tfs.free()
        return rc
    rc = tfs.initialize()
    if rc != Status.Okay:
        tfs.free()
        return rc
    if tfs_type in ("server", "embed"):
        try:
            tfs.dropDatabase("python17")
        except ErrorNoDB:
            pass
    rc = do_work_with_tfs_handle(tfs, tfs_type)
    tfs.free()
    return rc


def parse_args(argv):
    parser = argparse.ArgumentParser(
        description="TFS modes example with SSL."
    )
    g = parser.add_mutually_exclusive_group()
    g.add_argument("--embed", "-e", action="store_const", dest="tfs_type", const="embed")
    g.add_argument("--server", "-s", action="store_const", dest="tfs_type", const="server")
    g.add_argument("--client", "-c", action="store_const", dest="tfs_type", const="client")
    g.add_argument("--hybrid", "-y", action="store_const", dest="tfs_type", const="hybrid")
    parser.set_defaults(tfs_type="client")
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)
    return 0 if do_work(args.tfs_type) == Status.Okay else 1


if __name__ == "__main__":
    sys.exit(main())
