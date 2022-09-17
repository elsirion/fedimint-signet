{ name, nodes, lib, modulesPath, ... }: {
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot = {
    initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sr_mod" "virtio_blk" ];
    kernelModules = [ "kvm-amd" ];
  };

  fileSystems."/" = {
    device = "/dev/mapper/crypt";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."crypt".device = "/dev/vda2";

  fileSystems."/boot" = {
    device = "/dev/vda1";
    fsType = "ext4";
  };

  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/vda";

  networking = {
    useDHCP = false;
    interfaces.ens3 = {
      useDHCP = lib.mkDefault true;
    };
  };
}
