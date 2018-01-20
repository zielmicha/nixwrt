import subprocess, argparse, os, sys

parser = argparse.ArgumentParser()
parser.add_argument('--out', default='.')
parser.add_argument('--rpath', default='$ORIGIN')
parser.add_argument('--arch')
parser.add_argument('--with-libc', action='store_true') # this option is buggy
parser.add_argument('exe', nargs='+')
args = parser.parse_args()

if not args.arch:
    args.arch = os.uname()[4]

linker = {
    'x86_64': '/lib64/ld-linux-x86-64.so.2',
    'armv7l': '/lib/ld-linux-armhf.so.3',
}[args.arch]
full_path = {}

system_libs = [linker.split('/')[-1]]
if not args.with_libc:
    system_libs += ['libc.so.6', 'libm.so.6', 'libutil.so.1', 'libdl.so.2', 'libpthread.so.0', 'libresolv.so.2', 'librt.so.1']

ignore_conflict = ['libgcc_s.so.1']

def find_in_path(path, name):
    for comp in path.split(':'):
        abs_path = comp + '/' + name
        if os.path.exists(abs_path):
            return os.path.realpath(abs_path)

queue = []

for exe in args.exe:
    # ignore scripts
    if open(exe, 'rb').read(2) == '#!':
        continue

    basename = os.path.basename(exe)
    full_path[basename] = exe
    queue.append(basename)

while queue:
    name = queue.pop()
    exe = full_path[name]

    out = args.out + '/' + name

    if os.path.islink(exe):
        subprocess.check_call(['cp', '-av', exe, out])
        continue

    try:
        needed = subprocess.check_output(['patchelf', '--print-needed', exe]).splitlines()
    except subprocess.CalledProcessError:
        print('skip fixing ' + name)
        subprocess.check_call(['cp', '-v', exe, out])
        continue

    rpath = subprocess.check_output(['patchelf', '--print-rpath', exe]).strip()

    for lib in needed:
        if lib in system_libs:
            continue

        lib_path = find_in_path(rpath, lib)

        if not lib_path:
            if (not rpath) or 'eeeeeeeee' in rpath: # --with-libc: workaround for missing rpath in libgcc_s.so.1
                lib_path = full_path[lib]
            else:
                sys.exit('library %s not found (needed by %s)' % (lib, name))

        if lib in full_path and full_path[lib] != lib_path and (lib not in ignore_conflict):
            sys.exit('Library conflict: %s uses %s, while other executable uses %s' % (exe, lib_path, full_path.get(lib)))

        if lib not in full_path:
            full_path[lib] = lib_path
            queue.append(lib)

    subprocess.check_call(['cp', '-v', exe, out])
    subprocess.check_call(['chmod', '755', out])
    subprocess.check_call(['patchelf', '--set-rpath', args.rpath, out])
    if '.so.' not in exe and not exe.endswith('.so'):
        subprocess.check_call(['patchelf', '--set-interpreter', linker, out])
