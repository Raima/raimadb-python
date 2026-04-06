#include <Python.h>
#include <stdio.h>  // for snprintf
#include <string.h> // for memset
#include "rdmbcdtypes.h"

// Clamp exp to int8_t limits (prevents overflow)
static int8_t clamp_exp(int exp_val) {
    if (exp_val > 127) return 127;
    if (exp_val < -128) return -128;
    return (int8_t)exp_val;
}

RDM_EXPORT extern "C" int bcd_to_decimal(const RDM_BCD_T* bcd, PyObject **out) {
    if (!bcd || !out) return -1;
    if (bcd->flags != 0) {
        return -1;
    }
    if (bcd->prec > 32) {
        return -1;
    }
    PyObject *decimal_mod = PyImport_ImportModule("decimal");
    if (!decimal_mod) return -1;

    PyObject *dec = NULL;
    if (bcd->prec == 0) {
        // Zero case
        dec = PyObject_CallMethod(decimal_mod, "Decimal", "s", "0");
    } else {
        // Validate digits (0-9)
        for (uint32_t i = 1; i <= bcd->prec; ++i) {
            if (bcd->data[i] > 9) {
                Py_DECREF(decimal_mod);
                return -1;
            }
        }
        // Build mantissa string from data[1..prec] (normalized, leading non-zero)
        char mant_str[33] = {0};
        for (uint32_t i = 0; i < bcd->prec; ++i) {
            mant_str[i] = '0' + bcd->data[i + 1];
        }
        // Decimal exponent: exp_d = bcd->exp - prec (adjusts for 0-based indexing in Decimal)
        int exp_d = bcd->exp - (int)bcd->prec;
        // Full string for Decimal: sign + mantissa + E + exp_d
        char full_str[64] = {0};
        const char *sign_prefix = (bcd->sign < 0) ? "-" : "";
        snprintf(full_str, sizeof(full_str), "%s%sE%d", sign_prefix, mant_str, exp_d);
        // Create Decimal from string (handles normalization)
        dec = PyObject_CallMethod(decimal_mod, "Decimal", "s", full_str);
    }
    Py_DECREF(decimal_mod);
    if (!dec) return -1;
    *out = dec;  // Caller must Py_DECREF
    return 0;
}

RDM_EXPORT extern "C" int decimal_to_bcd(PyObject *dec, RDM_BCD_T* out) {
    if (!dec || !out) return -1;
    PyObject *decimal_mod = PyImport_ImportModule("decimal");
    if (!decimal_mod) return -1;
    PyObject *DecimalType = PyObject_GetAttrString(decimal_mod, "Decimal");
    Py_DECREF(decimal_mod);
    if (!DecimalType || !PyObject_TypeCheck(dec, (PyTypeObject *)DecimalType)) {
        Py_XDECREF(DecimalType);
        return -1;
    }
    Py_XDECREF(DecimalType);

    // Use as_tuple() for sign, digits (tuple of ints 0-9), exponent
    PyObject *tuple = PyObject_CallMethod(dec, "as_tuple", NULL);
    if (!tuple || !PyTuple_Check(tuple) || PyTuple_GET_SIZE(tuple) != 3) {
        Py_XDECREF(tuple);
        return -1;
    }
    PyObject *sign_obj = PyTuple_GET_ITEM(tuple, 0);
    PyObject *digits_obj = PyTuple_GET_ITEM(tuple, 1);
    PyObject *exp_obj = PyTuple_GET_ITEM(tuple, 2);
    if (!PyTuple_Check(digits_obj)) {
        Py_DECREF(tuple);
        return -1;
    }

    int is_neg = PyObject_IsTrue(sign_obj);
    if (is_neg == -1) {
        Py_DECREF(tuple);
        return -1;
    }
    long exp_d_long = PyLong_AsLong(exp_obj);
    if (exp_d_long == -1 && PyErr_Occurred()) {
        Py_DECREF(tuple);
        return -1;
    }
    int exp_d = (int)exp_d_long;

    Py_ssize_t orig_prec = PyTuple_GET_SIZE(digits_obj);
    if (orig_prec > 32) {
        Py_DECREF(tuple);
        return -1;
    }

    // Extract and validate digits
    uint8_t dig[100] = {0};
    int all_zero = 1;
    for (Py_ssize_t i = 0; i < orig_prec; ++i) {
        PyObject *d_obj = PyTuple_GET_ITEM(digits_obj, i);
        long d_long = PyLong_AsLong(d_obj);
        if (d_long == -1 || d_long < 0 || d_long > 9) {
            Py_DECREF(tuple);
            return -1;
        }
        dig[i] = (uint8_t)d_long;
        if (dig[i] != 0) all_zero = 0;
    }

    // Zero handling
    if (orig_prec == 0 || all_zero) {
        memset(out, 0, sizeof(RDM_BCD_T));
        out->prec = 0;
        out->exp = 0;
        out->sign = 1;
        out->flags = 0;
        Py_DECREF(tuple);
        return 0;
    }

    // Set precision (Decimal normalized: no leading zeros)
    uint8_t new_prec = (uint8_t)orig_prec;
    memset(out, 0, sizeof(RDM_BCD_T));
    for (uint8_t i = 0; i < new_prec; ++i) {
        out->data[i + 1] = dig[i];
    }
    // BCD exp: exp = exp_d + prec (positions decimal point after exp digits from left)
    out->prec = new_prec;
    out->exp = clamp_exp(exp_d + (int)new_prec);
    out->sign = is_neg ? -1 : 1;
    out->flags = 0;

    Py_DECREF(tuple);
    return 0;
}
