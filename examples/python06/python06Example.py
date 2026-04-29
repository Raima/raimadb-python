#!/usr/bin/env python3
"""python06Example: Many-to-many relationships.

Builds upon python03Example, python04Example, and python05Example.
Mirrors core06Example_main.c.

The concept introduced in this example is:

- Many-to-many relationships

The data model differs from earlier examples: there is a many-to-many
relationship between students and classes. Three tables are used:
``STUDENT``, ``CLASS``, and ``ENROLLMENT``. ``STUDENT`` and ``CLASS``
are the *owner* tables (in network-model terms) or *primary* tables
(in relational-model terms); ``ENROLLMENT`` is the *member* table
(or *secondary* table) and is the member side of *both*
relationships, which is what produces the many-to-many between
students and classes. References used for linking enrollment rows
are ``"ENROLLMENT_STUDENT_NAME"`` and ``"ENROLLMENT_CLASS_ID"``,
following the auto-generated ``"<MEMBER_TABLE>_<FK_COLUMN>"`` pattern.

If you understood the previous examples this one should be
straightforward; no further conceptual discussion is needed here.
"""
import sys
import datetime
from rdm import *
from rdm.tfsapi import *
from rdm.dbapi import *
from rdm.cursorapi import *
from rdm.rdmapi import *
from rdm.types import *
from rdm.exceptions import *
from rdm.retcodetypes import *

REF_STUDENT = "ENROLLMENT_STUDENT_NAME"
REF_CLASS = "ENROLLMENT_CLASS_ID"

SCHEMA = """
create table class (
   id char(10) primary key,
   title char(40) not null
);

create table student (
   name char(40) primary key
);

create table enrollment (
   begin_date date,
   end_date date,
   status char(9),
   current_grade integer,
   class_id char(10) references class,
   student_name char(40) references student
);
"""

STUDENTS = ["Jeff", "Brooke", "Jonah", "Norah", "Micah"]
CLASSES = [
    ("ACCTG1A", "Principles of Accounting"),
    ("MATH037", "Finite Mathematics"),
    ("CAOTO15", "Business Communications"),
    ("CBIS36", "Systems Analysis and Design"),
    ("IBUS1", "Introduction to International Business"),
]
ENROLLMENTS = [
    ("Jeff", "IBUS1"),
    ("Jeff", "CAOTO15"),
    ("Jeff", "ACCTG1A"),
    ("Brooke", "CBIS36"),
    ("Brooke", "IBUS1"),
    ("Jonah", "MATH037"),
    ("Jonah", "CBIS36"),
    ("Norah", "IBUS1"),
    ("Norah", "ACCTG1A"),
    ("Norah", "MATH037"),
    ("Micah", "ACCTG1A"),
]


def insert_students(db):
    for name in STUDENTS:
        rc, _ = db.insertRow("STUDENT", NAME=name)
        if rc != Status.Okay:
            return rc
    return Status.Okay


def insert_classes(db):
    for cid, title in CLASSES:
        rc, _ = db.insertRow("CLASS", ID=cid, TITLE=title)
        if rc != Status.Okay:
            return rc
    return Status.Okay


def register_for_course(db, student_name, class_id):
    """Insert an ENROLLMENT row and link it to its STUDENT and CLASS owners."""
    rc, students = db.getRowsByKey("STUDENT", "NAME")
    if rc != Status.Okay:
        return rc
    rc = students.moveToKey("NAME", NAME=student_name)
    if rc != Status.Okay:
        students.free()
        return rc
    rc, classes = db.getRowsByKey("CLASS", "ID")
    if rc != Status.Okay:
        students.free()
        return rc
    rc = classes.moveToKey("ID", ID=class_id)
    if rc != Status.Okay:
        students.free()
        classes.free()
        return rc
    today = datetime.date.today()
    rc, enrollment = db.insertRow(
        "ENROLLMENT", BEGIN_DATE=today, STATUS="enrolled"
    )
    if rc == Status.Okay:
        rc = enrollment.linkRow(REF_CLASS, classes)
    if rc == Status.Okay:
        rc = enrollment.linkRow(REF_STUDENT, students)
    students.free()
    classes.free()
    return rc


def register_for_classes(db):
    for student_name, class_id in ENROLLMENTS:
        rc = register_for_course(db, student_name, class_id)
        if rc != Status.Okay:
            return rc
    return Status.Okay


def display_class_roster(db):
    rc, trans = db.startRead()
    if rc != Status.Okay:
        return rc
    print("List of courses each student is registered for:")
    rc, students = db.getRows("STUDENT")
    if rc != Status.Okay:
        trans.end()
        return rc
    while True:
        status = students.moveToNext()
        if status == Status.EndOfCursor:
            break
        if status != Status.Okay:
            students.free()
            trans.end()
            return status
        # Snapshot the student name before getMemberRows clears at_row.
        name = students.NAME
        print("{}:".format(name))
        rc2, enrollments = students.getMemberRows(REF_STUDENT)
        if rc2 != Status.Okay:
            students.free()
            trans.end()
            return rc2
        while True:
            estatus = enrollments.moveToNext()
            if estatus == Status.EndOfCursor:
                break
            if estatus != Status.Okay:
                enrollments.free()
                students.free()
                trans.end()
                return estatus
            begin_date = enrollments.BEGIN_DATE
            rc3, course = enrollments.getOwnerRow(REF_CLASS)
            if rc3 != Status.Okay:
                enrollments.free()
                students.free()
                trans.end()
                return rc3
            course.moveToFirst()
            print("\t{}: {} {}".format(begin_date, course.ID, course.TITLE))
            course.free()
        enrollments.free()
    students.free()
    trans.end()
    return Status.Okay


def populate(db):
    rc, trans = db.startUpdate()
    if rc != Status.Okay:
        return rc
    for fn in (insert_students, insert_classes, register_for_classes):
        rc = fn(db)
        if rc != Status.Okay:
            trans.endRollback()
            return rc
    return trans.end()


def do_work_with_db_handle(db):
    rc = populate(db)
    if rc == Status.Okay:
        rc = display_class_roster(db)
    return rc


def do_work_with_tfs_handle(tfs):
    db = tfs.allocDatabase()
    rc = db.setCatalog(SCHEMA)
    if rc == Status.Okay:
        rc = db.open("python06", OpenMode.SHARED)
        if rc == Status.Okay:
            rc = do_work_with_db_handle(db)
    db.free()
    return rc


def do_work():
    tfs = allocTfs()
    rc = tfs.initialize()
    if rc != Status.Okay:
        tfs.free()
        return rc
    try:
        tfs.dropDatabase("python06")
        print("The database was dropped")
    except ErrorNoDB:
        print("The database does not exist")
    rc = do_work_with_tfs_handle(tfs)
    tfs.free()
    return rc


def main(argv=None):
    return 0 if do_work() == Status.Okay else 1


if __name__ == "__main__":
    sys.exit(main())
