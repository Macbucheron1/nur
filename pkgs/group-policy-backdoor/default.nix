{
  lib,
  python313Packages,
  fetchFromGitHub,
  makeWrapper,
}:

let
  pythonDeps = with python313Packages; [
    chardet
    ldap3-bleeding-edge
    lxml
    pydantic
    smbprotocol
    typer
  ];
in
python313Packages.buildPythonApplication {
  pname = "group-policy-backdoor";
  version = "unstable-2025-12-07";

  src = fetchFromGitHub {
    owner = "synacktiv";
    repo = "GroupPolicyBackdoor";
    rev = "c5d935b01b8288fc81e19fd62ce8cb2d4ecaacea";
    hash = "sha256-+ZjQVECYvGIXAQlyRrvz4KEx9WNBlLsWu0GT80aqnQY=";
  };

  # Upstream is a script and a Python package without packaging metadata.
  format = "other";

  nativeBuildInputs = [ makeWrapper ];

  dependencies = pythonDeps;
  dontWrapPythonPrograms = true;

  postPatch = ''
    substituteInPlace config.py \
      --replace-fail '"gpt_path": "Preferences\ScheduledTasks\ScheduledTasks.xml"' '"gpt_path": r"Preferences\ScheduledTasks\ScheduledTasks.xml"' \
      --replace-fail '"gpt_path": "Preferences\Files\Files.xml"' '"gpt_path": r"Preferences\Files\Files.xml"' \
      --replace-fail '"gpt_path": "Preferences\Groups\Groups.xml"' '"gpt_path": r"Preferences\Groups\Groups.xml"' \
      --replace-fail '"gpt_path": "Preferences\Registry\Registry.xml"' '"gpt_path": r"Preferences\Registry\Registry.xml"' \
      --replace-fail '"gpt_path": "Preferences\Folders\Folders.xml"' '"gpt_path": r"Preferences\Folders\Folders.xml"'

    substituteInPlace gpb/modules/ScheduledTasks.py \
      --replace-fail 'runAs = "NT AUTHORITY\SYSTEM"' 'runAs = r"NT AUTHORITY\SYSTEM"'

    substituteInPlace gpb/commands/gpo/create.py \
      --replace-fail 'logger.info(f"[INFO] Created the '\'''{share}\{dir_name}'\''' directory")' 'logger.info(fr"[INFO] Created the '\'''{share}\{dir_name}'\''' directory")' \
      --replace-fail 'logger.info(f"[INFO] Initialized the '\'''{share}\{dir_name}\GPT.INI'\''' file")' 'logger.info(fr"[INFO] Initialized the '\'''{share}\{dir_name}\GPT.INI'\''' file")'

    substituteInPlace gpb/commands/gpo/inject.py \
      --replace-fail 'to_create = f"{target_path}\{directory}"' 'to_create = fr"{target_path}\{directory}"' \
      --replace-fail 'target_file = f"{base_path}\{MODULES_CONFIG[module_name]['\'''gpt_path'\''']}"' 'target_file = fr"{base_path}\{MODULES_CONFIG[module_name]['\'''gpt_path'\''']}"'

    substituteInPlace gpb/commands/gpo/delete.py \
      --replace-fail 'logger.warning(f"{bcolors.FAIL}[!] Can'\'''t save original content for deleted file {smb_path}\{file_info.name}'\''', file is too big ({file_info.smb_info.end_of_file}){bcolors.ENDC}")' 'logger.warning(fr"{bcolors.FAIL}[!] Can'\'''t save original content for deleted file {smb_path}\{file_info.name}'\''', file is too big ({file_info.smb_info.end_of_file}){bcolors.ENDC}")' \
      --replace-fail 'logger.warning(f"[*] Deleting SMB file {smb_path}\{file_info.name}")' 'logger.warning(fr"[*] Deleting SMB file {smb_path}\{file_info.name}")'
  '';

  buildPhase = ''
    runHook preBuild
    PYTHONWARNINGS=error::SyntaxWarning ${python313Packages.python.interpreter} -m compileall -q .
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/${python313Packages.python.sitePackages}"
    cp -r gpb "$out/${python313Packages.python.sitePackages}/"
    install -Dm644 config.py "$out/${python313Packages.python.sitePackages}/config.py"

    install -Dm644 gpb.py "$out/${python313Packages.python.sitePackages}/group_policy_backdoor_cli.py"
    makeWrapper ${python313Packages.python.interpreter} "$out/bin/gpb" \
      --add-flags "$out/${python313Packages.python.sitePackages}/group_policy_backdoor_cli.py" \
      --prefix PYTHONPATH : "$out/${python313Packages.python.sitePackages}:${python313Packages.makePythonPath pythonDeps}"
    ln -s gpb "$out/bin/gpb.py"

    mkdir -p "$out/share/GroupPolicyBackdoor"
    cp -r modules_templates "$out/share/GroupPolicyBackdoor/"

    runHook postInstall
  '';

  pythonImportsCheck = [
    "config"
    "gpb"
    "gpb.protocols.ldap"
    "gpb.protocols.smb"
  ];

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/gpb" --help >/dev/null
    "$out/bin/gpb.py" gpo --help >/dev/null
    runHook postInstallCheck
  '';

  meta = {
    description = "Modular framework for manipulating and exploiting Group Policy Objects";
    homepage = "https://github.com/synacktiv/GroupPolicyBackdoor";
    license = lib.licenses.mit;
    mainProgram = "gpb.py";
    platforms = lib.platforms.linux;
  };
}
