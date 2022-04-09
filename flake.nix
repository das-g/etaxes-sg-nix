{
  description = "A very basic flake";

  inputs.nixpkgs.url = "nixpkgs/nixos-21.11";

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.etaxes-ch-sg-2021 = let
      pkgs = import nixpkgs { system = "x86_64-linux"; };

      responseVarfile = pkgs.writeTextFile {
        name = "response.varfile";
        text = ''
          sys.installationDir=INSTALLDIR/lib/etaxes-ch-sg-2021
          sys.symlinkDir=INSTALLDIR/bin
        '';
      };
      fontsConf =
        pkgs.makeFontsConf { fontDirectories = [ pkgs.dejavu_fonts.minimal ]; };

    in pkgs.stdenv.mkDerivation rec {
      pname = "etaxes-ch-sg-2021";
      version = "1.5.0";

      src = pkgs.fetchurl ({
        url =
          "https://steuersoftware.sg.oca.ch/Steuern_2021/SGnP2021_installieren_unix_64bit.sh";
        sha256 = "sha256-NdCiBV9O5BBmyjtXYClOsnN2Qm5hxMQnU7h/UjFRrAE=";
      });

      nativeBuildInputs = [ pkgs.makeWrapper ];
      phases = [ "installPhase" ];

      installPhase = ''
        mkdir -p $out/lib/${pname}

        # the installer wants to use its internal JRE
        # disable this. The extra spaces are needed because the installer carries
        # a binary payload, so should not change in size
        sed -e 's/^if \[ -f jre.tar.gz/if false          /' $src > installer
        chmod a+x installer

        sed -e "s|INSTALLDIR|$out|" ${responseVarfile} > response.varfile

        export HOME=`pwd`
        export INSTALL4J_JAVA_HOME=${pkgs.jre8.home}
        export FONTCONFIG_FILE=${fontsConf}
        bash -ic './installer -q -varfile response.varfile'

        mkdir -p $out/share/applications
        for i in $out/lib/etaxes-ch-sg-2021/*.desktop; do
          name=$(basename "$i")
          sed -e 's|/lib/etaxes-ch-sg-2021/bin|/bin|' "$i" > "$out/share/applications/$name"
        done
        rm -r $out/lib/etaxes-ch-sg-2021/*.desktop $out/lib/etaxes-ch-sg-2021/uninstall
      '';

      meta = {
        description = "eTaxes Kanton St.Gallen Privatperson 2022";
        homepage =
          "https://www.sg.ch/content/sgch/steuern-finanzen/steuern/elektronische-steuererklaerung/etaxes-privatpersonen.html";
        license = nixpkgs.lib.licenses.unfreeRedistributable;

        maintainers = [ nixpkgs.lib.maintainers.fabianhauser ];
        platforms = [ "x86_64-linux" ];
      };
    };
  };
}
