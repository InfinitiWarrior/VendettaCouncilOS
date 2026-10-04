{
  description = "Vendetta Council OS — NixOS edition (live ISO + installer)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    plasma-manager.url = "github:nix-community/plasma-manager";
    plasma-manager.inputs.nixpkgs.follows = "nixpkgs";
    plasma-manager.inputs.home-manager.follows = "home-manager";
  };

  outputs = { self, nixpkgs, home-manager, plasma-manager }: {
    nixosConfigurations.vendetta-iso = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix"
        home-manager.nixosModules.home-manager
        { home-manager.sharedModules = [ plasma-manager.homeManagerModules.plasma-manager ]; }
        ./vendetta.nix
      ];
    };

    packages.x86_64-linux.iso =
      self.nixosConfigurations.vendetta-iso.config.system.build.isoImage;
  };
}
