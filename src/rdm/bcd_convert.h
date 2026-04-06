#ifndef BCD_CONVERT_H
#define BCD_CONVERT_H

#include "rdmbcdtypes.h"
#include <Python.h>

extern "C" {
    int bcd_to_decimal(const RDM_BCD_T* bcd, PyObject **out);
    int decimal_to_bcd(PyObject *dec, RDM_BCD_T* out);
}

#endif // BCD_CONVERT_H