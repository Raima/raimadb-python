#!/usr/bin/env python3
import unittest
import python01Example_main
from io import StringIO
import os
import shutil

class Py01ExampleTest(unittest.TestCase):
    def _cleanup(self):
        db_path = "python01.rdm"
        if os.path.exists(db_path):
            shutil.rmtree(db_path)
        lock_file = "tfserver.lock"
        if os.path.exists(lock_file):
            os.remove(lock_file)
    def setUp(self):
        self._cleanup()
    def tearDown(self):
        self._cleanup()
    def test_run_main(self):
        old_stdout = sys.stdout
        sys.stdout = mystdout = StringIO()
        try:
            python01Example_main.main()
        except SystemExit:
            pass
        finally:
            sys.stdout = old_stdout
        output = mystdout.getvalue()
        lines = output.splitlines()
        hello_lines = [line for line in lines if "Hello World" in line]
        self.assertEqual(len(hello_lines), 1, "Expected exactly one line containing 'Hello World'")

if __name__ == '__main__':
    unittest.main()
