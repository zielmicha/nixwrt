{stdenv, python2, patchelf}:

rec {
  make = {libDir, package, mainExe}: stdenv.mkDerivation {
    name = package.name;
    version = package.version;
    buildInputs = [patchelf python2];
    phases = ["buildPhase" "fixupPhase"];
    buildPhase = ''
python ${./portable.py} --rpath='$ORIGIN/../../lib/${libDir}' ${package}/bin/*
cp -a ${package} $out
chmod -R 755 $out
rm -r $out/bin
mkdir -p $out/libexec/${libDir}/ $out/bin
mkdir -p $out/lib/${libDir}/
mv *.so* $out/lib/${libDir}/
mv * $out/libexec/${libDir}/
for name in ${builtins.concatStringsSep " " mainExe}; do
  ln -s ../libexec/${libDir}/$name $out/bin/
done
rm $out/libexec/${libDir}/env-vars || true # where this comes from?
'';
    fixupPhase = "";
  };
}
