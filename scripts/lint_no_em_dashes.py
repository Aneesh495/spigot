#!/usr/bin/env python3
"""
Lint script to ensure that no em dashes (\u2014) or en dashes (\u2013)
exist anywhere in the repository.
"""

import os
import sys

FORBIDDEN_CHARS = {
    '\u2014': 'Unicode Em Dash U+2014',
    '\u2013': 'Unicode En Dash U+2013',
}

EXCLUDED_DIRS = {'.git', '.build', 'build', '__pycache__', '.pytest_cache'}

def lint_file(file_path):
    violations = []
    try:
        with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
            for line_num, line in enumerate(f, 1):
                for char, name in FORBIDDEN_CHARS.items():
                    if char in line:
                        col = line.index(char) + 1
                        violations.append((line_num, col, name, line.strip()))
    except Exception as e:
        print(f"Error reading {file_path}: {e}", file=sys.stderr)
    return violations

def main():
    root_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    has_violations = False
    checked_count = 0

    for dirpath, dirnames, filenames in os.walk(root_dir):
        dirnames[:] = [d for d in dirnames if d not in EXCLUDED_DIRS]
        for filename in filenames:
            ext = os.path.splitext(filename)[1].lower()
            if ext in ['.nut', '.cpp', '.hpp', '.h', '.c', '.py', '.sh', '.md', '.txt', '.yaml', '.yml', '.json', '']:
                full_path = os.path.join(dirpath, filename)
                rel_path = os.path.relpath(full_path, root_dir)
                violations = lint_file(full_path)
                checked_count += 1
                if violations:
                    has_violations = True
                    print(f"Violation in {rel_path}:")
                    for line_num, col, name, snippet in violations:
                        print(f"  Line {line_num}:{col} [{name}]: {snippet}")

    if has_violations:
        print("\nLint failed: forbidden dashes detected.", file=sys.stderr)
        sys.exit(1)
    else:
        print(f"Lint passed: {checked_count} files checked. Zero forbidden dashes found.")
        sys.exit(0)

if __name__ == '__main__':
    main()
