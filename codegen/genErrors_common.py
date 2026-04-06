# codegen/genErrors_common.py
import os
import re

def transform_name(raw):
    if not raw:
        return raw
    return raw[0] + raw[1:].upper()

def parse_line(line):
    tokens = []
    i = 0
    n = len(line)
    while i < n:
        c = line[i]
        if c.isspace():
            i += 1
            continue
        if c == ',':
            tokens.append(('COMMA', ','))
            i += 1
            continue
        if c == '"':
            j = i + 1
            s = []
            while j < n:
                if line[j] == '\\':
                    j += 1
                    if j < n:
                        s.append(line[j])
                        j += 1
                    continue
                if line[j] == '"':
                    j += 1
                    break
                s.append(line[j])
                j += 1
            else:
                raise ValueError(f"Unterminated string in line: {line}")
            tokens.append(('STRING', ''.join(s)))
            i = j
            continue
        if c.isdigit() or (c == '-' and i + 1 < n and line[i + 1].isdigit()):
            j = i + 1 if c != '-' else i + 2
            while j < n and line[j].isdigit():
                j += 1
            num_str = line[i:j]
            tokens.append(('NUMBER', num_str))
            i = j
            continue
        # Keyword or other
        j = i
        while j < n and not line[j].isspace() and line[j] not in ',"':
            j += 1
        word = line[i:j].lower()
        if word == 'comment':
            tokens.append(('COMMENT', line[j:].strip()))
            i = n
            continue
        elif word == 'group':
            tokens.append(('GROUP', 'group'))
        elif word == 'code':
            tokens.append(('CODE', 'code'))
        elif word == 'skip':
            tokens.append(('SKIP', line[j:].strip()))
            i = n
            continue
        else:
            raise ValueError(f"Unknown token '{word}' in line: {line}")
        i = j
    return tokens

def get_group(tokens):
    if not tokens or tokens[0][0] != 'COMMA':
        return None
    tokens.pop(0)
    if not tokens or tokens[0][0] != 'STRING':
        return None
    name = tokens.pop(0)[1]
    if not tokens or tokens[0][0] != 'COMMA':
        return None
    tokens.pop(0)
    if not tokens or tokens[0][0] != 'NUMBER':
        return None
    startnum = int(tokens.pop(0)[1])
    return (name, startnum)

def get_code(tokens):
    if not tokens or tokens[0][0] != 'COMMA':
        return None
    tokens.pop(0)
    if not tokens or tokens[0][0] != 'NUMBER':
        return None
    num = int(tokens.pop(0)[1])
    if not tokens or tokens[0][0] != 'COMMA':
        return None
    tokens.pop(0)
    if not tokens or tokens[0][0] != 'STRING':
        return None
    name = tokens.pop(0)[1]
    if not tokens or tokens[0][0] != 'COMMA':
        return None
    tokens.pop(0)
    if not tokens or tokens[0][0] != 'STRING':
        return None
    desc = tokens.pop(0)[1]
    sqlstate = None
    if tokens and tokens[0][0] == 'COMMA':
        tokens.pop(0)
        if not tokens or tokens[0][0] != 'STRING':
            return None
        sqlstate = tokens.pop(0)[1]
    return (num, name, desc, sqlstate)

def parse_statuses_and_errors(errsource):
    if not os.path.isfile(errsource):
        raise FileNotFoundError(f"errordefns.txt not found: {errsource}")
    with open(errsource, 'r') as handle:
        lines = handle.readlines()
    errors = []
    currgroup = -1
    ndx = 0
    maxgrouplen = 0
    maxcodelen = 0
    numGen = 0
    incr = 0
    line_num = 0
    for line in lines:
        line_num += 1
        line = line.rstrip()
        if not line:
            continue
        try:
            token_list = parse_line(line)
            if not token_list:
                continue
            ttype = token_list[0][0]
            if ttype == 'COMMENT':
                continue
            tokens = token_list[1:]
            if ttype == 'GROUP':
                group_res = get_group(tokens)
                if group_res is None:
                    raise ValueError("invalid group specification")
                groupname, startnum = group_res
                if currgroup != -1:
                    if not (startnum < errors[currgroup]['endnum']):
                        raise ValueError("invalid group initial code: must be less than the last code")
                    if not (startnum <= numGen):
                        raise ValueError("invalid group initial code: overlaps with last group code assignment")
                incr = -1 if startnum < 0 else 1
                numGen = startnum
                currgroup += 1
                errors.append({
                    'name': groupname,
                    'startnum': startnum,
                    'codes': []
                })
                ndx = 0
                len_ = len(groupname)
                if maxgrouplen < len_:
                    maxgrouplen = len_
            elif ttype == 'CODE':
                code_res = get_code(tokens)
                if code_res is None:
                    raise ValueError("invalid code specification")
                num, raw_name, desc, sqlstate = code_res
                name = transform_name(raw_name)
                if not (num == numGen or raw_name == 'eNOTIMPLEMENTED_min'):
                    raise ValueError(f"invalid number, a SKIP may be needed for {raw_name}")
                numGen += incr
                info = {
                    'name': name,
                    'raw_name': raw_name,
                    'desc': desc,
                    'num': num,
                    'sqlstate': sqlstate
                }
                errors[currgroup]['codes'].append(info)
                if 'firstcode' not in errors[currgroup]:
                    errors[currgroup]['firstcode'] = name
                errors[currgroup]['lastcode'] = name
                errors[currgroup]['endnum'] = num
                len_ = len(name)
                if maxcodelen < len_:
                    maxcodelen = len_
            elif ttype == 'SKIP':
                numGen += incr
            else:
                raise ValueError("group/code/skip/comment expected")
        except ValueError as ve:
            raise ValueError(f"{errsource}:{line_num}:0: error: {ve}") from ve
    return errors, maxgrouplen, maxcodelen