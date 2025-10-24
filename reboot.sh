import os
import platform

def reboot_computer():
    """
    Reboots the computer based on the detected operating system.
    """
    system_os = platform.system()

    if system_os == "Windows":
        # For Windows: shutdown /r /t 0 initiates an immediate restart
        os.system("shutdown /r /t 0")
    elif system_os == "Linux" or system_os == "Darwin":  # Darwin is macOS
        # For Linux/macOS: 'reboot now' initiates an immediate restart
        # 'sudo' might be required depending on user permissions
        try:
            os.system("reboot now")
        except Exception:
            print("Reboot failed. Try running the script with administrative privileges (e.g., using 'sudo' on Linux/macOS).")
    else:
        print(f"Operating system '{system_os}' not supported for automatic reboot.")

if __name__ == "__main__":
    confirm = input("Are you sure you want to reboot the computer? (yes/no): ").lower()
    if confirm == "yes":
        print("Rebooting in progress...")
        reboot_computer()
    else:
        print("Reboot cancelled.")
