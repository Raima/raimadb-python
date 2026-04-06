from .exceptions cimport exception_class_map
from .retcodetypes import Status

cdef class ReturnCodeFactory:
    cdef set return_instead

    def __init__(self):
        self.return_instead = set()

    def handleCode(self, int code) -> Status:
        if code >= 0:
            return Status(code)
        elif code in exception_class_map:
            exception_class = exception_class_map[code]
            raise exception_class()
        else:
            raise IndexError (f"Unknown error code: {code}")

    def handleCodeWithNoStatus(self, int code):
        if code == 0:
            pass
        elif code > 0:
             raise IndexError (f"Did not expect a status: {code}")
        elif code in exception_class_map:
            exception_class = exception_class_map[code]
            raise exception_class()
        else:
            raise IndexError (f"Unknown error code: {code}")

factory = ReturnCodeFactory()
