# The Calamares build we ship reads the bootloader choice from global storage
# (it expects a bootloader chooser page). We always install GRUB, so say so.
import libcalamares


def pretty_name():
    return "Select bootloader."


def run():
    libcalamares.globalstorage.insert("vendettaBootloader", "grub")
    return None
