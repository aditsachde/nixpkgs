{ stdenv
, fetchurl
, meson
, ninja
, pkgconfig
, gettext
, alsaLib
, acpid
, bc
, ddcutil
, efl
, pam
, xkeyboard_config
, udisks2

, bluetoothSupport ? true, bluez5
, pulseSupport ? !stdenv.isDarwin, libpulseaudio
}:

stdenv.mkDerivation rec {
  pname = "enlightenment";
  version = "0.24.0";

  src = fetchurl {
    url = "http://download.enlightenment.org/rel/apps/${pname}/${pname}-${version}.tar.xz";
    sha256 = "01053hxdmyjfb6gmz1pqmw0llrgc4356np515h5vsqcn59mhvfz7";
  };

  nativeBuildInputs = [
    gettext
    meson
    ninja
    pkgconfig
  ];

  buildInputs = [
    alsaLib
    acpid # for systems with ACPI for lid events, AC/Battery plug in/out etc
    bc # for the Everything module calculator mode
    ddcutil # specifically libddcutil.so.2 for backlight control
    efl
    pam
    xkeyboard_config
    udisks2 # for removable storage mounting/unmounting
  ]
  ++ stdenv.lib.optional bluetoothSupport bluez5 # for bluetooth configuration and control
  ++ stdenv.lib.optional pulseSupport libpulseaudio # for proper audio device control and redirection
  ;

  patches = [
    # Executables cannot be made setuid in nix store. They should be
    # wrapped in the enlightenment service module, and the wrapped
    # executables should be used instead.
    ./0001-wrapped-setuid-executables.patch
  ];

  postPatch = ''
    substituteInPlace src/modules/everything/evry_plug_calc.c \
      --replace "ecore_exe_pipe_run(\"bc -l\"" "ecore_exe_pipe_run(\"${bc}/bin/bc -l\""
  '';

  mesonFlags = [
    "-D systemdunitdir=lib/systemd/user"
  ];

  passthru.providedSessions = [ "enlightenment" ];

  meta = with stdenv.lib; {
    description = "The Compositing Window Manager and Desktop Shell";
    homepage = "https://www.enlightenment.org";
    license = licenses.bsd2;
    platforms = platforms.linux;
    maintainers = with maintainers; [ matejc tstrobel ftrvxmtrx romildo ];
  };
}
