{ fetchFromGitHub, buildGoModule, lib }:
buildGoModule (finalAttrs: {
  pname = "koffan";
  version = "2.1.1";
  src = fetchFromGitHub {
    owner = "PanSalut";
    repo = "Koffan";
    rev = "v${finalAttrs.version}";
    sha256 = "sha256-ZFA/++iKJm7zrijDhNgvEK7rOUGfA2decG/BaK2Z8rk=";
  };
  vendorHash = "sha256-9QNqW1Cif5sNuI5rvM5JoBTdEwWWXROcmMOVP2eOc2M=";
  meta = with lib; {
    description =
      "Free selfhosted groceries list for families and shared households";
    homepage = "https://github.com/PanSalut/Koffan";
    changelog =
      "https://github.com/PanSalut/Koffan/releases/tag/v${finalAttrs.version}";
    license = licenses.mit;
    maintainers = with maintainers; [ nobodyinperson ];
    mainProgram = "shopping-list";
  };
})
