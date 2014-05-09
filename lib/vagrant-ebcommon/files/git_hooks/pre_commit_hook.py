import re
import os
import subprocess
import sys

FILE_TYPE_PYTHON = 'py'
FILE_TYPE_JS = 'js'

FORBIDDEN = {
    FILE_TYPE_PYTHON: [
        'import ipdb',
        'import pdb',
    ],
    FILE_TYPE_JS: [
        'console\.',
        'debugger',
    ],
    'all': [
    ],
}

# spaces in the flake8 strings are required to ensure we're only matching these
# exact strings. for example, flake8 calls out "unable to detect undefined
# names" when "from package import *" is used. without spaces around "undefined
# name" we would match this.
FLAKE8_WARNINGS = [
    ' imported but unused',
    ' assigned to but never used',
]
FLAKE8_ERRORS = [
    ' undefined name ',
    'SyntaxError',
]

REJECT_TEMPLATE = """
%(filename)s:
%(indx)s: %(line)s

COMMIT REJECTED. Please correct the aforementioned mistake.
"""


def flake8_file(filename):
    exit_code = 0

    child = subprocess.Popen(['flake8', filename], stdout=subprocess.PIPE)
    stdout, stderr = child.communicate()

    # we only want to split out lines if you have a warning or error
    lines = None
    for warning in FLAKE8_WARNINGS:
        if warning in stdout:
            if lines is None:
                lines = stdout.split('\n')
            for line in lines:
                if warning in line:
                    print 'FLAKE8 WARNING:', line

    for error in FLAKE8_ERRORS:
        if error in stdout:
            if lines is None:
                lines = stdout.split('\n')
            for line in lines:
                if error in line:
                    print 'COMMIT REJECTED. FLAKE8 ERROR:', line
                    exit_code = 1
    return exit_code


def look_for_forbidden_items(filename):
    exit_code = 0
    regexes = FORBIDDEN['all']
    file_type = None
    if '.' in filename:
        file_type = filename.rsplit('.', 1)[1]
        regexes.extend(FORBIDDEN.get(file_type, []))
    if regexes:
        regex = '(' + '|'.join(regexes) + ')'

        with open(filename) as filedata:
            lines = filedata.readlines()
            for indx, line in enumerate(lines):
                line = line.strip()
                if re.search(regex, line):
                    print REJECT_TEMPLATE % {
                        'filename': filename,
                        'indx': indx + 1,
                        'line': line,
                    }
                    exit_code = 1

    if (
        not os.environ.get('EB_PRE_COMMIT_NO_FLAKE8') and
        file_type and
        file_type == FILE_TYPE_PYTHON
    ):
        try:
            flake_exit = flake8_file(filename)
            # make sure we don't override the exit_code above if flake succeeds
            if flake_exit > 0:
                exit_code = flake_exit
        except OSError:
            try:
                import flake8
            except ImportError:
                print 'Please install flake8 to continue: pip install flake8'
                exit_code = 1
    return exit_code


if __name__ == '__main__':
    files = sys.argv[1:]
    for f in files:
        # Ignore files that have been deleted.
        if os.path.exists(os.path.abspath(f)):
            exit_val = look_for_forbidden_items(f)
            if exit_val:
                sys.exit(exit_val)
