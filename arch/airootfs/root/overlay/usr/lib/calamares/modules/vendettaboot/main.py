import libcalamares

def pretty_name():
    return "Select bootloader."

def run():
    libcalamares.globalstorage.insert("vendettaBootloader", "grub")
    return None
