{
  description = "eTaxes Kanton St.Gallen Privatpersonen";

  inputs.nixpkgs.url = "nixpkgs/nixos-21.11";

  outputs = { self, nixpkgs }:
    let platform = "x86_64-linux";
    in {
      packages.${platform} = let
        mkETaxesFor = { pkgs, year, version, src }:
          (pkgs.stdenv.mkDerivation {
            pname = "etaxes-ch-sg-${year}";
            inherit version;
            src = pkgs.fetchurl (src);

            phases = [ "installPhase" ];
            installPhase = let
              fontsConf = pkgs.makeFontsConf {
                fontDirectories = [ pkgs.dejavu_fonts.minimal ];
              };
            in ''
              mkdir -p $out/lib/etaxes

              # the installer wants to use its internal JRE
              # disable this. The extra spaces are needed because the installer carries
              # a binary payload, so should not change in size
              sed -e 's/^if \[ -f jre.tar.gz/if false          /' $src > installer
              chmod a+x installer

              cat <<__EOF__ > response.varfile
              sys.installationDir=$out/lib/etaxes
              sys.symlinkDir=$out/bin
              __EOF__

              export HOME=`pwd`
              export INSTALL4J_JAVA_HOME=${pkgs.jre8.home}
              export FONTCONFIG_FILE=${fontsConf}
              bash -ic './installer -q -varfile response.varfile'

              mkdir -p $out/share/applications
              for i in $out/lib/etaxes/*.desktop; do
                name=$(basename "$i")
                sed -e 's|/lib/etaxes/bin|/bin|' "$i" > "$out/share/applications/$name"
              done
              rm -r $out/lib/etaxes/*.desktop $out/lib/etaxes/uninstall
            '';

            meta = {
              description = "eTaxes Kanton St.Gallen Privatpersonen ${year}";
              homepage =
                "https://www.sg.ch/content/sgch/steuern-finanzen/steuern/elektronische-steuererklaerung/etaxes-privatpersonen.html";
              license = nixpkgs.lib.licenses.unfreeRedistributable;
              maintainers = [ nixpkgs.lib.maintainers.fabianhauser ];
              platforms = [ platform ];
            };
          });
      in {
        etaxes-ch-sg-2021 = mkETaxesFor {
          pkgs = import nixpkgs { system = platform; };
          year = "2021";
          version = "1.5.0";
          src = {
            url =
              "https://steuersoftware.sg.oca.ch/Steuern_2021/SGnP2021_installieren_unix_64bit.sh";
            sha256 = "sha256-NdCiBV9O5BBmyjtXYClOsnN2Qm5hxMQnU7h/UjFRrAE=";
          };
        };
      };
    };
}
