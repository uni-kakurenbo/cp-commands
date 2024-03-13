#!/usr/bin/env python3

import re
import sys
import argparse
from logging import Logger, basicConfig, getLogger
from os import getenv, environ, pathsep
from pathlib import Path
from typing import List, Set, Optional

LIB_ROOT = "/home/uni_kakurenbo/CompetitiveProgramming/sources/libraries/"
logger = getLogger(__name__)  # type: Logger

class Expander:
    atcoder_include = re.compile(r'\s*#include\s*["<](atcoder/[a-z_]*(|.hpp))[">]\s*')
    original_include = re.compile(r'\s*#include\s*"(.+)"\s*')
    include = re.compile(r'\s*#include\s*["<].+[">]\s*')

    # include_guard = re.compile(r'#.*ATCODER_[A-Z_]*_HPP')

    already_included_stl = set()

    def is_ignored_line(self, line) -> bool:
        # if self.include_guard.match(line):
        #     return True
        if line.strip() == "#pragma once":
            return True
        if self.compress and line.strip().startswith('//'):
            return True
        if self.include.match(line):
            if line in self.already_included_stl:
                return True
            self.already_included_stl.add(line)
        return 0

    def remove_comments(self, line) -> str:
        if "//" not in line: return line
        return line[:line.find("//")]

    def __init__(self, lib_paths: List[Path], compress : bool, acl : bool):
        self.lib_paths = lib_paths
        self.compress = compress
        self.acl = acl

    included = set()  # type: Set[Path]

    def find_lib(self, acl_name: str) -> Path:
        for lib_path in self.lib_paths:
            path = lib_path / acl_name
            if path.exists():
                return path
        logger.error('cannot find: {}'.format(acl_name))
        raise FileNotFoundError()

    def expand_lib(self, acl_file_path: Path) -> str:
        module = acl_file_path.relative_to(LIB_ROOT)
        if str(module).startswith("original/"): module = module.relative_to("original/")

        if acl_file_path in self.included:
            logger.info('already included: {}'.format(module))
            return ""

        self.included.add(acl_file_path)
        logger.info('include: {}'.format(module))

        acl_source = open(str(acl_file_path)).read()

        prev = "#"
        result = [f"/* [begin]: { module } */\n"]  # type: List[str]

        if not self.compress: result.append("#line 1 \"{}\"".format(module))

        for row, line in enumerate(acl_source.splitlines(), 1):
            if self.is_ignored_line(line):
                if not self.compress: result.append(f"\n/* [ignored]: { line } */")
                continue

            m = self.original_include.match(line)
            if m:
                name = m.group(1)
                result.append("\n")
                result.extend(self.expand_lib(self.find_lib(name)))
                if not self.compress: result.append("\n#line {} \"{}\"".format(row+1, module))
                continue

            m = self.atcoder_include.match(line)
            if self.acl and m:
                name = m.group(1)
                result.append("\n")
                result.extend(self.expand_lib(self.find_lib(name)))
                if not self.compress: result.append("\n#line {} \"{}\"".format(row+1, module))
                continue

            if self.compress:
                if not line: continue
                line = self.remove_comments(line)
                line = re.sub(r'\s+', " ", line).strip()
                if prev.find("#") == 0 or line.find("#") == 0: result.append("\n")
                else: result.append(" ")
            else: result.append("\n")

            result.append(line)
            prev = line.strip()

        result.append(f"\n/* [end]: { module }*/")
        result = ''.join(result)
        if self.compress:
            result = result.strip()
            result = re.sub(' +', ' ', result)
            result = re.sub('\n+', '\n', result)
        return result

    def expand(self, source: str, path : Path) -> str:
        self.included = set()

        result = []  # type: List[str]
        if not self.compress: result.append("#line 1 \"{}\"".format(path))

        for row, line in enumerate(source.splitlines(), 1):
            m = self.original_include.match(line)
            if m:
                acl_path = self.find_lib(m.group(1))
                result.append(self.expand_lib(acl_path))
                if not self.compress: result.append("#line {} \"{}\"".format(row+1, path))
                continue

            m = self.atcoder_include.match(line)
            if self.acl and m:
                acl_path = self.find_lib(m.group(1))
                result.append(self.expand_lib(acl_path))
                if not self.compress: result.append("#line {} \"{}\"".format(row+1, path))
                continue

            result.append(line)
        return '\n'.join(result).strip()

if __name__ == "__main__":
    basicConfig(
        format="%(asctime)s [%(levelname)s] %(message)s",
        datefmt="%H:%M:%S",
        level=getenv('LOG_LEVEL', 'INFO'),
    )
    parser = argparse.ArgumentParser(description='Expander')
    parser.add_argument('source', help='Source File')
    parser.add_argument('-c', '--console',
                        action='store_true', help='Print to Console')
    parser.add_argument('--no-compress',
                        action='store_false', help='Disable compression')
    parser.add_argument('--acl',
                        action='store_true', help='Expand ACL')
    parser.add_argument('--lib', help='Path to Atcoder Library')
    opts = parser.parse_args()

    lib_paths = []
    if opts.lib:
        lib_paths.extend(map(Path, opts.lib.split(";")))
    if 'CPLUS_INCLUDE_PATH' in environ:
        lib_paths.extend(
            map(Path, filter(None, environ['CPLUS_INCLUDE_PATH'].split(pathsep))))
    lib_paths.append(Path.cwd())
    expander = Expander(lib_paths, opts.no_compress, opts.acl)
    source = open(opts.source).read()
    output = expander.expand(source, Path(opts.source))

    if opts.console:
        print(output)
    else:
        with open('combined.cpp', 'w') as f:
            f.write(output)
