{
  description = "eTaxes Kanton St.Gallen Privatpersonen";

  inputs.nixos2111.url = "nixpkgs/nixos-21.11";
  inputs.nixos2211.url = "nixpkgs/nixos-22.11";
  inputs.nixos2405.url = "nixpkgs/nixos-24.05";
  inputs.nixos-unstable.url = "nixpkgs/nixos-unstable";

  outputs = { self, nixos2111, nixos2211, nixos2405, nixos-unstable }:
    let
      platform = "x86_64-linux";
      packageName = year: "etaxes-ch-sg-${builtins.toString year}";
    in {
      packages.${platform} = let
        mkETaxesFor = { pkgs, year, version, src, lib }:
          (pkgs.stdenv.mkDerivation {
            pname = packageName year;
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
              export INSTALL4J_JAVA_HOME=${pkgs.jre.home}
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
              description = "eTaxes Kanton St.Gallen Privatpersonen ${
                  builtins.toString year
                }";
              homepage =
                "https://www.sg.ch/content/sgch/steuern-finanzen/steuern/elektronische-steuererklaerung/etaxes-privatpersonen.html";
              license = lib.licenses.unfreeRedistributable;
              maintainers = [ lib.maintainers.fabianhauser ];
              platforms = [ platform ];
              mainProgram = "Steuer St.Gallen ${builtins.toString year} nP";
            };
          });
        mkAllowUnfreePkg = year: {
          allowUnfreePredicate = pkg:
            (nixos2111.lib.getName pkg) == (packageName year);
        };
        defaultUrl = year: "https://steuersoftware.sg.oca.ch/Steuern_${builtins.toString year}/SGnP${builtins.toString year}_installieren_unix_64bit.sh";
      in {
        ${packageName 2021} = let year = 2021;
        in mkETaxesFor {
          pkgs = import nixos2111 {
            system = platform;
            config = mkAllowUnfreePkg year;
          };
          lib = nixos2111.lib;
          inherit year;
          version = "1.5.0";
          src = {
            url = defaultUrl 2021;
            sha256 = "sha256-NdCiBV9O5BBmyjtXYClOsnN2Qm5hxMQnU7h/UjFRrAE=";
          };
        };
        ${packageName 2022} = let year = 2022;
        in mkETaxesFor {
          pkgs = import nixos2211 {
            system = platform;
            config = mkAllowUnfreePkg year;
          };
          lib = nixos2211.lib;
          inherit year;
          version = "1.2.0";
          src = {
            url = defaultUrl 2022;
            sha256 = "sha256-BZfw/nmtl9+QJ2c2rtvq0fKnfLqR9rSxMUIsDD7JhLg=";
          };
        };
        ${packageName 2023} = let year = 2023;
        in mkETaxesFor {
          pkgs = import nixos2405 {
            system = platform;
            config = mkAllowUnfreePkg year;
          };
          lib = nixos2405.lib;
          inherit year;
          version = "1.2.0";
          src = {
            url = defaultUrl 2023;
            sha256 = "sha256-zNMmcPjjexnkc945cYZv2BH1ef/LLQ6hFt3kuz8nY+Y=";
          };
        };
        ${packageName 2024} = let year = 2024;
        in mkETaxesFor {
          pkgs = import nixos-unstable {
            system = platform;
            config = mkAllowUnfreePkg year;
          };
          lib = nixos-unstable.lib;
          inherit year;
          version = "1.2.0";
          src = {
            url = defaultUrl 2024;
            sha256 = "sha256-KgpzTN4ZIg6Udiar11QhxIfcWj1nj/cA8P/kzEwgnbE=";
          };
        };

      default = self.packages.${platform}.${packageName 2022};
      };
    };
}
